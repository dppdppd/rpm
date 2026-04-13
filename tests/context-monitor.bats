#!/usr/bin/env bats

load helpers

setup()    { setup_sandbox; seed_minimal_trackers; }
teardown() {
  rm -f /tmp/rpm-ctx-counter-ctxmon-*
  teardown_sandbox
}

MARKER_REL="docs/rpm/~rpm-session-start"

seed_marker() {
  cat > "$TEST_DIR/$MARKER_REL" <<EOF
session_id: sess-1
started: 2026-04-13T10:00:00Z
task: x
EOF
}

# Run the hook with a synthesized transcript containing one assistant
# message whose usage block sums to the requested token count (placed in
# cache_read_input_tokens — same code path as input/cache_creation).
run_monitor() {
  local tokens="$1"
  local sid="${2:-ctxmon-$$}"
  local window="${3:-}"
  local transcript
  transcript="$(mktemp)"
  if [ "$tokens" -gt 0 ]; then
    printf '{"type":"assistant","message":{"role":"assistant","usage":{"input_tokens":0,"cache_creation_input_tokens":0,"cache_read_input_tokens":%d,"output_tokens":1}}}\n' \
      "$tokens" > "$transcript"
  fi
  if [ -n "$window" ]; then
    RPM_CONTEXT_TOKENS="$window" \
      printf '{"session_id":"%s","transcript_path":"%s"}' "$sid" "$transcript" \
      | RPM_CONTEXT_TOKENS="$window" bash "$CLAUDE_PLUGIN_ROOT/hooks/context-monitor.sh"
  else
    printf '{"session_id":"%s","transcript_path":"%s"}' "$sid" "$transcript" \
      | bash "$CLAUDE_PLUGIN_ROOT/hooks/context-monitor.sh"
  fi
  rm -f "$transcript"
}

prime_counter() {
  local sid="$1"
  echo 9 > "/tmp/rpm-ctx-counter-$sid"
}

@test "no-op when docs/rpm missing" {
  rm -rf "$PM_DIR"
  run run_monitor 500000
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "no-op when no active session marker" {
  run run_monitor 500000
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "skips first tool call silently" {
  seed_marker
  sid="ctxmon-first-$$"
  run run_monitor 800000 "$sid"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "silent when under the 75% threshold at 10th call (1M default)" {
  seed_marker
  sid="ctxmon-under-$$"
  prime_counter "$sid"
  run run_monitor 700000 "$sid"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "emits 75% recommendation when tokens cross WARN (1M default)" {
  seed_marker
  sid="ctxmon-warn-$$"
  prime_counter "$sid"
  run run_monitor 800000 "$sid"
  [ "$status" -eq 0 ]
  [[ "$output" == *"past 75%"* ]]
  [[ "$output" == *"consider /session-end"* ]]
  [[ "$output" == *"hookSpecificOutput"* ]]
  echo "$output" | jq -e . >/dev/null
}

@test "emits 90% recommendation when tokens cross ALERT (1M default)" {
  seed_marker
  sid="ctxmon-alert-$$"
  prime_counter "$sid"
  run run_monitor 950000 "$sid"
  [ "$status" -eq 0 ]
  [[ "$output" == *"past 90%"* ]]
  [[ "$output" == *"consider /session-end"* ]]
  echo "$output" | jq -e . >/dev/null
}

@test "RPM_CONTEXT_TOKENS override scales thresholds (200K window, 75%)" {
  seed_marker
  sid="ctxmon-200k-$$"
  prime_counter "$sid"
  # 160K tokens on a 200K window = 80% → trips WARN (75%).
  run run_monitor 160000 "$sid" 200000
  [ "$status" -eq 0 ]
  [[ "$output" == *"past 75%"* ]]
}

@test "RPM_CONTEXT_TOKENS override — 95% of 200K window hits 90%" {
  seed_marker
  sid="ctxmon-200kstop-$$"
  prime_counter "$sid"
  run run_monitor 190000 "$sid" 200000
  [ "$status" -eq 0 ]
  [[ "$output" == *"past 90%"* ]]
}

@test "silent on non-10th call even over threshold" {
  seed_marker
  sid="ctxmon-skip-$$"
  echo 4 > "/tmp/rpm-ctx-counter-$sid"
  run run_monitor 950000 "$sid"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "silent when transcript_path missing from payload" {
  seed_marker
  sid="ctxmon-notp-$$"
  prime_counter "$sid"
  run bash -c "echo '{\"session_id\":\"$sid\"}' | bash \"\$CLAUDE_PLUGIN_ROOT/hooks/context-monitor.sh\""
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "skips sidechain assistant entries, uses main-chain usage" {
  seed_marker
  sid="ctxmon-sidechain-$$"
  prime_counter "$sid"
  transcript="$(mktemp)"
  # Older main-chain entry at 80% (trips WARN), newer sidechain at 5%.
  {
    printf '{"type":"assistant","isSidechain":false,"message":{"role":"assistant","usage":{"input_tokens":0,"cache_creation_input_tokens":0,"cache_read_input_tokens":800000,"output_tokens":1}}}\n'
    printf '{"type":"assistant","isSidechain":true,"message":{"role":"assistant","usage":{"input_tokens":0,"cache_creation_input_tokens":0,"cache_read_input_tokens":50000,"output_tokens":1}}}\n'
  } > "$transcript"
  run bash -c "printf '{\"session_id\":\"$sid\",\"transcript_path\":\"$transcript\"}' | bash \"\$CLAUDE_PLUGIN_ROOT/hooks/context-monitor.sh\""
  [ "$status" -eq 0 ]
  [[ "$output" == *"past 75%"* ]]
  rm -f "$transcript"
}

@test "silent when transcript has no assistant usage block" {
  seed_marker
  sid="ctxmon-nousage-$$"
  prime_counter "$sid"
  transcript="$(mktemp)"
  echo '{"type":"user","message":{"role":"user","content":"hi"}}' > "$transcript"
  run bash -c "printf '{\"session_id\":\"$sid\",\"transcript_path\":\"$transcript\"}' | bash \"\$CLAUDE_PLUGIN_ROOT/hooks/context-monitor.sh\""
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  rm -f "$transcript"
}
