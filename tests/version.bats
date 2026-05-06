#!/usr/bin/env bats

load helpers

setup()    { setup_sandbox; }
teardown() { teardown_sandbox; }

@test "version script reports plugin manifest version" {
  local version
  version=$(jq -r '.version' "$CLAUDE_PLUGIN_ROOT/.claude-plugin/plugin.json")

  run bash "$CLAUDE_PLUGIN_ROOT/skills/version/scripts/version.sh"
  [ "$status" -eq 0 ]
  [ "$output" = "rpm v${version}" ]
}
