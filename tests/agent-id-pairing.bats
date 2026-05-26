#!/usr/bin/env bats

# Regression: review-ready.sh and status.sh must not require (target, agent_id)
# to match across log entries. Workers default to agent_id="worker-unknown"
# because the runtime doesn't expose their dispatch ID; the orchestrator
# records the dispatch ID returned by Agent({...}). Matching only on target
# (with timestamp ordering to dedupe repeated dispatches) keeps the
# "needs-review" and "in-flight" counts honest.

load helpers

setup()    { setup_sandbox; }
teardown() { teardown_sandbox; }

seed_one_task() {
  cat > "$PM_DIR/future/tasks.org" <<'EOF'
** TODO Pairing target
:PROPERTIES:
:ID: target-x
:END:
[[file:2026-05-26-target-x.md]]
EOF
  touch "$PM_DIR/future/2026-05-26-target-x.md"
}

run_review_ready() {
  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/review-ready.sh"
}

run_status() {
  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/status.sh"
}

@test "review-ready: target-only join clears a worker-unknown backlog-result against a dispatch-ID review-result" {
  seed_one_task

  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/log-decision.sh" \
    actionable-backlog target-x "dispatch" foo
  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/log-decision.sh" \
    backlog-result target-x "worker finished" worker-unknown needs-review
  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/log-decision.sh" \
    review-result target-x "approved" foo approved

  run run_review_ready
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "status: in-flight count is 0 when a worker-unknown backlog-result follows a dispatch-ID actionable-backlog" {
  seed_one_task

  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/log-decision.sh" \
    actionable-backlog target-x "dispatch" foo
  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/log-decision.sh" \
    backlog-result target-x "worker finished" worker-unknown needs-review

  run run_status
  [ "$status" -eq 0 ]
  in_flight_block=$(printf '%s\n' "$output" | awk '/^== In-flight ==$/,/^$/' )
  [[ "$in_flight_block" == *"(none)"* ]]
}

@test "status: changes-requested cycle — only the unpaired dispatch counts as in-flight" {
  seed_one_task

  # First cycle: dispatch -> worker result -> changes-requested review.
  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/log-decision.sh" \
    actionable-backlog target-x "dispatch one" foo
  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/log-decision.sh" \
    backlog-result target-x "worker one" worker-unknown needs-review
  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/log-decision.sh" \
    review-result target-x "tweak it" foo changes-requested

  # Second dispatch (re-issued because of changes-requested) — still in flight.
  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/log-decision.sh" \
    actionable-backlog target-x "dispatch two" bar

  run run_status
  [ "$status" -eq 0 ]
  in_flight_block=$(printf '%s\n' "$output" | awk '/^== In-flight ==$/,/^$/' )
  # Exactly one entry (the second dispatch) is in flight; first is resolved.
  in_flight_lines=$(printf '%s\n' "$in_flight_block" | grep -c "actionable-backlog: target-x" || true)
  [ "$in_flight_lines" -eq 1 ]
}

@test "review-ready: changes-requested cycle — only the unreviewed worker result surfaces" {
  seed_one_task

  # First cycle: paired by target, second review-result is later — cleared.
  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/log-decision.sh" \
    actionable-backlog target-x "dispatch one" foo
  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/log-decision.sh" \
    backlog-result target-x "worker one" worker-unknown needs-review
  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/log-decision.sh" \
    review-result target-x "tweak it" foo changes-requested

  # Second cycle: dispatched again and finished, but no follow-up review yet.
  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/log-decision.sh" \
    actionable-backlog target-x "dispatch two" bar
  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/log-decision.sh" \
    backlog-result target-x "worker two" worker-unknown needs-review

  run run_review_ready
  [ "$status" -eq 0 ]
  # Only the most-recent backlog-result is unreviewed (worker two);
  # the first was cleared by the changes-requested review-result.
  matches=$(printf '%s\n' "$output" | grep -c "target=target-x" || true)
  [ "$matches" -eq 1 ]
  [[ "$output" == *"target=target-x"* ]]
  [[ "$output" == *"rationale=worker two"* ]]
}
