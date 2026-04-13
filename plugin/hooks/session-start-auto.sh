#!/bin/bash
# SessionStart hook: auto-inject rpm context.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
PM_DIR="$PROJECT_DIR/docs/rpm"
MARKER="$PM_DIR/~rpm-session-active"
CONTEXT="$PM_DIR/context.md"
FUTURE="$PM_DIR/future/tasks.org"
PRESENT="$PM_DIR/present/status.md"
LAST_SESSION="$PM_DIR/~rpm-last-session"

# Read source from stdin (startup, clear, resume, compact)
PAYLOAD=$(cat)
SOURCE=$(echo "$PAYLOAD" | jq -r '.source // empty' 2>/dev/null)
[ -z "$SOURCE" ] && SOURCE=$(echo "$PAYLOAD" | sed -n 's/.*"source" *: *"\([^"]*\)".*/\1/p')
[ -z "$SOURCE" ] && SOURCE="startup"

# Let PostCompact handle compaction
[ "$SOURCE" = "compact" ] && exit 0

# --- Not initialized — exit silently ---
# If the user hasn't bootstrapped, don't assume they want rpm here.
[ ! -d "$PM_DIR" ] && exit 0

# --- Active marker present — resume the in-flight task ---
# Covers clear, resume, and fresh startup where the user exited without /session-end.
if [ -f "$MARKER" ]; then
  TASK=$(grep -oP 'task: \K.*' "$MARKER" 2>/dev/null | head -1)
  STARTED=$(grep -oP 'started: \K.*' "$MARKER" 2>/dev/null | head -1)
  echo "rpm: resuming — ${TASK:-unknown task}"
  [ -n "$STARTED" ] && echo "(session started $STARTED)"
  echo ""
  if git -C "$PROJECT_DIR" rev-parse --git-dir > /dev/null 2>&1; then
    PORCELAIN=$(git -C "$PROJECT_DIR" status --porcelain 2>/dev/null || true)
    MODIFIED=$(echo "$PORCELAIN" | grep -cE '^.M|^M ' || true)
    UNTRACKED=$(echo "$PORCELAIN" | grep -cE '^\?\?' || true)
    STAGED=$(echo "$PORCELAIN" | grep -cE '^M |^A |^D ' || true)
    echo "git: modified=$MODIFIED untracked=$UNTRACKED staged=$STAGED"
    echo ""
    echo "=== recent_commits ==="
    git -C "$PROJECT_DIR" log --oneline -5 2>/dev/null || echo "(none)"
  fi
  echo ""
  echo "=== instructions ==="
  echo "IMPORTANT: Begin your first response with exactly this line (no markdown, no extras):"
  echo "  rpm: resuming — ${TASK:-unknown task}"
  echo ""
  echo "An rpm session marker is present — the user has unfinished work on this task."
  echo "Check git state and recent commits to orient, then offer options:"
  echo "  A. Continue the in-flight task"
  echo "  B. Wrap it up with /session-end"
  echo "  C. Switch to something else (then present the task menu)"
  echo "Wait for the user's choice before acting."
  echo "rpm: don't forget to set /effort" >&2
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
  # Modified file names (up to 15)
  if [ "$MODIFIED" -gt 0 ] 2>/dev/null; then
    git -C "$PROJECT_DIR" diff --name-only 2>/dev/null | head -15 | while read -r f; do
      echo "  M $f"
    done
  fi
  # Recent commits
  echo ""
  echo "=== recent_commits ==="
  git -C "$PROJECT_DIR" log --oneline -10 2>/dev/null || echo "(none)"
else
  echo "not a git repo"
fi

# --- drift ---
if [ -f "$PRESENT" ] && git -C "$PROJECT_DIR" rev-parse --git-dir > /dev/null 2>&1; then
  LAST=$(git -C "$PROJECT_DIR" log -1 --format=%H -- "$PRESENT" 2>/dev/null)
  if [ -n "$LAST" ]; then
    DRIFT=$(git -C "$PROJECT_DIR" log --oneline "${LAST}..HEAD" 2>/dev/null | wc -l | tr -d ' ')
    [ "$DRIFT" -gt 0 ] && echo "drift: $DRIFT commits since status.md updated"
  fi
fi

# (ready_tasks logic moved into task_menu below)

# --- context ---
echo ""
echo "=== context ==="
if [ -f "$CONTEXT" ]; then
  cat "$CONTEXT"
else
  echo "(missing)"
fi

# --- present ---
echo ""
echo "=== present ==="
if [ -f "$PRESENT" ]; then
  head -10 "$PRESENT"
else
  echo "(missing)"
fi

# --- task_menu ---
echo ""
echo "=== task_menu ==="
if [ -f "$FUTURE" ]; then
  # Scoreboard
  DONE_N=$(grep -cE '^\*\* DONE ' "$FUTURE" 2>/dev/null || true)
  IP_N=$(grep -cE '^\*\* IN-PROGRESS ' "$FUTURE" 2>/dev/null || true)
  TODO_N=$(grep -cE '^\*\* TODO ' "$FUTURE" 2>/dev/null || true)
  BLOCKED_N=$(grep -cE '^\*\* BLOCKED ' "$FUTURE" 2>/dev/null || true)
  echo "scoreboard: $DONE_N done · $IP_N in-progress · $TODO_N todo · $BLOCKED_N blocked"
  echo ""
  # Check for last session task
  LAST_TASK="" LAST_NEXT=""
  if [ -f "$LAST_SESSION" ]; then
    LAST_TASK=$(grep -oP 'task: \K.*' "$LAST_SESSION" 2>/dev/null | head -1)
    LAST_NEXT=$(grep -oP 'next: \K.*' "$LAST_SESSION" 2>/dev/null | head -1)
  fi
  echo "What would you like to work on? Open tasks from your backlog:"

  # Pass 1: collect task IDs and statuses for dependency resolution
  san() { echo "$1" | tr '-' '_'; }
  _S=""
  while IFS= read -r line; do
    if echo "$line" | grep -qE '^\*\* (TODO|IN-PROGRESS|BLOCKED|DONE) '; then
      _S=$(echo "$line" | sed -E 's/^\*\* (TODO|IN-PROGRESS|BLOCKED|DONE) .*/\1/')
    fi
    if echo "$line" | grep -qE '^\s+:ID:\s'; then
      _I=$(echo "$line" | sed -E 's/^\s+:ID:\s+//' | tr -d ' ')
      eval "STATUS_$(san "$_I")=$_S"
    fi
  done < "$FUTURE"

  # Pass 2: collect menu items in document order with parent context
  MENU_ITEMS=""
  CUR_PARENT="" CUR_TASK_PARENT="" CUR_S="" CUR_H="" CUR_B="" CUR_D=""

  flush_item() {
    [ -z "$CUR_H" ] && return
    [ "$CUR_S" = "DONE" ] && return

    local show=false
    case "$CUR_S" in
      IN-PROGRESS) show=true ;;
      TODO|BLOCKED)
        if [ -z "$CUR_B" ]; then
          [ "$CUR_S" = "TODO" ] && show=true
        else
          show=true
          local ds=""
          for dep in $CUR_B; do
            eval "ds=\${STATUS_$(san "$dep"):-UNKNOWN}"
            [ "$ds" != "DONE" ] && { show=false; break; }
          done
        fi
        ;;
    esac
    $show || return

    # Use detail from heading or body, strip [[file:...]] and org tags from label
    local detail="$CUR_D"
    [ -z "$detail" ] && detail=$(echo "$CUR_H" | grep -oP '\[\[file:\K[^\]]+' | head -1)
    local label parent
    label=$(echo "$CUR_H" | sed -E 's/\[\[file:[^]]*\]\]//g; s/\s+:[a-zA-Z0-9_:-]+:\s*$//; s/^\s+|\s+$//g; s/\s+/ /g')
    parent=$(echo "$CUR_TASK_PARENT" | sed -E 's/\s+:[a-zA-Z0-9_:-]+:\s*$//; s/^\s+|\s+$//g; s/\s+/ /g')

    MENU_ITEMS="${MENU_ITEMS}${parent}|${label}|${detail}|${CUR_S}"$'\n'
  }

  while IFS= read -r line; do
    # Track * parent headings
    if echo "$line" | grep -qE '^\* '; then
      CUR_PARENT=$(echo "$line" | sed -E 's/^\* (DONE |TODO |IN-PROGRESS |BLOCKED )?//')
    fi
    if echo "$line" | grep -qE '^\*\* (TODO|IN-PROGRESS|BLOCKED|DONE) '; then
      flush_item
      CUR_S=$(echo "$line" | sed -E 's/^\*\* (TODO|IN-PROGRESS|BLOCKED|DONE) .*/\1/')
      CUR_H=$(echo "$line" | sed -E 's/^\*\* (TODO|IN-PROGRESS|BLOCKED|DONE) //')
      CUR_TASK_PARENT="$CUR_PARENT"
      CUR_B="" CUR_D=""
    fi
    # Capture detail file from body lines: [[file:...]] or - Detail: [[file:...]]
    if [ -z "$CUR_D" ]; then
      _d=$(echo "$line" | grep -oP '\[\[file:\K[^\]]+' 2>/dev/null | head -1)
      [ -n "$_d" ] && CUR_D="$_d"
    fi
    echo "$line" | grep -qE '^\s+:BLOCKED_BY:\s' && \
      CUR_B=$(echo "$line" | sed -E 's/^\s+:BLOCKED_BY:\s+//')
  done < "$FUTURE"
  flush_item

  # Output numbered menu grouped by parent
  NUM=0 LAST_PARENT=""
  while IFS='|' read -r parent label detail status; do
    [ -z "$label" ] && continue
    if [ "$parent" != "$LAST_PARENT" ]; then
      [ -n "$LAST_PARENT" ] && echo ""
      [ -n "$parent" ] && echo "$parent"
      LAST_PARENT="$parent"
    fi
    NUM=$((NUM + 1))
    tag=""
    [ "$status" = "IN-PROGRESS" ] && tag=" (in-progress)"
    echo "   ${NUM}. ${label}${tag}"
    [ -n "$detail" ] && echo "      detail: future/${detail}"
  done <<< "$MENU_ITEMS"

  if [ "$NUM" -eq 0 ]; then
    echo "(no actionable tasks)"
  fi

  echo ""
  echo "S: something else"
  echo "R: review tasks"
  if [ -n "$LAST_TASK" ]; then
    echo "C: continue working on ${LAST_TASK}"
  fi
  echo ""
  if [ -n "$LAST_TASK" ]; then
    echo "Pick #, #? for details, C, S, or R."
  else
    echo "Pick #, #? for details, S, or R."
  fi
else
  echo "(no tasks.org found)"
fi

# --- daily_log ---
echo ""
LATEST=$(find "$PM_DIR/past/" -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort -r | head -1)
if [ -n "$LATEST" ]; then
  echo "=== daily_log: $(basename "$LATEST") ==="
  head -20 "$LATEST"
else
  echo "=== daily_log: none ==="
fi

# --- learnings from last session ---
LEARNINGS="$PM_DIR/~rpm-learnings.jsonl"
if [ -f "$LEARNINGS" ]; then
  LCOUNT=$(wc -l < "$LEARNINGS" | tr -d ' ')
  if [ "$LCOUNT" -gt 0 ]; then
    echo ""
    echo "=== learnings ($LCOUNT captured) ==="
    tail -5 "$LEARNINGS" | jq -r '.excerpt // empty' 2>/dev/null | while read -r ex; do
      [ -n "$ex" ] && echo "  - $ex"
    done
  fi
fi

# --- Random tip (user-visible only, not model context) ---
TIPS_FILE="${CLAUDE_PLUGIN_ROOT}/hooks/tips.txt"
if [ -f "$TIPS_FILE" ]; then
  TIP=$(shuf -n 1 "$TIPS_FILE" 2>/dev/null)
  [ -n "$TIP" ] && echo "rpm tip: $TIP" >&2
fi

echo "rpm: don't forget to set /effort" >&2

# --- Instructions for Claude ---
echo ""
echo "=== instructions ==="
echo "IMPORTANT: Begin your first response with exactly this line (no markdown, no extras):"
echo "  rpm: session active"
echo ""
if [ -n "$LAST_NEXT" ]; then
echo "Then:"
echo "1. Tell the user what was next from the last session:"
echo "   \"$LAST_NEXT\""
echo "2. Ask if they want to continue with that or pick something else."
echo "   - If yes → proceed to step 3"
echo "   - If no → present the task menu (scoreboard through prompt line, verbatim)"
echo "     and handle their selection"
echo "3. On task selection, write the session marker:"
echo "   cat > docs/rpm/~rpm-session-active << MARKER"
echo "   ---"
echo "   session_id: \${CLAUDE_CODE_SESSION_ID:-unknown}"
echo "   started: \$(date -Iseconds)"
echo "   task: {chosen task}"
echo "   ---"
echo "   MARKER"
echo "4. Create a native task via TaskCreate."
echo "5. Begin working."
else
echo "Then:"
echo "1. Note leftover state (uncommitted work, drift) — ask the developer how to handle it."
echo "2. Present the task menu in a code block (triple backticks) to preserve formatting."
echo "   Include everything from the scoreboard through the prompt line, verbatim."
echo "3. Handle the user's response:"
echo "   - #  → select that task, proceed to step 4"
echo "   - #? → read the detail file (path shown under the task), summarize it,"
echo "          then re-present the menu"
if [ -n "$LAST_TASK" ]; then
echo "   - C  → continue working on last session's task, proceed to step 4"
fi
echo "   - S: <description> → use their custom task, proceed to step 4"
echo "   - R  → show ALL tasks from tasks.org (including DONE/BLOCKED) with statuses,"
echo "          then re-present the actionable menu"
echo "4. On task selection, write the session marker:"
echo "   cat > docs/rpm/~rpm-session-active << MARKER"
echo "   ---"
echo "   session_id: \${CLAUDE_CODE_SESSION_ID:-unknown}"
echo "   started: \$(date -Iseconds)"
echo "   task: {chosen task}"
echo "   ---"
echo "   MARKER"
echo "5. Create a native task via TaskCreate."
echo "6. Begin working."
fi
echo ""
echo "Task management: /tasks (add, list, review, done) for mid-session backlog operations."
echo ""
echo "When you discover a root cause or change approach, lead with \"Key finding:\" so learnings are captured automatically."
echo ""
echo "Context: docs/rpm/context.md, docs/rpm/present/status.md, docs/rpm/future/tasks.org, CLAUDE.md"
echo "Wrap up: /session-end | All commands: /rpm ?"
