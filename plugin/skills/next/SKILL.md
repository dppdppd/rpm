---
name: next
description: One-step rpm orchestrator. Picks ONE action per invocation from a priority list (blocked-on-user → drift-fix → actionable-backlog → idle), dispatches a subagent if needed, logs the decision, and returns. Designed to be wrapped by `/loop /next` — never loops internally. Terminates the loop after 3 consecutive idle ticks. Use when the user wants the session to autonomously work the rpm backlog.
argument-hint: "[status]"
allowed-tools: Read Write Edit Glob Grep Bash Agent
---

# /next

Single-step orchestrator that picks ONE action per turn from a strict
priority list, dispatches the work (often as a background subagent),
and returns. **Never loops internally.** Wrap with `/loop /next` for
self-paced execution.

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

## Action priority

Evaluate top-to-bottom; first match wins:

1. **blocked-on-user** — the previous decision (in
   `docs/rpm/~rpm-orchestrator-log.jsonl`) was `blocked-on-user`
   AND the most recent user message didn't address the question.
   Action: re-surface what we're waiting on; do not dispatch.

2. **drift-fix** — `skills/session-end/scripts/scan.sh` reports
   actionable drift: `broken_refs.count > 0`, `claude_md.status` is
   `warn`/`critical`, `pm_docs_staleness.count > 0` with any entry
   `days > 3`, or `migration.count > 0`. Action: apply the obvious
   fix inline (it's mechanical) and log.

3. **needs-review** — run:
   `bash ${CLAUDE_SKILL_DIR}/scripts/review-ready.sh`. If it reports
   a worker result with `status=needs-review` and no matching
   `review-result`, pick the first row. Action: review the detail
   file, git diff, and any verification noted by the worker. If the
   work is acceptable, mark the backlog entry DONE or leave a clear
   session-end reconciliation note, then log `review-result` with
   status `approved`. If more work is needed, append reviewer notes to
   the detail file and log `review-result` with status
   `changes-requested`.

4. **actionable-backlog** — `tasks.org` has at least one TODO or
   IN-PROGRESS entry whose `:BLOCKED_BY:` deps all resolve to DONE
   or CANCELLED. Action: pick the topmost across all `* Parent`
   groups, dispatch a worker using the contract below, and log the
   dispatch. Workers must persist their own result; do not rely on a
   background notification as the only return path.

5. **idle** — none of the above matched. Action: emit summary, log
   `idle`. After 3 consecutive `idle` entries in the log, output
   `action: loop-exhausted` and do NOT call `ScheduleWakeup` —
   hand back to user.

## Output format

Three lines, exactly:

```
action: <kind>
in-flight: <N>
next: <hint or USER ATTENTION>
```

- `<kind>`: one of `blocked-on-user`, `drift-fix`, `needs-review`,
  `actionable-backlog`, `idle`, `loop-exhausted`.
- `<N>`: count of background subagents currently running (read from
  the log; entries with `kind: actionable-backlog` and no
  corresponding `kind: backlog-result` are still in-flight).
- `<hint>`: short prose for what will likely come next, or
  `USER ATTENTION needed for: <reason>` when waiting.

After the three-line block, include any follow-on output the chosen
action produced (e.g. drift-fix details, dispatch confirmation).

## Logging

Use the helper script — never hand-format JSONL:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/log-decision.sh <kind> [target] [rationale] [agent-id] [status]
```

After each priority branch's action, call the script with the
appropriate kind:

- `blocked-on-user` — pass the open question text as `<rationale>`
- `drift-fix` — pass the drift category as `<target>` (e.g.
  `context.md broken-ref`) and the fix summary as `<rationale>`
- `actionable-backlog` — pass the task ID as `<target>`, the
  one-line rationale, and the dispatched subagent's ID as
  `<agent-id>`. Match volta's idiom: the agent ID is what the
  Agent tool returned (look for `agentId:` in the dispatch result).
- `needs-review` — pass the task ID as `<target>`, the reviewer
  action as `<rationale>`, the worker ID as `<agent-id>`, and a
  status of `approved | changes-requested`
- `idle` — empty `<target>`, short `<rationale>`
- `loop-exhausted` — empty `<target>`, fixed `<rationale>` like
  `3 idle ticks`
- `backlog-result` — when a `<task-notification>` arrives for a
  prior `actionable-backlog` dispatch, log it: pass the same
  `<target>` and `<agent-id>` plus a `<status>` of
  `needs-review | plan-written | blocked | no-op`. This pairing is
  what powers the `in-flight: <N>` count.
  If the worker already wrote this line itself, do not duplicate it.
- `review-result` — after reviewing a `needs-review` result, log the
  same `<target>` and `<agent-id>` with status
  `approved | changes-requested`. This clears the review queue for
  that worker result.

The script writes to `docs/rpm/~rpm-orchestrator-log.jsonl`
(gitignored, ephemeral). Failures print a stderr warning and
exit 0 — never block the orchestrator.

## Worker Contract

When dispatching `actionable-backlog`, include this contract in the
worker prompt. This is mandatory for Codex, where background workers
may not reliably re-enter the orchestrator thread.

```
You are an rpm backlog worker.

Task:
- target id: <task-id>
- task heading: <task heading from tasks.org>
- detail file: docs/rpm/future/<detail-file>.md
- orchestrator log: docs/rpm/~rpm-orchestrator-log.jsonl
- worker id: <agent-id if known, otherwise worker-unknown>

Rules:
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
     "<task-id>" "<one-line result>" "<agent-id>" "needs-review"

   Use status `needs-review` when you did work and want the
   orchestrator to review it. Use `plan-written` if you only appended
   `## Plan`, `blocked` if you appended `## Blocked`, and `no-op` only
   when the task is already fully handled.
6. In your final response, state the detail file changed and the status
   you logged. The file + JSONL log are the source of truth.
```

When dispatching from Codex, the generated skill rewrites the helper
path to the installed marketplace plugin path. If you are hand-running
the command, set `RPM_PROJECT_DIR=/absolute/project/root` when the
worker's cwd is not the project root.

## Idle terminal

Read `docs/rpm/~rpm-orchestrator-log.jsonl` only if it exists. Filter
to `kind` ∈ {`blocked-on-user`, `drift-fix`, `actionable-backlog`,
`idle`, `loop-exhausted`} and ignore `backlog-result`. If the file
does not exist, the idle streak is `0`. If the last three filtered
entries are `idle`, this turn becomes `loop-exhausted` instead of
`idle`.

The 3-idle threshold prevents runaway dynamic-mode loops. The user
can resume by running `/next` directly; the next invocation reads
the log fresh and picks up wherever priority leads.

## Concurrency — one worker at a time

`/next` itself is single-threaded — one action per turn. The
subagent it dispatches for `actionable-backlog` runs in background,
but only ONE may be in-flight at a time. Full depth, multi-game
verified before merge.

If `<N>` ≥ 1 already, fall through `actionable-backlog` to `idle` —
wait for the current worker to complete before dispatching another.

Rationale (2026-05-04 audit): saturating to 4 produced an 8.4%
dispatch hit rate (107 dispatches → 9 shipped fixes) because (a)
workers competed for the daemon render queue, (b) concurrent edits
created non-FF push conflicts, (c) each fix verified against one
game shipped before contradictions in other games surfaced. Single-
threaded with corpus-wide verification trades throughput for hit
rate.

## What this skill does NOT do

- Does not pick up tactical user requests — `/next` is for
  unattended autonomous work, not the conversational thread.
- Does not modify `tasks.org` ordering — that's `/backlog review`'s
  job. `/next` only reads.
- Does not run audits, releases, or session-end. Those are explicit
  user-invoked operations.
- Does not retry failed dispatches. A failed subagent logs a
  `backlog-result` with `status: blocked`; the next `/next` tick
  picks the next unblocked item.

## Example session

```
$ /loop /next

action: drift-fix
in-flight: 0
next: actionable-backlog likely (sync-codex-scripts is topmost unblocked)

Fixed: docs/rpm/context.md broken-ref to legacy plugin path.

---

action: actionable-backlog
in-flight: 0
next: idle if no further drift; otherwise drift-fix

Dispatched general-purpose subagent <id> on `sync-codex-scripts`.
Will append a plan to 2026-04-30-sync-codex-scripts.md when it
returns.

---

action: idle
in-flight: 1
next: idle (waiting on backlog-result for sync-codex-scripts)

---

action: idle
in-flight: 1
next: idle

---

action: idle
in-flight: 1
next: USER ATTENTION — 3 idle ticks; loop-exhausted

action: loop-exhausted
```
