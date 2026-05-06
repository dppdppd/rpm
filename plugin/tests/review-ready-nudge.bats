#!/usr/bin/env bats

load helpers

setup()    { setup_sandbox; }
teardown() { teardown_sandbox; }

repo_root() {
  cd "$BATS_TEST_DIRNAME/../.." && pwd
}

seed_review_ready_result() {
  cat > "$PM_DIR/future/tasks.org" <<'EOF'
** TODO Review task
:PROPERTIES:
:ID: task-one
:END:
[[file:2026-05-06-review-task.md]]
EOF
  echo "# Review task" > "$PM_DIR/future/2026-05-06-review-task.md"

  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/log-decision.sh" \
    actionable-backlog task-one "dispatch" agent-1
  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/log-decision.sh" \
    backlog-result task-one "worker finished" agent-1 needs-review
}

run_nudge_hook() {
  local nudge_dir="$1"
  local root
  root=$(repo_root)
  mkdir -p "$nudge_dir"
  printf '{"cwd":"%s","session_id":"test-session"}\n' "$TEST_DIR" \
    | RPM_PLUGIN_ROOT="$root/codex/.codex" \
      RPM_REVIEW_READY_NUDGE_DIR="$nudge_dir" \
      bash "$root/codex/.codex/hooks/review-ready-nudge.sh"
}

@test "review-ready nudge emits one reminder for pending worker result" {
  seed_review_ready_result
  unset CLAUDE_PROJECT_DIR

  run run_nudge_hook "$TEST_DIR/nudges"
  [ "$status" -eq 0 ]
  [[ "$output" == *"rpm: worker result ready for review"* ]]
  [[ "$output" == *"target=task-one"* ]]
  [[ "$output" == *"agent_id=agent-1"* ]]

  run run_nudge_hook "$TEST_DIR/nudges"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "review-ready nudge is quiet after review result exists" {
  seed_review_ready_result
  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/log-decision.sh" \
    review-result task-one "approved" agent-1 approved
  unset CLAUDE_PROJECT_DIR

  run run_nudge_hook "$TEST_DIR/nudges"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
