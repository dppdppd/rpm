#!/bin/bash
# SessionStart hook: auto-inject rpm context.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
PM_DIR="$PROJECT_DIR/docs/rpm"
MARKER="$PM_DIR/~rpm-session-active"
FUTURE="$PM_DIR/future/FUTURE.org"
PRESENT="$PM_DIR/present/PRESENT.md"

# --- Not initialized ---
if [ ! -d "$PM_DIR" ]; then
  echo "This project has no docs/rpm/ directory."
  echo ""
  echo "If the user's first message invokes /bootstrap, proceed with"
  echo "bootstrap directly — do NOT print the line below."
  echo "Otherwise, begin your first response with exactly this line:"
  echo "  rpm: not initialized — run /bootstrap to set up"
  exit 0
fi

# --- Stale session ---
if [ -f "$MARKER" ]; then
  echo "rpm: stale session detected"
  echo ""
  cat "$MARKER"
  echo ""
  echo "IMPORTANT: Begin your first response with exactly this line (no markdown, no extras):"
  echo "  rpm: stale session — run /session-end or ask to continue"
  echo "Then briefly explain the stale state and ask the user how to handle it."
  exit 0
fi

# --- git ---
echo "=== git ==="
if git -C "$PROJECT_DIR" rev-parse --git-dir > /dev/null 2>&1; then
  PORCELAIN=$(git -C "$PROJECT_DIR" status --porcelain 2>/dev/null || true)
  MODIFIED=$(echo "$PORCELAIN" | grep -cE '^.M|^M ' || true)
  UNTRACKED=$(echo "$PORCELAIN" | grep -cE '^\?\?' || true)
  STAGED=$(echo "$PORCELAIN" | grep -cE '^M |^A |^D ' || true)
  STASHES=$(git -C "$PROJECT_DIR" stash list 2>/dev/null | wc -l | tr -d ' ')
  echo "modified=$MODIFIED untracked=$UNTRACKED staged=$STAGED stashes=$STASHES"
else
  echo "not a git repo"
fi

# --- drift ---
if [ -f "$PRESENT" ] && git -C "$PROJECT_DIR" rev-parse --git-dir > /dev/null 2>&1; then
  LAST=$(git -C "$PROJECT_DIR" log -1 --format=%H -- "$PRESENT" 2>/dev/null)
  if [ -n "$LAST" ]; then
    DRIFT=$(git -C "$PROJECT_DIR" log --oneline "${LAST}..HEAD" 2>/dev/null | wc -l | tr -d ' ')
    [ "$DRIFT" -gt 0 ] && echo "drift: $DRIFT commits since PRESENT.md updated"
  fi
fi

# --- ready_tasks ---
if [ -f "$FUTURE" ]; then
  san() { echo "$1" | tr '-' '_'; }
  CUR_STATUS="" CUR_ID="" CUR_BLOCKED="" CUR_HEADING=""
  ALL_IDS="" READY=""

  while IFS= read -r line; do
    if echo "$line" | grep -qE '^\*\* (TODO|IN-PROGRESS|BLOCKED|DONE) '; then
      if [ -n "$CUR_ID" ] && [ -n "$CUR_BLOCKED" ]; then
        if [ "$CUR_STATUS" = "TODO" ] || [ "$CUR_STATUS" = "BLOCKED" ]; then
          ALL_BLOCKERS_DONE=true
          for dep in $CUR_BLOCKED; do
            eval "dep_status=\${STATUS_$(san "$dep"):-UNKNOWN}"
            [ "$dep_status" != "DONE" ] && ALL_BLOCKERS_DONE=false
          done
          $ALL_BLOCKERS_DONE && READY="$READY  - $CUR_HEADING"$'\n'
        fi
      fi
      CUR_STATUS=$(echo "$line" | sed -E 's/^\*\* (TODO|IN-PROGRESS|BLOCKED|DONE) .*/\1/')
      CUR_HEADING=$(echo "$line" | sed -E 's/^\*\* (TODO|IN-PROGRESS|BLOCKED|DONE) //')
      CUR_ID="" CUR_BLOCKED=""
    fi
    if echo "$line" | grep -qE '^\s+:ID:\s'; then
      CUR_ID=$(echo "$line" | sed -E 's/^\s+:ID:\s+//' | tr -d ' ')
      ALL_IDS="$ALL_IDS $CUR_ID"
      eval "STATUS_$(san "$CUR_ID")=$CUR_STATUS"
    fi
    if echo "$line" | grep -qE '^\s+:BLOCKED_BY:\s'; then
      CUR_BLOCKED=$(echo "$line" | sed -E 's/^\s+:BLOCKED_BY:\s+//')
    fi
  done < "$FUTURE"
  # Flush last
  if [ -n "$CUR_ID" ] && [ -n "$CUR_BLOCKED" ]; then
    if [ "$CUR_STATUS" = "TODO" ] || [ "$CUR_STATUS" = "BLOCKED" ]; then
      ALL_BLOCKERS_DONE=true
      for dep in $CUR_BLOCKED; do
        eval "dep_status=\${STATUS_$(san "$dep"):-UNKNOWN}"
        [ "$dep_status" != "DONE" ] && ALL_BLOCKERS_DONE=false
      done
      $ALL_BLOCKERS_DONE && READY="$READY  - $CUR_HEADING"$'\n'
    fi
  fi
  [ -n "$READY" ] && echo "" && echo "=== ready_tasks ===" && echo "$READY"
fi

# --- present ---
echo ""
echo "=== present ==="
if [ -f "$PRESENT" ]; then
  head -10 "$PRESENT"
else
  echo "(missing)"
fi

# --- future ---
echo ""
echo "=== future ==="
if [ -f "$FUTURE" ]; then
  grep -E '^\*\* (TODO|IN-PROGRESS|BLOCKED) ' "$FUTURE" 2>/dev/null || echo "(none)"
else
  echo "(missing)"
fi

# --- daily_log ---
echo ""
LATEST=$(ls -1 "$PM_DIR/past/"*.md 2>/dev/null | sort -r | head -1)
if [ -n "$LATEST" ]; then
  echo "=== daily_log: $(basename "$LATEST") ==="
  head -20 "$LATEST"
else
  echo "=== daily_log: none ==="
fi

# --- Instructions for Claude ---
echo ""
echo "=== instructions ==="
echo "IMPORTANT: Begin your first response with exactly this line (no markdown, no extras):"
echo "  rpm: session active"
echo ""
echo "Then:"
echo "1. Note leftover state (uncommitted work, drift) — ask the developer how to handle it."
echo "2. Propose a task from FUTURE.org (prefer unblocked TODOs, especially ready ones above)."
echo "3. On confirmation, write the session marker:"
echo "   cat > docs/rpm/~rpm-session-active << MARKER"
echo "   ---"
echo "   session_id: \${CLAUDE_CODE_SESSION_ID:-unknown}"
echo "   started: \$(date -Iseconds)"
echo "   task: {chosen task}"
echo "   ---"
echo "   MARKER"
echo "4. Create a native task via TaskCreate."
echo "5. Begin working."
echo ""
echo "When you discover a root cause or change approach, lead with \"Key finding:\" so learnings are captured automatically."
echo ""
echo "Context: docs/rpm/present/PRESENT.md, docs/rpm/future/FUTURE.org, CLAUDE.md"
echo "Wrap up: /session-end"
