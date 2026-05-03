#!/bin/bash
# /next status — read-only view over docs/rpm/~rpm-orchestrator-log.jsonl.
#
# Emits five sections:
#   == Needs review ==   completed worker results waiting for orchestrator review
#   == In-flight ==      actionable-backlog dispatches without a matching backlog-result
#   == Last 10 decisions ==
#   == Idle streak ==    trailing idle entries; loop-exhausted at 3
#   == Today ==          counters by kind for $(date +%Y-%m-%d)
#
# Pure bash + jq (already in the rpm hook stack). No server, no JS.

set -euo pipefail

PROJECT_DIR="${RPM_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-.}}"
LOG="$PROJECT_DIR/docs/rpm/~rpm-orchestrator-log.jsonl"

if [ ! -f "$LOG" ]; then
  echo "== Needs review =="
  echo "  (none)"
  echo
  echo "== In-flight =="
  echo "  (none)"
  echo
  echo "== Last 10 decisions =="
  echo "  (none)"
  echo
  echo "== Idle streak =="
  echo "  0  (no /next decisions logged yet)"
  echo
  echo "== Today ($(date +%Y-%m-%d)) =="
  echo "  drift fixes: 0   dispatches: 0   needs review: 0   approved: 0   plans: 0   blocked: 0"
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq not found — install jq to use /next status"
  exit 0
fi

# ---- Needs review: worker results not yet reviewed by orchestrator ----
echo "== Needs review =="
REVIEW_READY=$(bash "$(dirname "$0")/review-ready.sh")
if [ -z "$REVIEW_READY" ]; then
  echo "  (none)"
else
  printf '%s\n' "$REVIEW_READY" | sed 's/^/  /'
fi
echo

# ---- In-flight: actionable-backlog without matching backlog-result ----
# An "in-flight" entry has agent_id A and kind=actionable-backlog with no
# subsequent kind=backlog-result for the same agent_id.
echo "== In-flight =="
jq -s -r '
  . as $all
  | map(select(.kind == "actionable-backlog"))
  | map(. as $d
        | $all
        | map(select(.kind == "backlog-result" and .agent_id == $d.agent_id))
        | length as $resolved
        | $d + {resolved: $resolved})
  | map(select(.resolved == 0))
  | if length == 0 then "  (none)"
    else
      map("  " + (.agent_id // "?") + "  " + .kind + ": " + (.target // "?") +
          "  (started " + (.ts // "?") + ")")
      | join("\n")
    end
' "$LOG"
echo

# ---- Last 10 decisions (orchestrator decisions only, not backlog-results) ----
echo "== Last 10 decisions =="
jq -s -r '
  map(select(.kind | IN("blocked-on-user","drift-fix","actionable-backlog","review-result","idle","loop-exhausted")))
  | .[-10:]
  | if length == 0 then "  (none)"
    else
      map("  " + ((.ts // "") | split("T") | (.[1] // "")[0:5])
          + "  " + ((.kind + "                    ")[0:20])
          + "  " + (.target // ""))
      | join("\n")
    end
' "$LOG"
echo

# ---- Idle streak ----
echo "== Idle streak =="
STREAK=$(jq -s -r '
  map(select(.kind | IN("blocked-on-user","drift-fix","actionable-backlog","review-result","idle","loop-exhausted")))
  | reverse
  | map(.kind)
  | (map(. == "idle") | index(false)) // length
' "$LOG")
REMAINING=$((3 - STREAK))
if [ "$STREAK" -ge 3 ]; then
  echo "  $STREAK  (loop-exhausted reached)"
else
  echo "  $STREAK  (loop-exhausted in $REMAINING more idle ticks)"
fi
echo

# ---- Today ----
TODAY=$(date +%Y-%m-%d)
echo "== Today ($TODAY) =="
jq -s -r --arg today "$TODAY" '
  map(select((.ts // "") | startswith($today)))
  | (map(select(.kind == "drift-fix"))           | length) as $drift
  | (map(select(.kind == "actionable-backlog"))  | length) as $disp
  | (map(select(.kind == "backlog-result" and .status == "needs-review")) | length) as $review
  | (map(select(.kind == "review-result" and .status == "approved")) | length) as $done
  | (map(select(.kind == "backlog-result" and .status == "plan-written")) | length) as $plans
  | (map(select(.kind == "backlog-result" and .status == "blocked"))      | length) as $blocked
  | "  drift fixes: \($drift)   dispatches: \($disp)   needs review: \($review)   approved: \($done)   plans: \($plans)   blocked: \($blocked)"
' "$LOG"
