#!/bin/bash
# PostCompact hook: re-inject session state after compaction.
# Reads compact_summary from stdin (provided by Claude Code) and
# merges it with the saved state snapshot from PreCompact.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
STATE_FILE="$PROJECT_DIR/docs/rpm/~rpm-compact-state"

[ -f "$STATE_FILE" ] || exit 0

# Read payload from stdin — compact_summary has the conversation
# summary Claude Code generated during compaction.
PAYLOAD=$(cat)
SUMMARY=$(echo "$PAYLOAD" | jq -r '.compact_summary // empty' 2>/dev/null)

# Visible to user in terminal
echo "rpm: session state recovered" >&2

# Context for Claude
echo "rpm: recovered session state"
echo ""
cat "$STATE_FILE"

if [ -n "$SUMMARY" ]; then
  echo ""
  echo "=== compact_summary ==="
  echo "$SUMMARY"
fi

echo ""
echo "IMPORTANT: Begin your first response with exactly this line (no markdown, no extras):"
echo "  rpm: session recovered after compaction"
echo "Then continue with the active task. The compact_summary above"
echo "captures what was being discussed before compaction — use it"
echo "alongside the saved state to resume without re-investigation."
