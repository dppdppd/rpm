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

@test "files the compaction summary under past/compact and links it from the daily log" {
  echo "task=widget work" > "$PM_DIR/~rpm-compact-state"
  run bash -c 'printf "%s" "{\"compact_summary\":\"the widget latches low\"}" | bash "$CLAUDE_PLUGIN_ROOT/hooks/post-compact.sh"'
  [ "$status" -eq 0 ]
  local today; today="$(date +%Y-%m-%d)"
  local f; f=$(ls "$PM_DIR/past/compact/"*.md 2>/dev/null | head -1)
  [ -n "$f" ]
  grep -q "the widget latches low" "$f"
  grep -q "widget work" "$f"
  grep -q "Compaction summary" "$PM_DIR/past/$today.md"
}

@test "no summary file written when compact_summary is empty" {
  echo "task=widget work" > "$PM_DIR/~rpm-compact-state"
  run bash -c 'printf "%s" "{}" | bash "$CLAUDE_PLUGIN_ROOT/hooks/post-compact.sh"'
  [ "$status" -eq 0 ]
  [ ! -d "$PM_DIR/past/compact" ]
}
