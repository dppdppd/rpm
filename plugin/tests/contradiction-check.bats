#!/usr/bin/env bats

# Covers plugin/skills/next/scripts/contradiction-check.sh.
# The script gates the rpm:guidance-aligner agent for /next preflight:
# it decides whether a dispatch is needed (inputs changed) or whether
# a cached result can be reused. Tests assert the protocol contract
# the /next skill body relies on:
#   check  -> prints one of: cached|dispatch|skip + a payload
#   save   -> writes a cache header + JSON body the next check can reuse

load helpers

setup()    { setup_sandbox; }
teardown() { teardown_sandbox; }

SCRIPT_REL="skills/next/scripts/contradiction-check.sh"

# Each test gets its own fake project memory dir, isolated from the
# real ~/.claude/projects tree by overriding HOME.
prepare_memory() {
  export HOME="$TEST_DIR/home"
  PROJECT_SLUG=$(printf '%s' "$TEST_DIR" | sed 's|/|-|g')
  MEMORY_DIR="$HOME/.claude/projects/${PROJECT_SLUG}/memory"
  mkdir -p "$MEMORY_DIR"
}

run_check() {
  RPM_PROJECT_DIR="$TEST_DIR" bash "$CLAUDE_PLUGIN_ROOT/$SCRIPT_REL" check
}

run_save() {
  RPM_PROJECT_DIR="$TEST_DIR" \
    bash "$CLAUDE_PLUGIN_ROOT/$SCRIPT_REL" save "$1"
}

@test "check: skip no-memory-dir when memory dir does not exist" {
  export HOME="$TEST_DIR/home-empty"
  mkdir -p "$HOME"
  run run_check
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^skip\ no-memory-dir ]]
}

@test "check: skip no-inputs when memory dir empty and no instructions" {
  prepare_memory
  run run_check
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^skip\ no-inputs ]]
}

@test "check: dispatch with newest epoch when inputs exist and no cache" {
  prepare_memory
  echo "rule body" > "$MEMORY_DIR/feedback_test.md"
  run run_check
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^dispatch\ [0-9]+$ ]]
}

@test "save: writes header + JSON body that check can reuse" {
  prepare_memory
  echo "rule" > "$MEMORY_DIR/feedback_x.md"
  # First check requests dispatch
  EPOCH=$(run_check | awk '{print $2}')
  [ -n "$EPOCH" ]
  # Save a cache entry pretending the agent returned no findings
  printf '{"mode":"contradictions-only","findings":[]}\n' | run_save "$EPOCH"
  # Cache file exists with the expected header
  CACHE="$TEST_DIR/docs/rpm/~rpm-contradiction-cache"
  [ -f "$CACHE" ]
  grep -qE "^inputs_newest=$EPOCH$" "$CACHE"
  grep -qE '^checked_at=[0-9]+$' "$CACHE"
  grep -q '"mode":"contradictions-only"' "$CACHE"
}

@test "check: returns cached <path> when inputs unchanged since save" {
  prepare_memory
  echo "rule" > "$MEMORY_DIR/feedback_y.md"
  EPOCH=$(run_check | awk '{print $2}')
  printf '{"mode":"contradictions-only","findings":[]}\n' | run_save "$EPOCH"
  run run_check
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^cached\ .*~rpm-contradiction-cache$ ]]
}

@test "check: returns dispatch again after a memory file is touched" {
  prepare_memory
  echo "rule" > "$MEMORY_DIR/feedback_z.md"
  EPOCH=$(run_check | awk '{print $2}')
  printf '{"mode":"contradictions-only","findings":[]}\n' | run_save "$EPOCH"
  # Bump mtime past the cached epoch
  sleep 1
  touch "$MEMORY_DIR/feedback_z.md"
  run run_check
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^dispatch\ [0-9]+$ ]]
}
