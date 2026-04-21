#!/bin/bash
# TaskCreated / TaskCompleted hook.
#
# Job 1 (both events): persist the native task lifecycle to a JSONL log
# (~rpm-native-tasks.jsonl). Survives unexpected session termination;
# /session-end reads TaskList as authoritative and uses this as backup.
#
# Job 2 (TaskCompleted only): score the completed task's subject against
# every actionable `** TODO|IN-PROGRESS|BLOCKED` heading in tasks.org and
# append a candidate line to ~rpm-task-candidates.jsonl. Session-end
# reads the candidates file to auto-apply high-confidence DONE edits and
# to ask about borderline matches — while the subject is fresh, not
# re-derived from cold conversation context.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
PM_DIR="$PROJECT_DIR/docs/rpm"
LOG="$PM_DIR/~rpm-native-tasks.jsonl"
CANDIDATES="$PM_DIR/~rpm-task-candidates.jsonl"
TASKS_ORG="$PM_DIR/future/tasks.org"
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

ESCAPED=$(echo "$SUBJECT" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr -d '\n' | head -c 200)

printf '{"ts":"%s","session":"%s","event":"%s","task_id":"%s","subject":"%s"}\n' \
  "$TS" "$SESSION" "$EVENT" "$TASK_ID" "$ESCAPED" \
  >> "$LOG" 2>/dev/null

# ============================================================
# Job 2: candidate scoring (TaskCompleted only)
# ============================================================
if [ "$EVENT" != "TaskCompleted" ] || [ ! -f "$TASKS_ORG" ] || [ -z "$SUBJECT" ]; then
  exit 0
fi

# shellcheck source=./_scoring.sh
source "$(dirname "${BASH_SOURCE[0]}")/_scoring.sh"

SUBJECT_NORM=$(normalize "$SUBJECT")

BEST_CONF=0
BEST_HEADING=""
BEST_ID=""
CUR_HEADING=""
CUR_ID=""

score_current() {
  [ -z "$CUR_HEADING" ] && return
  local head_norm conf
  head_norm=$(normalize "$CUR_HEADING")
  conf=$(confidence "$SUBJECT_NORM" "$head_norm")
  if [ "$conf" -gt "$BEST_CONF" ]; then
    BEST_CONF=$conf
    BEST_HEADING="$CUR_HEADING"
    BEST_ID="$CUR_ID"
  fi
}

while IFS= read -r line; do
  if [[ "$line" =~ ^\*\*\ (TODO|IN-PROGRESS|BLOCKED)\ (.+)$ ]]; then
    score_current
    CUR_HEADING="${BASH_REMATCH[2]}"
    CUR_ID=""
    # Strip [[file:...]] links
    while [[ "$CUR_HEADING" == *"[[file:"*"]]"* ]]; do
      pre="${CUR_HEADING%%\[\[file:*}"
      rest="${CUR_HEADING#*\[\[file:}"
      post="${rest#*\]\]}"
      CUR_HEADING="${pre}${post}"
    done
    # Strip trailing :tag1:tag2: clusters
    [[ "$CUR_HEADING" =~ ^(.*)[[:space:]]+:[a-zA-Z0-9_:-]+:[[:space:]]*$ ]] && CUR_HEADING="${BASH_REMATCH[1]}"
    [[ "$CUR_HEADING" =~ ^[[:space:]]*(.*[^[:space:]])[[:space:]]*$ ]] && CUR_HEADING="${BASH_REMATCH[1]}"
  elif [[ "$line" =~ ^\*\*\ (DONE|CANCELLED) ]]; then
    # Terminal state — score + clear, so a DONE/CANCELLED entry's
    # :ID: drawer doesn't overwrite the prior actionable heading's ID.
    score_current
    CUR_HEADING=""
    CUR_ID=""
  elif [[ "$line" =~ ^[[:space:]]+:ID:[[:space:]]+([^[:space:]]+) ]]; then
    [ -n "$CUR_HEADING" ] && CUR_ID="${BASH_REMATCH[1]}"
  fi
done < "$TASKS_ORG"
score_current

ESC_HEAD=$(echo "$BEST_HEADING" | sed 's/\\/\\\\/g; s/"/\\"/g')

if [ "$BEST_CONF" -ge 40 ]; then
  printf '{"ts":"%s","session":"%s","event":"complete","native_id":"%s","native_subject":"%s","match":{"heading":"%s","id":"%s","confidence":%d}}\n' \
    "$TS" "$SESSION" "$TASK_ID" "$ESCAPED" "$ESC_HEAD" "$BEST_ID" "$BEST_CONF" \
    >> "$CANDIDATES" 2>/dev/null
else
  printf '{"ts":"%s","session":"%s","event":"complete","native_id":"%s","native_subject":"%s","match":null}\n' \
    "$TS" "$SESSION" "$TASK_ID" "$ESCAPED" \
    >> "$CANDIDATES" 2>/dev/null
fi

# Capture-only — never block task completion.
exit 0
