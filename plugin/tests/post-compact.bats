#!/usr/bin/env bats

load helpers

setup()    { setup_sandbox; seed_minimal_trackers; }
teardown() { teardown_sandbox; }

STATE_REL="docs/rpm/~rpm-compact-state"

seed_state() {
  cat > "$TEST_DIR/$STATE_REL" <<'EOF'
=== rpm_compact_state ===
saved=2026-04-13T10:00:00-07:00
task=ship v2.5.3
branch=master

session_id: sess-xyz
task: ship v2.5.3
EOF
}

run_post() {
  local summary="${1:-}"
  if [ -n "$summary" ]; then
    printf '{"compact_summary":%s}' "$(printf '%s' "$summary" | jq -R -s .)" \
      | bash "$CLAUDE_PLUGIN_ROOT/hooks/post-compact.sh"
  else
    echo '{}' | bash "$CLAUDE_PLUGIN_ROOT/hooks/post-compact.sh"
  fi
}

@test "no-op when no state file saved" {
  run run_post
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "emits recovered state when state file present" {
  seed_state
  run run_post
  [ "$status" -eq 0 ]
  [[ "$output" == *"recovered session state"* ]]
  [[ "$output" == *"ship v2.5.3"* ]]
  [[ "$output" == *"session_id: sess-xyz"* ]]
  [[ "$output" == *"session recovered after compaction"* ]]
}

@test "merges compact_summary from stdin when provided" {
  seed_state
  run run_post "We were discussing the marketplace submission."
  [ "$status" -eq 0 ]
  [[ "$output" == *"compact_summary"* ]]
  [[ "$output" == *"marketplace submission"* ]]
}

@test "omits compact_summary section when empty" {
  seed_state
  run run_post
  [ "$status" -eq 0 ]
  [[ "$output" != *"=== compact_summary ==="* ]]
}
