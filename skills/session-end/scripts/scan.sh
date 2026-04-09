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
# Scope: CLAUDE.md, README.md, docs/pm/PM.md (three "what IS" docs).
#
# Excluded: docs/pm/PM-LOG.md, docs/pm/past/*.md, docs/pm/PRESENT.md
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
for src in CLAUDE.md README.md docs/pm/PM.md; do
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
if [ -d docs/pm/past ]; then
  LATEST=$(ls -1 docs/pm/past/*.md 2>/dev/null | grep -E '[0-9]{4}-[0-9]{2}-[0-9]{2}\.md$' | sort -r | head -1)
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
    if [ -f "docs/pm/past/$TODAY.md" ]; then
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
if [ -f docs/pm/~pm-session-active ]; then
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
if [ ! -f docs/pm/PRESENT.md ]; then
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
      if grep -qF "$base.md" docs/pm/PRESENT.md 2>/dev/null \
         || grep -qF "specs/$base" docs/pm/PRESENT.md 2>/dev/null \
         || grep -qF "spec/$base" docs/pm/PRESENT.md 2>/dev/null; then
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
# docs/ and docs/pm/ (top level only — past/ and reviews/ are
# append-only). Emits days-since-last-commit for each match;
# skill interprets. Catches the "parity-fix-log.md stale since
# 2026-04-05 despite 8+ fixes since" pattern from the volta
# 2026-04-09 audit.
#
# Excludes pm-meta files (PM-LOG.md, PM.md, PRESENT.md, FUTURE.org)
# which are updated by pm itself and have their own checks.
if git rev-parse --git-dir > /dev/null 2>&1; then
  NOW_EPOCH=$(date +%s)
  STALE_COUNT=0
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    [ ! -f "$f" ] && continue
    base=$(basename "$f")
    case "$base" in
      PM-LOG.md|PM.md|PRESENT.md|FUTURE.org) continue ;;
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
  done < <(find docs docs/pm -maxdepth 1 -type f \( -iname '*log*.md' -o -iname '*tracker*.md' -o -iname '*inventory*.md' \) 2>/dev/null)
  echo "count=$STALE_COUNT"
else
  echo "count=0"
fi
