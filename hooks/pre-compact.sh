#!/bin/bash
# PreCompact hook: checkpoint PM session state before context compaction.
#
# Two jobs:
# 1. Save recovery snapshot to ~rpm-compact-state (for PostCompact)
# 2. Append a mechanical checkpoint to today's daily log — modified
#    files, active task, auto-captured learnings. This is the data a
#    bash script can extract; LLM synthesis happens post-compact.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
PM_DIR="$PROJECT_DIR/docs/rpm"
STATE_FILE="$PM_DIR/~rpm-compact-state"
MARKER="$PM_DIR/~rpm-session-active"
LEARNINGS="$PM_DIR/~rpm-learnings.jsonl"
TODAY=$(date +%Y-%m-%d)
DAILY_LOG="$PM_DIR/past/$TODAY.md"
NOW=$(date +%H:%M)

# Only act if pm is initialized and a session is active
[ -d "$PM_DIR" ] || exit 0
[ -f "$MARKER" ] || exit 0

# --- Extract active task from marker ---
TASK=$(grep -oP 'task: \K.*' "$MARKER" 2>/dev/null | head -1)

# --- Git working state ---
BRANCH=$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null)
MODIFIED_FILES=$(git -C "$PROJECT_DIR" diff --name-only 2>/dev/null | head -20)
STAGED_FILES=$(git -C "$PROJECT_DIR" diff --cached --name-only 2>/dev/null | head -20)
MOD_COUNT=$(echo "$MODIFIED_FILES" | grep -c . 2>/dev/null || echo 0)
STAGE_COUNT=$(echo "$STAGED_FILES" | grep -c . 2>/dev/null || echo 0)

# --- Extract learnings excerpts ---
LEARN_LINES=""
if [ -f "$LEARNINGS" ]; then
  LEARN_LINES=$(jq -r '.excerpt // empty' "$LEARNINGS" 2>/dev/null | head -10)
fi

# === Job 1: Save recovery snapshot ===
{
  echo "=== pm compact state ==="
  echo "saved=$(date -Iseconds)"
  echo "task=$TASK"
  echo "branch=$BRANCH"
  echo ""

  cat "$MARKER"
  echo ""

  if [ -f "$PM_DIR/FUTURE.org" ]; then
    echo "=== open tasks ==="
    grep -E '^\*\* (TODO|IN-PROGRESS|BLOCKED) ' "$PM_DIR/FUTURE.org" 2>/dev/null || echo "(none)"
    echo ""
  fi

  echo "=== git state ==="
  echo "modified_count=$MOD_COUNT"
  echo "staged_count=$STAGE_COUNT"
  [ -n "$MODIFIED_FILES" ] && echo "$MODIFIED_FILES" | while read -r f; do echo "modified=$f"; done
  [ -n "$STAGED_FILES" ] && echo "$STAGED_FILES" | while read -r f; do echo "staged=$f"; done
  echo ""

  if [ -f "$PM_DIR/PRESENT.md" ]; then
    echo "=== present snapshot ==="
    head -10 "$PM_DIR/PRESENT.md"
    echo ""
  fi

  if [ -n "$LEARN_LINES" ]; then
    echo "=== captured learnings ==="
    echo "$LEARN_LINES"
  fi
} > "$STATE_FILE" 2>/dev/null

# === Job 2: Append checkpoint to daily log ===
mkdir -p "$PM_DIR/past"

# Create daily log if it doesn't exist
if [ ! -f "$DAILY_LOG" ]; then
  echo "# $TODAY" > "$DAILY_LOG"
  echo "" >> "$DAILY_LOG"
fi

{
  echo ""
  echo "### $NOW pre-compaction checkpoint"
  echo "- **Task:** ${TASK:-unknown}"
  echo "- **Modified files ($MOD_COUNT):**"
  if [ -n "$MODIFIED_FILES" ]; then
    echo "$MODIFIED_FILES" | while read -r f; do
      [ -n "$f" ] && echo "  - $f"
    done
  else
    echo "  - (none)"
  fi
  if [ -n "$LEARN_LINES" ]; then
    echo "- **Auto-captured learnings:**"
    echo "$LEARN_LINES" | while read -r l; do
      [ -n "$l" ] && echo "  - $l"
    done
  fi
} >> "$DAILY_LOG" 2>/dev/null

echo "PM: Pre-compaction checkpoint saved — recovery state + daily log updated."
