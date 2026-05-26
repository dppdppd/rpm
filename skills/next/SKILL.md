---
name: next
description: One-step rpm orchestrator. Runs preflight maintenance, then either starts the next obvious backlog action or asks for clarification when direct use leaves no clear next task. Designed to be wrapped by `/loop /next` — never loops internally. In loop mode it never waits for input; it dispatches only unambiguous work and otherwise idles or exhausts after 3 idle ticks. TRIGGER on terse forward-motion prompts — phrasings like "next", "next?", "next.", "next task", "what's next", "do next", "go next", "keep going", "continue" (when the prior turn was rpm work) all qualify and must route through this skill instead of being answered inline from the SessionStart preview. Use whenever the user wants the session to autonomously work the rpm backlog.
argument-hint: "[status]"
allowed-tools: Read Write Edit Glob Grep Bash Agent
---

# /next

Single-step orchestrator that handles preflight maintenance, then tries
to move the backlog forward. A normal direct `/next` turn should end by
either starting the next obvious backlog action or asking the user to
clarify what should be next. A looped `/next` turn must not expect user
input; it dispatches only unambiguous work and otherwise idles until the
loop-exhausted guard stops it. **Never loops internally.** Wrap with
`/loop /next` for self-paced execution.

## Routing

If `$ARGUMENTS` is `status`, run the status formatter and stop:

!`bash ${CLAUDE_SKILL_DIR}/scripts/status.sh`

Render the script's output verbatim. Do not interpret, summarize, or
add commentary — the user wants the raw view.

If `$ARGUMENTS` is empty, continue with the orchestrator below.

If `$ARGUMENTS` is anything else, print:

```
/next        — one orchestrator step (use `/loop /next` for autonomous mode)
/next status — show in-flight subagents, recent decisions, idle streak, daily counters
```

and stop.

## Mode

Infer loop mode when the current invocation is visibly part of
`/loop /next`, an unattended dynamic loop, or repeated automatic
invocation. Otherwise treat it as direct interactive mode.

- **Direct mode** may ask one concise clarification question when no
  obvious next backlog action can be started safely.
- **Loop mode** must not ask for input. If there is no unambiguous
  action, log `idle` with the reason and stop. After 3 consecutive idle
  ticks, emit `loop-exhausted`.

## Orchestrator Flow

Do not treat preflight and tasking as mutually exclusive. Run preflight
first, in order, and continue to task selection when the preflight item
was resolved locally. Stop only when continuing would be unsafe, when a
direct-mode user question is required, or when loop mode has no
unambiguous next action.

### Preflight

1. **Outstanding user blocker** — if the previous decision in
   `docs/rpm/~rpm-orchestrator-log.jsonl` was `blocked-on-user` and the
   most recent user message did not address the question:
   - Direct mode: re-surface what we are waiting on, log
     `blocked-on-user` if needed, and stop.
   - Loop mode: do not ask again. Log `idle` with rationale
     `blocked-on-user unresolved`, then stop or `loop-exhausted` if the
     idle streak reached 3.

2. **Mechanical drift** — run the session-end scan. If
   `skills/session-end/scripts/scan.sh` reports actionable drift
   (`broken_refs.count > 0`, `claude_md.status` warn/critical,
   stale rpm docs with any `days > 3`, or `migration.count > 0`), apply
   every obvious mechanical fix inline and log each `drift-fix`.
   Continue to the next preflight item. If a drift item needs a product
   decision:
   - Direct mode: ask a concise question, log `blocked-on-user`, stop.
   - Loop mode: log `idle` with the ambiguity, then stop or exhaust.

3. **Worker review** — run:
   `bash ${CLAUDE_SKILL_DIR}/scripts/review-ready.sh`.
   If it reports any worker result with no matching `review-result`,
   review the first row before starting new work. This applies to every
   durable worker output status: `needs-review`, `plan-written`,
   `blocked`, and `no-op`. Surface the worker result before reviewing
   even when no user-visible chat notification exists: worker ID,
   target, status, result rationale from `review-ready.sh` or the
   orchestrator log, claimed changes and verification from the detail
   file, and any matching `<subagent_notification>` or task notification
   if available in model context. Then review the detail file, git diff,
   and any verification noted by the worker. Do not approve based on the
   notification alone.

   For `needs-review`, evaluate the changed files and verification.
   For `plan-written`, evaluate whether the plan is clear and actionable.
   For `blocked`, evaluate whether the blocker is real and whether it
   requires user input. For `no-op`, verify the claimed no-op is valid.
   If acceptable, mark the backlog entry DONE or leave a clear
   session-end reconciliation note, then log `review-result` with
   status `approved`. If more work is needed, append reviewer notes to
   the detail file and log `review-result` with status
   `changes-requested`. If an approved blocker still needs user input,
   surface it and log the terminal outcome as `blocked-on-user`.
   Continue to task selection unless the review exposed unsafe repo
   state or a question the user must answer.

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
   `bash ${CLAUDE_SKILL_DIR}/scripts/is-pre-completed.sh <id>`;
   if it exits 0, the linked detail file already has a populated
   `## Worker Result` — log `drift-fix: pre-completed-todo: <id>`
   and continue to the next task instead of dispatching.

4. **Goal-aligned dispatch.** Before picking the topmost actionable
   task, score it against its `*` parent's `Goal:` line. The task
   should either (a) close a stated success-metric gap or
   (b) unblock a critical-path item. Side-quest tasks that don't
   move the goal are deprioritized in favor of goal-aligned ones,
   even when topmost in file order. If NO actionable task in any
   parent moves a goal, that's a **gap** — file a new
   research/triage/scoping task on the gap before dispatching
   anything else, instead of idling.

5. If there is a clear next task, dispatch a worker using the contract
   below and log `actionable-backlog`. Workers must persist their own
   result; do not rely on a background notification as the only return
   path.

6. If there is no actionable task, or the top task is missing an ID,
   missing a readable detail file, marked watch/deferred, or otherwise
   not scoped enough to start without guessing:
   - Direct mode: ask a concise clarification question, log
     `blocked-on-user` with that question as rationale, and stop.
   - Loop mode: log `idle` with the reason and stop. If this is the
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

After the four-line block, include follow-on output for preflight work
and for the terminal outcome: drift-fix details, review summary,
dispatch confirmation, clarification question, or loop idle reason. For
every worker-review preflight, include the surfaced worker-result
summary before the review result. Use the matching notification when it
is available; otherwise reconstruct the summary from `review-ready.sh`,
the orchestrator log, and the detail file.

## Logging

Use the helper script — never hand-format JSONL:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/log-decision.sh <kind> [target] [rationale] [agent-id] [status]
```

Log every preflight action and the terminal outcome with the
appropriate kind:

- `drift-fix` — pass the drift category as `<target>` (e.g.
  `context.md broken-ref`) and the fix summary as `<rationale>`.
- `review-result` — after reviewing a pending worker result, pass the
  same task ID as `<target>`, the reviewer action as `<rationale>`,
  the worker ID as `<agent-id>`, and a status of
  `approved | changes-requested`. This clears the review queue for
  that worker result.
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

   bash ${CLAUDE_SKILL_DIR}/scripts/log-decision.sh backlog-result \
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

Idle is for loop-mode ambiguity or waiting on in-flight work, not for a
direct-mode "no obvious next task" state. In direct mode, ask the user
when task selection is unclear. In loop mode, never ask; log idle and
let the 3-idle threshold stop runaway autonomous loops. The user can
resume by running `/next` directly; the next invocation reads the log
fresh and picks up wherever priority leads.

**Killed workers.** A worker that registers an orch-job but never
calls `complete` (process killed mid-run, runtime early-terminated,
quota exhausted) leaves a phantom `running` entry. The orchestrator
must close the orch-job (`orch-job.sh complete <id> <success|no-op|
failed> "killed: <reason>"`) and log a paired `backlog-result` so the
dashboard reflects reality and the in-flight count is accurate. Do
not rely on the worker's own logging — it didn't reach that step.

## Concurrency — one worker at a time

`/next` itself is a single orchestrator turn. It may do several
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

## What this skill does NOT do

- Does not pick up tactical user requests — `/next` is for unattended
  autonomous work, not the conversational thread.
- Does not modify `tasks.org` ordering — that's `/backlog review`'s
  job. `/next` only reads.
- Does not run audits, releases, or session-end. Those are explicit
  user-invoked operations.
- Does not retry failed dispatches. A failed subagent logs a
  `backlog-result` with `status: blocked`; the next `/next` tick picks
  the next unblocked item.

## Example Sessions

Looped run with mechanical preflight and a clear next task:

```
$ /loop /next

action: actionable-backlog
preflight: drift-fix: context.md broken-ref
in-flight: 0
next: review worker result when it returns

Fixed: docs/rpm/context.md broken-ref to legacy plugin path.
Dispatched general-purpose subagent <id> on `sync-codex-scripts`.
Will append a result to 2026-04-30-sync-codex-scripts.md when it
returns.
```

Looped run with no unambiguous task:

```
action: idle
preflight: none
in-flight: 0
next: no unambiguous backlog task; loop mode will not ask for input

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
