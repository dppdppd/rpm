#!/usr/bin/env bats

load helpers

setup()    { setup_sandbox; }
teardown() { teardown_sandbox; }

run_validator() {
  bash "$CLAUDE_PLUGIN_ROOT/hooks/handoff-validator.sh" 2>&1
}

# Make the most-recent commit look like a session-end commit.
make_session_end_commit() {
  (
    cd "$TEST_DIR"
    git commit -q --allow-empty -m "rpm: session end — wrap up"
  )
}

seed_good_handoff() {
  local today
  today="$(date +%Y-%m-%d)"
  cat > "$PM_DIR/past/$today.md" <<'EOF'
# Session

## Accomplished
- thing

## Next
- other thing
EOF
  cat > "$PM_DIR/present/status.md" <<EOF
# status
Last updated: $today
EOF
  cat > "$PM_DIR/~rpm-last-session" <<EOF
task: prior
ended: ${today}T12:00:00Z
next: pick up widget
EOF
}

@test "silent when last commit is not session-end" {
  (cd "$TEST_DIR" && git commit -q --allow-empty -m "unrelated")
  run run_validator
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "silent on clean handoff" {
  seed_good_handoff
  make_session_end_commit
  run run_validator
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "flags missing past log" {
  make_session_end_commit
  run run_validator
  [[ "$output" == *"past/"*"does not exist"* ]]
}

@test "flags missing last-session fields" {
  seed_good_handoff
  cat > "$PM_DIR/~rpm-last-session" <<EOF
task: prior
EOF
  make_session_end_commit
  run run_validator
  [[ "$output" == *"'ended:'"* ]]
  [[ "$output" == *"'next:'"* ]]
}

@test "flags leftover transient markers" {
  seed_good_handoff
  : > "$PM_DIR/~rpm-session-active"
  : > "$PM_DIR/~rpm-learnings.jsonl"
  make_session_end_commit
  run run_validator
  [[ "$output" == *"~rpm-session-active still present"* ]]
  [[ "$output" == *"~rpm-learnings.jsonl still present"* ]]
}

@test "dedupes — second run on same commit is silent" {
  seed_good_handoff
  : > "$PM_DIR/~rpm-session-active"
  make_session_end_commit
  run run_validator
  [ -n "$output" ]
  run run_validator
  [ -z "$output" ]
}
