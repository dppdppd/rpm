#!/bin/bash
# PostToolUse hook: monitor transcript size as a proxy for context usage.
# Three-tier soft recommendations at ~40% / ~60% / ~70% of context window.
# Pattern adapted from shihchengwei-lab/claude-code-session-kit.
#
# Only runs on every 10th tool call (skipping the first 3) to keep
# overhead negligible. Does nothing unless rpm is initialized AND a
# session is active.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
PM_DIR="$PROJECT_DIR/docs/rpm"
MARKER="$PM_DIR/~rpm-session-start"

[ -d "$PM_DIR" ] || exit 0
[ -f "$MARKER" ] || exit 0

PAYLOAD=$(cat)

# Session-local counter (reset per session via /tmp)
SESSION_ID=$(echo "$PAYLOAD" | jq -r '.session_id // "unknown"' 2>/dev/null)
COUNTER_FILE="/tmp/rpm-ctx-counter-${SESSION_ID}"
COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)
COUNT=$((COUNT + 1))
echo "$COUNT" > "$COUNTER_FILE"

# Skip first 3 calls, then every 10th. Keeps overhead near zero.
[ "$COUNT" -lt 3 ] && exit 0
[ $((COUNT % 10)) -ne 0 ] && exit 0

# transcript_path arrives on stdin for PostToolUse events
TRANSCRIPT=$(echo "$PAYLOAD" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -z "$TRANSCRIPT" ] && exit 0
[ ! -f "$TRANSCRIPT" ] && exit 0

SIZE=$(wc -c < "$TRANSCRIPT" 2>/dev/null || echo 0)

# Thresholds — rough estimates calibrated for ~1MB context window.
# Adjust if your workflow uses a different model/context size.
WARN=400000       # ~40% → soft heads-up
ALERT=600000      # ~60% → recommend wrap-up at next break
STOP=700000       # ~70% → strong recommendation (still user's call)

if [ "$SIZE" -gt "$STOP" ]; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "rpm: context past 70% — consider /session-end soon; detail starts getting lost to compaction beyond this point."
  }
}
EOF
elif [ "$SIZE" -gt "$ALERT" ]; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "rpm: context past 60% — consider /session-end at the next natural break."
  }
}
EOF
elif [ "$SIZE" -gt "$WARN" ]; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "rpm: context past 40% — heads up, you may want to consider /session-end when you reach a good stopping point."
  }
}
EOF
fi

exit 0
