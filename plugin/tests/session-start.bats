#!/usr/bin/env bats

load helpers

setup()    { setup_sandbox; }
teardown() { teardown_sandbox; }

@test "exits silently when docs/rpm/ missing" {
  rm -rf "$PM_DIR"
  run run_session_start startup
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "source=compact exits 0 with no output" {
  seed_minimal_trackers
  run run_session_start compact
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "active marker triggers resume path with task name" {
  seed_minimal_trackers
  cat > "$PM_DIR/~rpm-session-active" <<EOF
task: fix flux capacitor
started: 2026-04-12T10:00:00Z
EOF
  run run_session_start startup
  [ "$status" -eq 0 ]
  [[ "$output" == *"rpm: resuming"* ]]
  [[ "$output" == *"fix flux capacitor"* ]]
  [[ "$output" != *"task_menu"* ]]
}

@test "fresh session renders scoreboard and task menu" {
  seed_minimal_trackers
  cat > "$PM_DIR/future/tasks.org" <<'EOF'
* Work
** TODO alpha task
   :PROPERTIES:
   :ID: alpha
   :END:
** DONE done task
   :PROPERTIES:
   :ID: delta
   :END:
EOF
  run run_session_start startup
  [ "$status" -eq 0 ]
  [[ "$output" == *"scoreboard:"* ]]
  [[ "$output" == *"alpha task"* ]]
  [[ "$output" != *"done task"* ]]
}

@test "BLOCKED_BY with incomplete dep hides task" {
  seed_minimal_trackers
  cat > "$PM_DIR/future/tasks.org" <<'EOF'
* Work
** TODO first
   :PROPERTIES:
   :ID: first
   :END:
** BLOCKED blocked-task
   :PROPERTIES:
   :ID: second
   :BLOCKED_BY: first
   :END:
EOF
  run run_session_start startup
  [[ "$output" == *"first"* ]]
  [[ "$output" != *"blocked-task"* ]]
}

@test "BLOCKED_BY with completed dep surfaces task" {
  seed_minimal_trackers
  cat > "$PM_DIR/future/tasks.org" <<'EOF'
* Work
** DONE first
   :PROPERTIES:
   :ID: first
   :END:
** BLOCKED second
   :PROPERTIES:
   :ID: second
   :BLOCKED_BY: first
   :END:
EOF
  run run_session_start startup
  [[ "$output" == *"second"* ]]
}

@test "last-session next message appears when present" {
  seed_minimal_trackers
  : > "$PM_DIR/future/tasks.org"
  cat > "$PM_DIR/~rpm-last-session" <<EOF
task: prior thing
ended: 2026-04-11T12:00:00Z
next: wire up the widget
EOF
  run run_session_start startup
  [[ "$output" == *"wire up the widget"* ]]
}
