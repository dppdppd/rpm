# `review-ready.sh` / `status.sh` agent_id pairing bug

## Gap
The orchestrator's review queue (`review-ready.sh`) and in-flight count
(`status.sh`) join `backlog-result` against `review-result` / `actionable-backlog`
on `(target, agent_id)`. But workers default to `agent_id="worker-unknown"`
because the runtime doesn't pass an agent ID into the worker prompt — they
have no way to know their own ID. The orchestrator's `actionable-backlog`
and `review-result` entries, however, use the dispatch ID returned by
`Agent({...})`. So the join key never matches:

- `actionable-backlog target=X agent_id=a6bf091c…`
- `backlog-result      target=X agent_id=worker-unknown`
- `review-result       target=X agent_id=a6bf091c…`

`review-ready.sh` reports the unpaired `backlog-result` as pending
forever; `status.sh` reports the unpaired `actionable-backlog` as
in-flight forever. This blocks future dispatches because the
single-worker concurrency rule trips on phantom in-flights.

## Evidence
- This session (2026-05-26): after closing 5 backlog tickets via worker
  dispatches, `/next status` reported `in-flight: 5` and `review-ready.sh`
  surfaced all 5 as `needs-review` despite each having matching
  `review-result` entries (just keyed on the dispatch ID, not
  `worker-unknown`). Forced retroactive logging of 10 catch-up entries
  to clear the queue and unblock dispatch on `codex-sessionstart-strategy`.

## Platform
**Both** — the scripts live under `plugin/skills/next/scripts/` and ship
to both runtimes via the existing mirror.

## Proposed fix
Two options, pick one:

### Option A — Drop `agent_id` from the join key
Match on `target` alone in both scripts. Simpler, no contract change for
workers. Risk: if the same target is dispatched twice (rare, e.g. after
a `changes-requested` review), the second pair could shadow the first.
Mitigate by requiring the joined `review-result` ts to be greater than
the `backlog-result` ts (already in the script's jq filter).

### Option B — Pass the dispatch agent_id into the worker prompt
Modify `/next`'s Worker Contract to require the orchestrator to template
the dispatch ID into the prompt at dispatch time, e.g. as
`worker id: <runtime_agent_id>`. Workers parse it and pass it through
to `log-decision.sh backlog-result <id>`. Cleanest contractually but
requires every worker invocation site to be updated.

**Recommendation:** Option A. The `agent_id` field is only useful for
auditing/debugging which subagent did what — it doesn't need to be the
join key to get that signal. Option B is more invasive and depends on
every dispatcher remembering to template the ID in.

## Validation
- bats fixture: seed a log with `actionable-backlog agent_id=foo` +
  `backlog-result agent_id=worker-unknown` + `review-result agent_id=foo`.
  Assert `review-ready.sh` returns 0 rows and `status.sh` reports
  `in-flight: 0`.
- Run `/next status` after a dispatch+review cycle in a real session;
  confirm queues match reality.
