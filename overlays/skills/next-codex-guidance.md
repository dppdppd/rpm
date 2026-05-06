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

   send_input({ target: "<parent-thread-id>", message: "rpm worker result ready: <status> <task-id> by <agent-id>; run /next worker review preflight when convenient." })

   Do not set interrupt true. Do not include raw worker results in this
   message. If the tool is unavailable or rejects the target, continue;
   docs/rpm/~rpm-orchestrator-log.jsonl remains the source of truth and
   the Codex review-ready hook is the fallback.
   ```

This wake call is only a pointer. `/next` worker-review preflight must
still read `review-ready.sh`, inspect the detail file and git diff, and
log `review-result` before dispatching more backlog work.
