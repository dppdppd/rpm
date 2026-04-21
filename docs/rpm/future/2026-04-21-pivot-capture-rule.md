# Pivot-capture rule: marker + tasks.org top on mid-session redirects

## Description
When the user pivots mid-session to new multi-step work (meets
TaskCreate bar), the LLM must immediately:

1. Edit `docs/rpm/~rpm-session-start` — update the `task:` field.
2. Insert a `** TODO` at the **top** of the actionable band in
   `docs/rpm/future/tasks.org`.
3. Write a detail file `docs/rpm/future/YYYY-MM-DD-slug.md`.
4. Run `TaskCreate` for session-scoped tracking.

No separate user question — the pivot request IS the confirmation.

## Scope
- `plugin/hooks/_directives.sh` — add one directive line (shared
  source for SessionStart + post-compact injection).
- `plugin/skills/backlog/SKILL.md` — preamble callout referencing
  the directive.
- Memory: `feedback_pivot_capture.md` + MEMORY.md index entry.

## Threshold (when to apply vs. skip)
**Apply:** multi-step, multi-file, explicit "work on X" framing —
same bar as `TaskCreate`.

**Skip:** single-step tactical requests — "explain this",
"rename x → y", "run tests", "commit", "push", operational
commands, conversational questions.

## Rationale
Native tasks vanish on abnormal exit. The marker-backfill in
session-start synthesizes a title from conversation but is lossy.
Auto-promoting pivots to the backlog top keeps durable state
accurate even if `/session-end` never runs.

## Follow-up
File a separate backlog item for **hook enforcement**: a PostToolUse
matcher on Edits to `~rpm-session-start` that mirrors the `task:`
field to the top of `tasks.org` automatically, making the marker
the single source of truth. Defer until LLM-side drift is observed.
