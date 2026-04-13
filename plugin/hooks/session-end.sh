#!/bin/bash
# SessionEnd hook: detect sessions that ended without running /session-end.
# If the session-active marker is still present when this fires, the user
# ended via /exit, /clear, resume, logout, etc. without the wrap-up skill.
# This hook appends a stub entry to today's daily log so the gap is at
# least documented, and writes a stderr warning so the terminal shows it.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
PM_DIR="$PROJECT_DIR/docs/rpm"
MARKER="$PM_DIR/~rpm-session-start"
TODAY=$(date +%Y-%m-%d)
DAILY_LOG="$PM_DIR/past/$TODAY.md"
NOW=$(date +%H:%M)

[ -d "$PM_DIR" ] || exit 0
[ -f "$MARKER" ] || exit 0   # Clean exit — /session-end removed the marker

# Read matcher from stdin: clear | resume | logout | prompt_input_exit |
# bypass_permissions_disabled | other
PAYLOAD=$(cat)
REASON=$(echo "$PAYLOAD" | jq -r '.reason // empty' 2>/dev/null)
[ -z "$REASON" ] && REASON="other"

# clear / resume are not really "ended" — SessionStart will reload state.
# Only warn on real terminations.
case "$REASON" in
  clear|resume) exit 0 ;;
esac

TASK=$(grep -oP 'task: \K.*' "$MARKER" 2>/dev/null | head -1)
SESSION_ID=$(grep -oP 'session_id: \K.*' "$MARKER" 2>/dev/null | head -1)

# Uncommitted file count for the warning
MOD_COUNT=0
if git -C "$PROJECT_DIR" rev-parse --git-dir > /dev/null 2>&1; then
  MOD_COUNT=$(git -C "$PROJECT_DIR" status --porcelain 2>/dev/null | grep -cE '^.M|^M |^\?\?' || echo 0)
fi

# Terminal-visible warning
{
  echo "rpm: session ended without /session-end"
  echo "rpm:   task: ${TASK:-unknown}"
  [ "$MOD_COUNT" -gt 0 ] && echo "rpm:   uncommitted: $MOD_COUNT files"
  echo "rpm:   next session: run /session-end to backfill or start fresh"
} >&2

# Append a stub to today's daily log if one doesn't already note this
mkdir -p "$PM_DIR/past"
[ ! -f "$DAILY_LOG" ] && { echo "# $TODAY" > "$DAILY_LOG"; echo "" >> "$DAILY_LOG"; }

{
  echo ""
  echo "### $NOW session ended without wrap-up"
  echo "- **Session:** ${SESSION_ID:-unknown}"
  echo "- **Task:** ${TASK:-unknown}"
  echo "- **Reason:** $REASON"
  echo "- **Uncommitted files:** $MOD_COUNT"
  echo "- **Action:** next session should backfill past/ and commit outstanding work"
} >> "$DAILY_LOG" 2>/dev/null

exit 0
