#!/usr/bin/env bats

load helpers

setup()    { setup_sandbox; seed_minimal_trackers; }
teardown() { teardown_sandbox; }

STATE_REL="docs/rpm/~rpm-compact-state"
MARKER_REL="docs/rpm/~rpm-session-start"

seed_marker() {
  cat > "$TEST_DIR/$MARKER_REL" <<EOF
session_id: sess-99
started: 2026-04-13T10:00:00Z
task: ship v2.5.3
EOF
}

run_pre_compact() {
  echo '{}' | bash "$CLAUDE_PLUGIN_ROOT/hooks/pre-compact.sh"
}

@test "no-op when docs/rpm missing" {
  rm -rf "$PM_DIR"
  run run_pre_compact
  [ "$status" -eq 0 ]
  [ ! -f "$TEST_DIR/$STATE_REL" ]
}

@test "no-op when marker missing" {
  run run_pre_compact
  [ "$status" -eq 0 ]
  [ ! -f "$TEST_DIR/$STATE_REL" ]
}

@test "writes state snapshot with task, marker, git state" {
  seed_marker
  run run_pre_compact
  [ "$status" -eq 0 ]
  [ -f "$TEST_DIR/$STATE_REL" ]
  state=$(cat "$TEST_DIR/$STATE_REL")
  [[ "$state" == *"rpm_compact_state"* ]]
  [[ "$state" == *"task=ship v2.5.3"* ]]
  [[ "$state" == *"session_id: sess-99"* ]]
  [[ "$state" == *"git state"* ]]
}

@test "appends checkpoint to today's daily log" {
  seed_marker
  run run_pre_compact
  [ "$status" -eq 0 ]
  today=$(date +%Y-%m-%d)
  [ -f "$PM_DIR/past/$today.md" ]
  grep -q "pre-compaction checkpoint" "$PM_DIR/past/$today.md"
  grep -q "Task:.*ship v2.5.3" "$PM_DIR/past/$today.md"
}

@test "lists modified files in git state section" {
  seed_marker
  echo "change" > "$TEST_DIR/untracked.txt"
  (cd "$TEST_DIR" && git add untracked.txt && git commit -q -m "add")
  echo "more" >> "$TEST_DIR/untracked.txt"
  run run_pre_compact
  state=$(cat "$TEST_DIR/$STATE_REL")
  [[ "$state" == *"modified=untracked.txt"* ]]
}

@test "includes open tasks from tasks.org" {
  seed_marker
  cat > "$PM_DIR/future/tasks.org" <<'EOF'
* Work
** TODO first task
** IN-PROGRESS second task
** DONE third task
EOF
  run run_pre_compact
  state=$(cat "$TEST_DIR/$STATE_REL")
  [[ "$state" == *"open tasks"* ]]
  [[ "$state" == *"first task"* ]]
  [[ "$state" == *"second task"* ]]
  [[ "$state" != *"third task"* ]]
}

@test "includes present/status.md snapshot" {
  seed_marker
  cat > "$PM_DIR/present/status.md" <<EOF
# status
Last updated: 2026-04-13
Version: 2.5.3
EOF
  run run_pre_compact
  state=$(cat "$TEST_DIR/$STATE_REL")
  [[ "$state" == *"present snapshot"* ]]
  [[ "$state" == *"Version: 2.5.3"* ]]
}

@test "captures learnings excerpts when present" {
  seed_marker
  printf '{"ts":"t","session":"s","excerpt":"key finding: widget bug"}\n' \
    > "$PM_DIR/~rpm-learnings.jsonl"
  run run_pre_compact
  state=$(cat "$TEST_DIR/$STATE_REL")
  [[ "$state" == *"captured learnings"* ]]
  [[ "$state" == *"widget bug"* ]]
}

@test "stdout asks for confirmation string" {
  seed_marker
  run run_pre_compact
  [ "$status" -eq 0 ]
  [[ "$output" == *"checkpoint saved"* ]]
  [[ "$output" == *"compaction OK"* ]]
}
