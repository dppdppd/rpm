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

## Worker Result

### Summary

All four refinements implemented. F2 (no-ops counter) was already
present in `status.sh` from a prior pass — left in place and added
bats coverage to lock the behavior in. F1/F3/F4 required SKILL.md
prose changes (both runtimes) plus a new helper script for F4. New
bats tests pass; full suite still green (160 tests, 0 failures);
shellcheck clean.

### F1 — WATCH keyword

- `plugin/skills/next/SKILL.md` Task Selection step 3: added an
  explicit skip rule for `WATCH` entries (treated like closed
  `DONE`/`CANCELLED`).
- `codex/.codex/skills/next/SKILL.md`: same change, runtime-mirrored.
- `plugin/skills/init-rpm/SKILL.md` future-tracker template:
  `#+TODO: TODO IN-PROGRESS BLOCKED WATCH | DONE` plus a short
  paragraph documenting WATCH semantics.
- `codex/.codex/skills/init-rpm/SKILL.md`: same change.
- `docs/rpm/future/tasks.org` header: added `WATCH` keyword on the
  `#+TODO:` line. **Did not retag any existing entries** — that's a
  separate housekeeping pass.

### F2 — no-ops column in status.sh

- `plugin/skills/next/scripts/status.sh`: confirmed `no-ops:` counter
  was already in the Today line (added in a prior pass that landed
  before this ticket was filed). Both the live log-present branch
  and the log-missing branch include the column.
- `codex/.codex/skills/next/scripts/status.sh`: same; already
  mirrored.
- Verification: `bash plugin/skills/next/scripts/status.sh` runs
  cleanly against this repo's live log and reports `no-ops: 0` for
  today (correct — no `no-op` entries dated 2026-05-26).
- New bats: `plugin/tests/next-status-noops.bats` (3 tests covering
  empty-log default, today's no-ops counted, prior-day no-ops
  excluded). No edit was required to status.sh itself; this finding
  is now anchored by the test rather than left as ambient behavior.

### F3 — today's date in dispatch prompt

- `plugin/skills/next/SKILL.md` Worker Contract: added
  `- today: <YYYY-MM-DD>` to the task block and a new Rule 0
  instructing workers to use that literal value for any dated
  artifact. Added a paragraph above the contract requiring the
  orchestrator to compute `$(date +%Y-%m-%d)` at dispatch time and
  substitute it in.
- `codex/.codex/skills/next/SKILL.md`: same change.
- This is prose only; the actual substitution happens when a future
  `/next` run dispatches a worker.

### F4 — Pre-completed-task skip helper

- `plugin/skills/next/scripts/is-pre-completed.sh` (new, executable):
  reads `docs/rpm/future/tasks.org`, finds the entry whose
  `:ID:` matches the argument, extracts its `[[file:...]]` link, and
  greps the linked detail file for `^## Worker Result`. Exits 0 when
  the section exists; exits 1 for any defensive failure (missing
  argument, missing tasks.org, missing entry, missing link, missing
  file, no Worker Result section).
- `codex/.codex/skills/next/scripts/is-pre-completed.sh` (new): same
  content, runtime-mirrored.
- `plugin/skills/next/SKILL.md` Task Selection step 3: added an
  instruction to call `is-pre-completed.sh <id>` before declaring a
  task actionable; on exit 0, log
  `drift-fix: pre-completed-todo: <id>` and continue.
- `codex/.codex/skills/next/SKILL.md`: same change, with the codex
  `${RPM_PLUGIN_ROOT:-...}` path expansion.
- New bats: `plugin/tests/is-pre-completed.bats` (6 tests covering
  Worker Result present → 0, missing → 1, unknown task → 1, missing
  detail file → 1, no argument → 1, no tasks.org → 1).
- Recommendation A (audit-side auto-promote of stale TODOs whose
  detail file already carries Worker Result) is **out of scope for
  this ticket**. If the pre-completion drift-fix log line shows up
  in practice, file a separate ticket to add an `/audit` pass that
  proposes flipping matching `** TODO` → `** DONE`.

### Files changed

```
plugin/skills/next/SKILL.md                      (F1 + F3 + F4 prose)
plugin/skills/init-rpm/SKILL.md                  (F1 template + WATCH doc)
plugin/skills/next/scripts/is-pre-completed.sh   (F4 new helper, +x)
codex/.codex/skills/next/SKILL.md                (F1 + F3 + F4 prose mirror)
codex/.codex/skills/init-rpm/SKILL.md            (F1 template mirror)
codex/.codex/skills/next/scripts/is-pre-completed.sh (F4 mirror, +x)
docs/rpm/future/tasks.org                        (F1: #+TODO header only)
plugin/tests/next-status-noops.bats              (F2 new tests)
plugin/tests/is-pre-completed.bats               (F4 new tests)
```

### Verification run

```
$ bash plugin/tests/run.sh
... 160 tests passed; 0 failed (was 151 baseline + 9 new)

$ shellcheck \
    plugin/skills/next/scripts/is-pre-completed.sh \
    codex/.codex/skills/next/scripts/is-pre-completed.sh \
    plugin/skills/next/scripts/status.sh \
    codex/.codex/skills/next/scripts/status.sh
(exit 0; no findings)

$ bash plugin/skills/next/scripts/status.sh
== Today (2026-05-26) ==
  drift fixes: 0   dispatches: 8   needs review: 7   approved: 7   plans: 0   blocked: 3   no-ops: 0
```

Manual sanity for is-pre-completed against this repo's live state:
- `task-unassigned-backfill` (Worker Result present) → exit 0
- `next-refinements` (no Worker Result yet) → exit 1
- `nonexistent-task` → exit 1

### Remaining risks / follow-ups

- **WATCH detection only takes effect on new bootstraps and on
  manual retagging.** This ticket added the keyword
  infrastructure to the `#+TODO:` header, the `/next` skip rule,
  and the init-rpm template — but it did NOT retag the deferred
  entries called out in the source ticket
  (`sessionstart-clear-flake`, `pivot-capture-hook`,
  `phase3-retry-hardening`). A separate housekeeping pass should
  flip those `** TODO`s to `** WATCH` once the new keyword
  propagates.
- **Audit-side stale-TODO sweep (Rec A) deferred.** If the
  `pre-completed-todo` drift-fix log lines start appearing in
  practice, file a follow-up ticket to add an `/audit` pass that
  proposes flipping pre-completed `** TODO`s to `** DONE`.
- **F2 was already implemented in code before this ticket.** The
  ticket's wording assumed status.sh did not yet count no-ops, but
  the column is in both runtimes' status.sh as of this pass. The
  net effect of this ticket on F2 is regression protection (new
  bats coverage), not a behavior change.
- **`done.org` template still reads
  `#+TODO: TODO IN-PROGRESS BLOCKED | DONE CANCELLED`** (no
  `WATCH`). Intentional: the closed-archive file only holds DONE
  and CANCELLED entries; `WATCH` belongs in active tasks.org.
- **score-natives.bats fixture still uses the old `#+TODO:` line.**
  It tests scoring on a fixture, not real bootstrap output, so it
  was left alone to avoid coupling unrelated tests to the keyword
  change.
