#!/bin/bash
# UserPromptSubmit hook: nudge for session-end when session runs long.
# Checkpointing is handled by PreCompact, so this only covers the
# wrap-up recommendation. Hook has once:true so harness fires it at
# most once per session — no manual flag files needed.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
PM_DIR="$PROJECT_DIR/docs/rpm"
MARKER="$PM_DIR/~rpm-session-active"

# Only act during active sessions
[ -f "$MARKER" ] || exit 0

STARTED=$(grep -oP 'started: \K.*' "$MARKER" 2>/dev/null | head -1)
[ -z "$STARTED" ] && exit 0

START_EPOCH=$(date -d "$STARTED" +%s 2>/dev/null || echo 0)
[ "$START_EPOCH" -eq 0 ] && exit 0

ELAPSED_MIN=$(( ( $(date +%s) - START_EPOCH ) / 60 ))

# Only nudge after 90 min
[ "$ELAPSED_MIN" -lt 90 ] && exit 0

HOURS=$(( ELAPSED_MIN / 60 ))
MINS=$(( ELAPSED_MIN % 60 ))
echo "SessionAge: ${HOURS}h${MINS}m. Context may be degrading. Recommend /rpm:session-end when ready — auto-updates past/present/future, surfaces uncommitted work, and hands off cleanly."
echo ""
echo "IMPORTANT: After completing your current task, you MUST address the user's message above. Do not ignore it."
