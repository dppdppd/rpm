#!/usr/bin/env bats

load helpers

setup()    { setup_sandbox; seed_minimal_trackers; }
teardown() { teardown_sandbox; }

LOG_REL="docs/rpm/~rpm-native-tasks.jsonl"
MARKER_REL="docs/rpm/~rpm-session-start"

seed_marker() {
  printf 'session_id: abc\nstarted: 2026-04-13T10:00:00Z\ntask: something\n' \
    > "$TEST_DIR/$MARKER_REL"
}

run_capture() {
  local payload="$1"
  echo "$payload" | bash "$CLAUDE_PLUGIN_ROOT/hooks/task-capture.sh"
}

@test "no-op when docs/rpm missing" {
  rm -rf "$PM_DIR"
  run run_capture '{"hook_event_name":"TaskCreated","task_id":"t1","task_subject":"x","session_id":"s"}'
  [ "$status" -eq 0 ]
  [ ! -f "$TEST_DIR/$LOG_REL" ]
}

@test "no-op when no active session marker" {
  run run_capture '{"hook_event_name":"TaskCreated","task_id":"t1","task_subject":"x","session_id":"s"}'
  [ "$status" -eq 0 ]
  [ ! -f "$TEST_DIR/$LOG_REL" ]
}

@test "TaskCreated appends a JSONL line with core fields" {
  seed_marker
  run run_capture '{"hook_event_name":"TaskCreated","task_id":"t1","task_subject":"hello","session_id":"sess-a"}'
  [ "$status" -eq 0 ]
  [ -f "$TEST_DIR/$LOG_REL" ]
  line=$(cat "$TEST_DIR/$LOG_REL")
  [[ "$line" == *'"event":"TaskCreated"'* ]]
  [[ "$line" == *'"task_id":"t1"'* ]]
  [[ "$line" == *'"subject":"hello"'* ]]
  [[ "$line" == *'"session":"sess-a"'* ]]
}

@test "TaskCompleted appends a second JSONL line" {
  seed_marker
  run_capture '{"hook_event_name":"TaskCreated","task_id":"t1","task_subject":"one","session_id":"s"}'
  run_capture '{"hook_event_name":"TaskCompleted","task_id":"t1","task_subject":"one","session_id":"s"}'
  lines=$(wc -l < "$TEST_DIR/$LOG_REL")
  [ "$lines" -eq 2 ]
  grep -q '"event":"TaskCompleted"' "$TEST_DIR/$LOG_REL"
}

@test "escapes embedded quotes in subject" {
  seed_marker
  run_capture '{"hook_event_name":"TaskCreated","task_id":"t1","task_subject":"he said \"hi\"","session_id":"s"}'
  line=$(cat "$TEST_DIR/$LOG_REL")
  # Resulting line must still be valid JSON
  echo "$line" | jq -e . >/dev/null
}

@test "falls back to sed parse when payload is minimal" {
  seed_marker
  # Missing session_id on purpose — sed fallback should fill 'unknown'.
  run_capture '{"hook_event_name":"TaskCreated","task_id":"t9","task_subject":"x"}'
  line=$(cat "$TEST_DIR/$LOG_REL")
  [[ "$line" == *'"session":"unknown"'* ]]
  [[ "$line" == *'"task_id":"t9"'* ]]
}
