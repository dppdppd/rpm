# Fix committed-handoff continuation loop

Session-start has a committed-handoff path for `~rpm-last-session` entries
with a concrete `next:` value. The generated instructions say to treat that
handoff as the plan, but then also tell the agent to ask whether to start or do
something else. That contradiction caused the VOC continuation to loop on a
confirmation question instead of beginning the known next step.

The fix should make committed handoffs procedural: state the next step, update
`docs/rpm/~rpm-session-start`, create the native task, and begin. Only the
ordinary backlog path should ask the user to choose between continuing and
something else.

## Resolution

Changed both the plugin hook and the Codex mirror so a concrete `next:` handoff
is treated as an already selected task. The generated startup instructions now
explicitly forbid asking whether to continue that handoff and tell the agent to
update the session marker to the handoff text before creating the native task.

Validation backs the change with source and mirror regressions: `plugin/tests/session-start.bats`
checks the plugin hook, and `plugin/tests/codex-port.bats` checks the Codex
mirror. Focused and full Bats runs passed during implementation.
