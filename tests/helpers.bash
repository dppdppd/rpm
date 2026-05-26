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
# Commits them so subsequent `git status` only reflects test-driven edits,
# matching what a real rpm-initialized project looks like on disk.
seed_minimal_trackers() {
  echo "# context" > "$PM_DIR/context.md"
  printf '# status\n\nLast updated: %s\n' "$(date +%Y-%m-%d)" > "$PM_DIR/present/status.md"
  : > "$PM_DIR/future/tasks.org"
  (
    cd "$TEST_DIR"
    # ~rpm-* runtime files are session-scoped — gitignore them like real projects.
    cat >> .gitignore <<'GITIGNORE_EOF'
docs/rpm/~rpm-*
GITIGNORE_EOF
    git add .gitignore docs/rpm/context.md docs/rpm/present/status.md docs/rpm/future/tasks.org 2>/dev/null
    git commit -q -m "seed trackers" 2>/dev/null
  ) || true
}

# Invoke a hook with a given SessionStart source payload. Captures stdout.
# Optional second arg: session_id (defaults to test-sess-123).
run_session_start() {
  local source="${1:-startup}"
  local sid="${2:-test-sess-123}"
  echo "{\"source\":\"$source\",\"session_id\":\"$sid\"}" \
    | bash "$CLAUDE_PLUGIN_ROOT/hooks/session-start-auto.sh"
}
