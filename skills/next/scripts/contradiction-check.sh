#!/bin/bash
# contradiction-check.sh — gate the rpm:guidance-aligner agent for
# /next preflight. Returns whether a dispatch is needed (inputs
# changed since last check) or whether a cached result can be reused.
#
# Subcommands:
#   check        Inspect cache + input mtimes. Print one line to stdout:
#                  cached <path-to-cache>      (exit 0, reuse cache)
#                  dispatch <newest-epoch>     (exit 0, agent needed)
#                  skip <reason>               (exit 0, nothing to do)
#                Always exits 0 — never block preflight.
#   save EPOCH   Read JSON from stdin, persist with EPOCH header.
#
# Cache layout (docs/rpm/~rpm-contradiction-cache):
#   inputs_newest=<epoch>
#   checked_at=<epoch>
#   ---
#   <agent JSON, single line>

set -euo pipefail

PROJECT_DIR="${RPM_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"
CACHE="$PROJECT_DIR/docs/rpm/~rpm-contradiction-cache"

# Project memory dir convention: ~/.claude/projects/<slugified-pwd>/memory
PROJECT_SLUG=$(printf '%s' "$PROJECT_DIR" | sed 's|/|-|g')
MEMORY_DIR="${HOME}/.claude/projects/${PROJECT_SLUG}/memory"

collect_inputs() {
  # Print every input file path that exists, one per line.
  [ -f "$PROJECT_DIR/CLAUDE.md" ] && printf '%s\n' "$PROJECT_DIR/CLAUDE.md"
  [ -f "$PROJECT_DIR/AGENTS.md" ] && printf '%s\n' "$PROJECT_DIR/AGENTS.md"
  [ -f "$PROJECT_DIR/MEMORY.md" ] && printf '%s\n' "$PROJECT_DIR/MEMORY.md"
  if [ -d "$PROJECT_DIR/plugin/skills" ]; then
    find "$PROJECT_DIR/plugin/skills" -maxdepth 2 -name 'SKILL.md' -type f 2>/dev/null
  fi
  if [ -d "$MEMORY_DIR" ]; then
    find "$MEMORY_DIR" -maxdepth 1 -type f \( -name 'feedback_*.md' -o -name 'MEMORY.md' \) 2>/dev/null
  fi
}

newest_mtime() {
  local newest=0
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    local m
    m=$(stat -c %Y "$f" 2>/dev/null || echo 0)
    [ "$m" -gt "$newest" ] && newest=$m
  done
  printf '%s\n' "$newest"
}

cmd_check() {
  if [ ! -d "$MEMORY_DIR" ]; then
    printf 'skip no-memory-dir\n'
    return 0
  fi

  local files newest cached
  files=$(collect_inputs)
  if [ -z "$files" ]; then
    printf 'skip no-inputs\n'
    return 0
  fi

  newest=$(printf '%s\n' "$files" | newest_mtime)

  cached=0
  if [ -f "$CACHE" ]; then
    cached=$(grep -oP '^inputs_newest=\K[0-9]+' "$CACHE" 2>/dev/null | head -1)
    cached=${cached:-0}
  fi

  if [ -f "$CACHE" ] && [ "$newest" -le "$cached" ]; then
    printf 'cached %s\n' "$CACHE"
  else
    printf 'dispatch %s\n' "$newest"
  fi
}

cmd_save() {
  local epoch="${1:-}"
  if [ -z "$epoch" ]; then
    printf 'save: missing EPOCH argument\n' >&2
    return 2
  fi
  mkdir -p "$(dirname "$CACHE")"
  local payload
  payload=$(cat)
  {
    printf 'inputs_newest=%s\n' "$epoch"
    printf 'checked_at=%s\n' "$(date +%s)"
    printf -- '---\n'
    printf '%s\n' "$payload"
  } > "$CACHE"
}

case "${1:-}" in
  check) cmd_check ;;
  save)  shift; cmd_save "$@" ;;
  *)
    printf 'usage: %s {check|save EPOCH}\n' "$0" >&2
    exit 2
    ;;
esac
