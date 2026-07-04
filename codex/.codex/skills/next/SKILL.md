---
name: next
description: One-step rpm orchestrator, or a bounded internal sequence when given a count or scope. Runs preflight maintenance, then starts the next obvious backlog action (or, in direct use, asks for clarification when nothing is clearly next). With no argument it runs one step; with `N`, `blocked`, `all`, or a group name it runs several steps itself, skipping the heavy preflight between steps, and is the recommended way to work several backlog items at once — cheaper than driving `rpm:next` from an external loop. How wide it fans out — one worker at a time or a concurrent batch — is the orchestrator's judgment call, sized to how independent the selected work is; it never waits for input mid-sequence. TRIGGER on terse forward-motion prompts — phrasings like "next", "next?", "next.", "next task", "what's next", "do next", "go next", "keep going", "continue" (when the prior turn was rpm work) all qualify and must route through this skill instead of being answered inline from the SessionStart preview. Use whenever the user wants the session to autonomously work the rpm backlog.
---

# rpm:next

Orchestrator that handles preflight maintenance, then tries to move the
backlog forward. With **no argument** a direct `/next` turn ends by
either starting the next obvious backlog action or asking the user to
clarify what should be next; a looped `/next` turn must not expect user
input, dispatches only unambiguous work, and otherwise idles until the
loop-exhausted guard stops it.

When given a **count or scope** (`N`, `blocked`, `all`, or a group
name), `/next` runs a **bounded internal sequence** instead: it works
several backlog items in one turn, skipping the heavy preflight between
steps (see **Sequencing**). How wide it runs — one worker at a time or a
fan-out batch — is the orchestrator's judgment call, sized to how
independent the selected work is (see **Concurrency**). It never waits for
user input mid-sequence. **For an attended multi-step push,
reach for a sequence first** — it is cheaper than an external loop (heavy
preflight only at the start and end, not every tick) and stays in one
turn. `do rpm:next until blocked` still works and remains the right tool for genuinely
unattended or scheduled runs that span many turns; it benefits from the
same preflight cadence.

## Project Amendments

At the start of every invocation, check whether
`docs/rpm/skills/next.md` exists in the consuming project. If it
does, read it and apply its contents as additional project-specific
instructions for this skill. Amendments may add preflight steps,
narrow dispatch criteria, add output requirements, or extend the
worker contract. They cannot remove or override plugin defaults —
on conflict, this SKILL.md wins.

## Routing

Parse `$ARGUMENTS` into a first token and an optional second token:

- **empty** → run one orchestrator step (the single-step flow below).
- **`status`** → run the status formatter and stop:

  !`bash ${RPM_PLUGIN_ROOT:-${CODEX_HOME:-$HOME/.codex}/.tmp/marketplaces/dppdppd-rpm/.codex}/skills/next/scripts/status.sh`

  Render the output verbatim. Do not interpret, summarize, or add
  commentary — the user wants the raw view.
- **integer `N` (≥ 1)** → run a sequence of up to N cycles (see
  **Sequencing**). `N = 1` is identical to the single-step flow.
- **`blocked`** → run a sequence until a task needs the user, or no
  actionable task remains.
- **`all`** → run a sequence until no actionable task remains, skipping
  tasks that need the user and continuing with the rest.
- **anything else** → treat the first token as a `* Parent` **group
  name** in `docs/rpm/future/tasks.org` (match the heading text exactly,
  then case-insensitively). An optional second token scopes the run
  within that group: `N`, `all`, or `blocked` (default: drain the group
  until it has no actionable task or one needs the user). If no parent
  matches, print the usage block below and stop.

Reserved first tokens (`status`, `blocked`, `all`, and any integer) are
never interpreted as group names.

Usage block (print only when the argument is unrecognized):

```
/next               — one orchestrator step
/next N             — up to N steps; width per step is the orchestrator's call (one worker, or a fan-out batch); heavy preflight only at start + end
/next blocked       — run until a task needs you, or nothing is actionable
/next all           — run everything actionable, skipping tasks that need you
/next <group> [N]   — work only that backlog group (drain it, or N steps)
/next status        — in-flight subagents, recent decisions, idle streak, counters
(prefer the sequence forms above; `do rpm:next until blocked` still wraps the one-step form for unattended, multi-turn runs)
```

## Mode

There are three modes:

- **Direct (single-step)** — no argument, run interactively. May ask one
  concise clarification question when no obvious next backlog action can
  be started safely.
- **Autonomous directive** — this invocation is visibly part of `do rpm:next until blocked`, an
  unattended dynamic loop, or repeated automatic invocation. Must not ask
  for input. If there is no unambiguous action, log `idle` with the
  reason and stop; after 3 consecutive idle ticks, emit `loop-exhausted`.
- **Sequence** — `/next` was given a count or scope (`N` / `blocked` /
  `all` / `<group>`). Runs a bounded internal loop (see **Sequencing**).
  Like autonomous directive mode it never asks for input mid-sequence; it stops at the
  argument's termination condition or the safety ceiling.

## Sequencing

Triggered by a count or scope argument. A sequence runs cycles **in the
foreground**. Each cycle's width — a single worker or a fan-out batch — is
the orchestrator's call, sized to how independent the selected work is
(see **Concurrency**).

1. **Full preflight once, at the start.** Run the delegated preflight
   (Preflight step 2) with `phases=full`, act on its report, and log a
   marker:

   ```bash
   bash ${RPM_PLUGIN_ROOT:-${CODEX_HOME:-$HOME/.codex}/.tmp/marketplaces/dppdppd-rpm/.codex}/skills/next/scripts/log-decision.sh preflight-full "" "sequence start"
   ```

2. **Cycle loop.** Repeat until a termination condition (below) or the
   safety ceiling:
   - **a. Cheap inline gate.** Check the termination conditions and the
     outstanding-user-blocker rule (Preflight step 1). **Do not** run the
     drift scan, the contradiction check, or the preflight subagent
     here — that overhead is exactly what a sequence exists to avoid.
   - **b. Task Selection.** Recompute in-flight, walk the tree,
     goal-aligned dispatch, apply the group filter if scoped, and run the
     `is-pre-completed.sh` skip check.
   - **c. Dispatch.** Dispatch using the Worker Contract, **in the
     foreground** — await results, do not background. Log one
     `actionable-backlog` per worker. Width is the orchestrator's call
     (see **Concurrency**): one worker when the next candidates are
     coupled, or a fan-out batch when they are independent — awaited
     together before reviewing.
   - **d. Review inline.** Evaluate each returned result, mark the backlog
     entry DONE (or append changes-requested notes to the detail file),
     then log `review-result` and a paired `backlog-result` per worker.
     Lean on the worker's terse report (it also persisted the full result
     to the detail file) to keep orchestrator context lean.

3. **Full preflight once, at the end.** After the loop stops, run the
   delegated preflight again with `phases=full` — it catches any drift
   the workers introduced — and log a second `preflight-full` marker
   (`"sequence end"`).

4. Emit the **sequence summary** (see Output Format).

### Termination

- **`N`** — stop after N completed cycles.
- **`blocked`** — stop the moment a cycle would need user input (the top
  candidate's only next move is a question), or when no actionable task
  remains.
- **`all`** — stop only when no actionable task remains. If a cycle's top
  candidate needs user input, skip it (leave it as-is) and continue with
  the next actionable task; collect skipped items for the summary.
- **`<group>`** — restrict Task Selection to the matched `* Parent`;
  terminate per the second token (`N` / `all` / `blocked`, default
  drain-until-empty-or-blocked).
- **Safety ceiling.** `blocked`, `all`, and unbounded group runs stop
  after at most **25 cycles** in one invocation. On hitting it, stop and
  report `ceiling reached — run again to continue`. An explicit `N` above
  25 is honored, still cycle-by-cycle; the ceiling only bounds the
  open-ended forms.

### Preflight cadence (autonomous directive mode)

Outside a sequence, `do rpm:next until blocked` repeats the single-step flow across
separate turns. To avoid re-paying the full preflight every tick, run
`bash ${RPM_PLUGIN_ROOT:-${CODEX_HOME:-$HOME/.codex}/.tmp/marketplaces/dppdppd-rpm/.codex}/skills/next/scripts/preflight-due.sh` at the top of a loop
tick:

- **`full`** → run the delegated preflight with `phases=full` and log a
  `preflight-full` marker (this happens when there is no prior marker,
  the last one is stale, or a guidance input changed).
- **`lite`** → skip the drift scan and contradiction check. Do the inline
  blocker check, then run `review-ready.sh`; **only if** a worker result
  is pending, dispatch the preflight subagent with `phases=review-only`
  to review it. Then continue to Task Selection.

Direct single-step `/next` (no argument) always runs a full preflight.

## Orchestrator Flow

Do not treat preflight and tasking as mutually exclusive. Run preflight
first, in order, and continue to task selection when the preflight item
was resolved locally. Stop only when continuing would be unsafe, when a
direct-mode user question is required, or when autonomous directive mode has no
unambiguous next action.

This section describes a single step. A **Sequence** (see **Sequencing**)
runs the full preflight once at the start and once at the end; each
in-between cycle skips the preflight and goes straight to Task Selection.

### Preflight

1. **Outstanding user blocker** — if the previous decision in
   `docs/rpm/~rpm-orchestrator-log.jsonl` was `blocked-on-user` and the
   most recent user message did not address the question:
   - Direct mode: re-surface what we are waiting on, log
     `blocked-on-user` if needed, and stop.
   - Autonomous directive mode: do not ask again. Log `idle` with
     rationale
     `blocked-on-user unresolved`, then stop or `loop-exhausted` if the
     idle streak reached 3.

2. **Delegated preflight** — dispatch the `rpm:preflight` subagent
   (foreground) so the token-heavy work (raw `scan.sh` output,
   contradiction classification, worker diffs) stays in the agent's
   context, not this one. Resolve each value before sending — pass real
   paths, not literals:
   - `mode=` `direct` or `loop` (this turn's mode)
   - `phases=` `full` (default — all three phases) or `review-only`
     (Phase 3 worker review only; used on a `lite` loop tick that has a
     pending worker result, per **Preflight cadence**)
   - `scan_script=${RPM_PLUGIN_ROOT:-${CODEX_HOME:-$HOME/.codex}/.tmp/marketplaces/dppdppd-rpm/.codex}/skills/session-end/scripts/scan.sh`
   - `contradiction_script=${RPM_PLUGIN_ROOT:-${CODEX_HOME:-$HOME/.codex}/.tmp/marketplaces/dppdppd-rpm/.codex}/skills/next/scripts/contradiction-check.sh`
   - `review_ready_script=${RPM_PLUGIN_ROOT:-${CODEX_HOME:-$HOME/.codex}/.tmp/marketplaces/dppdppd-rpm/.codex}/skills/next/scripts/review-ready.sh`
   - `log_script=${RPM_PLUGIN_ROOT:-${CODEX_HOME:-$HOME/.codex}/.tmp/marketplaces/dppdppd-rpm/.codex}/skills/next/scripts/log-decision.sh`
   - `memory_dir=$HOME/.claude/projects/$(printf '%s' "$PWD" | sed 's|/|-|g')/memory`
   - `instructions=` the active directive files (`CLAUDE.md`,
     `AGENTS.md`, `MEMORY.md` at project root if present, plus every
     `plugin/skills/*/SKILL.md`)
   - `today=$(date +%Y-%m-%d)`

   The agent applies obvious mechanical drift fixes, runs the
   contradiction check, reviews the first ready worker result, and logs
   each `drift-fix`, contradiction count, and `review-result` itself. It
   returns ONLY a compact report (`drift-fixes`, `drift-decisions`,
   `contradictions`, `review`, `repo-safe`, `notes`). Read that report;
   do NOT re-run the scans, re-review the diff, or re-log what the agent
   already logged.

   Act on the report. If it reports `repo-safe: no`, an open question
   the user must answer, or a `drift-decisions` item (e.g. an overridden
   skill recommended for migration to the `docs/rpm/skills/` amendment
   path) needing a product decision:
   - Direct mode: ask a concise question, log `blocked-on-user`, stop.
   - Autonomous directive mode: log `idle` with the ambiguity, then
     stop or exhaust.

   Otherwise carry the report's `drift-fixes`, `contradictions` (count +
   top pairs), and `review` summary into your `preflight:` output line
   and continue to task selection.

### Task Selection

After preflight, recompute `in-flight`.

1. If `in-flight >= 1`, log `idle` with rationale
   `waiting on in-flight worker`, output the waiting state, and stop.

2. Read `docs/rpm/future/tasks.org` **and walk the whole tree**, not
   just the recurring/triage sub-task you most recently dispatched.
   Each `*` parent should carry a `Goal:` body line stating the
   measurable success metric for that tier; tasks are evaluated
   against it (see "Goal-aligned dispatch" below). **When the run is
   scoped to a group** (the `<group>` argument), restrict the walk to
   tasks under the matched `* Parent` only — other parents are out of
   scope for both selection and termination.

3. The clear next task is the topmost TODO or IN-PROGRESS entry
   whose `:BLOCKED_BY:` deps all resolve to DONE or CANCELLED, as
   long as it has an `:ID:` and a readable linked detail file. If
   multiple tasks are actionable, the topmost one is the expected
   next task; do not ask solely because more than one exists.
   **Skip entries keyworded `WATCH` (deferred / observe-only) the
   same way you skip closed `DONE` / `CANCELLED` — they are not
   actionable. Entries marked `BLOCKED` without resolved deps are
   likewise skipped.** Before declaring a TODO or IN-PROGRESS entry
   actionable, call
   `bash ${RPM_PLUGIN_ROOT:-${CODEX_HOME:-$HOME/.codex}/.tmp/marketplaces/dppdppd-rpm/.codex}/skills/next/scripts/is-pre-completed.sh <id>`;
   if it exits 0, the linked detail file already has a populated
   `## Worker Result` — log `drift-fix: pre-completed-todo: <id>`
   and continue to the next task instead of dispatching.

4. **Goal-seeking — file the PROOF step, don't just grind gaps.**
   Before dispatching toward any `*` parent goal that is NOT MET,
   reason **backward** from the goal — don't just pick the topmost
   gap-task. Confirm both:
   1. the goal's definition-of-done is a **DEMONSTRATION** — a
      test/artifact that PROVES it met (e.g. "N representative cases
      pass end-to-end vs reference", "trace 38/38"), not a
      gap-checklist or a vague description ("launch ready");
   2. a terminal **VERIFY / SIGN-OFF** task exists whose completion
      DEMONSTRATES the goal met, with the gap-tasks as its
      `:BLOCKED_BY:` deps.

   If either is missing, **filing it is the dispatch** — file the
   demonstrable DoD and/or the verify/sign-off task (decompose
   backward: demonstrable DoD → verify/sign-off closer → the
   gap-tasks it depends on) before grinding any gap-closer. This is
   higher leverage than any gap-closer: a gap-closer only nudges a
   NOT-MET goal; only the demonstration flips it to MET. Closing
   every coded gap is necessary but not sufficient — without a
   terminal proof the orchestrator gets "lost in the weeds,"
   reporting progress while the actual capability is never verified.

   Only once the chain terminates in a demonstrable proof, pick the
   topmost actionable task by **goal-aligned dispatch:** score it
   against its `*` parent's `Goal:` line. The task should either
   (a) close a stated success-metric gap or (b) unblock a
   critical-path item. Side-quest tasks that don't move the goal are
   deprioritized in favor of goal-aligned ones, even when topmost in
   file order. If NO actionable task in any parent moves a goal,
   that's a **gap** — file a new research/triage/scoping task on the
   gap before dispatching anything else, instead of idling.

5. If there is a clear next task, dispatch a worker using the contract
   below and log `actionable-backlog`. Workers must persist their own
   result; do not rely on a background notification as the only return
   path.

6. If there is no actionable task, or the top task is missing an ID,
   missing a readable detail file, marked watch/deferred, or otherwise
   not scoped enough to start without guessing:
   - Direct mode: ask a concise clarification question, log
     `blocked-on-user` with that question as rationale, and stop.
   - Autonomous directive mode: log `idle` with the reason and stop. If this is the
     third consecutive idle tick, emit `loop-exhausted`. **Do not
     collapse "visible queue=0" to "no work" before walking the
     full tree against parent Goal: lines** — the recurring/triage
     queue is one node of one parent; many other goals may have
     unaddressed critical-path items.

7. **Saturation override.** If the user has set a saturation
   directive in memory (e.g. "1 tier3 + 1 tier2 at all times"),
   the `in-flight >= 1` rule from step 1 is replaced by per-slot
   counts: dispatch as long as the directive's slots aren't all
   full and the new dispatch wouldn't violate "never 2 daemon-using
   simultaneously." When all slots are filled, log `idle` with
   rationale `saturated at directive ceiling` — do **not** treat
   this as exhaustion (it's intentional waiting, not "no work").

## Output Format

Four lines, plus an optional fifth `gaps:` line when the goal-aligned
dispatch step (Task Selection step 4) found unaddressed critical-path
items:

```
action: <kind>
preflight: <none or comma-separated completed preflight actions>
in-flight: <N>
next: <hint or USER ATTENTION>
gaps: <none or comma-separated parent:metric pairs with no actionable task>
```

- `<kind>`: the terminal outcome for this turn, one of
  `actionable-backlog`, `blocked-on-user`, `idle`, or `loop-exhausted`.
- `<preflight>`: `none` or short entries like
  `drift-fix: context.md broken-ref`, `review-result: task-id approved`.
- `<N>`: count of background subagents currently running (read from
  the log; entries with `kind: actionable-backlog` and no
  corresponding `kind: backlog-result` are still in-flight).
- `<hint>`: short prose for what will likely come next. Use
  `USER ATTENTION needed for: <reason>` only in direct mode or when
  reporting a loop-exhausted terminal state.

After the four-line block, include follow-on output for the terminal
outcome: dispatch confirmation, clarification question, or loop idle
reason. For the delegated preflight, relay the agent's compact report
verbatim-ish (its `drift-fixes`, `contradictions`, and `review` lines) —
that summary IS the preflight view; do not re-derive it by re-running
the scans or re-reading the diff.

### Sequence output

For a sequence, do not print the four-line block per cycle. Emit one
short line per cycle as it completes, then a final summary:

```
sequence: <arg>  (cycles: <done>/<limit>, done: <X>, changes-requested: <C>, skipped-needs-user: <S>)
preflight: full@start, full@end
  1. <task-id> → <approved | changes-requested | skipped>
  2. <task-id> → ...
stopped: <count reached | nothing actionable | task needs you | ceiling reached — run again to continue>
next: <hint>
```

The two `preflight-full` runs are the only preflight entries — do not
report a preflight per cycle.

### Cheaper-path tip (once per run)

Interior sequencing is cheaper than driving `/next` from an external
`do rpm:next until blocked`: a sequence pays the heavy preflight only at its start and
end, while a loop re-checks it every tick. To steer users toward the
cheaper path **without nagging**, emit a one-time tip.

On a **Autonomous directive mode** tick, append one extra line to the output —

```
tip: /next all runs this in one cheaper turn (skips per-tick preflight)
```

— if and only if **both** hold:

1. there are **≥ 2 actionable backlog tasks** this turn (an interior
   sequence would batch more than one — a single-task backlog gains
   nothing from sequencing), and
2. no `nudge` marker appears in
   `docs/rpm/~rpm-orchestrator-log.jsonl` after the most recent
   `loop-exhausted` entry (or anywhere in the log, if there is none).

When you emit it, log the marker so it does not repeat this run:

```bash
bash ${RPM_PLUGIN_ROOT:-${CODEX_HOME:-$HOME/.codex}/.tmp/marketplaces/dppdppd-rpm/.codex}/skills/next/scripts/log-decision.sh nudge "" "suggested /next all"
```

This fires **at most once per loop run**. It never blocks, never gates
dispatch, and never repeats — under-suggesting is preferred to nagging
(soft suggestion only, per rpm's recommend-not-force stance). Direct and
Sequence modes never emit it.

## Logging

Use the helper script — never hand-format JSONL:

```bash
bash ${RPM_PLUGIN_ROOT:-${CODEX_HOME:-$HOME/.codex}/.tmp/marketplaces/dppdppd-rpm/.codex}/skills/next/scripts/log-decision.sh <kind> [target] [rationale] [agent-id] [status]
```

The `rpm:preflight` agent writes the delegated-preflight entries
(`drift-fix`, contradiction counts as `drift-fix`, and `review-result`)
itself — do not duplicate them. The orchestrator logs the step-1
blocker outcome, the terminal outcome, and `actionable-backlog`.

Log with the appropriate kind:

- `drift-fix` — pass the drift category as `<target>` (e.g.
  `context.md broken-ref`) and the fix summary as `<rationale>`.
  Emitted by the preflight agent.
- `review-result` — after reviewing a pending worker result, pass the
  same task ID as `<target>`, the reviewer action as `<rationale>`,
  the worker ID as `<agent-id>`, and a status of
  `approved | changes-requested`. This clears the review queue for
  that worker result. Emitted by the preflight agent.
- `actionable-backlog` — pass the task ID as `<target>`, the one-line
  rationale, and the dispatched subagent's ID as `<agent-id>`. Match
  volta's idiom: the agent ID is what the Agent tool returned (look
  for `agentId:` in the dispatch result).
- `blocked-on-user` — pass the open question text as `<rationale>`.
  Use this for previously unanswered direct-mode questions and for
  direct-mode task-selection ambiguity.
- `idle` — empty `<target>`, short `<rationale>`.
- `loop-exhausted` — empty `<target>`, fixed `<rationale>` like
  `3 idle ticks`.
- `preflight-full` — empty `<target>`, short `<rationale>` (e.g.
  `sequence start`, `sequence end`, `loop tick`). Marks that a full
  preflight ran. `preflight-due.sh` reads the most recent one to decide
  whether a later loop tick can go `lite`. It is ignored by the
  decisions view and the idle-streak count (status.sh and the Idle
  Terminal filter only track terminal decisions), so it never resets the
  loop-exhausted guard.
- `nudge` — empty `<target>`, short `<rationale>` like
  `suggested /next all`. Marks that the one-time Autonomous directive mode cheaper-path
  tip fired (see **Cheaper-path tip**). Like `preflight-full`, it is
  ignored by the decisions view and the idle-streak count, so it never
  resets the loop-exhausted guard.
- `backlog-result` — when a `<task-notification>` arrives for a prior
  `actionable-backlog` dispatch, log it: pass the same `<target>` and
  `<agent-id>` plus a `<status>` of
  `needs-review | plan-written | blocked | no-op`. This pairing is what
  powers the `in-flight: <N>` count. If the worker already wrote this
  line itself, do not duplicate it.

The script writes to `docs/rpm/~rpm-orchestrator-log.jsonl`
(gitignored, ephemeral). Failures print a stderr warning and exit 0 —
never block the orchestrator.

## Worker Contract

When dispatching `actionable-backlog`, include this contract in the
worker prompt. Workers must write a durable result to the orchestrator
log before finishing; chat notifications are only supporting context.

The orchestrator computes today's date at dispatch time
(`$(date +%Y-%m-%d)`) and substitutes it into the `today:` field
below. Workers must use that exact value for any dated artifact —
they cannot infer the current date reliably.

```
You are an rpm backlog worker.

Task:
- target id: <task-id>
- task heading: <task heading from tasks.org>
- detail file: docs/rpm/future/<detail-file>.md
- orchestrator log: docs/rpm/~rpm-orchestrator-log.jsonl
- worker id: <agent-id if known, otherwise worker-unknown>
- today: <YYYY-MM-DD>

Rules:
0. Use the literal `today:` value above for every dated artifact you
   create (filenames, frontmatter dates, log entries). Subagents do
   not have reliable clock access; the orchestrator passes the date
   in via this field. Do not infer it.
1. Read docs/rpm/future/tasks.org and the detail file before writing.
2. Do real work when the task is scoped enough to execute safely.
   Keep changes limited to the task. If the task is ambiguous or too
   broad, do not guess; write a plan instead.
3. Append a `## Worker Result` section to the detail file when you
   changed files or otherwise completed the task. Include:
   - Summary
   - Files changed
   - Verification run
   - Remaining risks or follow-ups
4. Append `## Plan` if you only planned the work. Append `## Blocked`
   if you could not proceed, with the missing information.
5. Before finishing, log your result:

   bash ${RPM_PLUGIN_ROOT:-${CODEX_HOME:-$HOME/.codex}/.tmp/marketplaces/dppdppd-rpm/.codex}/skills/next/scripts/log-decision.sh backlog-result \
     "<task-id>" "<one-line result>" "<agent-id>" "<status>"

   `<status>` for `log-decision.sh backlog-result`:
   - `needs-review` — you did work and want the orchestrator to review it
   - `plan-written` — you only appended `## Plan`
   - `blocked` — you appended `## Blocked`
   - `no-op` — the task is already fully handled

   If your project also uses an orch-job tracker (e.g. Volta's
   `tools/scripts/orch-job.sh`), close it with the equivalent status.
   Status enums may differ between the two helpers — check the script's
   usage line. Common mapping: `needs-review` → orch-job `success`;
   `plan-written` → orch-job `success` (with summary noting the plan);
   `blocked` → orch-job `blocked`; `no-op` → orch-job `no-op`.
6. In your final response, state the detail file changed and the status
   you logged. The file + JSONL log are the source of truth.
```

## Idle Terminal

Read `docs/rpm/~rpm-orchestrator-log.jsonl` only if it exists. Filter
to `kind` in {`blocked-on-user`, `drift-fix`, `actionable-backlog`,
`review-result`, `idle`, `loop-exhausted`} and ignore `backlog-result`.
If the file does not exist, the idle streak is `0`. If the last three
filtered entries are `idle`, this turn becomes `loop-exhausted` instead
of `idle`.

**Saturation exception:** if the current `idle` rationale starts with
`saturated` (i.e. workers are intentionally running at the saturation
directive's ceiling, see Task Selection step 7), the 3-idle threshold
does NOT apply — saturation idles are not "no work," they're "work in
flight," and exhausting the loop here is wrong. Log normal `idle` and
keep the cron armed.

Idle is for autonomous directive ambiguity or waiting on in-flight work, not for a
direct-mode "no obvious next task" state. In direct mode, ask the user
when task selection is unclear. In autonomous directive mode, never ask; log idle and
let the 3-idle threshold stop runaway autonomous runs. The user can
resume by asking for `rpm:next` directly; the next invocation reads the log
fresh and picks up wherever priority leads.

**Killed workers.** A worker that registers an orch-job but never
calls `complete` (process killed mid-run, runtime early-terminated,
quota exhausted) leaves a phantom `running` entry. The orchestrator
must close the orch-job (`orch-job.sh complete <id> <success|no-op|
failed> "killed: <reason>"`) and log a paired `backlog-result` so the
dashboard reflects reality and the in-flight count is accurate. Do
not rely on the worker's own logging — it didn't reach that step.

## Concurrency — the orchestrator decides how wide to fan out

**The orchestrator owns width.** How many workers to run at once is its
judgment call, made from the shape of the selected work — not a fixed
ceiling. A no-argument `/next` typically dispatches one `actionable-backlog`
worker in the background and reviews it next turn; a **sequence** (`N` /
`blocked` / `all` / `<group>`) works foreground. Either may fan out to as
many concurrent workers as the batch genuinely supports, or stay at one.

**What narrows effective width.** Fan-out pays off only to the extent the
batch lacks couplings. Weigh these when sizing a batch — each one that
applies pulls width back toward one:

- **Overlapping edits** — workers touching the same files/directories risk
  concurrent-edit clobbers and non-FF push conflicts.
- **Shared serialized resource** — tasks competing for one render queue,
  build lock, dev server, port, or fixture serialize anyway.
- **Cross-cutting verification** — a corpus-wide check that one worker's
  change can invalidate for another means fixes must land and verify one
  at a time to stay honest.
- **Needs user input** — an ambiguous task can't be dispatched unattended
  regardless of width.

Genuinely independent work (disjoint edits, no shared resource, per-task
verification) can fan out wide; tightly coupled work stays narrow or
single-threaded. Judge per batch.

For a no-argument turn that stays single-worker: if `<N>` >= 1 after
preflight and you are not fanning out, do not dispatch another worker.
Output `action: idle` with `next: waiting on in-flight worker`.

Rationale (2026-05-04 audit) — **why width tracks coupling**: on a
game-fix corpus, saturating to 4 produced an 8.4% dispatch hit rate (107
dispatches -> 9 shipped fixes) because (a) workers competed for the daemon
render queue, (b) concurrent edits created non-FF push conflicts, (c) each
fix verified against one game shipped before contradictions in other games
surfaced. That corpus was maximally coupled on all three axes above — so
its right width was one. A batch without those couplings has no such tax;
size it to the work. The lesson is *width follows coupling*, not *width is
capped*.

## What this skill does NOT do

- Does not pick up tactical user requests — `rpm:next` is for unattended
  autonomous work, not the conversational thread.
- Does not modify `tasks.org` ordering — that's `/backlog review`'s
  job. `rpm:next` only reads.
- Does not run audits, releases, or session-end. Those are explicit
  user-invoked operations.
- Does not retry failed dispatches. A failed subagent logs a
  `backlog-result` with `status: blocked`; the next `rpm:next` tick picks
  the next unblocked item.

## Example Sessions

Autonomous Codex directive run with mechanical preflight and a clear next task:

```
User directive: do rpm:next until blocked

action: actionable-backlog
preflight: drift-fix: context.md broken-ref
in-flight: 0
next: review worker result when it returns

Fixed: docs/rpm/context.md broken-ref to legacy plugin path.
Dispatched general-purpose subagent <id> on `sync-codex-scripts`.
Will append a result to 2026-04-30-sync-codex-scripts.md when it
returns.
```

Autonomous Codex directive run with no unambiguous task:

```
action: idle
preflight: none
in-flight: 0
next: no unambiguous backlog task; autonomous directive mode will not ask for input

No unblocked TODO/IN-PROGRESS backlog entry has a readable detail file.
```

Direct run with no unambiguous task:

```
action: blocked-on-user
preflight: review-result: sync-codex-scripts approved
in-flight: 0
next: USER ATTENTION needed for: choose next backlog item

Reviewed worker <id> for `sync-codex-scripts`; approved.
Which backlog item should rpm start next?
```

Sequence run (`/next 3`):

```
sequence: 3  (cycles: 3/3, done: 3, changes-requested: 0, skipped-needs-user: 0)
preflight: full@start, full@end
  1. sync-codex-scripts → approved
  2. fix-broken-ref     → approved
  3. update-readme      → approved
stopped: count reached
next: backlog top is now `dutch-bakeoff` (needs a scope decision)
```

Sequence run that stops early (`/next blocked`):

```
sequence: blocked  (cycles: 2, done: 2, changes-requested: 0, skipped-needs-user: 0)
preflight: full@start, full@end
  1. fix-broken-ref → approved
  2. sync-codex     → approved
stopped: task needs you
next: USER ATTENTION needed for: `dutch-bakeoff` scope (v1/v2/native?)
```

## Codex Experimental Worker Wake

This section is Codex-only guidance appended by `scripts/sync-codex.sh`.
Do not copy it into the shared Claude Code skill: the wake path depends
on Codex's experimental subagent messaging behavior and is best-effort.

When dispatching `actionable-backlog` from Codex:

1. Read the parent thread id from `CODEX_THREAD_ID` before spawning the
   worker. If it is empty, continue without wakeback.
2. Spawn the worker and log `actionable-backlog`. Do not call
   `wait_agent`; the parent thread must remain free for other work.
3. After `spawn_agent` returns, immediately send the worker one
   follow-up containing its actual worker id and, when available, the
   parent thread id. This follow-up lets the worker use the same id in
   its `backlog-result` row and in the optional wake message.
4. Extend the worker prompt with this Codex-only field when the parent
   thread id is non-empty:

   ```
   - parent thread id: <CODEX_THREAD_ID>
   ```

5. Add this Codex-only worker rule after the durable `backlog-result`
   logging rule:

   ```
   If a parent thread id was provided, after writing the durable
   backlog-result log row and before finishing, make exactly one
   best-effort parent wake call using this exact tool shape:

   send_input({ target: "<parent-thread-id>", message: "rpm worker result ready: <status> <task-id> by <agent-id>; run rpm:next worker review preflight when convenient." })

   Do not set interrupt true. Do not include raw worker results in this
   message. If the tool is unavailable or rejects the target, continue;
   docs/rpm/~rpm-orchestrator-log.jsonl remains the source of truth and
   the Codex review-ready hook is the fallback.
   ```

This wake call is only a pointer. `rpm:next` worker-review preflight must
still read `review-ready.sh`, inspect the detail file and git diff, and
log `review-result` before dispatching more backlog work.
