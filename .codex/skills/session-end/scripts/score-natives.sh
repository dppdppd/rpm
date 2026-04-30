#!/bin/bash
# score-natives.sh — score native tasks against tasks.org headings.
#
# Used by /session-end Phase 3a to avoid re-deriving the scoring logic
# in LLM tokens each session. Same 100/80/60/40 buckets as task-capture.sh
# (both source hooks/_scoring.sh).
#
# Stdin: JSONL, one task per line:
#   {"id":"t1","subject":"Fix bug X","status":"in_progress"}
#
# Stdout: JSONL, one match per input line:
#   {"native_id":"t1","native_subject":"Fix bug X","match":{"heading":"...","id":"...","confidence":80}}
#   {"native_id":"t2","native_subject":"...","match":null}

set -u

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
TASKS_ORG="${TASKS_ORG:-$PROJECT_DIR/docs/rpm/future/tasks.org}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"

# shellcheck source=../../../hooks/_scoring.sh
source "$PLUGIN_ROOT/hooks/_scoring.sh"

emit_null() {
  local id="$1" subject="$2"
  local esc
  esc=$(printf '%s' "$subject" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr -d '\n')
  printf '{"native_id":"%s","native_subject":"%s","match":null}\n' "$id" "$esc"
}

emit_match() {
  local id="$1" subject="$2" heading="$3" hid="$4" conf="$5"
  local esc_subj esc_head
  esc_subj=$(printf '%s' "$subject" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr -d '\n')
  esc_head=$(printf '%s' "$heading" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr -d '\n')
  printf '{"native_id":"%s","native_subject":"%s","match":{"heading":"%s","id":"%s","confidence":%d}}\n' \
    "$id" "$esc_subj" "$esc_head" "$hid" "$conf"
}

parse_line() {
  # Populate globals IN_ID + IN_SUBJECT from a JSONL task line.
  # Uses jq if available, falls back to sed for minimal inputs.
  local line="$1"
  IN_ID=$(echo "$line" | jq -r '.id // empty' 2>/dev/null)
  IN_SUBJECT=$(echo "$line" | jq -r '.subject // empty' 2>/dev/null)
  [ -z "$IN_ID" ] && IN_ID=$(echo "$line" | sed -n 's/.*"id" *: *"\([^"]*\)".*/\1/p' | head -1)
  [ -z "$IN_SUBJECT" ] && IN_SUBJECT=$(echo "$line" | sed -n 's/.*"subject" *: *"\([^"]*\)".*/\1/p' | head -1)
}

# --- Fast path: no tasks.org → every native gets match:null ---
if [ ! -f "$TASKS_ORG" ]; then
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    parse_line "$line"
    [ -z "$IN_ID" ] && continue
    emit_null "$IN_ID" "$IN_SUBJECT"
  done
  exit 0
fi

# --- Collect actionable headings from tasks.org ---
HEADINGS=()
HEADING_IDS=()
CUR_HEADING=""
CUR_ID=""

flush_heading() {
  [ -z "$CUR_HEADING" ] && return
  HEADINGS+=("$CUR_HEADING")
  HEADING_IDS+=("$CUR_ID")
}

while IFS= read -r line; do
  if [[ "$line" =~ ^\*\*\ (TODO|IN-PROGRESS|BLOCKED)\ (.+)$ ]]; then
    flush_heading
    CUR_HEADING="${BASH_REMATCH[2]}"
    CUR_ID=""
    # Strip every [[file:...]] link
    while [[ "$CUR_HEADING" == *"[[file:"*"]]"* ]]; do
      pre="${CUR_HEADING%%\[\[file:*}"
      rest="${CUR_HEADING#*\[\[file:}"
      post="${rest#*\]\]}"
      CUR_HEADING="${pre}${post}"
    done
    # Drop trailing :tag1:tag2: cluster
    [[ "$CUR_HEADING" =~ ^(.*)[[:space:]]+:[a-zA-Z0-9_:-]+:[[:space:]]*$ ]] && CUR_HEADING="${BASH_REMATCH[1]}"
    # Trim
    [[ "$CUR_HEADING" =~ ^[[:space:]]*(.*[^[:space:]])[[:space:]]*$ ]] && CUR_HEADING="${BASH_REMATCH[1]}"
  elif [[ "$line" =~ ^\*\*\ (DONE|CANCELLED) ]]; then
    # Terminal state — flush the prior actionable and stop tracking
    # until the next actionable heading. Without this, a DONE/CANCELLED
    # entry's :ID: drawer overwrites CUR_ID and contaminates the
    # previous actionable's match output.
    flush_heading
    CUR_HEADING=""
    CUR_ID=""
  elif [[ "$line" =~ ^[[:space:]]+:ID:[[:space:]]+([^[:space:]]+) ]]; then
    [ -n "$CUR_HEADING" ] && CUR_ID="${BASH_REMATCH[1]}"
  fi
done < "$TASKS_ORG"
flush_heading

# --- Score each input line against the heading set ---
while IFS= read -r line; do
  [ -z "$line" ] && continue
  parse_line "$line"
  [ -z "$IN_ID" ] && continue

  subj_norm=$(normalize "$IN_SUBJECT")
  best_conf=0
  best_heading=""
  best_id=""

  for i in "${!HEADINGS[@]}"; do
    h="${HEADINGS[$i]}"
    h_norm=$(normalize "$h")
    c=$(confidence "$subj_norm" "$h_norm")
    if [ "$c" -gt "$best_conf" ]; then
      best_conf=$c
      best_heading="$h"
      best_id="${HEADING_IDS[$i]}"
    fi
  done

  if [ "$best_conf" -ge 40 ]; then
    emit_match "$IN_ID" "$IN_SUBJECT" "$best_heading" "$best_id" "$best_conf"
  else
    emit_null "$IN_ID" "$IN_SUBJECT"
  fi
done
