# /next refinements from end-to-end validation

Three findings surfaced when /next was first run end-to-end (against
sessionstart-clear-flake on 2026-04-30). All are small, none block
the orchestrator from working — but each will recur until fixed.

## F1 — Watch tasks aren't formally distinguished from actionable ones

The SKILL's priority-3 trigger picks "TODO with no `:BLOCKED_BY:`"
as actionable. But tasks like `sessionstart-clear-flake`,
`pivot-capture-hook`, and `phase3-retry-hardening` carry "Defer
until observed" / "Watch only" semantics in the detail-file body.
The dispatched subagent has to read the detail and infer the watch
state, then emit `no-op`. Wasteful — one subagent round-trip per
watch task per /next idle pass.

**Fix options (pick one):**

- Add `WATCH` keyword to org-mode `#+TODO:` line:
  `#+TODO: TODO IN-PROGRESS BLOCKED WATCH | DONE`. Update /next's
  priority-3 detection to skip `WATCH` entries. Cleanest.
- Use an org-mode tag: `:WATCH:` after the heading. Same idea,
  different mechanism.
- Add `:DEFERRED: t` to the `:PROPERTIES:` drawer.

Recommendation: `WATCH` keyword. Surfaces in the SessionStart
backlog menu (which already filters TODO/IN-PROGRESS) without
adding new parsing.

## F2 — `status.sh` "Today" counters miss `no-op`

Currently counts:
- `drift fixes`
- `dispatches`
- `completions` (backlog-result with status=plan-written)
- `blocked` (backlog-result with status=blocked)

`no-op` results aren't counted, so a watch-heavy backlog reports
"0 work happened today" when in fact every dispatch returned
no-op (i.e. all watch tasks confirmed). Add a fourth column:
`no-ops: <N>`. Trivial: one extra line in `plugin/skills/next/scripts/status.sh`.

## F3 — Subagent used stale date in investigation note

The validation subagent appended an investigation note dated
`2026-04-28` when actual today was `2026-04-30`. Subagents lack
reliable date sense — they should not infer it.

**Fix:** /next's actionable-backlog dispatch prompt should pass
`$(date +%Y-%m-%d)` explicitly as a `today: <date>` field, and
the prompt should instruct the subagent to use that exact value
for any date stamps in artifacts.

## Scope

All three are quick:

- F1: ~10 lines in /next SKILL.md + the `#+TODO:` header in any
  bootstrapped tasks.org. Bootstrap script (init-rpm) needs the
  new keyword too.
- F2: 1 jq query addition + 1 echo line in status.sh.
- F3: 2-3 lines in /next SKILL.md's dispatch prompt template.

Estimate: ~30 minutes total.

## Provenance

Surfaced 2026-04-30 during the end-to-end validation of
`/loop /next` against `sessionstart-clear-flake`. Validation
result: orchestrator works as designed; these three are
refinements, not blockers.
