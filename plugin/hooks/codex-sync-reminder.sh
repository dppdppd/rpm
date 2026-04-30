#!/bin/bash
# PostToolUse Edit|Write hook — reminds the LLM to run sync-codex.sh
# whenever a file under plugin/skills/, plugin/hooks/, or
# plugin/agents/ is touched in a project that has a codex/ sibling
# port (i.e. the rpm plugin's own monorepo). Fires once per matching
# write; main session picks up the REMINDER on the next turn.
#
# Why this hook exists (audit trail):
#   - 2026-04-30 documents audit found that the codex port silently
#     drifted from plugin/ between syncs (e.g. session-end SKILL.md
#     untracked-files reconciliation shipped to plugin/ days before
#     the codex copy got it).
#   - sync-codex.sh is fast, idempotent, and has a manual-sync
#     sentinel for hand-tweaked files — running it on every edit
#     pass is safe.
#   - Stdout reminder (not stderr) so the next turn's main-session
#     model context sees it and can act.
#
# No-op when:
#   - The edit isn't under plugin/{skills,hooks,agents}/
#   - The project doesn't have scripts/sync-codex.sh (i.e. it's not
#     the rpm plugin's own monorepo)

set -u

PAYLOAD=$(cat)

# Extract tool_input.file_path from stdin payload. Fall back to
# the top-level file_path in case the payload shape varies.
FILE_PATH=$(echo "$PAYLOAD" | jq -r '.tool_input.file_path // .file_path // empty' 2>/dev/null)
[ -z "$FILE_PATH" ] && exit 0

# Only fire for edits under the rpm-plugin monorepo's source tree.
case "$FILE_PATH" in
  */plugin/skills/*/SKILL.md|*/plugin/hooks/*.sh|*/plugin/agents/*.md)
    ;;
  *)
    exit 0
    ;;
esac

# Only fire when the project has a sync-codex.sh — i.e. this IS the
# rpm monorepo, not a project that merely consumes the rpm plugin.
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
[ -f "$PROJECT_DIR/scripts/sync-codex.sh" ] || exit 0

# Stdout → next-turn model context. Keep it terse; one line.
echo "REMINDER: $(basename "$FILE_PATH") edited under plugin/ — run \`bash scripts/sync-codex.sh\` before commit so the codex port stays in sync."
