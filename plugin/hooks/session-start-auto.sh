#!/bin/bash
# SessionStart hook: auto-inject rpm context.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
PM_DIR="$PROJECT_DIR/docs/rpm"
MARKER="$PM_DIR/~rpm-session-start"
HANDOFF="$PM_DIR/~rpm-session-end"
CONTEXT="$PM_DIR/context.md"
FUTURE="$PM_DIR/future/tasks.org"
PRESENT="$PM_DIR/present/status.md"
LAST_SESSION="$PM_DIR/~rpm-last-session"

# Read source + session_id from stdin (startup, clear, resume, compact)
PAYLOAD=$(cat)
SOURCE=$(echo "$PAYLOAD" | jq -r '.source // empty' 2>/dev/null)
[ -z "$SOURCE" ] && SOURCE=$(echo "$PAYLOAD" | sed -n 's/.*"source" *: *"\([^"]*\)".*/\1/p')
[ -z "$SOURCE" ] && SOURCE="startup"
HOOK_SESSION_ID=$(echo "$PAYLOAD" | jq -r '.session_id // empty' 2>/dev/null)
[ -z "$HOOK_SESSION_ID" ] && HOOK_SESSION_ID=$(echo "$PAYLOAD" | sed -n 's/.*"session_id" *: *"\([^"]*\)".*/\1/p')
[ -z "$HOOK_SESSION_ID" ] && HOOK_SESSION_ID="${CLAUDE_CODE_SESSION_ID:-unknown}"

# Let PostCompact handle compaction
[ "$SOURCE" = "compact" ] && exit 0

# --- Not initialized — exit silently ---
# If the user hasn't bootstrapped, don't assume they want rpm here.
[ ! -d "$PM_DIR" ] && exit 0

# --- Active marker present — resume, wrap up stale session, or drop orphan ---
# Covers clear, resume, and fresh startup where the user exited without /session-end.
if [ -f "$MARKER" ]; then
  TASK=$(grep -oP 'task: \K.*' "$MARKER" 2>/dev/null | head -1)
  STARTED=$(grep -oP 'started: \K.*' "$MARKER" 2>/dev/null | head -1)
  SESSION_ID=$(grep -oP 'session_id: \K.*' "$MARKER" 2>/dev/null | head -1)

  # Different CC process? session_id mismatch handles --continue, --resume
  # across CC processes, and fresh startup alike; /clear and /resume
  # within the same CC process preserve session_id, so they stay on the
  # resume path.
  DIFFERENT_SESSION=0
  if [ -n "$HOOK_SESSION_ID" ] && [ "$HOOK_SESSION_ID" != "unknown" ] \
     && [ -n "$SESSION_ID" ] && [ "$HOOK_SESSION_ID" != "$SESSION_ID" ]; then
    DIFFERENT_SESSION=1
  fi

  # Pair detection: every session should have a matching pair of markers —
  # a "start" marker (~rpm-session-start, written by this hook on startup)
  # and an "end" marker (~rpm-session-end, written by /session-end). If they
  # pair on session_id, the session wrapped up cleanly and any marker left
  # behind (e.g. a /clear after /session-end proactively rewrote one) is
  # an orphan — silently reset and fall through. If no pair, the previous
  # session didn't wrap up — warn.
  STALE=0
  if [ "$DIFFERENT_SESSION" = "1" ]; then
    HANDOFF_SID=""
    [ -f "$HANDOFF" ] && HANDOFF_SID=$(grep -oP 'session_id: \K.*' "$HANDOFF" 2>/dev/null | head -1)
    if [ -n "$HANDOFF_SID" ] && [ "$HANDOFF_SID" != "unknown" ] \
       && [ -n "$SESSION_ID" ] && [ "$HANDOFF_SID" = "$SESSION_ID" ]; then
      # Paired: start and end markers from the same session_id.
      rm -f "$MARKER" "$HANDOFF"
    else
      STALE=1
    fi
  fi
fi

# Drop an orphan end marker if no start marker paired with it (e.g. a
# clean /session-end followed directly by /exit and a new CC process).
# Keep the end marker if it matches the current CC session (we're
# inside the /session-end→/clear transition in the same process, and
# the proactive block below will rewrite a start marker to pair).
if [ -f "$HANDOFF" ] && [ ! -f "$MARKER" ]; then
  H_SID=$(grep -oP 'session_id: \K.*' "$HANDOFF" 2>/dev/null | head -1)
  if [ -z "$H_SID" ] || [ "$H_SID" = "unknown" ] \
     || [ -z "$HOOK_SESSION_ID" ] || [ "$HOOK_SESSION_ID" = "unknown" ] \
     || [ "$H_SID" != "$HOOK_SESSION_ID" ]; then
    rm -f "$HANDOFF"
  fi
fi

# If the marker block above consumed the marker (resume / stale), emit
# the appropriate header + instructions and exit. Otherwise fall through
# to proactive creation + the normal startup flow.
if [ -f "$MARKER" ]; then
  if [ "$STALE" = "1" ]; then
    echo "rpm: previous session wasn't ended with /session-end"
    echo "(last active task: ${TASK:-unknown}, started $STARTED)"
    echo "(session_id: ${SESSION_ID:-unknown})"
  else
    echo "rpm: resuming — ${TASK:-unknown task}"
    [ -n "$STARTED" ] && echo "(session started $STARTED)"
  fi
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
  if [ "$STALE" = "1" ]; then
    echo "IMPORTANT: Begin your first response with exactly this line (no markdown, no extras):"
    echo "  rpm: your previous session wasn't ended with /session-end"
    echo ""
    echo "Then emit this verbatim:"
    echo ""
    echo "  You can /resume ${SESSION_ID:-<session id>} and run /session-end to"
    echo "  close it out, or I can clear the marker and we'll move on."
    echo ""
    echo "Stop after emitting. Do NOT present the task menu. Wait for the user."
    echo "If they ask to clear:"
    echo "  rm docs/rpm/~rpm-session-start"
    echo "then write a fresh marker for the current session:"
    echo "  cat > docs/rpm/~rpm-session-start <<MARKER"
    echo "  ---"
    echo "  session_id: $HOOK_SESSION_ID"
    echo "  started: \$(date -Iseconds)"
    echo "  task: (unassigned)"
    echo "  ---"
    echo "  MARKER"
    echo "Then wait silently for the user's next instruction — do not offer"
    echo "the task menu or suggest what to do next."
  else
    echo "IMPORTANT: Begin your first response with exactly this line (no markdown, no extras):"
    echo "  rpm: resuming — ${TASK:-unknown task}"
    echo ""
    echo "An rpm session marker is present — unfinished work on this task."
    echo "Check git state and recent commits to orient, then end your response"
    echo "with ONE question offering these options:"
    echo "  A. Continue the in-flight task"
    echo "  B. Wrap it up with /session-end"
    echo "  C. Switch to something else (then present the task menu)"
  fi
  echo "rpm: don't forget to set /effort" >&2
  exit 0
fi

# --- Proactively write an "unassigned" marker ---
# Guarantees that any work done this session (even if the user skips the menu
# and starts typing) is visible to the next session's stale-detection.
# Claude updates the task: field when the user picks from the menu.
cat > "$MARKER" <<MARKER_EOF
---
session_id: $HOOK_SESSION_ID
started: $(date -Iseconds)
task: (unassigned)
---
MARKER_EOF

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
  # Check for last session task
  LAST_TASK="" LAST_NEXT=""
  if [ -f "$LAST_SESSION" ]; then
    LAST_TASK=$(grep -oP 'task: \K.*' "$LAST_SESSION" 2>/dev/null | head -1)
    LAST_NEXT=$(grep -oP 'next: \K.*' "$LAST_SESSION" 2>/dev/null | head -1)
  fi
  echo "Your task backlog:"
  echo ""

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
    BACKLOG_EMPTY=1
    echo "(no actionable tasks)"
  else
    BACKLOG_EMPTY=0
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
  fi
else
  BACKLOG_EMPTY=1
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
if [ "$BACKLOG_EMPTY" = "1" ] && [ -z "$LAST_NEXT" ]; then
echo "Then the backlog has no actionable tasks. Do NOT present a menu or"
echo "ask the user to pick. Instead:"
echo "1. Read docs/rpm/future/tasks.org in full. Review every TODO/BLOCKED/"
echo "   DONE entry and decide honestly whether any could be made actionable"
echo "   now (e.g. BLOCKED tasks whose :BLOCKED_BY: dep is already complete,"
echo "   IN-PROGRESS items that are actually finished, TODOs that were"
echo "   filtered because a parent heading is ambiguous)."
echo "2. If one or more ARE actually actionable, say so as a statement,"
echo "   then end your response with a single question asking whether to"
echo "   start on the one you think is most promising — do not print the"
echo "   full menu; just name the task."
echo "3. If truly none are actionable, say so briefly, then look at"
echo "   docs/rpm/context.md, docs/rpm/present/status.md, and any daily log"
echo "   above to infer plausible next work. Draft 2–4 candidate task"
echo "   titles and end your response with ONE question: \"Want me to add"
echo "   any of these to tasks.org, or would you rather describe your own?\""
echo "4. On task selection (from review or brainstorm), update the marker:"
echo "   Edit docs/rpm/~rpm-session-start — change 'task: (unassigned)'"
echo "   to 'task: <chosen task>'. Preserve session_id and started: fields."
echo "   Then create a native task via TaskCreate and begin working."
elif [ -n "$LAST_NEXT" ]; then
echo "Then:"
echo "1. Tell the user what was next from the last session as a statement"
echo "   (not a question): \"$LAST_NEXT\""
echo "2. End your response by asking — and ONLY at the end — whether to"
echo "   continue with that or pick something else."
echo "   - If yes → proceed to step 3"
echo "   - If no → present the task menu (title through prompt line, verbatim)"
echo "     and handle their selection"
echo "3. On task selection, update the marker task field:"
echo "   Edit docs/rpm/~rpm-session-start — change 'task: (unassigned)'"
echo "   to 'task: <chosen task>'. Preserve session_id and started: fields"
echo "   (the hook already set them)."
echo "4. Create a native task via TaskCreate."
echo "5. Begin working."
else
echo "Then:"
echo "1. If there's leftover state (uncommitted work, drift), note it briefly"
echo "   as a statement — do NOT ask a question about it here."
echo "   You'll handle it after the user picks a task."
echo "2. Present the task menu in a code block (triple backticks) to preserve formatting."
echo "   Include everything from the \"Your task backlog:\" title through the prompt line, verbatim."
echo "   The final \"Pick #...\" line is the ONLY question in your response — ask nothing else."
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
echo "4. On task selection, update the marker task field:"
echo "   Edit docs/rpm/~rpm-session-start — change 'task: (unassigned)'"
echo "   to 'task: <chosen task>'. Preserve session_id and started: fields"
echo "   (the hook already set them)."
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
