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

@test "active marker + clear source — resume path regardless of last-session state" {
  seed_minimal_trackers
  cat > "$PM_DIR/~rpm-session-active" <<EOF
task: fix flux capacitor
started: 2026-04-12T10:00:00Z
EOF
  # No ~rpm-last-session file — but source=clear means same CC process, so resume.
  run run_session_start clear
  [ "$status" -eq 0 ]
  [[ "$output" == *"rpm: resuming"* ]]
  [[ "$output" == *"fix flux capacitor"* ]]
  [[ "$output" != *"didn't wrap up"* ]]
}

@test "active marker + startup + no last-session = stale — offers wrap-up" {
  seed_minimal_trackers
  cat > "$PM_DIR/~rpm-session-active" <<EOF
task: fix flux capacitor
started: 2026-04-12T10:00:00Z
EOF
  run run_session_start startup
  [ "$status" -eq 0 ]
  [[ "$output" == *"previous session didn't wrap up"* ]]
  [[ "$output" == *"Wrap up the previous task now"* ]]
  [[ "$output" == *"fix flux capacitor"* ]]
  [[ "$output" != *"rpm: resuming"* ]]
}

@test "active marker + startup + fresh last-session = resume" {
  seed_minimal_trackers
  cat > "$PM_DIR/~rpm-session-active" <<EOF
task: fix flux capacitor
started: 2026-04-12T10:00:00Z
EOF
  # last-session ended AFTER current marker started — current work is in-flight.
  cat > "$PM_DIR/~rpm-last-session" <<EOF
task: earlier thing
ended: 2026-04-12T11:00:00Z
next: follow-up
EOF
  run run_session_start startup
  [ "$status" -eq 0 ]
  [[ "$output" == *"rpm: resuming"* ]]
  [[ "$output" != *"didn't wrap up"* ]]
}

@test "active marker + startup + stale last-session = stale path" {
  seed_minimal_trackers
  cat > "$PM_DIR/~rpm-session-active" <<EOF
task: current task
started: 2026-04-12T15:00:00Z
EOF
  # last-session predates current marker — stale.
  cat > "$PM_DIR/~rpm-last-session" <<EOF
task: some older thing
ended: 2026-04-11T12:00:00Z
next: something
EOF
  run run_session_start startup
  [ "$status" -eq 0 ]
  [[ "$output" == *"previous session didn't wrap up"* ]]
}

@test "fresh session renders task menu with backlog title" {
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
  [[ "$output" == *"Your task backlog:"* ]]
  [[ "$output" != *"scoreboard:"* ]]
  [[ "$output" == *"alpha task"* ]]
  [[ "$output" != *"done task"* ]]
}

@test "menu has no blank lines between parent groups" {
  seed_minimal_trackers
  cat > "$PM_DIR/future/tasks.org" <<'EOF'
* First group
** TODO task-a
   :PROPERTIES:
   :ID: a
   :END:
* Second group
** TODO task-b
   :PROPERTIES:
   :ID: b
   :END:
EOF
  run run_session_start startup
  [ "$status" -eq 0 ]
  # Between the last item of First group and the "Second group" heading
  # there should be no blank line.
  [[ "$output" != *$'1. task-a\n\nSecond group'* ]]
  [[ "$output" == *$'1. task-a\nSecond group'* ]]
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

@test "empty backlog — no Pick prompt, brainstorm instructions instead" {
  seed_minimal_trackers
  # tasks.org exists but has no actionable TODOs
  cat > "$PM_DIR/future/tasks.org" <<'EOF'
#+TITLE: test
* Active
** DONE already done
   :PROPERTIES:
   :ID: d1
   :END:
EOF
  run run_session_start startup
  [ "$status" -eq 0 ]
  [[ "$output" == *"(no actionable tasks)"* ]]
  [[ "$output" != *"Pick #"* ]]
  [[ "$output" != *"S: something else"* ]]
  [[ "$output" == *"Review every TODO/BLOCKED/"* ]]
  [[ "$output" == *"Draft 2"*"candidate task"* ]]
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
