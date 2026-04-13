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

@test "silent when under the 40% threshold at 10th call (1M default)" {
  seed_marker
  sid="ctxmon-under-$$"
  prime_counter "$sid"
  run run_monitor 300000 "$sid"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "emits 40% heads-up when tokens cross WARN (1M default)" {
  seed_marker
  sid="ctxmon-warn-$$"
  prime_counter "$sid"
  run run_monitor 450000 "$sid"
  [ "$status" -eq 0 ]
  [[ "$output" == *"past 40%"* ]]
  [[ "$output" == *"consider /session-end"* ]]
  [[ "$output" == *"hookSpecificOutput"* ]]
  echo "$output" | jq -e . >/dev/null
}

@test "emits 60% recommendation when tokens cross ALERT (1M default)" {
  seed_marker
  sid="ctxmon-alert-$$"
  prime_counter "$sid"
  run run_monitor 650000 "$sid"
  [ "$status" -eq 0 ]
  [[ "$output" == *"past 60%"* ]]
  [[ "$output" == *"consider /session-end"* ]]
  echo "$output" | jq -e . >/dev/null
}

@test "emits 70% recommendation when tokens cross STOP (1M default)" {
  seed_marker
  sid="ctxmon-stop-$$"
  prime_counter "$sid"
  run run_monitor 750000 "$sid"
  [ "$status" -eq 0 ]
  [[ "$output" == *"past 70%"* ]]
  [[ "$output" == *"consider /session-end"* ]]
  echo "$output" | jq -e . >/dev/null
}

@test "RPM_CONTEXT_TOKENS override scales thresholds (200K window)" {
  seed_marker
  sid="ctxmon-200k-$$"
  prime_counter "$sid"
  # 90K tokens on a 200K window = 45% → should trip WARN (40%).
  run run_monitor 90000 "$sid" 200000
  [ "$status" -eq 0 ]
  [[ "$output" == *"past 40%"* ]]
}

@test "RPM_CONTEXT_TOKENS override — 1M-sized tokens on 200K window hit 70%" {
  seed_marker
  sid="ctxmon-200kstop-$$"
  prime_counter "$sid"
  run run_monitor 160000 "$sid" 200000
  [ "$status" -eq 0 ]
  [[ "$output" == *"past 70%"* ]]
}

@test "silent on non-10th call even over threshold" {
  seed_marker
  sid="ctxmon-skip-$$"
  echo 4 > "/tmp/rpm-ctx-counter-$sid"
  run run_monitor 750000 "$sid"
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
