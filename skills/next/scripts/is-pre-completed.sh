#!/bin/bash
# is-pre-completed.sh — exit 0 if a backlog task's linked detail file
# already contains a populated `## Worker Result` section; exit 1
# otherwise (including missing task, missing link, missing file).
#
# Usage:
#   is-pre-completed.sh <task-id>
#
# Used by /next task-selection to skip stale TODOs whose detail file
# was completed in a prior run but whose tasks.org entry was never
# flipped to DONE (orchestrator crashed, worker logged result but
# missed the org flip, etc). Cheap pre-dispatch grep that prevents the
# wasted subagent round-trip pattern from spec F4.

set -euo pipefail

TASK_ID="${1:-}"
if [ -z "$TASK_ID" ]; then
  exit 1
fi

PROJECT_DIR="${RPM_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-.}}"
TASKS="$PROJECT_DIR/docs/rpm/future/tasks.org"

[ -f "$TASKS" ] || exit 1

# Parse the entry that owns :ID: <task-id> and extract its
# [[file:...]] link. The link can appear on the heading line OR within
# the entry body. We collect the entry text from `**` heading to the
# next `**` heading, confirm it carries the requested :ID:, then pick
# the first [[file:...]] inside it.
DETAIL_REL=$(
  awk -v id="$TASK_ID" '
    BEGIN { entry = ""; matched = 0 }
    /^\*\*/ {
      if (matched) {
        print entry
        exit
      }
      entry = $0 "\n"
      next
    }
    {
      entry = entry $0 "\n"
      if ($0 ~ "^[[:space:]]*:ID:[[:space:]]*" id "[[:space:]]*$") {
        matched = 1
      }
    }
    END {
      if (matched) print entry
    }
  ' "$TASKS" \
    | sed -n 's/.*\[\[file:\([^]]*\)\]\].*/\1/p' \
    | head -1
)

[ -n "$DETAIL_REL" ] || exit 1

DETAIL_PATH="$PROJECT_DIR/docs/rpm/future/$DETAIL_REL"
[ -f "$DETAIL_PATH" ] || exit 1

# Treat any `## Worker Result` heading as pre-completion. The detail
# file body may contain example fences; require beginning of line.
if grep -qE '^## Worker Result[[:space:]]*$' "$DETAIL_PATH"; then
  exit 0
fi
exit 1
