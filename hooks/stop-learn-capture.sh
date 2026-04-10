#!/bin/bash
# Stop hook: capture potential learnings from the assistant's response.
# Appends to docs/rpm/~rpm-learnings.jsonl when learning signals are
# detected. Session-end reviews and promotes; file is ephemeral.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
PM_DIR="$PROJECT_DIR/docs/pm"
LEARNINGS="$PM_DIR/~rpm-learnings.jsonl"
MARKER="$PM_DIR/~rpm-session-active"

# Only capture during active pm sessions
[ -d "$PM_DIR" ] || exit 0
[ -f "$MARKER" ] || exit 0

# Read payload from stdin
PAYLOAD=$(cat)
MSG=$(echo "$PAYLOAD" | jq -r '.last_assistant_message // empty' 2>/dev/null)
SESSION=$(echo "$PAYLOAD" | jq -r '.session_id // "unknown"' 2>/dev/null)

# Skip empty or short responses (< 200 chars unlikely to contain learnings)
[ ${#MSG} -lt 200 ] && exit 0

# Check for learning signals (case-insensitive)
SIGNALS="root cause|the issue was|turns out|discovered that|the problem was|the fix |should have|mistake was|wrong approach|key discovery|key learning|what didn.t work|correction:|finding:|the real issue|actually caused by|lesson learned"

MATCH=$(echo "$MSG" | grep -ioP ".{0,80}($SIGNALS).{0,80}" | head -3)
[ -z "$MATCH" ] && exit 0

# Build a compact excerpt: the matched context lines
EXCERPT=$(echo "$MATCH" | tr '\n' ' | ' | head -c 500)
TS=$(date -Iseconds)

# Append as JSONL
printf '{"ts":"%s","session":"%s","excerpt":"%s"}\n' \
  "$TS" "$SESSION" "$(echo "$EXCERPT" | sed 's/"/\\"/g' | tr -d '\n')" \
  >> "$LEARNINGS"
