#!/bin/bash
# Stop hook: capture learnings to docs/rpm/~rpm-learnings.jsonl.
# Also backfills task: (unassigned) in the session-start marker when the
# session actually did work (edits or commits since started:), so the
# placeholder doesn't propagate into the next session's resume nudge.

# Read payload from stdin
PAYLOAD=$(cat)
MSG=$(echo "$PAYLOAD" | jq -r '.last_assistant_message // empty' 2>/dev/null)
SESSION=$(echo "$PAYLOAD" | jq -r '.session_id // "unknown"' 2>/dev/null)

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-}"
[ -z "$PROJECT_DIR" ] && PROJECT_DIR=$(echo "$PAYLOAD" | jq -r '.cwd // empty' 2>/dev/null)
[ -z "$PROJECT_DIR" ] && PROJECT_DIR="."
PM_DIR="$PROJECT_DIR/docs/rpm"
LEARNINGS="$PM_DIR/~rpm-learnings.jsonl"
MARKER="$PM_DIR/~rpm-session-start"

# Only capture during active rpm sessions
[ -d "$PM_DIR" ] || exit 0
[ -f "$MARKER" ] || exit 0

# --- Backfill task: (unassigned) when the session has done real work ---
# Title derivation is heuristic — last commit subject may not reflect the
# session's actual work, but it's better than the placeholder propagating.
# Skip silently when grep/sed fail; this is best-effort.
backfill_unassigned_marker() {
  local marker="$1" project="$2"
  grep -q '^task: (unassigned)$' "$marker" 2>/dev/null || return 0

  # Confirm there's real work to attribute a title to.
  # Strip rpm session-state files (~rpm-*) — they're metadata, not work,
  # and may show up here when the project hasn't gitignored docs/rpm/~*.
  # --untracked-files=all forces file-level (not dir-level) entries so the
  # filter can match the actual paths.
  local porcelain
  porcelain=$(git -C "$project" status --porcelain --untracked-files=all 2>/dev/null \
    | grep -vE 'docs/rpm/~rpm-' || true)

  local started commits_since=""
  started=$(grep -oP '^started: \K.*' "$marker" 2>/dev/null | head -1)
  if [ -n "$started" ] && git -C "$project" rev-parse --git-dir >/dev/null 2>&1; then
    commits_since=$(git -C "$project" log --since="$started" --format=%H 2>/dev/null | head -1)
  fi

  # No work, no backfill — don't speculate.
  [ -z "$porcelain" ] && [ -z "$commits_since" ] && return 0

  local derived=""
  if [ -n "$commits_since" ]; then
    # Most recent commit subject; strip common conventional-commit prefixes.
    derived=$(git -C "$project" log -1 --format=%s 2>/dev/null \
      | sed -E 's/^(release|chore|wip|fix|feat|docs|refactor|test|build|ci|perf|style|revert)(\([^)]*\))?:[[:space:]]*//I')
  fi

  if [ -z "$derived" ] && [ -n "$porcelain" ]; then
    # No commit since started: → describe edits by basename.
    local files
    files=$(echo "$porcelain" | awk '{print $NF}' | xargs -n1 basename 2>/dev/null \
      | head -3 | paste -sd', ' -)
    [ -n "$files" ] && derived="edits in: $files"
  fi

  [ -z "$derived" ] && return 0
  # Cap to ≤80 chars to keep marker readable.
  derived=$(printf '%s' "$derived" | head -c 80)

  # In-place rewrite. Escape sed metachars (& / \) in derived, plus any
  # whitespace newlines collapsed already by head -c above.
  local escaped
  escaped=$(printf '%s' "$derived" | sed -e 's/[\/&]/\\&/g')
  sed -i "s/^task: (unassigned)$/task: $escaped/" "$marker" 2>/dev/null || return 0
}

backfill_unassigned_marker "$MARKER" "$PROJECT_DIR"

# Skip empty or short responses (< 200 chars unlikely to contain learnings)
[ ${#MSG} -lt 200 ] && exit 0

# Check for learning signals (case-insensitive)
SIGNALS="key finding:|root cause|the issue was|turns out|discovered that|the problem was|the fix |should have|mistake was|wrong approach|key discovery|key learning|what didn.t work|correction:|finding:|the real issue|actually caused by|lesson learned"

MATCH=$(echo "$MSG" | grep -ioP ".{0,80}($SIGNALS).{0,80}" | head -3)
[ -z "$MATCH" ] && exit 0

# Build a compact excerpt: the matched context lines
EXCERPT=$(echo "$MATCH" | tr '\n' ' | ' | head -c 500)
TS=$(date -Iseconds)

# Append as JSONL
printf '{"ts":"%s","session":"%s","excerpt":"%s"}\n' \
  "$TS" "$SESSION" "$(echo "$EXCERPT" | sed 's/"/\\"/g' | tr -d '\n')" \
  >> "$LEARNINGS"
