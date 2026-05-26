# Backfill `task: (unassigned)` in marker before it propagates

## Gap
`docs/rpm/~rpm-session-start`'s `task:` field stays at `(unassigned)` when
sessions die without /session-end, propagating into every subsequent
SessionStart resume nudge and making the "what's next" prompt useless.

## Evidence
- volta `/home/coder/projects/volta/docs/rpm/~rpm-session-start`:
  filesystem state shows marker stuck since **2026-04-28, ~27 days** —
  surviving multiple CC and Codex sessions.
- Codex: **215 propagated occurrences** of `task: (unassigned)` across 8+
  Codex sessions surveyed.
- volta Claude: **240 instances** of `task: (unassigned)` in SessionStart
  previews.
- BIT, BGSD: 3/6 sessions surface `(unassigned)` in resume nudges.

The `/session-end` skill already has a "Backfill an unassigned task title"
step; the bug is that sessions that die without /session-end never reach
that path, and the Stop hook doesn't mirror the logic.

## Platform
**Both** — both runtimes write the marker via session-start-auto.sh and
both can leave it unassigned.

## Proposed fix
Two complementary fixes:

1. **Stop hook backfill**: in `plugin/hooks/stop-learn-capture.sh` (or
   `handoff-validator.sh`), when the marker `task:` is still `(unassigned)`
   AND the session had file edits, derive a title from `git log -1
   --format=%s` plus modified files and rewrite the marker.

2. **session-start-auto.sh fallback**: when reading the marker for the
   resume nudge, if `task:` is `(unassigned)` and `~rpm-last-session`
   has a `top_actionable` field, substitute that instead of showing the
   literal `(unassigned)`.

## Validation
- Manual: simulate a CC session with edits but no /session-end (Ctrl-D),
  assert marker `task:` is backfilled before next session start.
- Filesystem audit: `find ~/projects -name '~rpm-session-start' -exec grep
  -l 'task: (unassigned)' {} +` should return ≤ 1 file (the currently
  active session).

## Worker Result

### Summary
Both fixes landed. Stop hook now backfills `task: (unassigned)` from the
last commit subject (or modified-file basenames) when the session shows
real work; SessionStart resume nudge substitutes
`~rpm-last-session.top_actionable` (or `next:`, or `(no task recorded)`)
for the placeholder so propagation is at least labelled differently when
a session genuinely did nothing.

### Files changed
- `plugin/hooks/stop-learn-capture.sh` — new `backfill_unassigned_marker`
  function fires when marker `task: (unassigned)` AND porcelain
  (excluding `docs/rpm/~rpm-*` metadata) OR commits since `started:`.
  Derived title strips conventional-commit prefixes, capped at 80 chars,
  sed-escaped before in-place rewrite.
- `codex/.codex/hooks/stop-learn-capture.sh` — identical mirror.
- `plugin/hooks/session-start-auto.sh` — after parsing `TASK` from
  marker, substitute placeholder with last-session `top_actionable:` →
  `next:` → `(no task recorded)`. Display-only; does not rewrite the
  marker.
- `codex/.codex/hooks/session-start-auto.sh` — identical mirror.
- `plugin/tests/stop-learn-capture.bats` — six new backfill tests
  (positive commit subject, conventional-prefix strip, basename
  fallback, negative clean repo, untouched if already titled, 80-char
  cap).
- `plugin/tests/session-start.bats` — three new fallback tests
  (`top_actionable` substitution, `next:` substitution, `(no task
  recorded)` when neither present).
- `plugin/tests/helpers.bash` — `seed_minimal_trackers` now commits the
  seeded trackers and adds `docs/rpm/~rpm-*` to `.gitignore` so the
  sandbox mirrors a real rpm-initialized repo (otherwise porcelain
  leaked tracker fixtures and broke the backfill negative test).

### Verification
- bats: 145/145 pass (added 9, was 136).
  ```
  ok 125 backfill: rewrites (unassigned) to commit subject when session has new commits
  ok 126 backfill: strips conventional-commit prefix
  ok 127 backfill: uses modified file basenames when there are uncommitted edits but no new commits
  ok 128 backfill negative: clean repo with no new commits → marker untouched
  ok 129 backfill: does not touch already-titled marker
  ok 130 backfill: caps derived title at 80 chars
  ...
  ok 115 (unassigned) marker + last-session top_actionable → resume nudge shows top_actionable
  ok 116 (unassigned) marker + last-session with only next: → falls back to next:
  ok 117 (unassigned) marker with no last-session → displays (no task recorded)
  ```
- shellcheck: `shellcheck -e SC1091` on all four touched hooks exits 0.
  Pre-existing SC1091 info on `source ./_directives.sh` in both
  session-start hooks is unchanged by this work.

### Remaining risks
- **Title heuristic is approximate.** Commit subject from `git log -1`
  may not reflect what the session actually worked on (e.g. an
  unrelated `chore:` commit committed at session start, then the user
  works on something else without committing). Accepted because the
  alternative — leaving `(unassigned)` to propagate — is strictly
  worse, and the fallback `(no task recorded)` from fix 2 would be
  equally uninformative.
- **Filter excludes `docs/rpm/~rpm-*` from porcelain.** A user editing
  a session-state file by hand won't trigger backfill, but that's
  vanishingly rare and intentional.
- **Backfill runs on every Stop event,** not just session-final stops.
  After the first Stop with real work, the marker no longer has
  `(unassigned)` so subsequent Stops short-circuit at the first grep.
  Cheap, idempotent.
- **No-op when `started:` is absent or malformed.** The marker writer
  always sets it via `date -Iseconds`, but if a hand-edited marker
  lacks the field, `git log --since=""` returns the whole log — we'd
  still need porcelain to flip the no-work guard, so this only
  mis-fires on dirty trees with no commits, where derivation is
  obviously approximate anyway.
