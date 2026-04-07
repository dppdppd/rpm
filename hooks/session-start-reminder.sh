#!/bin/bash
# SessionStart hook: Remind user to run /pm:session-start
# stdout goes to Claude as context

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
MARKER="$PROJECT_DIR/docs/pm/tmp/pm-session-active"

if [ -f "$MARKER" ]; then
  echo "WARNING: Previous session did not run /pm:session-end."
  echo "Session state from unclean exit:"
  echo ""
  cat "$MARKER"
  echo ""
  echo "Ask the user if they want to run /pm:session-end for the previous session before starting a new one."
  rm -f "$MARKER"
else
  echo "REMINDER: Run /pm:session-start to load context and pick a task. If the user starts working without it, ask them to run it first."
fi
