#!/usr/bin/env bats

# Covers the SessionEnd lifecycle hook (plugin/hooks/session-end.sh),
# not the /session-end skill.

load helpers

setup()    { setup_sandbox; seed_minimal_trackers; }
teardown() { teardown_sandbox; }

MARKER_REL="docs/rpm/~rpm-session-start"

seed_marker() {
  cat > "$TEST_DIR/$MARKER_REL" <<EOF
session_id: sess-1
started: 2026-04-13T10:00:00Z
task: write tests
EOF
}

run_end_hook() {
  local reason="${1:-other}"
  echo "{\"reason\":\"$reason\"}" \
    | bash "$CLAUDE_PLUGIN_ROOT/hooks/session-end.sh" 2>&1
}

@test "no-op when docs/rpm missing" {
  rm -rf "$PM_DIR"
  run run_end_hook other
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "no-op when marker missing — clean /session-end path" {
  run run_end_hook other
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "clear reason exits silently" {
  seed_marker
  run run_end_hook clear
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "resume reason exits silently" {
  seed_marker
  run run_end_hook resume
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "logout reason silently backfills daily log" {
  seed_marker
  run run_end_hook logout
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  today=$(date +%Y-%m-%d)
  [ -f "$PM_DIR/past/$today.md" ]
  grep -q "session ended without wrap-up" "$PM_DIR/past/$today.md"
  grep -Fq "Reason:** logout" "$PM_DIR/past/$today.md"
  grep -Fq "Task:** write tests" "$PM_DIR/past/$today.md"
  grep -Fq "Session:** sess-1" "$PM_DIR/past/$today.md"
}

@test "other reason backfills daily log without stderr noise" {
  seed_marker
  run run_end_hook other
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  today=$(date +%Y-%m-%d)
  grep -q "session ended without wrap-up" "$PM_DIR/past/$today.md"
}

@test "empty reason defaults to 'other' and silently backfills" {
  seed_marker
  run bash -c 'echo "{}" | bash "$CLAUDE_PLUGIN_ROOT/hooks/session-end.sh" 2>&1'
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  today=$(date +%Y-%m-%d)
  grep -Fq "Reason:** other" "$PM_DIR/past/$today.md"
}

@test "task field missing from marker logs 'unknown' in daily log" {
  cat > "$TEST_DIR/$MARKER_REL" <<EOF
session_id: sess-2
started: 2026-04-13T10:00:00Z
EOF
  run run_end_hook logout
  [ "$status" -eq 0 ]
  today=$(date +%Y-%m-%d)
  grep -Fq "Task:** unknown" "$PM_DIR/past/$today.md"
}
