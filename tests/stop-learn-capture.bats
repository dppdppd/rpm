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

# --- Backfill task: (unassigned) when session did real work ---

seed_unassigned_marker() {
  local started="${1:-2020-01-01T00:00:00Z}"
  cat > "$TEST_DIR/$MARKER_REL" <<EOF
session_id: test-sess
started: $started
task: (unassigned)
EOF
}

@test "backfill: rewrites (unassigned) to commit subject when session has new commits" {
  seed_unassigned_marker "2020-01-01T00:00:00Z"
  (cd "$TEST_DIR" && \
    echo hello > example.txt && \
    git add example.txt && \
    git commit -q -m "add example feature")
  # Short message — learning capture skipped, but backfill should run.
  run run_capture "n/a"
  [ "$status" -eq 0 ]
  marker_content=$(cat "$TEST_DIR/$MARKER_REL")
  [[ "$marker_content" != *"task: (unassigned)"* ]]
  [[ "$marker_content" == *"task: add example feature"* ]]
}

@test "backfill: strips conventional-commit prefix" {
  seed_unassigned_marker "2020-01-01T00:00:00Z"
  (cd "$TEST_DIR" && \
    echo x > x.txt && git add x.txt && \
    git commit -q -m "fix: handle the race condition")
  run run_capture "n/a"
  marker_content=$(cat "$TEST_DIR/$MARKER_REL")
  [[ "$marker_content" == *"task: handle the race condition"* ]]
  [[ "$marker_content" != *"fix:"* ]]
}

@test "backfill: uses modified file basenames when there are uncommitted edits but no new commits" {
  # started: set to future so the init commit doesn't qualify.
  seed_unassigned_marker "2099-01-01T00:00:00Z"
  (cd "$TEST_DIR" && echo dirty > scratch.md && git add scratch.md)
  run run_capture "n/a"
  marker_content=$(cat "$TEST_DIR/$MARKER_REL")
  [[ "$marker_content" == *"task: edits in: scratch.md"* ]]
}

@test "backfill negative: clean repo with no new commits → marker untouched" {
  # No edits, started: in the future so init commit doesn't count.
  seed_unassigned_marker "2099-01-01T00:00:00Z"
  run run_capture "n/a"
  marker_content=$(cat "$TEST_DIR/$MARKER_REL")
  [[ "$marker_content" == *"task: (unassigned)"* ]]
}

@test "backfill: does not touch already-titled marker" {
  cat > "$TEST_DIR/$MARKER_REL" <<EOF
session_id: test-sess
started: 2020-01-01T00:00:00Z
task: real existing title
EOF
  (cd "$TEST_DIR" && echo x > x.txt && git add x.txt && \
    git commit -q -m "some commit")
  run run_capture "n/a"
  marker_content=$(cat "$TEST_DIR/$MARKER_REL")
  [[ "$marker_content" == *"task: real existing title"* ]]
  [[ "$marker_content" != *"some commit"* ]]
}

@test "backfill: caps derived title at 80 chars" {
  seed_unassigned_marker "2020-01-01T00:00:00Z"
  long_subj="this is a very long commit subject that absolutely exceeds eighty characters and then keeps going further still"
  (cd "$TEST_DIR" && echo x > x.txt && git add x.txt && \
    git commit -q -m "$long_subj")
  run run_capture "n/a"
  marker_content=$(cat "$TEST_DIR/$MARKER_REL")
  task_line=$(grep '^task: ' "$TEST_DIR/$MARKER_REL")
  # 'task: ' is 6 chars; remainder ≤ 80
  remainder=${task_line#task: }
  [ "${#remainder}" -le 80 ]
}
