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
