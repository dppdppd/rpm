#!/usr/bin/env bats

load helpers

setup()    { setup_sandbox; seed_minimal_trackers; }
teardown() { teardown_sandbox; }

LEARN_REL="docs/rpm/~rpm-learnings.jsonl"
MARKER_REL="docs/rpm/~rpm-session-start"

seed_marker() {
  printf 'session_id: abc\nstarted: 2026-04-13T10:00:00Z\ntask: x\n' \
    > "$TEST_DIR/$MARKER_REL"
}

run_capture() {
  local msg="$1"
  # Pad to ≥200 chars so the length gate passes when appropriate.
  printf '{"last_assistant_message":%s,"session_id":"sess"}' \
    "$(printf '%s' "$msg" | jq -R -s .)" \
    | bash "$CLAUDE_PLUGIN_ROOT/hooks/stop-learn-capture.sh"
}

long() {
  local prefix="$1"
  printf '%s' "$prefix"
  # Pad to 250 chars total
  head -c $((250 - ${#prefix})) /dev/urandom | base64 | tr -d '\n/+=' | head -c $((250 - ${#prefix}))
}

@test "no-op when docs/rpm missing" {
  rm -rf "$PM_DIR"
  seed_marker 2>/dev/null || true
  msg=$(long "key finding: root cause was a race. ")
  run run_capture "$msg"
  [ "$status" -eq 0 ]
  [ ! -f "$TEST_DIR/$LEARN_REL" ]
}

@test "no-op when session marker missing" {
  msg=$(long "key finding: root cause was a race. ")
  run run_capture "$msg"
  [ "$status" -eq 0 ]
  [ ! -f "$TEST_DIR/$LEARN_REL" ]
}

@test "short messages are skipped regardless of signal" {
  seed_marker
  run run_capture "key finding: tiny"
  [ "$status" -eq 0 ]
  [ ! -f "$TEST_DIR/$LEARN_REL" ]
}

@test "long message without signals does not capture" {
  seed_marker
  msg=$(long "I did some things and then some more things. Everything was fine. ")
  run run_capture "$msg"
  [ "$status" -eq 0 ]
  [ ! -f "$TEST_DIR/$LEARN_REL" ]
}

@test "captures on 'key finding:' signal" {
  seed_marker
  msg=$(long "key finding: the bug was a missing await. Fixing that resolved it. ")
  run run_capture "$msg"
  [ "$status" -eq 0 ]
  [ -f "$TEST_DIR/$LEARN_REL" ]
  line=$(cat "$TEST_DIR/$LEARN_REL")
  # Valid JSON line
  echo "$line" | jq -e . >/dev/null
  [[ "$line" == *'"session":"sess"'* ]]
  [[ "$line" == *'key finding'* ]]
}

@test "captures on alternate signal phrase" {
  seed_marker
  msg=$(long "Turns out the env var was empty. That explained the crash. ")
  run run_capture "$msg"
  [ -f "$TEST_DIR/$LEARN_REL" ]
}

@test "appends — two captures create two lines" {
  seed_marker
  m1=$(long "key finding: first learning here. ")
  m2=$(long "root cause was a stale cache in the second run. ")
  run_capture "$m1"
  run_capture "$m2"
  lines=$(wc -l < "$TEST_DIR/$LEARN_REL")
  [ "$lines" -eq 2 ]
}
