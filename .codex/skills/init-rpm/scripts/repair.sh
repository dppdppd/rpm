#!/bin/bash
# /init-rpm repair helper — idempotently brings an existing rpm project's
# .gitignore and AGENTS.md up to the current expected layout.
#
# Two checks, runnable independently or together:
#
#   1. .gitignore wildcard.
#      - If `.gitignore` is missing or lacks a `docs/rpm/~rpm-*` rule,
#        ensure the rule is present (creates the file if needed).
#      - If explicit `docs/rpm/~rpm-...` lines accumulated from the old
#        per-file ignore pattern, offer to collapse them into the
#        wildcard. Default is to leave them in place unless --auto-yes
#        is passed (or stdin answers yes).
#
#   2. AGENTS.md `# include:` directive.
#      - If `AGENTS.md` exists and is missing the
#        `# include: docs/rpm/~rpm-context.md` line near the top, offer
#        to prepend it. The line is placed at the top, after any
#        existing YAML frontmatter block but before any other content,
#        so the Codex preprocessor picks it up.
#
# Exit codes:
#   0 — done (no changes needed, changes applied, or user declined)
#   2 — fatal misuse (bad arg)
#
# All informational output goes to stdout in a structured form the
# /init-rpm SKILL body can echo back to the user. Errors go to stderr.
#
# Usage:
#   repair.sh [--check]               # report-only, no writes
#   repair.sh [--auto-yes]            # apply all safe migrations w/o prompting
#   repair.sh [--gitignore-only]      # only run gitignore check
#   repair.sh [--agents-only]         # only run AGENTS.md check
#
# Defaults: run both checks, apply non-destructive additions
# (wildcard append, missing .gitignore, AGENTS.md include prepend),
# but only collapse explicit gitignore lines with --auto-yes.

set -u

MODE_CHECK=0
MODE_AUTO_YES=0
MODE_GITIGNORE_ONLY=0
MODE_AGENTS_ONLY=0

while [ $# -gt 0 ]; do
  case "$1" in
    --check)          MODE_CHECK=1 ;;
    --auto-yes)       MODE_AUTO_YES=1 ;;
    --gitignore-only) MODE_GITIGNORE_ONLY=1 ;;
    --agents-only)    MODE_AGENTS_ONLY=1 ;;
    -h|--help)
      sed -n '2,40p' "$0"
      exit 0
      ;;
    *)
      echo "repair.sh: unknown arg: $1" >&2
      exit 2
      ;;
  esac
  shift
done

ROOT="${RPM_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"
cd "$ROOT" 2>/dev/null || {
  echo "repair.sh: cannot cd to $ROOT" >&2
  exit 2
}

WILDCARD_LINE='docs/rpm/~rpm-*'
WILDCARD_COMMENT='# rpm session-state (transient, regenerated per session)'
INCLUDE_LINE='# include: docs/rpm/~rpm-context.md'

# --- helpers ---------------------------------------------------------------

# True if .gitignore exists and contains the wildcard on a line of its own.
has_wildcard() {
  [ -f .gitignore ] || return 1
  grep -Fxq "$WILDCARD_LINE" .gitignore
}

# Print all explicit `docs/rpm/~rpm-...` lines (one per call). The wildcard
# itself is excluded.
explicit_rpm_lines() {
  [ -f .gitignore ] || return 0
  grep -E '^docs/rpm/~rpm-[A-Za-z0-9.-]+$' .gitignore || true
}

# True if AGENTS.md exists and has the include line in the first 20 lines,
# before any heading deeper than H2.
has_include() {
  [ -f AGENTS.md ] || return 1
  awk -v target="$INCLUDE_LINE" '
    NR > 20 { exit }
    /^### / { exit }
    $0 == target { found = 1; exit }
    END { exit !found }
  ' AGENTS.md
}

# --- check 1: .gitignore wildcard -----------------------------------------

run_gitignore_check() {
  echo "=== gitignore ==="

  local explicit_count=0
  local explicit_lines=""
  if [ -f .gitignore ]; then
    explicit_lines=$(explicit_rpm_lines)
    if [ -n "$explicit_lines" ]; then
      explicit_count=$(printf '%s\n' "$explicit_lines" | wc -l | tr -d ' ')
    fi
  fi

  if has_wildcard; then
    echo "wildcard=present"
  else
    echo "wildcard=absent"
  fi
  echo "explicit_count=$explicit_count"

  if [ "$MODE_CHECK" -eq 1 ]; then
    return 0
  fi

  # Step A: ensure wildcard present.
  if ! has_wildcard; then
    if [ -f .gitignore ]; then
      # Append wildcard with comment header (separated by blank line if file
      # doesn't end with one).
      if [ -s .gitignore ]; then
        # ensure trailing newline before appending
        local last_byte
        last_byte=$(tail -c1 .gitignore 2>/dev/null || true)
        if [ "$last_byte" != "" ] && [ "$last_byte" != $'\n' ]; then
          printf '\n' >> .gitignore
        fi
        printf '\n%s\n%s\n' "$WILDCARD_COMMENT" "$WILDCARD_LINE" >> .gitignore
      else
        printf '%s\n%s\n' "$WILDCARD_COMMENT" "$WILDCARD_LINE" >> .gitignore
      fi
      echo "action=appended_wildcard"
    else
      # Create .gitignore from scratch.
      printf '%s\n%s\n' "$WILDCARD_COMMENT" "$WILDCARD_LINE" > .gitignore
      echo "action=created_gitignore"
    fi
  fi

  # Step B: optionally collapse explicit entries.
  if [ "$explicit_count" -gt 0 ]; then
    if [ "$MODE_AUTO_YES" -eq 1 ]; then
      # Filter explicit lines out of .gitignore; preserve order of all
      # other lines.
      local tmp
      tmp=$(mktemp)
      # `grep -vE` drops the explicit pattern; surviving content
      # preserves everything else verbatim.
      grep -vE '^docs/rpm/~rpm-[A-Za-z0-9.-]+$' .gitignore > "$tmp" || true
      mv "$tmp" .gitignore
      echo "action=collapsed_explicit count=$explicit_count"
    else
      echo "action=offer_collapse count=$explicit_count"
      # Print which lines would be removed so the SKILL body can show them.
      printf '%s\n' "$explicit_lines" | sed 's/^/explicit_line=/'
    fi
  fi
}

# --- check 2: AGENTS.md include -------------------------------------------

run_agents_check() {
  echo "=== agents_md ==="

  if [ ! -f AGENTS.md ]; then
    echo "agents_md=absent"
    return 0
  fi

  if has_include; then
    echo "agents_md=include_present"
    return 0
  fi

  echo "agents_md=include_missing"

  if [ "$MODE_CHECK" -eq 1 ]; then
    return 0
  fi

  if [ "$MODE_AUTO_YES" -ne 1 ]; then
    echo "action=offer_prepend"
    return 0
  fi

  # Prepend the include line. If file starts with YAML frontmatter
  # (`---` on line 1 ... `---` on a later line), insert immediately
  # after the closing `---`. Otherwise insert at line 1.
  local tmp
  tmp=$(mktemp)

  local first_line
  first_line=$(head -n1 AGENTS.md)

  if [ "$first_line" = "---" ]; then
    # Find the closing --- (must be >= line 2).
    local close_line
    close_line=$(awk 'NR>1 && $0=="---" {print NR; exit}' AGENTS.md)
    if [ -n "$close_line" ]; then
      # Copy frontmatter through close_line, then blank line, then include
      # line, then blank line, then the rest. (`close` is reserved in awk,
      # so use `endline` here.)
      awk -v endline="$close_line" -v inc="$INCLUDE_LINE" '
        { lines[NR] = $0 }
        END {
          for (i = 1; i <= endline; i++) print lines[i]
          print ""
          print inc
          for (i = endline + 1; i <= NR; i++) print lines[i]
        }
      ' AGENTS.md > "$tmp"
      mv "$tmp" AGENTS.md
      echo "action=prepended_after_frontmatter"
      return 0
    fi
    # Frontmatter never closed — fall through and prepend at line 1.
  fi

  # No frontmatter: prepend at line 1 with a trailing blank line.
  {
    printf '%s\n\n' "$INCLUDE_LINE"
    cat AGENTS.md
  } > "$tmp"
  mv "$tmp" AGENTS.md
  echo "action=prepended_at_top"
}

# --- dispatch -------------------------------------------------------------

if [ "$MODE_GITIGNORE_ONLY" -eq 1 ] && [ "$MODE_AGENTS_ONLY" -eq 1 ]; then
  echo "repair.sh: --gitignore-only and --agents-only are mutually exclusive" >&2
  exit 2
fi

if [ "$MODE_AGENTS_ONLY" -ne 1 ]; then
  run_gitignore_check
fi

if [ "$MODE_GITIGNORE_ONLY" -ne 1 ]; then
  run_agents_check
fi

exit 0
