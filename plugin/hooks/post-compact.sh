#!/bin/bash
# PostCompact hook: output saved PM state for context recovery
# stdout may or may not be injected into context depending on
# Claude Code version — the CLAUDE.md fallback instruction
# ensures recovery either way.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
STATE_FILE="$PROJECT_DIR/docs/rpm/~rpm-compact-state"

[ -f "$STATE_FILE" ] || exit 0

echo "PM SESSION STATE (recovered after compaction):"
echo ""
cat "$STATE_FILE"
echo ""
echo "Continue the active PM session. Read docs/rpm/~rpm-compact-state or docs/rpm/~rpm-session-active for full context if needed."
echo ""
echo "IMPORTANT: Begin your first response with exactly this line (no markdown, no extras):"
echo "  rpm: session recovered after compaction"
echo "This confirms to the user that PM state was restored. Then continue with the active task."
