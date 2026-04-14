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

# ============================================================
# Candidate scoring — TaskCompleted → ~rpm-task-candidates.jsonl
# ============================================================

CAND_REL="docs/rpm/~rpm-task-candidates.jsonl"

seed_tasks_org() {
  cat > "$TEST_DIR/docs/rpm/future/tasks.org" <<'EOF'
* Work
** TODO Build login flow
   :PROPERTIES:
   :ID: login
   :END:
** TODO Polish the README
   :PROPERTIES:
   :ID: readme
   :END:
** TODO Refactor auth middleware
   :PROPERTIES:
   :ID: auth
   :END:
** DONE Something already done
   :PROPERTIES:
   :ID: done1
   :END:
EOF
}

@test "TaskCreated does NOT write a candidate" {
  seed_marker; seed_tasks_org
  run_capture '{"hook_event_name":"TaskCreated","task_id":"t1","task_subject":"Build login flow","session_id":"s"}'
  [ ! -f "$TEST_DIR/$CAND_REL" ]
}

@test "TaskCompleted with exact match → confidence 100, heading + id captured" {
  seed_marker; seed_tasks_org
  run_capture '{"hook_event_name":"TaskCompleted","task_id":"t1","task_subject":"Build login flow","session_id":"s"}'
  [ -f "$TEST_DIR/$CAND_REL" ]
  line=$(cat "$TEST_DIR/$CAND_REL")
  echo "$line" | jq -e . >/dev/null
  [[ "$line" == *'"confidence":100'* ]]
  [[ "$line" == *'"heading":"Build login flow"'* ]]
  [[ "$line" == *'"id":"login"'* ]]
}

@test "TaskCompleted with substring match → confidence 80" {
  seed_marker; seed_tasks_org
  # Subject contains the heading text after normalization
  run_capture '{"hook_event_name":"TaskCompleted","task_id":"t2","task_subject":"Implement build login flow today","session_id":"s"}'
  line=$(cat "$TEST_DIR/$CAND_REL")
  [[ "$line" == *'"confidence":80'* ]]
  [[ "$line" == *'"heading":"Build login flow"'* ]]
}

@test "TaskCompleted with word-overlap match → confidence 60 (Jaccard path)" {
  seed_marker; seed_tasks_org
  # "refactor middleware" is NOT a substring of "Refactor auth middleware"
  # (the "auth" word breaks the contiguous substring), so falls through to
  # Jaccard. Overlap: {refactor,middleware} ∩ {refactor,auth,middleware} =
  # 2/3 ≈ 0.67 ≥ 0.6 → confidence 60.
  run_capture '{"hook_event_name":"TaskCompleted","task_id":"t3","task_subject":"refactor middleware","session_id":"s"}'
  line=$(cat "$TEST_DIR/$CAND_REL")
  [[ "$line" == *'"confidence":60'* ]]
  [[ "$line" == *'"heading":"Refactor auth middleware"'* ]]
}

@test "TaskCompleted with no reasonable match → match:null" {
  seed_marker; seed_tasks_org
  run_capture '{"hook_event_name":"TaskCompleted","task_id":"t4","task_subject":"Compose a haiku about kittens","session_id":"s"}'
  line=$(cat "$TEST_DIR/$CAND_REL")
  [[ "$line" == *'"match":null'* ]]
}

@test "TaskCompleted skips DONE entries when picking best match" {
  seed_marker; seed_tasks_org
  # Exactly matches the DONE heading but should still be match:null since
  # DONE entries are terminal — the hook only scans TODO/IN-PROGRESS/BLOCKED.
  run_capture '{"hook_event_name":"TaskCompleted","task_id":"t5","task_subject":"Something already done","session_id":"s"}'
  line=$(cat "$TEST_DIR/$CAND_REL")
  [[ "$line" == *'"match":null'* ]]
}

@test "TaskCompleted with no tasks.org file → no candidate written" {
  seed_marker
  # Remove the empty tasks.org that seed_minimal_trackers creates
  rm -f "$TEST_DIR/docs/rpm/future/tasks.org"
  run_capture '{"hook_event_name":"TaskCompleted","task_id":"t6","task_subject":"whatever","session_id":"s"}'
  [ ! -f "$TEST_DIR/$CAND_REL" ]
}

@test "candidates file appends multiple TaskCompleted events" {
  seed_marker; seed_tasks_org
  run_capture '{"hook_event_name":"TaskCompleted","task_id":"t1","task_subject":"Build login flow","session_id":"s"}'
  run_capture '{"hook_event_name":"TaskCompleted","task_id":"t2","task_subject":"Polish the README","session_id":"s"}'
  lines=$(wc -l < "$TEST_DIR/$CAND_REL")
  [ "$lines" -eq 2 ]
}
