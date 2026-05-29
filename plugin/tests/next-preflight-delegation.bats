#!/usr/bin/env bats
# /next delegates its token-heavy preflight (scan + mechanical fixes,
# contradiction check, worker review) to the rpm:preflight subagent so
# raw scan output, contradiction reasoning, and diffs stay out of the
# orchestrator's context.
# See docs/rpm/future/2026-05-28-next-preflight-delegation.md.

PLUGIN_DIR="$BATS_TEST_DIRNAME/.."
REPO_ROOT="$PLUGIN_DIR/.."

AGENT="$PLUGIN_DIR/agents/preflight.md"
SKILL="$PLUGIN_DIR/skills/next/SKILL.md"

@test "preflight agent file exists with name and tools" {
  [ -f "$AGENT" ]
  run grep -qE '^name:[[:space:]]*preflight' "$AGENT"
  [ "$status" -eq 0 ]
  # Needs write + bash to apply fixes, edit tasks.org, and run scripts.
  run grep -qE '^[[:space:]]*-[[:space:]]*Bash' "$AGENT"
  [ "$status" -eq 0 ]
  run grep -qE '^[[:space:]]*-[[:space:]]*Edit' "$AGENT"
  [ "$status" -eq 0 ]
}

@test "preflight agent returns only a compact report, never raw output" {
  run grep -F 'Never paste raw scan output' "$AGENT"
  [ "$status" -eq 0 ]
  run grep -F 'drift-fixes:' "$AGENT"
  [ "$status" -eq 0 ]
  run grep -F 'repo-safe:' "$AGENT"
  [ "$status" -eq 0 ]
}

@test "preflight agent does not do task selection or dispatch workers" {
  run grep -F 'Do not do task selection or dispatch backlog workers' "$AGENT"
  [ "$status" -eq 0 ]
}

@test "next preflight dispatches rpm:preflight" {
  run grep -F 'Delegated preflight' "$SKILL"
  [ "$status" -eq 0 ]
  run grep -F 'rpm:preflight' "$SKILL"
  [ "$status" -eq 0 ]
}

@test "next no longer inlines the scan / contradiction / review steps" {
  # The old preflight step headings must be gone — that work is delegated.
  run grep -F '**Mechanical drift**' "$SKILL"
  [ "$status" -eq 1 ]
  run grep -F '**Worker review**' "$SKILL"
  [ "$status" -eq 1 ]
  # /next must not dispatch guidance-aligner anymore; preflight agent owns it.
  run grep -F 'rpm:guidance-aligner' "$SKILL"
  [ "$status" -eq 1 ]
}

@test "next still keeps the outstanding-user-blocker preflight inline" {
  run grep -F 'Outstanding user blocker' "$SKILL"
  [ "$status" -eq 0 ]
}

@test "codex mirror ships the preflight agent reference and dispatch" {
  [ -d "$REPO_ROOT/codex/.codex/skills" ] || skip "codex port requires monorepo layout"
  [ -f "$REPO_ROOT/codex/.codex/skills/next/references/preflight.md" ]
  run grep -F 'rpm:preflight' "$REPO_ROOT/codex/.codex/skills/next/SKILL.md"
  [ "$status" -eq 0 ]
  # Translation must not leave Claude-only runtime placeholders behind.
  run grep -F '${CLAUDE_SKILL_DIR}' "$REPO_ROOT/codex/.codex/skills/next/SKILL.md"
  [ "$status" -eq 1 ]
}
