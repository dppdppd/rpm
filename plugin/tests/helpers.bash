#!/usr/bin/env bash
# Shared helpers for rpm hook tests.
# Each test gets an isolated $TEST_DIR that stands in for the project root.

setup_sandbox() {
  TEST_DIR="$(mktemp -d)"
  PM_DIR="$TEST_DIR/docs/rpm"
  mkdir -p "$PM_DIR/past" "$PM_DIR/present" "$PM_DIR/future" "$PM_DIR/reviews"
  (
    cd "$TEST_DIR"
    git init -q
    git config user.email t@t
    git config user.name t
    git commit -q --allow-empty -m init
  )
  export CLAUDE_PROJECT_DIR="$TEST_DIR"
  export CLAUDE_PLUGIN_ROOT="$BATS_TEST_DIRNAME/.."
}

teardown_sandbox() {
  [ -n "$TEST_DIR" ] && rm -rf "$TEST_DIR"
}

# Write a minimal context.md / status.md / tasks.org so session-start runs.
seed_minimal_trackers() {
  echo "# context" > "$PM_DIR/context.md"
  printf '# status\n\nLast updated: %s\n' "$(date +%Y-%m-%d)" > "$PM_DIR/present/status.md"
  : > "$PM_DIR/future/tasks.org"
}

# Invoke a hook with a given SessionStart source payload. Captures stdout.
run_session_start() {
  local source="${1:-startup}"
  echo "{\"source\":\"$source\"}" | bash "$CLAUDE_PLUGIN_ROOT/hooks/session-start-auto.sh"
}
