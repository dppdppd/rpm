#!/usr/bin/env bats

# Tests F2 of 2026-04-30-next-refinements.md: the /next status `Today`
# block must report a `no-ops` counter so watch-heavy /next days are
# distinguishable from days with no orchestrator activity.

load helpers

setup()    { setup_sandbox; }
teardown() { teardown_sandbox; }

run_status() {
  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/status.sh"
}

@test "/next status Today line includes no-ops column when log missing" {
  run run_status
  [ "$status" -eq 0 ]
  [[ "$output" == *"== Today ("* ]]
  [[ "$output" == *"no-ops: 0"* ]]
}

@test "/next status counts today's no-op backlog-results" {
  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/log-decision.sh" \
    actionable-backlog watch-one "dispatch" agent-1
  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/log-decision.sh" \
    backlog-result watch-one "already handled" agent-1 no-op
  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/log-decision.sh" \
    actionable-backlog watch-two "dispatch" agent-2
  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/log-decision.sh" \
    backlog-result watch-two "nothing to do" agent-2 no-op
  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/log-decision.sh" \
    backlog-result real-work "worker changed files" agent-3 needs-review

  run run_status
  [ "$status" -eq 0 ]
  [[ "$output" == *"no-ops: 2"* ]]
  [[ "$output" == *"needs review: 1"* ]]
}

@test "/next status no-ops counter ignores prior-day entries" {
  # Forge a no-op from a past date directly into the log; the
  # log-decision helper uses now() for ts, so we write raw JSONL.
  LOG="$PM_DIR/~rpm-orchestrator-log.jsonl"
  cat >> "$LOG" <<'EOF'
{"ts":"2026-04-30T15:29:08-07:00","kind":"backlog-result","target":"old-task","agent_id":"old","status":"no-op"}
EOF

  run run_status
  [ "$status" -eq 0 ]
  [[ "$output" == *"no-ops: 0"* ]]
}
