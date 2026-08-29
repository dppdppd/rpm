#!/bin/bash
# PostCompact hook: re-inject session state after compaction.
# Reads compact_summary from stdin (provided by Claude Code) and
# merges it with the saved state snapshot from PreCompact.

# shellcheck source=./_directives.sh
source "$(dirname "${BASH_SOURCE[0]}")/_directives.sh"

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
STATE_FILE="$PROJECT_DIR/docs/rpm/~rpm-compact-state"

[ -f "$STATE_FILE" ] || exit 0

# Read payload from stdin — compact_summary has the conversation
# summary Claude Code generated during compaction.
PAYLOAD=$(cat)
SUMMARY=$(echo "$PAYLOAD" | jq -r '.compact_summary // empty' 2>/dev/null)

# --- Persist the summary so it outlives the conversation ---
# Compaction keeps the thread, so a compacting user loses nothing. A user
# who later runs /clear does — and the summary is otherwise reachable only
# by digging through the transcript JSONL. File it under past/compact/ and
# link it from the daily log, which is committed and survives the clear.
SUMMARY_REF=""
if [ -n "$SUMMARY" ]; then
  PM_DIR="$PROJECT_DIR/docs/rpm"
  TODAY=$(date +%Y-%m-%d)
  NOW=$(date +%H%M)
  COMPACT_DIR="$PM_DIR/past/compact"
  COMPACT_FILE="$COMPACT_DIR/$TODAY-$NOW.md"
  TASK=$(grep -oP '^task=\K.*' "$STATE_FILE" 2>/dev/null | head -1)
  if mkdir -p "$COMPACT_DIR" 2>/dev/null; then
    {
      echo "# Compaction summary — $TODAY $(date +%H:%M)"
      echo ""
      echo "**Task:** ${TASK:-unknown}"
      echo ""
      echo "$SUMMARY"
    } > "$COMPACT_FILE" 2>/dev/null && SUMMARY_REF="docs/rpm/past/compact/$TODAY-$NOW.md"

    # Link it from the daily log so it is findable without knowing the path.
    if [ -n "$SUMMARY_REF" ]; then
      DAILY_LOG="$PM_DIR/past/$TODAY.md"
      [ -f "$DAILY_LOG" ] || printf '# %s\n\n' "$TODAY" > "$DAILY_LOG" 2>/dev/null
      printf -- '- **Compaction summary:** [%s-%s](compact/%s-%s.md)\n' \
        "$TODAY" "$NOW" "$TODAY" "$NOW" >> "$DAILY_LOG" 2>/dev/null
    fi
  fi
fi

# Visible to user in terminal
if [ -n "$SUMMARY_REF" ]; then
  echo "rpm: session state recovered — summary saved to $SUMMARY_REF" >&2
else
  echo "rpm: session state recovered" >&2
fi

# Context for Claude
echo "rpm: recovered session state"
echo ""
cat "$STATE_FILE"

if [ -n "$SUMMARY" ]; then
  echo ""
  echo "=== compact_summary ==="
  echo "$SUMMARY"
fi

if [ -n "$SUMMARY_REF" ]; then
  echo ""
  echo "This summary is also saved at $SUMMARY_REF and linked from today's"
  echo "daily log, so it stays reachable after /clear. Point the user there"
  echo "rather than regenerating it."
fi

echo ""
echo "Open your first response with exactly this line: rpm: session recovered after compaction"
echo "Then continue with the active task. The compact_summary above"
echo "captures what was being discussed before compaction — use it"
echo "alongside the saved state to resume without re-investigation."
echo ""
emit_rpm_directives
