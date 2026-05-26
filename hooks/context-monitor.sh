#!/bin/bash
# PostToolUse hook: monitor actual context token usage from the transcript.
# Soft recommendation when fewer than 10% of the window remains.
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

PAYLOAD=$(cat)

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-}"
[ -z "$PROJECT_DIR" ] && PROJECT_DIR=$(echo "$PAYLOAD" | jq -r '.cwd // empty' 2>/dev/null)
[ -z "$PROJECT_DIR" ] && PROJECT_DIR="."
PM_DIR="$PROJECT_DIR/docs/rpm"
MARKER="$PM_DIR/~rpm-session-start"

[ -d "$PM_DIR" ] || exit 0
[ -f "$MARKER" ] || exit 0

SESSION_ID=$(echo "$PAYLOAD" | jq -r '.session_id // "unknown"' 2>/dev/null)
COUNTER_FILE="/tmp/rpm-ctx-counter-${SESSION_ID}"
# Defensive read: only the first line, digits only. Recovers gracefully if a
# prior concurrent write corrupted the file into a multi-line value.
COUNT=$(head -1 "$COUNTER_FILE" 2>/dev/null | tr -dc 0-9)
COUNT=${COUNT:-0}
COUNT=$((COUNT + 1))
# Atomic write: stage in .tmp, rename into place. mv(1) is atomic within a
# single filesystem, so concurrent PostToolUse fires can clobber each other
# but never produce a torn/multi-line counter file.
printf '%d\n' "$COUNT" > "$COUNTER_FILE.tmp" && mv -f "$COUNTER_FILE.tmp" "$COUNTER_FILE"

[ "$COUNT" -lt 3 ] && exit 0
[ $((COUNT % 10)) -ne 0 ] && exit 0

TRANSCRIPT=$(echo "$PAYLOAD" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -z "$TRANSCRIPT" ] && exit 0
[ ! -f "$TRANSCRIPT" ] && exit 0

# Pull the last main-chain assistant usage block from the transcript.
# tac walks from the end; jq's first() stops at the first match. We skip
# sidechain entries (subagent runs) so a Task/Agent call can't mask the
# parent session's true context size.
USAGE=$(tac "$TRANSCRIPT" 2>/dev/null \
  | jq -nr 'first(inputs
             | select(.type=="assistant")
             | select(.isSidechain != true)
             | .message.usage // empty)' 2>/dev/null)
[ -z "$USAGE" ] && exit 0

INPUT=$(echo "$USAGE" | jq -r '.input_tokens // 0' 2>/dev/null)
CACHE_READ=$(echo "$USAGE" | jq -r '.cache_read_input_tokens // 0' 2>/dev/null)
CACHE_CREATE=$(echo "$USAGE" | jq -r '.cache_creation_input_tokens // 0' 2>/dev/null)
TOKENS=$((INPUT + CACHE_READ + CACHE_CREATE))
[ "$TOKENS" -le 0 ] && exit 0

WINDOW="${RPM_CONTEXT_TOKENS:-1000000}"
REMAINING=$((WINDOW - TOKENS))
THRESHOLD=$((WINDOW / 10))

if [ "$REMAINING" -lt "$THRESHOLD" ]; then
  REMAINING_K=$((REMAINING / 1000))
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "rpm: under ${REMAINING_K}k tokens remaining (<10% of window) — consider /session-end soon before the session hits the limit."
  }
}
EOF
fi

exit 0
