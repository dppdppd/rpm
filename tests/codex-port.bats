#!/usr/bin/env bats

load helpers

setup()    { setup_sandbox; }
teardown() { teardown_sandbox; }

repo_root() {
  cd "$BATS_TEST_DIRNAME/../.." && pwd
}

require_codex_port_layout() {
  local root
  root=$(repo_root)
  [ -f "$root/plugin/.claude-plugin/plugin.json" ] || skip "codex port tests require monorepo layout"
  [ -d "$root/codex/.codex/skills" ] || skip "codex port tests require monorepo layout"
}

@test "codex manifest exists and carries plugin metadata" {
  require_codex_port_layout
  local root
  root=$(repo_root)
  local version
  version=$(jq -r '.version' "$root/plugin/.claude-plugin/plugin.json")

  run jq -r '.name, .version, .skills, .hooks, .interface.displayName' "$root/codex/.codex/.codex-plugin/plugin.json"
  [ "$status" -eq 0 ]
  [[ "$output" == *$'rpm\n'"${version}"$'\n./skills/\n./hooks.json\nrpm'* ]]
}

@test "codex skill frontmatter avoids unsafe plain YAML scalars" {
  require_codex_port_layout
  local root bad
  root=$(repo_root)

  bad=$(
    awk '
      FNR == 1 && $0 == "---" { in_fm = 1; next }
      in_fm && $0 == "---" { in_fm = 0; nextfile }
      in_fm && /^[A-Za-z][A-Za-z0-9_-]*:[[:space:]]+/ {
        value = $0
        sub(/^[^:]+:[[:space:]]*/, "", value)
        if (value !~ /^[">|]/ && substr(value, 1, 1) != sprintf("%c", 39) && value ~ /:[[:space:]]/) {
          print FILENAME ":" FNR ":" $0
        }
      }
    ' "$root"/codex/.codex/skills/*/SKILL.md
  )
  [ -z "$bad" ] || { echo "$bad"; return 1; }
}

@test "codex skill translation rewrites Claude-only runtime paths" {
  require_codex_port_layout
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

@test "shared next skill keeps Codex wake guidance out of Claude surface" {
  require_codex_port_layout
  local root skill
  root=$(repo_root)
  skill="$root/plugin/skills/next/SKILL.md"

  run grep -F 'CODEX_THREAD_ID' "$skill"
  [ "$status" -eq 1 ]
  run grep -F 'Codex Experimental Worker Wake' "$skill"
  [ "$status" -eq 1 ]
  run grep -F 'send_input({ target:' "$skill"
  [ "$status" -eq 1 ]
  run grep -F 'review-ready-nudge.sh' "$root/plugin/hooks/hooks.json"
  [ "$status" -eq 1 ]
}

@test "codex next worker contract adds experimental nonblocking wake overlay" {
  require_codex_port_layout
  local root skill
  root=$(repo_root)
  skill="$root/codex/.codex/skills/next/SKILL.md"

  run grep -F 'Codex Experimental Worker Wake' "$skill"
  [ "$status" -eq 0 ]
  run grep -F 'CODEX_THREAD_ID' "$skill"
  [ "$status" -eq 0 ]
  run grep -F 'send_input target=<orchestrator-thread-id>' "$skill"
  [ "$status" -eq 1 ]
  run grep -F 'send_input({ target: "<parent-thread-id>", message: "rpm worker result ready: <status> <task-id> by <agent-id>; run rpm:next worker review preflight when convenient." })' "$skill"
  [ "$status" -eq 0 ]
  run grep -F '/loop /next' "$skill"
  [ "$status" -eq 1 ]
  run grep -F 'do rpm:next until blocked' "$skill"
  [ "$status" -eq 0 ]
  run grep -F 'Do not call' "$skill"
  [ "$status" -eq 0 ]
  run grep -F 'wait_agent' "$skill"
  [ "$status" -eq 0 ]
}

@test "codex audit skill includes linked support docs" {
  require_codex_port_layout
  local root
  root=$(repo_root)

  [ -f "$root/codex/.codex/skills/audit/findings-menu.md" ]
  [ -f "$root/codex/.codex/skills/audit/project-mode.md" ]
  [ -f "$root/codex/.codex/skills/audit/references/auditor.md" ]
}

@test "codex scan script resolves rpm version without Claude env" {
  require_codex_port_layout
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
  require_codex_port_layout
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

@test "codex review-ready nudge hook is wired" {
  require_codex_port_layout
  local root
  root=$(repo_root)

  [ -f "$root/codex/.codex/hooks/review-ready-nudge.sh" ]

  run jq -e '.hooks.PostToolUse[0].hooks[]
             | select(.command == "bash ./hooks/review-ready-nudge.sh")' \
    "$root/codex/.codex/hooks.json"
  [ "$status" -eq 0 ]
}

@test "codex session-start hook uses payload cwd without Claude env" {
  require_codex_port_layout
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
