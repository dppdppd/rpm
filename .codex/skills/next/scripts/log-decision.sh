#!/bin/bash
# /next decision logger — appends one well-formed JSONL line to
# docs/rpm/~rpm-orchestrator-log.jsonl so the LLM running /next
# doesn't have to hand-format the entry each turn.
#
# Usage:
#   log-decision.sh <kind> [target] [rationale] [agent-id] [status]
#
#   <kind>      one of: blocked-on-user, drift-fix, actionable-backlog,
#                       idle, loop-exhausted, backlog-result
#   [target]    short identifier (task ID, drift category, etc.); ""
#               for idle/loop-exhausted
#   [rationale] one-line free text explaining the choice
#   [agent-id]  for actionable-backlog and backlog-result kinds: the
#               subagent ID returned by the Agent tool
#   [status]    for backlog-result only: plan-written | blocked | no-op
#
# Always exits 0; failures (jq missing, log unwritable) print a stderr
# warning and skip — never block the orchestrator.

set -euo pipefail

KIND="${1:-}"
TARGET="${2:-}"
RATIONALE="${3:-}"
AGENT_ID="${4:-}"
STATUS="${5:-}"

if [ -z "$KIND" ]; then
  echo "log-decision.sh: kind required" >&2
  exit 0
fi

PROJECT_DIR="${RPM_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-.}}"
LOG="$PROJECT_DIR/docs/rpm/~rpm-orchestrator-log.jsonl"
mkdir -p "$(dirname "$LOG")" 2>/dev/null || true

TS=$(date -Iseconds 2>/dev/null || date "+%Y-%m-%dT%H:%M:%S%z")

# Build the JSON object via jq when available (escaping is safe);
# fall back to a simple printf if jq is missing.
if command -v jq >/dev/null 2>&1; then
  jq -nc \
    --arg ts "$TS" \
    --arg kind "$KIND" \
    --arg target "$TARGET" \
    --arg rationale "$RATIONALE" \
    --arg agent_id "$AGENT_ID" \
    --arg status "$STATUS" \
    '{ts:$ts, kind:$kind}
     + (if $target    != "" then {target:    $target}    else {} end)
     + (if $rationale != "" then {rationale: $rationale} else {} end)
     + (if $agent_id  != "" then {agent_id:  $agent_id}  else {} end)
     + (if $status    != "" then {status:    $status}    else {} end)' \
    >> "$LOG"
else
  # Best-effort fallback. Avoids embedded quotes — rationale gets
  # stripped of any " characters to keep the JSON parseable.
  R="${RATIONALE//\"/}"
  T="${TARGET//\"/}"
  printf '{"ts":"%s","kind":"%s"' "$TS" "$KIND" >> "$LOG"
  [ -n "$T" ]        && printf ',"target":"%s"' "$T" >> "$LOG"
  [ -n "$R" ]        && printf ',"rationale":"%s"' "$R" >> "$LOG"
  [ -n "$AGENT_ID" ] && printf ',"agent_id":"%s"' "$AGENT_ID" >> "$LOG"
  [ -n "$STATUS" ]   && printf ',"status":"%s"' "$STATUS" >> "$LOG"
  printf '}\n' >> "$LOG"
fi
