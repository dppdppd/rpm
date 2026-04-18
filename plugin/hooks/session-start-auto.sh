#!/bin/bash
# SessionStart hook: auto-inject rpm context.

# shellcheck source=./_directives.sh
source "$(dirname "${BASH_SOURCE[0]}")/_directives.sh"

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

# rpm plugin version — appended to session headers for visibility
PLUGIN_MANIFEST="${CLAUDE_PLUGIN_ROOT:-$(dirname "${BASH_SOURCE[0]}")/..}/.claude-plugin/plugin.json"
RPM_VERSION=$(jq -r '.version // empty' "$PLUGIN_MANIFEST" 2>/dev/null)
[ -z "$RPM_VERSION" ] && RPM_VERSION=$(sed -n 's/.*"version" *: *"\([^"]*\)".*/\1/p' "$PLUGIN_MANIFEST" 2>/dev/null | head -1)
VTAG=""
[ -n "$RPM_VERSION" ] && VTAG=" (rpm $RPM_VERSION)"

# Let PostCompact handle compaction
[ "$SOURCE" = "compact" ] && exit 0

# --- Not initialized — emit a stderr hint and exit ---
# Don't inject into model context (would assume the user wants rpm here),
# but the plugin IS installed, so surface /bootstrap for discoverability.
# Stderr goes to the user's terminal only.
if [ ! -d "$PM_DIR" ]; then
  VMSG=""
  [ -n "$RPM_VERSION" ] && VMSG=" v$RPM_VERSION"
  echo "rpm${VMSG} installed — run /bootstrap to enable rpm tracking for this project" >&2
  exit 0
fi

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

# Stale marker: emit a soft note, clear the marker, and fall through to
# the normal startup flow (including the task menu). The user can pick
# up where they left off or move on — nothing is forced.
if [ -f "$MARKER" ] && [ "$STALE" = "1" ]; then
  echo "rpm: previous session didn't wrap up${VTAG}"
  echo "(task: ${TASK:-unknown}, started ${STARTED:-unknown})"
  echo "(to resume and close it out: /resume ${SESSION_ID:-<session id>} then /session-end — otherwise pick from the backlog below)"
  echo ""
  rm -f "$MARKER"
fi

# Active resume path: same CC process, marker still valid. Emit resume
# header + task-menu-style options and exit.
if [ -f "$MARKER" ]; then
  echo "rpm: resuming — ${TASK:-unknown task}${VTAG}"
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
  echo "Open your first response with exactly this line: rpm: resuming — ${TASK:-unknown task}${VTAG}"
  echo ""
  echo "An rpm session marker is present — unfinished work on this task."
  echo "Check git state and recent commits to orient, then end your response"
  echo "with ONE question offering these options:"
  echo "  A. Continue the in-flight task"
  echo "  B. Switch to something else (then present the task menu)"
  echo "  C. Wrap up with /session-end"
  echo ""
  emit_rpm_directives
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

  # Single-pass parse → collect tasks into MENU_ITEMS + build an
  # ID→status map; filter BLOCKED_BY on emit so forward refs work.
  # Uses bash builtins ([[ =~ ]], parameter expansion) — no per-line
  # echo|grep|sed subshells.
  CUR_PARENT="" CUR_TASK_PARENT="" CUR_S="" CUR_H="" CUR_B="" CUR_D=""
  MENU_ITEMS=""

  flush_item() {
    [ -z "$CUR_H" ] && return
    # DONE and CANCELLED are both terminal — hide from the actionable menu
    [ "$CUR_S" = "DONE" ] && return
    [ "$CUR_S" = "CANCELLED" ] && return
    MENU_ITEMS="${MENU_ITEMS}${CUR_TASK_PARENT}|${CUR_H}|${CUR_D}|${CUR_S}|${CUR_B}"$'\n'
  }

  while IFS= read -r line; do
    if [[ "$line" == "* "* && "$line" != "** "* ]]; then
      p="${line#\* }"
      case "$p" in
        "TODO "*|"DONE "*|"IN-PROGRESS "*|"BLOCKED "*|"CANCELLED "*) p="${p#* }" ;;
      esac
      CUR_PARENT="$p"
    elif [[ "$line" =~ ^\*\*\ (TODO|IN-PROGRESS|BLOCKED|DONE|CANCELLED)\ (.+)$ ]]; then
      flush_item
      CUR_S="${BASH_REMATCH[1]}"
      CUR_H="${BASH_REMATCH[2]}"
      CUR_TASK_PARENT="$CUR_PARENT"
      CUR_B="" CUR_D=""
    elif [[ "$line" =~ ^[[:space:]]+:ID:[[:space:]]+([^[:space:]]+) ]]; then
      safe="${BASH_REMATCH[1]//-/_}"
      eval "STATUS_${safe}=\$CUR_S"
    elif [[ "$line" =~ ^[[:space:]]+:BLOCKED_BY:[[:space:]]+(.+) ]]; then
      CUR_B="${BASH_REMATCH[1]}"
      # rtrim (drawers sometimes have trailing whitespace)
      [[ "$CUR_B" =~ ^(.*[^[:space:]])[[:space:]]*$ ]] && CUR_B="${BASH_REMATCH[1]}"
    fi
    # Detail file from any line with [[file:X]] — first wins
    if [ -z "$CUR_D" ] && [[ "$line" =~ \[\[file:([^]]+)\]\] ]]; then
      CUR_D="${BASH_REMATCH[1]}"
    fi
  done < "$FUTURE"
  flush_item

  # Emit menu: filter BLOCKED_BY, clean labels, number by parent.
  NUM=0 LAST_PARENT=""
  while IFS='|' read -r raw_parent raw_heading detail status blocked; do
    [ -z "$raw_heading" ] && continue

    show=0
    case "$status" in
      IN-PROGRESS) show=1 ;;
      TODO|BLOCKED)
        if [ -z "$blocked" ]; then
          [ "$status" = "TODO" ] && show=1
        else
          show=1
          ds=""
          for dep in $blocked; do
            safe="${dep//-/_}"
            eval "ds=\${STATUS_${safe}:-UNKNOWN}"
            # A CANCELLED dep is still terminal — treat as unblocked
            case "$ds" in DONE|CANCELLED) ;; *) show=0; break ;; esac
          done
        fi
        ;;
    esac
    [ "$show" = "1" ] || continue

    label="$raw_heading"
    # Strip every [[file:...]] link from the label
    while [[ "$label" == *"[[file:"*"]]"* ]]; do
      pre="${label%%\[\[file:*}"
      rest="${label#*\[\[file:}"
      post="${rest#*\]\]}"
      label="${pre}${post}"
    done
    # Drop trailing org-mode :tag1:tag2: clusters
    [[ "$label" =~ ^(.*)[[:space:]]+:[a-zA-Z0-9_:-]+:[[:space:]]*$ ]] && label="${BASH_REMATCH[1]}"
    # Trim + collapse internal whitespace
    [[ "$label" =~ ^[[:space:]]*(.*[^[:space:]])[[:space:]]*$ ]] && label="${BASH_REMATCH[1]}"
    while [[ "$label" == *"  "* ]]; do label="${label//  / }"; done

    parent="$raw_parent"
    [[ "$parent" =~ ^(.*)[[:space:]]+:[a-zA-Z0-9_:-]+:[[:space:]]*$ ]] && parent="${BASH_REMATCH[1]}"
    [[ "$parent" =~ ^[[:space:]]*(.*[^[:space:]])[[:space:]]*$ ]] && parent="${BASH_REMATCH[1]}"

    # Fallback: detail file embedded in the heading if no body line set it
    if [ -z "$detail" ] && [[ "$raw_heading" =~ \[\[file:([^]]+)\]\] ]]; then
      detail="${BASH_REMATCH[1]}"
    fi

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
  echo "(no rpm backlog found)"
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

# --- Instructions for Claude ---
echo ""
echo "=== instructions ==="
echo "Open your first response with exactly this line: rpm: session active${VTAG}"
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
echo "   any of these to your rpm backlog, or would you rather describe your own?\""
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
echo "   - R  → show ALL tasks from your rpm backlog (including DONE/BLOCKED) with statuses,"
echo "          then re-present the actionable menu"
echo "4. On task selection, update the marker task field:"
echo "   Edit docs/rpm/~rpm-session-start — change 'task: (unassigned)'"
echo "   to 'task: <chosen task>'. Preserve session_id and started: fields"
echo "   (the hook already set them)."
echo "5. Create a native task via TaskCreate."
echo "6. Begin working."
fi
echo ""
echo "Task management: /tasks (add, list, review, postpone, done) for mid-session backlog operations."
echo "Native tasks (TaskCreate / TaskList) = this session's active work only. Your rpm backlog (tasks.org) = long-term. Don't mirror backlog adds into the native task list."
echo ""
emit_rpm_directives
echo ""
echo "Context: docs/rpm/context.md, docs/rpm/present/status.md, docs/rpm/future/tasks.org, CLAUDE.md"
echo "Wrap up: /session-end | All commands: /rpm ?"
