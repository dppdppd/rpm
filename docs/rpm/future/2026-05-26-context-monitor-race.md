# Fix context-monitor.sh race condition

## Gap
`plugin/hooks/context-monitor.sh:28-29` does non-atomic read-modify-write on
`$COUNTER_FILE`. Concurrent PostToolUse fires from parallel Bash calls (or
parallel subagent dispatches) corrupt the counter into a multi-line value,
crashing the script on every subsequent invocation.

## Evidence
- volta Claude transcripts: **543+ stderr crashes across 8 sessions**.
- Worst session `c06be4a7-7994-4bf7-a03f-132c09d0e14c.jsonl:1690` — 198 crashes
  in one session.
- Quote: `context-monitor.sh: line 29: 1\n50: syntax error in expression
  (error token is "50")` — counter file ate concurrent writes.
- Not reproduced in Codex sampling (lower PostToolUse concurrency).

## Platform
**CC-only** (same script ships in Codex manifest but sampling didn't hit the
race — keep an eye on it once Codex concurrency increases).

## Proposed fix
One of:
1. `flock -x` around the increment.
2. Atomic write: `printf '%d\n' "$count" > "$COUNTER_FILE.tmp" && mv -f
   "$COUNTER_FILE.tmp" "$COUNTER_FILE"`.
3. Defensive read: `COUNT=$(head -1 "$COUNTER_FILE" 2>/dev/null | tr -dc 0-9
   || echo 0)`.

Approach #2 is cheapest and matches `mv`-rename atomic-write conventions in
the codebase.

## Validation
- bats test: spawn 20 concurrent invocations of the hook, assert counter
  ends at 20 and no stderr.
- Manual: trigger several parallel Bash calls in a volta session, watch
  stderr.

## Worker Result

### Summary
Applied approach #2 (atomic tmp+mv write) plus approach #3 (defensive read
via `head -1 | tr -dc 0-9`) to the counter-file read/modify/write in
`context-monitor.sh`. File-format corruption is eliminated; a pre-existing
torn file now self-heals on first read instead of crashing line 29. The
identical Codex mirror was patched in lockstep. Three new bats tests guard
the fix.

### Files changed
- `plugin/hooks/context-monitor.sh` — lines 26-30 → defensive read +
  atomic write block.
- `codex/.codex/hooks/context-monitor.sh` — same change (mirror stayed in
  lockstep; `diff` confirms files are byte-identical post-edit).
- `plugin/tests/context-monitor.bats` — three new tests:
  1. recovers from a pre-corrupted multi-line counter file (asserts no
     crash + counter becomes `2`),
  2. rewrites a clean single-line integer after corrupted read (asserts
     `wc -l == 1` and body matches `^[0-9]+$`),
  3. 20 concurrent invocations never crash and produce a valid integer
     counter (asserts no `syntax error` / `integer expression expected`
     in stderr, file is a clean single-line integer).

### Verification run
shellcheck (newly installed locally via apt; CI already runs it):
```
$ shellcheck plugin/hooks/context-monitor.sh ; echo $?
0
$ shellcheck codex/.codex/hooks/context-monitor.sh ; echo $?
0
```

bats (full suite via `bash plugin/tests/run.sh`):
```
ok 23 recovers from a pre-corrupted multi-line counter file
ok 24 rewrites a clean single-line integer after corrupted read
ok 25 20 concurrent invocations never crash and produce a valid integer counter
...
132 tests, 0 failures
```

### Remaining risks / caveats
- **Read-modify-write race not fully eliminated.** Approach #2 fixes file-
  format corruption (the actual crash signature in volta) but does NOT
  serialize increments. Two concurrent workers can both read `N`, both
  write `N+1`, and one increment is lost. The new 20-concurrent test
  reflects this: it asserts the final counter is a valid integer in
  `(0, 20]`, not exactly 20. Brief originally specified `== 20` — flagged
  this as the chosen approach's intended trade-off. If exact counts ever
  matter (they don't today — counter just gates the every-10th throttle),
  switch to approach #1 (`flock -x`).
- Atomic-write semantics rely on `$COUNTER_FILE.tmp` and `$COUNTER_FILE`
  living on the same filesystem (both under `/tmp`, so safe).
- The defensive read returns `0` for an entirely non-numeric file (e.g.
  someone manually wrote `garbage\n`). That's the same effective behavior
  as the pre-bug "file missing" branch — counter resets to 1 next call.
  Acceptable; the only consequence is one cycle of skipped throttling.
