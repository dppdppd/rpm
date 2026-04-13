#!/bin/bash
# TaskCreated / TaskCompleted hook: persist native task lifecycle to a
# JSONL log. The log survives unexpected session termination (where
# /session-end never runs) and informs next-session reconciliation.
# Normal sessions: /session-end reads TaskList as the authoritative
# source and uses this log only as a supplement / backup.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
PM_DIR="$PROJECT_DIR/docs/rpm"
LOG="$PM_DIR/~rpm-native-tasks.jsonl"
MARKER="$PM_DIR/~rpm-session-start"

[ -d "$PM_DIR" ] || exit 0
[ -f "$MARKER" ] || exit 0

PAYLOAD=$(cat)

# Schema: task_id, task_subject, task_description, hook_event_name,
# session_id are all top-level fields on stdin.
EVENT=$(echo "$PAYLOAD" | jq -r '.hook_event_name // empty' 2>/dev/null)
TASK_ID=$(echo "$PAYLOAD" | jq -r '.task_id // empty' 2>/dev/null)
SUBJECT=$(echo "$PAYLOAD" | jq -r '.task_subject // empty' 2>/dev/null)
SESSION=$(echo "$PAYLOAD" | jq -r '.session_id // empty' 2>/dev/null)

# Fallback parse if jq is unavailable or payload shape surprises.
[ -z "$EVENT" ] && EVENT=$(echo "$PAYLOAD" | sed -n 's/.*"hook_event_name" *: *"\([^"]*\)".*/\1/p' | head -1)
[ -z "$TASK_ID" ] && TASK_ID=$(echo "$PAYLOAD" | sed -n 's/.*"task_id" *: *"\([^"]*\)".*/\1/p' | head -1)
[ -z "$SUBJECT" ] && SUBJECT=$(echo "$PAYLOAD" | sed -n 's/.*"task_subject" *: *"\([^"]*\)".*/\1/p' | head -1)
[ -z "$SESSION" ] && SESSION=$(echo "$PAYLOAD" | sed -n 's/.*"session_id" *: *"\([^"]*\)".*/\1/p' | head -1)

EVENT="${EVENT:-unknown}"
TASK_ID="${TASK_ID:-unknown}"
SESSION="${SESSION:-unknown}"
TS=$(date -Iseconds)

# Escape subject for JSON embedding. Truncate to keep the log line small.
ESCAPED=$(echo "$SUBJECT" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr -d '\n' | head -c 200)

printf '{"ts":"%s","session":"%s","event":"%s","task_id":"%s","subject":"%s"}\n' \
  "$TS" "$SESSION" "$EVENT" "$TASK_ID" "$ESCAPED" \
  >> "$LOG" 2>/dev/null

# Capture-only — never block task creation/completion.
exit 0
