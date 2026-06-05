---
name: next
description: One-step rpm orchestrator. Runs preflight maintenance, then either starts the next obvious backlog action or asks for clarification when direct use leaves no clear next task. Designed for Codex directives such as `do rpm:next until blocked` — never loops internally. In autonomous directive mode it never waits for input; it dispatches only unambiguous work and otherwise idles or exhausts after 3 idle ticks. TRIGGER on terse forward-motion prompts — phrasings like "next", "next?", "next.", "next task", "what's next", "do next", "go next", "keep going", "continue" (when the prior turn was rpm work) all qualify and must route through this skill instead of being answered inline from the SessionStart preview. Use whenever the user wants the session to autonomously work the rpm backlog.
---

# rpm:next

Single-step orchestrator that handles preflight maintenance, then tries
to move the backlog forward. A normal direct `rpm:next` turn should end by
either starting the next obvious backlog action or asking the user to
clarify what should be next. An autonomous Codex directive must not
expect user input; it dispatches only unambiguous work and otherwise
idles until the loop-exhausted guard stops it. **Never loops internally.** For
self-paced execution, use a directive such as
`do rpm:next until blocked`.

## Project Amendments

At the start of every invocation, check whether
`docs/rpm/skills/next.md` exists in the consuming project. If it
does, read it and apply its contents as additional project-specific
instructions for this skill. Amendments may add preflight steps,
narrow dispatch criteria, add output requirements, or extend the
worker contract. They cannot remove or override plugin defaults —
on conflict, this SKILL.md wins.

## Routing

If `$ARGUMENTS` is `status`, run the status formatter and stop:

!`bash ${RPM_PLUGIN_ROOT:-${CODEX_HOME:-$HOME/.codex}/.tmp/marketplaces/dppdppd-rpm/.codex}/skills/next/scripts/status.sh`

Render the script's output verbatim. Do not interpret, summarize, or
add commentary — the user wants the raw view.

If `$ARGUMENTS` is empty, continue with the orchestrator below.

If `$ARGUMENTS` is anything else, print:

```
rpm:next     — one orchestrator step; for autonomous mode, ask `do rpm:next until blocked`
rpm:next status — show in-flight subagents, recent decisions, idle streak, daily counters
```

and stop.

## Mode

Infer autonomous directive mode when the current invocation is visibly
part of a Codex directive such as `do rpm:next until blocked`, an
unattended dynamic run, or repeated automatic invocation.
Otherwise treat it as direct interactive mode.

- **Direct mode** may ask one concise clarification question when no
  obvious next backlog action can be started safely.
- **Autonomous directive mode** must not ask for input. If there is no
  unambiguous action, log `idle` with the reason and stop. After 3
  consecutive idle ticks, emit `loop-exhausted`.

## Orchestrator Flow

Do not treat preflight and tasking as mutually exclusive. Run preflight
first, in order, and continue to task selection when the preflight item
was resolved locally. Stop only when continuing would be unsafe, when a
direct-mode user question is required, or when autonomous directive mode has no
unambiguous next action.

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
   against it (see "Goal-aligned dispatch" below).

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

## Concurrency — one worker at a time

`rpm:next` itself is a single orchestrator turn. It may do several
preflight actions inline, but it dispatches at most one new
`actionable-backlog` worker. The subagent runs in background, but only
ONE may be in-flight at a time. Full depth, multi-game verified before
merge.

If `<N>` >= 1 after preflight, do not dispatch another worker. Output
`action: idle` with `next: waiting on in-flight worker`.

Rationale (2026-05-04 audit): saturating to 4 produced an 8.4%
dispatch hit rate (107 dispatches -> 9 shipped fixes) because (a)
workers competed for the daemon render queue, (b) concurrent edits
created non-FF push conflicts, (c) each fix verified against one game
shipped before contradictions in other games surfaced. Single-threaded
with corpus-wide verification trades throughput for hit rate.

This ceiling is deliberate and overrides any default to fan out —
including ultracode / automatic Workflow orchestration. Do not raise
`/next` concurrency to chase throughput; the hit-rate math above is the
reason.

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
