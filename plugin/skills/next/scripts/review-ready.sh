#!/bin/bash
# List worker results that need orchestrator review.
#
# A pending review is a backlog-result with status=needs-review that has no
# later review-result for the same target + agent_id pair.

set -euo pipefail

PROJECT_DIR="${RPM_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-.}}"
LOG="$PROJECT_DIR/docs/rpm/~rpm-orchestrator-log.jsonl"
TASKS="$PROJECT_DIR/docs/rpm/future/tasks.org"

if [ ! -f "$LOG" ]; then
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "review-ready.sh: jq not found" >&2
  exit 0
fi

detail_for_id() {
  local id="$1"
  [ -f "$TASKS" ] || return 0
  awk -v id="$id" '
    BEGIN { entry = ""; seen = 0 }
    /^\*\*/ {
      if (seen) {
        print entry
        exit
      }
      entry = $0 "\n"
      next
    }
    {
      entry = entry $0 "\n"
      if ($0 ~ "^[[:space:]]*:ID:[[:space:]]*" id "[[:space:]]*$") {
        seen = 1
      }
    }
    END {
      if (seen) print entry
    }
  ' "$TASKS" \
    | sed -n 's/.*\[\[file:\([^]]*\)\]\].*/docs\/rpm\/future\/\1/p' \
    | head -1
}

jq -s -r '
  . as $all
  | map(select(.kind == "backlog-result" and .status == "needs-review"))
  | map(. as $result
      | ($all
          | map(select(.kind == "review-result"
                       and .target == $result.target
                       and ((.agent_id // "") == ($result.agent_id // ""))))
          | length) as $reviewed
      | $result + {reviewed: $reviewed})
  | map(select(.reviewed == 0))
  | .[]
  | [
      (.target // ""),
      (.agent_id // ""),
      (.ts // ""),
      (.rationale // "")
    ]
  | @tsv
' "$LOG" | while IFS=$'\t' read -r target agent_id ts rationale; do
  [ -n "$target" ] || continue
  detail=$(detail_for_id "$target")
  printf 'target=%s\tagent_id=%s\tts=%s\tdetail=%s\trationale=%s\n' \
    "$target" "$agent_id" "$ts" "$detail" "$rationale"
done
