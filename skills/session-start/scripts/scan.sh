#!/bin/bash
# Session-start mechanical scan. Collects git state, latest past
# file, PRESENT.md drift check, and session marker status.
#
# Runs via `!bash "${CLAUDE_SKILL_DIR}/scripts/scan.sh"` injection
# so output is in context before the skill body starts Phase 1.
# This eliminates ~4 sequential tool-call rounds (ls, git status,
# git log x2) that were the main session-start latency source.
#
# Output: sections (=== name ===) with key=value lines.

set -u

ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$ROOT" 2>/dev/null || { echo "error=cannot_cd_to_root"; exit 0; }

# ----------------------------------------------------------------
echo "=== latest_past ==="
if [ -d docs/pm/past ]; then
  LATEST=$(ls -1 docs/pm/past/*.md 2>/dev/null \
    | grep -E '[0-9]{4}-[0-9]{2}-[0-9]{2}\.md$' \
    | sort -r | head -1)
  if [ -n "$LATEST" ]; then
    echo "file=$(basename "$LATEST")"
  else
    echo "file=none"
  fi
else
  echo "file=none"
fi

# ----------------------------------------------------------------
echo
echo "=== git ==="
if git rev-parse --git-dir > /dev/null 2>&1; then
  PORCELAIN=$(git status --porcelain 2>/dev/null || true)
  MODIFIED=$(echo "$PORCELAIN" | grep -cE '^.M|^M ' || true)
  UNTRACKED=$(echo "$PORCELAIN" | grep -cE '^\?\?' || true)
  STAGED=$(echo "$PORCELAIN" | grep -cE '^M |^A |^D ' || true)
  STASHES=$(git stash list 2>/dev/null | wc -l | tr -d ' ')
  echo "modified=${MODIFIED:-0}"
  echo "untracked=${UNTRACKED:-0}"
  echo "staged=${STAGED:-0}"
  echo "stashes=${STASHES:-0}"
else
  echo "modified=0"
  echo "untracked=0"
  echo "staged=0"
  echo "stashes=0"
  echo "note=not_a_git_repo"
fi

# ----------------------------------------------------------------
echo
echo "=== present_drift ==="
if [ -f docs/pm/PRESENT.md ] && git rev-parse --git-dir > /dev/null 2>&1; then
  LAST=$(git log -1 --format=%H -- docs/pm/PRESENT.md 2>/dev/null)
  if [ -n "$LAST" ]; then
    echo "last_commit=$LAST"
    DRIFT_LOG=$(git log --oneline "${LAST}..HEAD" 2>/dev/null || true)
    if [ -n "$DRIFT_LOG" ]; then
      DRIFT_COUNT=$(echo "$DRIFT_LOG" | wc -l | tr -d ' ')
      echo "drift_count=$DRIFT_COUNT"
      echo "$DRIFT_LOG" | while IFS= read -r line; do
        echo "commit=$line"
      done
    else
      echo "drift_count=0"
    fi
  else
    echo "last_commit=none"
    echo "drift_count=0"
  fi
else
  echo "last_commit=none"
  echo "drift_count=0"
  [ ! -f docs/pm/PRESENT.md ] && echo "note=no_present_md"
fi

# ----------------------------------------------------------------
echo
echo "=== session_marker ==="
if [ -f docs/pm/~pm-session-active ]; then
  echo "exists=true"
  # Show marker contents so Claude can report the stale session
  cat docs/pm/~pm-session-active
else
  echo "exists=false"
fi
