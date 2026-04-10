#!/bin/bash
# SessionStart hook: auto-inject PM context so /rpm:session-start
# is no longer required. Outputs scan results + key file summaries
# + instructions for Claude to pick up the PM workflow automatically.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
PM_DIR="$PROJECT_DIR/docs/rpm"
MARKER="$PM_DIR/~rpm-session-active"
FUTURE="$PM_DIR/future/FUTURE.org"
PRESENT="$PM_DIR/present/PRESENT.md"

# Only activate if pm is initialized
if [ ! -d "$PM_DIR" ]; then
  echo "This project has no docs/rpm/ directory."
  echo ""
  echo "IMPORTANT: Begin your first response with exactly this line (no markdown, no extras):"
  echo "  rpm: not initialized — run /rpm:bootstrap to set up"
  echo "This confirms to the user that the PM plugin loaded but found no PM infrastructure."
  exit 0
fi

# --- Stale session check ---
if [ -f "$MARKER" ]; then
  echo "Previous session did not run /rpm:session-end."
  echo "Session state from unclean exit:"
  echo ""
  cat "$MARKER"
  echo ""
  echo "IMPORTANT: Begin your first response with exactly this line (no markdown, no extras):"
  echo "  rpm: stale session — run /rpm:session-end or ask to continue"
  echo "Then explain the stale session state and ask the user how to handle it."
  exit 0
fi

# --- Scan: git state ---
echo "=== pm:auto-start ==="
echo ""
if git -C "$PROJECT_DIR" rev-parse --git-dir > /dev/null 2>&1; then
  PORCELAIN=$(git -C "$PROJECT_DIR" status --porcelain 2>/dev/null || true)
  MODIFIED=$(echo "$PORCELAIN" | grep -cE '^.M|^M ' || true)
  UNTRACKED=$(echo "$PORCELAIN" | grep -cE '^\?\?' || true)
  STAGED=$(echo "$PORCELAIN" | grep -cE '^M |^A |^D ' || true)
  STASHES=$(git -C "$PROJECT_DIR" stash list 2>/dev/null | wc -l | tr -d ' ')
  echo "git: modified=$MODIFIED untracked=$UNTRACKED staged=$STAGED stashes=$STASHES"
else
  echo "git: not a git repo"
fi

# --- Scan: PRESENT.md drift ---
if [ -f "$PRESENT" ] && git -C "$PROJECT_DIR" rev-parse --git-dir > /dev/null 2>&1; then
  LAST=$(git -C "$PROJECT_DIR" log -1 --format=%H -- "$PRESENT" 2>/dev/null)
  if [ -n "$LAST" ]; then
    DRIFT=$(git -C "$PROJECT_DIR" log --oneline "${LAST}..HEAD" 2>/dev/null | wc -l | tr -d ' ')
    [ "$DRIFT" -gt 0 ] && echo "drift: $DRIFT commits since PRESENT.md last updated"
  fi
fi

# --- Scan: task deps (ready tasks) ---
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
  [ -n "$READY" ] && echo "" && echo "Ready tasks (blockers resolved):" && echo "$READY"
fi

# --- PRESENT.md summary (first 10 lines) ---
echo ""
echo "=== PRESENT.md (summary) ==="
if [ -f "$PRESENT" ]; then
  head -10 "$PRESENT"
else
  echo "(missing)"
fi

# --- FUTURE.org open items ---
echo ""
echo "=== FUTURE.org (open items) ==="
if [ -f "$FUTURE" ]; then
  grep -E '^\*\* (TODO|IN-PROGRESS|BLOCKED) ' "$FUTURE" 2>/dev/null || echo "(none)"
else
  echo "(missing)"
fi

# --- Latest daily log ---
echo ""
LATEST=$(ls -1 "$PM_DIR/past/"*.md 2>/dev/null | sort -r | head -1)
if [ -n "$LATEST" ]; then
  echo "=== Latest daily log: $(basename "$LATEST") ==="
  head -20 "$LATEST"
else
  echo "=== Latest daily log: none ==="
fi

# --- Instructions for Claude ---
echo ""
echo "=== PM session instructions ==="
echo "IMPORTANT: Begin your first response with exactly this line (no markdown, no extras):"
echo "  rpm: session active"
echo "This confirms to the user that the PM plugin loaded. Then continue normally."
echo ""
echo "You are this project's AI product manager. Context has been auto-loaded."
echo ""
echo "Your job:"
echo "1. Note any leftover state (uncommitted work, drift) and ask the developer how to handle it."
echo "2. Propose a task from FUTURE.org (prefer TODO items, especially 'ready' ones with resolved blockers)."
echo "3. Once the developer confirms (or if clean state + obvious task), write the session marker:"
echo "   cat > docs/rpm/~rpm-session-active << MARKER"
echo "   ---"
echo "   session_id: \${CLAUDE_CODE_SESSION_ID:-unknown}"
echo "   started: \$(date -Iseconds)"
echo "   task: {chosen task}"
echo "   ---"
echo "   MARKER"
echo "4. Create a native task via TaskCreate for the picked item."
echo "5. Then begin working. You track progress, capture learnings, and flag drift — the developer builds."
echo ""
echo "For full context, read: docs/rpm/present/PRESENT.md, docs/rpm/future/FUTURE.org, CLAUDE.md"
echo "To end the session: /rpm:session-end"
