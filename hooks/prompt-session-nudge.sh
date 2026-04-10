#!/bin/bash
# UserPromptSubmit hook: nudge for session-end after 90 min.
# once:true — fires at most once per session.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
MARKER="$PROJECT_DIR/docs/rpm/~rpm-session-active"

[ -f "$MARKER" ] || exit 0

STARTED=$(grep -oP 'started: \K.*' "$MARKER" 2>/dev/null | head -1)
[ -z "$STARTED" ] && exit 0

START_EPOCH=$(date -d "$STARTED" +%s 2>/dev/null || echo 0)
[ "$START_EPOCH" -eq 0 ] && exit 0

ELAPSED_MIN=$(( ( $(date +%s) - START_EPOCH ) / 60 ))
[ "$ELAPSED_MIN" -lt 90 ] && exit 0

HOURS=$(( ELAPSED_MIN / 60 ))
MINS=$(( ELAPSED_MIN % 60 ))
echo "rpm: session ${HOURS}h${MINS}m — consider /session-end when ready"
echo ""
echo "IMPORTANT: After completing your current task, mention this to the user. Do not ignore it."
