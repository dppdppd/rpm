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

## Worker Result

### Summary
Implemented option A: dropped the `agent_id` clause from the `(target, agent_id)`
join in both `review-ready.sh` (review queue) and `status.sh` (in-flight count).
Workers can keep emitting `agent_id="worker-unknown"`; the orchestrator can keep
recording dispatch IDs. The match is target-only, and timestamp ordering
(`.key > .key`) is now the sole dedupe guarantee for repeated dispatches of the
same target (e.g. changes-requested re-issues). For `status.sh` this required
adding the equivalent timestamp clause — without it, a single backlog-result
would falsely resolve every prior dispatch of the same target.

### Files changed
- `plugin/skills/next/scripts/review-ready.sh` — removed `agent_id` clause from
  the jq filter; updated the header comment to explain the join.
- `plugin/skills/next/scripts/status.sh` — same: target-only match in the
  in-flight calculation, plus a new `.key > .key` clause so each backlog-result
  only resolves an earlier actionable-backlog.
- `codex/.codex/skills/next/scripts/review-ready.sh` — mirrored from plugin
  (verified byte-identical post-edit).
- `codex/.codex/skills/next/scripts/status.sh` — mirrored from plugin
  (verified byte-identical post-edit).
- `plugin/tests/agent-id-pairing.bats` — new file with 4 tests:
  - target-only join clears worker-unknown vs dispatch-ID review;
  - in-flight count is 0 for worker-unknown backlog-result vs dispatch-ID
    actionable-backlog;
  - changes-requested cycle — only the unpaired second dispatch counts as
    in-flight;
  - changes-requested cycle — only the unreviewed worker result surfaces in
    review-ready.

### Verification
- `bash plugin/tests/run.sh` → 175/175 pass (4 new + 171 prior).
- `shellcheck plugin/.../review-ready.sh plugin/.../status.sh
  codex/.../review-ready.sh codex/.../status.sh` → exit 0.
- `bash plugin/skills/next/scripts/status.sh` against the real project log:
  pre-existing entries from earlier today now join correctly. The only
  in-flight entry is this task's own dispatch
  (`review-ready-agent-id-pairing`) — which is correct: the worker hasn't
  logged its result yet at the time of this verification snapshot.

### Remaining risks
- Two concurrent dispatches of the same target would be indistinguishable
  under the new join (the first backlog-result would resolve the earlier
  dispatch only thanks to ts ordering, but a second backlog-result could
  resolve either of two remaining open dispatches). This is the
  acknowledged tradeoff of option A and matches the detail file's
  mitigation note. Concurrent same-target dispatches are not a current
  use-case — the orchestrator enforces single-worker concurrency.
- Workers still default to `agent_id="worker-unknown"`; the `agent_id`
  field on `backlog-result` entries remains an audit-only signal, not a
  join key. If a future change wants per-worker attribution, option B
  (pass dispatch ID into the worker prompt) is still on the table.
