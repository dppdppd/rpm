#!/bin/bash
# PostCompact hook: re-inject session state after compaction.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
STATE_FILE="$PROJECT_DIR/docs/rpm/~rpm-compact-state"

[ -f "$STATE_FILE" ] || exit 0

# Visible to user in terminal
echo "rpm: session state recovered" >&2

# Context for Claude
echo "rpm: recovered session state"
echo ""
cat "$STATE_FILE"
echo ""
echo "Read docs/rpm/~rpm-compact-state or docs/rpm/~rpm-session-active if needed."
echo ""
echo "IMPORTANT: Begin your first response with exactly this line (no markdown, no extras):"
echo "  rpm: session recovered after compaction"
echo "Then continue with the active task."
