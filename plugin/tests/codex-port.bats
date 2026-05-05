#!/usr/bin/env bats

load helpers

setup()    { setup_sandbox; }
teardown() { teardown_sandbox; }

repo_root() {
  cd "$BATS_TEST_DIRNAME/../.." && pwd
}

@test "codex manifest exists and carries plugin metadata" {
  local root
  root=$(repo_root)
  local version
  version=$(jq -r '.version' "$root/plugin/.claude-plugin/plugin.json")

  run jq -r '.name, .version, .skills, .hooks, .interface.displayName' "$root/codex/.codex/.codex-plugin/plugin.json"
  [ "$status" -eq 0 ]
  [[ "$output" == *$'rpm\n'"${version}"$'\n./skills/\n./hooks.json\nrpm'* ]]
}

@test "codex skill translation rewrites Claude-only runtime paths" {
  local root
  root=$(repo_root)

  run grep -F '${CLAUDE_PLUGIN_ROOT}' "$root/codex/.codex/skills/rpm/SKILL.md"
  [ "$status" -eq 1 ]
  run grep -F '${CLAUDE_SKILL_DIR}' "$root/codex/.codex/skills/init-rpm/SKILL.md"
  [ "$status" -eq 1 ]

  run grep -F '${RPM_PLUGIN_ROOT:-${CODEX_HOME:-$HOME/.codex}/.tmp/marketplaces/dppdppd-rpm/.codex}/.codex-plugin/plugin.json' "$root/codex/.codex/skills/rpm/SKILL.md"
  [ "$status" -eq 0 ]
  run grep -F '${RPM_PLUGIN_ROOT:-${CODEX_HOME:-$HOME/.codex}/.tmp/marketplaces/dppdppd-rpm/.codex}/skills/init-rpm/scripts/detect.sh' "$root/codex/.codex/skills/init-rpm/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "codex audit skill includes linked support docs" {
  local root
  root=$(repo_root)

  [ -f "$root/codex/.codex/skills/audit/findings-menu.md" ]
  [ -f "$root/codex/.codex/skills/audit/project-mode.md" ]
  [ -f "$root/codex/.codex/skills/audit/references/auditor.md" ]
}

@test "codex scan script resolves rpm version without Claude env" {
  local root
  root=$(repo_root)
  local version
  version=$(jq -r '.version' "$root/plugin/.claude-plugin/plugin.json")
  unset CLAUDE_PROJECT_DIR
  unset CLAUDE_PLUGIN_ROOT
  unset CLAUDE_SKILL_DIR
  unset RPM_PLUGIN_ROOT

  run bash "$root/codex/.codex/skills/session-end/scripts/scan.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *$'=== plugin ===\n'"version=${version}"* ]]
}

@test "codex sync reminder hook is wired and uses payload cwd" {
  local root
  root=$(repo_root)
  unset CLAUDE_PROJECT_DIR

  run jq -e '.hooks.PostToolUse[0].hooks[]
             | select(.command == "bash ./hooks/codex-sync-reminder.sh")' \
    "$root/codex/.codex/hooks.json"
  [ "$status" -eq 0 ]

  run bash -c "printf '%s\n' '{\"cwd\":\"$root\",\"tool_input\":{\"file_path\":\"$root/plugin/hooks/session-start-auto.sh\"}}' | bash '$root/codex/.codex/hooks/codex-sync-reminder.sh'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"run \`bash scripts/sync-codex.sh\`"* ]]
}

@test "codex session-start hook uses payload cwd without Claude env" {
  local root
  root=$(repo_root)
  local version
  version=$(jq -r '.version' "$root/plugin/.claude-plugin/plugin.json")
  seed_minimal_trackers
  unset CLAUDE_PROJECT_DIR
  unset CLAUDE_PLUGIN_ROOT

  run bash -c "printf '%s\n' '{\"source\":\"startup\",\"session_id\":\"codex-sess\",\"cwd\":\"$TEST_DIR\"}' | bash '$root/codex/.codex/hooks/session-start-auto.sh'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"rpm: session active (rpm ${version})"* ]]
  [[ "$output" == *"Your rpm backlog:"* ]]

  local marker_content
  marker_content=$(cat "$PM_DIR/~rpm-session-start")
  [[ "$marker_content" == *"session_id: codex-sess"* ]]
}
