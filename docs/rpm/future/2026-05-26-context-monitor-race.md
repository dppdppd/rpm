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
