#!/usr/bin/env bats

load helpers

setup()    { setup_sandbox; }
teardown() { teardown_sandbox; }

seed_review_tasks() {
  cat > "$PM_DIR/future/tasks.org" <<'EOF'
** TODO Task one
:PROPERTIES:
:ID: task-one
:END:
[[file:2026-05-07-task-one.md]]

** TODO Task two
:PROPERTIES:
:ID: task-two
:END:
[[file:2026-05-07-task-two.md]]

** TODO Task three
:PROPERTIES:
:ID: task-three
:END:
[[file:2026-05-07-task-three.md]]

** TODO Task four
:PROPERTIES:
:ID: task-four
:END:
[[file:2026-05-07-task-four.md]]
EOF

  touch "$PM_DIR/future/2026-05-07-task-one.md"
  touch "$PM_DIR/future/2026-05-07-task-two.md"
  touch "$PM_DIR/future/2026-05-07-task-three.md"
  touch "$PM_DIR/future/2026-05-07-task-four.md"
}

run_review_ready() {
  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/review-ready.sh"
}

@test "review-ready lists every backlog-result status" {
  seed_review_tasks

  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/log-decision.sh" \
    backlog-result task-one "worker changed files" agent-1 needs-review
  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/log-decision.sh" \
    backlog-result task-two "worker wrote plan" agent-2 plan-written
  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/log-decision.sh" \
    backlog-result task-three "worker blocked" agent-3 blocked
  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/log-decision.sh" \
    backlog-result task-four "worker found no work" agent-4 no-op

  run run_review_ready
  [ "$status" -eq 0 ]
  [[ "$output" == *"target=task-one"* ]]
  [[ "$output" == *"status=needs-review"* ]]
  [[ "$output" == *"target=task-two"* ]]
  [[ "$output" == *"status=plan-written"* ]]
  [[ "$output" == *"target=task-three"* ]]
  [[ "$output" == *"status=blocked"* ]]
  [[ "$output" == *"target=task-four"* ]]
  [[ "$output" == *"status=no-op"* ]]
}

@test "review-ready only clears results with a later review-result" {
  seed_review_tasks

  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/log-decision.sh" \
    review-result task-one "old review" agent-1 approved
  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/log-decision.sh" \
    backlog-result task-one "new plan" agent-1 plan-written

  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/log-decision.sh" \
    backlog-result task-two "worker changed files" agent-2 needs-review
  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/log-decision.sh" \
    review-result task-two "approved" agent-2 approved

  run run_review_ready
  [ "$status" -eq 0 ]
  [[ "$output" == *"target=task-one"* ]]
  [[ "$output" == *"status=plan-written"* ]]
  [[ "$output" != *"target=task-two"* ]]
}
