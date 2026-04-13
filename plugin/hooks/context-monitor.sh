#!/bin/bash
# PostToolUse hook: monitor actual context token usage from the transcript.
# Two-tier soft recommendations at ~75% / ~90% of the context window.
#
# Reads the latest assistant message's usage block (input + cache_read +
# cache_creation tokens) — this is the real context size, not a byte proxy.
#
# Context window defaults to 1,000,000 tokens (Opus/Sonnet 4.6 with 1M beta).
# Users on the standard 200K window can override:
#   export RPM_CONTEXT_TOKENS=200000
#
# Runs every 10th tool call (after the first 3) to keep overhead negligible.
# No-op unless rpm is initialized AND a session is active.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
PM_DIR="$PROJECT_DIR/docs/rpm"
MARKER="$PM_DIR/~rpm-session-start"

[ -d "$PM_DIR" ] || exit 0
[ -f "$MARKER" ] || exit 0

PAYLOAD=$(cat)

SESSION_ID=$(echo "$PAYLOAD" | jq -r '.session_id // "unknown"' 2>/dev/null)
COUNTER_FILE="/tmp/rpm-ctx-counter-${SESSION_ID}"
COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)
COUNT=$((COUNT + 1))
echo "$COUNT" > "$COUNTER_FILE"

[ "$COUNT" -lt 3 ] && exit 0
[ $((COUNT % 10)) -ne 0 ] && exit 0

TRANSCRIPT=$(echo "$PAYLOAD" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -z "$TRANSCRIPT" ] && exit 0
[ ! -f "$TRANSCRIPT" ] && exit 0

# Pull the last assistant usage block from the transcript. tac walks from
# the end, so this is cheap even on very large transcripts.
USAGE=$(tac "$TRANSCRIPT" 2>/dev/null \
  | grep -m1 '"role":"assistant"' \
  | jq -r '.message.usage // empty' 2>/dev/null)
[ -z "$USAGE" ] && exit 0

INPUT=$(echo "$USAGE" | jq -r '.input_tokens // 0' 2>/dev/null)
CACHE_READ=$(echo "$USAGE" | jq -r '.cache_read_input_tokens // 0' 2>/dev/null)
CACHE_CREATE=$(echo "$USAGE" | jq -r '.cache_creation_input_tokens // 0' 2>/dev/null)
TOKENS=$((INPUT + CACHE_READ + CACHE_CREATE))
[ "$TOKENS" -le 0 ] && exit 0

WINDOW="${RPM_CONTEXT_TOKENS:-1000000}"
WARN=$((WINDOW * 75 / 100))
ALERT=$((WINDOW * 90 / 100))

if [ "$TOKENS" -gt "$ALERT" ]; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "rpm: context past 90% — consider /session-end soon; detail starts getting lost to compaction beyond this point."
  }
}
EOF
elif [ "$TOKENS" -gt "$WARN" ]; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "rpm: context past 75% — consider /session-end at the next natural break."
  }
}
EOF
fi

exit 0
