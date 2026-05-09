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

## F4 — Pre-completed tasks not detected before dispatch (2026-05-09)

Tasks linked to detail files that already contain a populated
`## Worker Result` section get dispatched as actionable, the
worker reads the file, finds it's done, returns `no-op`. Wasteful
in the same way as F1 — one subagent round-trip per stale TODO.

Observed 3× in a single Volta session (2026-05-09):
`tier3-resolver-square-zone`, `tier3-resolver-piece-at`,
`pax-pamir-2000-deck-numpieces-stale`. Each task linked a detail
file with `## Worker Result` from a prior run; tasks.org just
hadn't been flipped to DONE because the worker either crashed
before writing the org marker, or the orchestrator filed the task
without auditing the file first.

**Fix options (pick one):**

- **Auto-promote at audit time.** During `/audit`, grep linked
  detail files for `^## Worker Result` and propose flipping
  matching `** TODO` → `** DONE`. Surfaces stale TODOs without
  requiring an in-the-loop check on every `/next` dispatch.
- **Exclude at task-selection time.** `/next` task-selection step
  greps the linked detail file before declaring a task actionable.
  If `^## Worker Result` matches, skip + log `drift-fix:
  pre-completed-todo: <id>` and continue past it. Self-healing
  but adds I/O to every task-selection pass (fine — these are
  small files).

Recommendation: option B for /next's hot path (cheap grep, prevents
the wasted dispatch deterministically), AND option A for /audit
(catches stale entries that nothing has tried to dispatch yet).

Implementation surface for option B: `plugin/skills/next/scripts/`
(new helper, e.g. `is-pre-completed.sh <task-id>`) + the SKILL.md
task selection step references it.

## Scope

All four are quick:

- F1: ~10 lines in /next SKILL.md + the `#+TODO:` header in any
  bootstrapped tasks.org. Bootstrap script (init-rpm) needs the
  new keyword too.
- F2: 1 jq query addition + 1 echo line in status.sh.
- F3: 2-3 lines in /next SKILL.md's dispatch prompt template.
- F4: ~20 lines for `is-pre-completed.sh <task-id>` (grep linked
  detail file for `^## Worker Result`) + 3 lines in SKILL.md task
  selection to skip-and-log when it matches. Optional /audit
  pass: ~15 lines to scan + propose DONE flips.

Estimate: ~45 minutes total.

## Provenance

Surfaced 2026-04-30 (F1-F3) during end-to-end validation of
`/loop /next` against `sessionstart-clear-flake`. F4 surfaced
2026-05-09 in a Volta session that filed 3 stale TODOs in one
gap-fill pass — each forced a worker round-trip that returned
`no-op`. Validation result: orchestrator works as designed;
these refinements close known I/O-waste paths, not correctness
bugs.
