#!/usr/bin/env bats

# Covers skills/session-end/scripts/score-natives.sh.
# Input: JSONL on stdin, one native task per line.
# Output: JSONL on stdout, one match record per input line.
# Buckets: 100 exact / 80 substring / 60 Jaccard≥0.6 / 40 Jaccard≥0.3 / null.

load helpers

setup()    { setup_sandbox; }
teardown() { teardown_sandbox; }

SCORE_REL="skills/session-end/scripts/score-natives.sh"

run_score() {
  bash "$CLAUDE_PLUGIN_ROOT/$SCORE_REL"
}

seed_tasks_org() {
  cat > "$PM_DIR/future/tasks.org" <<'EOF'
#+TITLE: Future
#+TODO: TODO IN-PROGRESS BLOCKED | DONE

* Active
** TODO Decouple tasks.org adds from native TaskCreate [[file:detail.md]]
   :PROPERTIES:
   :ID: decouple-tasks
   :END:

** IN-PROGRESS Refresh session-end SKILL.md
   :PROPERTIES:
   :ID: refresh-session-end
   :END:

** DONE Shipped thing
   CLOSED: [2026-04-15]
   :PROPERTIES:
   :ID: shipped-thing
   :END:
EOF
}

@test "empty stdin → no output" {
  seed_tasks_org
  run bash -c "printf '' | bash \"$CLAUDE_PLUGIN_ROOT/$SCORE_REL\""
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "missing tasks.org → every native gets match:null" {
  run bash -c "printf '%s\n' '{\"id\":\"t1\",\"subject\":\"Anything\",\"status\":\"in_progress\"}' | bash \"$CLAUDE_PLUGIN_ROOT/$SCORE_REL\""
  [ "$status" -eq 0 ]
  echo "$output" | grep -Fq '"native_id":"t1"'
  echo "$output" | grep -Fq '"match":null'
}

@test "exact match → confidence 100 with heading + id" {
  seed_tasks_org
  run bash -c "printf '%s\n' '{\"id\":\"t1\",\"subject\":\"Refresh session-end SKILL.md\",\"status\":\"in_progress\"}' | bash \"$CLAUDE_PLUGIN_ROOT/$SCORE_REL\""
  [ "$status" -eq 0 ]
  echo "$output" | grep -Fq '"confidence":100'
  echo "$output" | grep -Fq '"heading":"Refresh session-end SKILL.md"'
  echo "$output" | grep -Fq '"id":"refresh-session-end"'
}

@test "substring match → confidence 80" {
  seed_tasks_org
  run bash -c "printf '%s\n' '{\"id\":\"t1\",\"subject\":\"Decouple tasks.org\",\"status\":\"in_progress\"}' | bash \"$CLAUDE_PLUGIN_ROOT/$SCORE_REL\""
  [ "$status" -eq 0 ]
  echo "$output" | grep -Fq '"confidence":80'
  echo "$output" | grep -Fq '"id":"decouple-tasks"'
}

@test "no reasonable match → match:null" {
  seed_tasks_org
  run bash -c "printf '%s\n' '{\"id\":\"t9\",\"subject\":\"Totally unrelated gibberish xyz\",\"status\":\"pending\"}' | bash \"$CLAUDE_PLUGIN_ROOT/$SCORE_REL\""
  [ "$status" -eq 0 ]
  echo "$output" | grep -Fq '"native_id":"t9"'
  echo "$output" | grep -Fq '"match":null'
}

@test "strips [[file:...]] link from heading before matching" {
  seed_tasks_org
  # Subject matches cleaned heading, not the raw string with [[file:...]]
  run bash -c "printf '%s\n' '{\"id\":\"t1\",\"subject\":\"Decouple tasks.org adds from native TaskCreate\",\"status\":\"in_progress\"}' | bash \"$CLAUDE_PLUGIN_ROOT/$SCORE_REL\""
  [ "$status" -eq 0 ]
  echo "$output" | grep -Fq '"confidence":100'
  # Heading in output has the link stripped
  echo "$output" | grep -Fq '"heading":"Decouple tasks.org adds from native TaskCreate"'
  # And is NOT the raw form with [[file:...]]
  ! echo "$output" | grep -Fq 'file:detail.md'
}

@test "DONE and CANCELLED headings are not scored" {
  cat > "$PM_DIR/future/tasks.org" <<'EOF'
* Active
** DONE Shipped thing
   :PROPERTIES:
   :ID: shipped
   :END:
EOF
  run bash -c "printf '%s\n' '{\"id\":\"t1\",\"subject\":\"Shipped thing\",\"status\":\"in_progress\"}' | bash \"$CLAUDE_PLUGIN_ROOT/$SCORE_REL\""
  [ "$status" -eq 0 ]
  # Even though subject equals a DONE heading text, DONE isn't scored
  echo "$output" | grep -Fq '"match":null'
}

@test "multiple input lines produce one output line each" {
  seed_tasks_org
  run bash -c "printf '%s\n%s\n' \
    '{\"id\":\"t1\",\"subject\":\"Refresh session-end SKILL.md\",\"status\":\"in_progress\"}' \
    '{\"id\":\"t2\",\"subject\":\"Totally unrelated xyz\",\"status\":\"pending\"}' \
    | bash \"$CLAUDE_PLUGIN_ROOT/$SCORE_REL\""
  [ "$status" -eq 0 ]
  lines=$(echo "$output" | grep -c '^{' || true)
  [ "$lines" -eq 2 ]
  echo "$output" | grep -Fq '"native_id":"t1"'
  echo "$output" | grep -Fq '"native_id":"t2"'
  # t1 matches, t2 doesn't
  echo "$output" | grep '"native_id":"t1"' | grep -Fq '"confidence":100'
  echo "$output" | grep '"native_id":"t2"' | grep -Fq '"match":null'
}

@test "embedded quotes in subject are escaped in output" {
  seed_tasks_org
  run bash -c "printf '%s\n' '{\"id\":\"t1\",\"subject\":\"Add \\\"foo\\\" to bar\",\"status\":\"in_progress\"}' | bash \"$CLAUDE_PLUGIN_ROOT/$SCORE_REL\""
  [ "$status" -eq 0 ]
  echo "$output" | grep -Fq 'native_subject":"Add \"foo\" to bar"'
}

@test "input line missing id is skipped" {
  seed_tasks_org
  run bash -c "printf '%s\n' '{\"subject\":\"No id\",\"status\":\"in_progress\"}' | bash \"$CLAUDE_PLUGIN_ROOT/$SCORE_REL\""
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
