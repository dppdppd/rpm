#!/usr/bin/env bats
# Regression guard: shipped skill/agent/hook bodies must never contain
# unrendered plugin-root template placeholders. An LLM following such a
# placeholder verbatim crashes with "No such file or directory" before
# recovering via find.
# See docs/rpm/future/2026-05-26-strip-unknown-plugin-paths.md.

PLUGIN_DIR="$BATS_TEST_DIRNAME/.."
REPO_ROOT="$PLUGIN_DIR/.."

# Codex mirror only exists in the monorepo layout. Subtree-split CI
# (plugin/ only) checks the plugin tree alone — that's the surface that
# actually ships to the GitHub plugin remote.
shipped_dirs() {
  printf '%s\n' \
    "$PLUGIN_DIR/skills" \
    "$PLUGIN_DIR/agents" \
    "$PLUGIN_DIR/hooks"
  [ -d "$REPO_ROOT/codex/.codex/skills" ] && printf '%s\n' "$REPO_ROOT/codex/.codex/skills"
  [ -d "$REPO_ROOT/codex/.codex/hooks" ]  && printf '%s\n' "$REPO_ROOT/codex/.codex/hooks"
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
