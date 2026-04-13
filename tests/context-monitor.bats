#!/usr/bin/env bats

load helpers

setup()    { setup_sandbox; seed_minimal_trackers; }
teardown() {
  # Clean per-session counter files we created during tests.
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

# Run the hook with a given transcript size and session id. The transcript
# file is a tmp file padded with zeros to the requested byte count.
run_monitor() {
  local size="$1"
  local sid="${2:-ctxmon-$$}"
  local transcript
  transcript="$(mktemp)"
  if [ "$size" -gt 0 ]; then
    dd if=/dev/zero of="$transcript" bs=1 count="$size" 2>/dev/null
  fi
  printf '{"session_id":"%s","transcript_path":"%s"}' "$sid" "$transcript" \
    | bash "$CLAUDE_PLUGIN_ROOT/hooks/context-monitor.sh"
  rm -f "$transcript"
}

# Prime the per-session counter so the next invocation lands on the 10th.
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

@test "silent when under the 40% threshold (at 10th call)" {
  seed_marker
  sid="ctxmon-under-$$"
  prime_counter "$sid"
  run run_monitor 100000 "$sid"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "emits 40% warning at 10th call when size crosses WARN" {
  seed_marker
  sid="ctxmon-warn-$$"
  prime_counter "$sid"
  run run_monitor 450000 "$sid"
  [ "$status" -eq 0 ]
  [[ "$output" == *"past 40%"* ]]
  [[ "$output" == *"hookSpecificOutput"* ]]
  echo "$output" | jq -e . >/dev/null
}

@test "emits 60% alert when size crosses ALERT" {
  seed_marker
  sid="ctxmon-alert-$$"
  prime_counter "$sid"
  run run_monitor 650000 "$sid"
  [ "$status" -eq 0 ]
  [[ "$output" == *"past 60%"* ]]
  echo "$output" | jq -e . >/dev/null
}

@test "emits 70% hard wrap-up gate when size crosses STOP" {
  seed_marker
  sid="ctxmon-stop-$$"
  prime_counter "$sid"
  run run_monitor 750000 "$sid"
  [ "$status" -eq 0 ]
  [[ "$output" == *"past 70%"* ]]
  [[ "$output" == *"HARD WRAP-UP GATE"* ]]
  echo "$output" | jq -e . >/dev/null
}

@test "silent on non-10th call even over threshold" {
  seed_marker
  sid="ctxmon-skip-$$"
  # Prime to 4 → next call is 5, which is not a multiple of 10.
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
