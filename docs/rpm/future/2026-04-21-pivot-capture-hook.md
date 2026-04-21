# Pivot-capture hook: mirror marker → tasks.org top automatically

## Description
Follow-up to the LLM-side pivot-capture rule (see
`2026-04-21-pivot-capture-rule.md`). Hook-enforce the backlog
mirror so the session marker becomes the single source of truth:
LLM updates the `task:` field, hook auto-inserts the corresponding
`** TODO` at the top of the actionable band.

## Shape
- `plugin/hooks/marker-mirror.sh` — new hook.
- Trigger: `PostToolUse` with matcher on `Edit` / `Write` tool calls
  targeting `docs/rpm/~rpm-session-start`.
- Behavior:
  1. Read the new `task:` field from the marker.
  2. If `tasks.org` already has a matching `** TODO` (heading-text
     or `:ID:` match), promote it to the top of the actionable band
     (no duplicate).
  3. Otherwise insert a new `** TODO <task>` at the top of the
     actionable band with an auto-generated `:ID:` derived from
     the task title (slugified).
  4. Skip if the `task:` value is `(unassigned)` or unchanged.

## Edge cases
- Detail file creation stays LLM-responsible (hook can't write
  `YYYY-MM-DD-slug.md` content meaningfully).
- If tasks.org has no `* Active` heading, create one.
- Concurrent LLM edit + hook run: since the hook runs after the
  tool call completes, there's no race with the same tool call;
  but two sequential Edits could both fire the hook. Idempotent
  insertion (check for match first) handles this.

## Defer until
LLM-side drift is observed — the rule in `_directives.sh` should
suffice in practice. Revisit if we see pivots missed across
multiple sessions.

## Estimate
~45 minutes: write hook + bats tests + wire into `hooks.json`.
