# Fix active-marker resume confirmation loop

The v2.30.0 fix covered committed `next:` handoffs from `~rpm-last-session`,
but KL-tricktaker showed the same bad interaction in the active-marker resume
path. When `docs/rpm/~rpm-session-start` is still present for an in-flight
task, SessionStart currently tells the agent to ask whether to continue,
switch, or wrap up.

That is the wrong prompt shape for already-selected work. A valid active
marker means rpm knows the current task, so the generated instructions should
state the task, orient from git state and recent commits, recreate/continue the
native task, and begin. Switching tasks or wrapping up should happen only when
the user explicitly asks for that.

## Resolution

Changed the active-marker resume branch in `session-start-auto.sh` so it treats
the marker task as already selected. The generated instructions now explicitly
forbid asking whether to continue, switch, or wrap up unless the user asks for
that, then tell the agent to orient from git state, create or continue the
native task, and begin.

Validation covers both shipped hook surfaces: `plugin/tests/session-start.bats`
checks the plugin hook and `plugin/tests/codex-port.bats` checks the Codex
mirror. A direct reproduction against KL-tricktaker's marker now emits the
procedural resume instructions and no A/B/C continue prompt.
