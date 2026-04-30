---
name: next
description: One-step rpm orchestrator. Picks ONE action per invocation from a priority list (blocked-on-user → drift-fix → actionable-backlog → idle), dispatches a subagent if needed, logs the decision, and returns. Designed to be wrapped by `/loop /next` — never loops internally. Terminates the loop after 3 consecutive idle ticks. Use when the user wants the session to autonomously work the rpm backlog.
---

# /next

Single-step orchestrator that picks ONE action per turn from a strict
priority list, dispatches the work (often as a background subagent),
and returns. **Never loops internally.** Wrap with `/loop /next` for
self-paced execution.

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

3. **actionable-backlog** — `tasks.org` has at least one TODO or
   IN-PROGRESS entry whose `:BLOCKED_BY:` deps all resolve to DONE
   or CANCELLED. Action: pick the topmost across all `* Parent`
   groups, dispatch a `general-purpose` subagent with
   `run_in_background: true` to investigate and draft a plan
   (subagent emits a `## Plan` block to be appended to the task's
   detail file). Log the dispatch.

4. **idle** — none of the above matched. Action: emit summary, log
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

- `<kind>`: one of `blocked-on-user`, `drift-fix`, `actionable-backlog`,
  `idle`, `loop-exhausted`.
- `<N>`: count of background subagents currently running (read from
  the log; entries with `kind: actionable-backlog` and no
  corresponding `kind: backlog-result` are still in-flight).
- `<hint>`: short prose for what will likely come next, or
  `USER ATTENTION needed for: <reason>` when waiting.

After the three-line block, include any follow-on output the chosen
action produced (e.g. drift-fix details, dispatch confirmation).

## Logging

Append one JSONL line to `docs/rpm/~rpm-orchestrator-log.jsonl` per
invocation:

```json
{"ts":"2026-04-30T10:34:00-07:00","kind":"actionable-backlog","target":"sync-codex-scripts","rationale":"top unblocked TODO; dispatched general-purpose subagent <agent-id>"}
```

For `actionable-backlog` dispatches, also append a `backlog-result`
entry when the `<task-notification>` arrives:

```json
{"ts":"…","kind":"backlog-result","target":"sync-codex-scripts","agent_id":"…","status":"plan-written|blocked|no-op"}
```

This pairing is what powers the `in-flight: <N>` count.

## Idle terminal

Read `tail -3 docs/rpm/~rpm-orchestrator-log.jsonl` (filter to
`kind` ∈ {`blocked-on-user`, `drift-fix`, `actionable-backlog`,
`idle`, `loop-exhausted`} — ignore `backlog-result`). If all three
are `idle`, this turn becomes `loop-exhausted` instead of `idle`.

The 3-idle threshold prevents runaway dynamic-mode loops. The user
can resume by running `/next` directly; the next invocation reads
the log fresh and picks up wherever priority leads.

## Concurrency

`/next` itself is single-threaded — one action per turn. But the
subagents it dispatches for `actionable-backlog` run in background,
so multiple investigations can be in-flight across loop ticks. The
log's `in-flight: <N>` count surfaces this honestly.

If `<N>` ≥ 4 already, fall through `actionable-backlog` to `idle` —
back-pressure to keep the agent fleet bounded.

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
