#!/usr/bin/env bats
# Regression guard: shipped skill/agent/hook bodies must never contain
# unrendered plugin-root template placeholders. An LLM following such a
# placeholder verbatim crashes with "No such file or directory" before
# recovering via find.
# See docs/rpm/future/2026-05-26-strip-unknown-plugin-paths.md.

PLUGIN_DIR="$BATS_TEST_DIRNAME/.."
REPO_ROOT="$PLUGIN_DIR/.."

shipped_dirs() {
  printf '%s\n' \
    "$PLUGIN_DIR/skills" \
    "$PLUGIN_DIR/agents" \
    "$PLUGIN_DIR/hooks" \
    "$REPO_ROOT/codex/.codex/skills" \
    "$REPO_ROOT/codex/.codex/hooks"
}

@test "no shipped skill/agent/hook body contains 'claude-plugins-official' placeholder" {
  mapfile -t dirs < <(shipped_dirs)
  run grep -rl 'claude-plugins-official' "${dirs[@]}"
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}

@test "no shipped skill/agent/hook body contains 'rpm/unknown' placeholder" {
  mapfile -t dirs < <(shipped_dirs)
  run grep -rl 'rpm/unknown' "${dirs[@]}"
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}
