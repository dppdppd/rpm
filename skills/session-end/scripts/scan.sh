#!/bin/bash
# Session-end mechanical scan. Deterministic drift + git state
# collection. Runs before the session-end skill body is sent to
# Claude via the `!${CLAUDE_SKILL_DIR}/scripts/scan.sh` injection,
# so its output is already in context when Claude starts Phase 1.
#
# Zero LLM tokens. The skill interprets the key=value output and
# only runs further LLM work on surfaced findings.
#
# Output: sections (=== name ===) with key=value lines.

set -u

ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$ROOT" 2>/dev/null || { echo "error=cannot_cd_to_root"; exit 0; }

# ----------------------------------------------------------------
echo "=== git ==="
if git rev-parse --git-dir > /dev/null 2>&1; then
  MODIFIED=$(git status --porcelain 2>/dev/null | grep -cE '^.M|^M ' || true)
  UNTRACKED=$(git status --porcelain 2>/dev/null | grep -cE '^\?\?' || true)
  STAGED=$(git status --porcelain 2>/dev/null | grep -cE '^M |^A |^D ' || true)
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
echo "=== claude_md ==="
if [ -f CLAUDE.md ]; then
  LINES=$(wc -l < CLAUDE.md | tr -d ' ')
  echo "lines=$LINES"
  if [ "$LINES" -gt 150 ]; then
    echo "status=critical"
  elif [ "$LINES" -gt 120 ]; then
    echo "status=warn"
  else
    echo "status=ok"
  fi
else
  echo "lines=0"
  echo "status=missing"
fi

# ----------------------------------------------------------------
echo
echo "=== not_implemented ==="
# Count and sample NOT_IMPLEMENTED references across common source types
NI_OUT=$(grep -rn NOT_IMPLEMENTED \
  --include='*.md' --include='*.sh' --include='*.py' \
  --include='*.ts' --include='*.tsx' --include='*.js' \
  --include='*.go' --include='*.rs' \
  . 2>/dev/null || true)
if [ -n "$NI_OUT" ]; then
  COUNT=$(echo "$NI_OUT" | wc -l | tr -d ' ')
  echo "count=$COUNT"
  # Emit up to 20 matches — anything above that is almost certainly meta
  echo "$NI_OUT" | head -20 | while IFS= read -r line; do
    echo "match=$line"
  done
else
  echo "count=0"
fi

# ----------------------------------------------------------------
echo
echo "=== broken_refs ==="
# Scan live current-state docs for backticked path references and
# verify they resolve on disk.
#
# Scope: CLAUDE.md, README.md, docs/rpm/RPM.md (three "what IS" docs).
#
# Excluded: docs/rpm/RPM-LOG.md, docs/rpm/past/*.md, docs/rpm/PRESENT.md
# — all append-only/historical. References to renamed or deleted
# files are expected there and are not drift.
#
# Token-is-a-path heuristic. A backticked token is treated as a
# project-relative path only if ALL hold:
#   1. contains `/`
#   2. does NOT start with `/`         (absolute paths / slash commands)
#   3. does NOT contain `:`            (slash commands like /pm:audit, URLs)
#   4. first char is lowercase or `.`  (CamelCase means tool/identifier)
#   5. no shell metacharacters or `~`
#   6. not a known shell command prefix
BROKEN_COUNT=0
for src in CLAUDE.md README.md docs/rpm/RPM.md; do
  [ -f "$src" ] || continue
  TOKENS=$(grep -oE '`[^`]+`' "$src" 2>/dev/null | sed 's/^`//;s/`$//' || true)
  while IFS= read -r token; do
    [ -z "$token" ] && continue
    case "$token" in */*) ;; *) continue ;; esac
    case "$token" in /*) continue ;; esac
    case "$token" in *:*) continue ;; esac
    case "$token" in [a-z.]*) ;; *) continue ;; esac
    echo "$token" | grep -qE '\$|\*|\||>|~' && continue
    echo "$token" | grep -qE '^(rm|git|cat|grep|ls|mkdir|cd|cp|mv|echo|curl|wget|npm|yarn|turbo|pnpm|claude|gh|bash|sh|python|node) ' && continue
    clean="${token#./}"
    if [ ! -e "$clean" ] && [ ! -e "$token" ]; then
      echo "broken=$src:$token"
      BROKEN_COUNT=$((BROKEN_COUNT + 1))
    fi
  done <<< "$TOKENS"
done
echo "count=$BROKEN_COUNT"

# ----------------------------------------------------------------
echo
echo "=== daily_log ==="
TODAY=$(date +%Y-%m-%d)
echo "today=$TODAY"
if [ -d docs/rpm/past ]; then
  LATEST=$(ls -1 docs/rpm/past/*.md 2>/dev/null | grep -E '[0-9]{4}-[0-9]{2}-[0-9]{2}\.md$' | sort -r | head -1)
  if [ -n "$LATEST" ]; then
    LOG_DATE=$(basename "$LATEST" .md)
    echo "latest=$LOG_DATE"
    # Days since last log
    if command -v date >/dev/null 2>&1; then
      DAYS=$(( ( $(date +%s) - $(date -d "$LOG_DATE" +%s 2>/dev/null || echo 0) ) / 86400 ))
      echo "days_since=$DAYS"
    fi
    # Commits since last log's day
    if git rev-parse --git-dir > /dev/null 2>&1; then
      COMMITS=$(git log --since="$LOG_DATE 23:59:59" --oneline 2>/dev/null | wc -l | tr -d ' ')
      echo "commits_since=$COMMITS"
    fi
    # Does today's log exist?
    if [ -f "docs/rpm/past/$TODAY.md" ]; then
      echo "today_exists=true"
    else
      echo "today_exists=false"
    fi
  else
    echo "latest=none"
    echo "today_exists=false"
  fi
else
  echo "status=no_past_dir"
fi

# ----------------------------------------------------------------
echo
echo "=== session_marker ==="
if [ -f docs/rpm/~rpm-session-active ]; then
  echo "exists=true"
else
  echo "exists=false"
fi

# ----------------------------------------------------------------
echo
echo "=== specs_inventory ==="
# If a spec directory exists, verify PRESENT.md mentions each
# spec file. Catches the "new specs added but PRESENT.md not
# updated" drift pattern (HIGH finding in volta 2026-04-09 audit:
# 17 top-level specs + 38 in docs/spec/traits/ unlisted).
#
# Searches common spec locations: specs/, spec/, docs/specs/,
# docs/spec/ — recursive within each. Match is filename-scoped
# (looks for `$base.md` or `spec(s)/$base` in PRESENT.md, not a
# loose substring) to avoid false positives on common basenames.
if [ ! -f docs/rpm/PRESENT.md ]; then
  echo "status=no_present_md"
else
  SPEC_LIST=$(find specs spec docs/specs docs/spec -type f -name '*.md' 2>/dev/null | sort)
  if [ -z "$SPEC_LIST" ]; then
    echo "status=no_spec_dir"
  else
    TOTAL=0
    UNLISTED=0
    UNLISTED_SAMPLES=""
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      TOTAL=$((TOTAL + 1))
      base=$(basename "$f" .md)
      if grep -qF "$base.md" docs/rpm/PRESENT.md 2>/dev/null \
         || grep -qF "specs/$base" docs/rpm/PRESENT.md 2>/dev/null \
         || grep -qF "spec/$base" docs/rpm/PRESENT.md 2>/dev/null; then
        continue
      fi
      UNLISTED=$((UNLISTED + 1))
      if [ "$UNLISTED" -le 10 ]; then
        UNLISTED_SAMPLES="${UNLISTED_SAMPLES}${base}"$'\n'
      fi
    done <<< "$SPEC_LIST"
    LISTED=$((TOTAL - UNLISTED))
    echo "total=$TOTAL"
    echo "listed=$LISTED"
    echo "unlisted=$UNLISTED"
    if [ -n "$UNLISTED_SAMPLES" ]; then
      while IFS= read -r sample; do
        [ -z "$sample" ] && continue
        echo "unlisted_sample=$sample"
      done <<< "$UNLISTED_SAMPLES"
    fi
  fi
fi

# ----------------------------------------------------------------
echo
echo "=== pm_docs_staleness ==="
# Staleness check for loose log/tracker/inventory files under
# docs/ and docs/rpm/ (top level only — past/ and reviews/ are
# append-only). Emits days-since-last-commit for each match;
# skill interprets. Catches the "parity-fix-log.md stale since
# 2026-04-05 despite 8+ fixes since" pattern from the volta
# 2026-04-09 audit.
#
# Excludes pm-meta files (RPM-LOG.md, RPM.md, PRESENT.md, FUTURE.org)
# which are updated by pm itself and have their own checks.
if git rev-parse --git-dir > /dev/null 2>&1; then
  NOW_EPOCH=$(date +%s)
  STALE_COUNT=0
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    [ ! -f "$f" ] && continue
    base=$(basename "$f")
    case "$base" in
      RPM-LOG.md|RPM.md|PRESENT.md|FUTURE.org) continue ;;
    esac
    MTIME=$(git log -1 --format='%cI' -- "$f" 2>/dev/null)
    [ -z "$MTIME" ] && continue
    MTIME_DATE="${MTIME%T*}"
    MTIME_EPOCH=$(date -d "$MTIME_DATE" +%s 2>/dev/null || echo 0)
    [ "$MTIME_EPOCH" -eq 0 ] && continue
    DAYS=$(( (NOW_EPOCH - MTIME_EPOCH) / 86400 ))
    # Strip leading ./ for display
    rel="${f#./}"
    echo "file=$rel days=$DAYS"
    STALE_COUNT=$((STALE_COUNT + 1))
  done < <(find docs docs/rpm -maxdepth 1 -type f \( -iname '*log*.md' -o -iname '*tracker*.md' -o -iname '*inventory*.md' \) 2>/dev/null)
  echo "count=$STALE_COUNT"
else
  echo "count=0"
fi

# ----------------------------------------------------------------
echo
echo "=== task_deps ==="
# Validate FUTURE.org dependency graph: extract :ID: and :BLOCKED_BY:
# from property drawers, check for dangling refs and cycles, and
# report tasks that are ready (TODO with all blockers DONE).
FUTURE="docs/rpm/FUTURE.org"
if [ -f "$FUTURE" ]; then
  # Build maps: id→status, id→blocked_by list
  # Parse sequentially: track current heading's status and ID
  # sanitize: convert ID to valid bash var name (hyphens → underscores)
  san() { echo "$1" | tr '-' '_'; }

  CUR_STATUS=""
  CUR_ID=""
  CUR_BLOCKED=""
  ALL_IDS=""
  READY=""

  while IFS= read -r line; do
    # Heading line: ** STATUS Text
    if echo "$line" | grep -qE '^\*\* (TODO|IN-PROGRESS|BLOCKED|DONE) '; then
      CUR_STATUS=$(echo "$line" | sed -E 's/^\*\* (TODO|IN-PROGRESS|BLOCKED|DONE) .*/\1/')
      CUR_ID=""
      CUR_BLOCKED=""
    fi
    # Property: :ID: value
    if echo "$line" | grep -qE '^\s+:ID:\s'; then
      CUR_ID=$(echo "$line" | sed -E 's/^\s+:ID:\s+//' | tr -d ' ')
      ALL_IDS="$ALL_IDS $CUR_ID"
      eval "STATUS_$(san "$CUR_ID")=$CUR_STATUS"
    fi
    # Property: :BLOCKED_BY: value (space-separated list)
    if echo "$line" | grep -qE '^\s+:BLOCKED_BY:\s'; then
      CUR_BLOCKED=$(echo "$line" | sed -E 's/^\s+:BLOCKED_BY:\s+//')
      eval "DEPS_$(san "$CUR_ID")=\"$CUR_BLOCKED\""
    fi
  done < "$FUTURE"

  # Second pass: validate refs and find ready tasks
  DEP_COUNT=0
  DANGLING=""
  for id in $ALL_IDS; do
    eval "deps=\${DEPS_$(san "$id"):-}"
    [ -z "$deps" ] && continue
    DEP_COUNT=$((DEP_COUNT + 1))
    eval "my_status=\${STATUS_$(san "$id"):-}"
    ALL_DONE=true
    for dep in $deps; do
      if ! echo "$ALL_IDS" | grep -qwF "$dep"; then
        DANGLING="$DANGLING $id→$dep"
      else
        eval "dep_status=\${STATUS_$(san "$dep"):-}"
        [ "$dep_status" != "DONE" ] && ALL_DONE=false
      fi
    done
    if [ "$my_status" = "TODO" ] || [ "$my_status" = "BLOCKED" ]; then
      if $ALL_DONE; then
        READY="$READY $id"
      fi
    fi
  done

  echo "ids=$(echo $ALL_IDS | wc -w | tr -d ' ')"
  echo "with_deps=$DEP_COUNT"
  [ -n "$DANGLING" ] && echo "dangling=$DANGLING"
  [ -n "$READY" ] && echo "ready=$READY"
  echo "status=ok"
else
  echo "status=no_future_org"
fi

# ----------------------------------------------------------------
echo
echo "=== learnings_capture ==="
# Check for auto-captured learnings from the Stop hook
LEARNINGS_FILE="docs/rpm/~rpm-learnings.jsonl"
if [ -f "$LEARNINGS_FILE" ]; then
  ENTRY_COUNT=$(wc -l < "$LEARNINGS_FILE" | tr -d ' ')
  echo "file=$LEARNINGS_FILE"
  echo "entries=$ENTRY_COUNT"
  # Show last 10 excerpts for Phase 1c
  tail -10 "$LEARNINGS_FILE" | while IFS= read -r line; do
    EXCERPT=$(echo "$line" | jq -r '.excerpt // empty' 2>/dev/null)
    [ -n "$EXCERPT" ] && echo "excerpt=$EXCERPT"
  done
else
  echo "entries=0"
fi
