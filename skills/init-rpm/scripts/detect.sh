#!/bin/bash
# Bootstrap Phase 1: detect project state in a single pass.
# Output: key=value lines grouped by section.
# Runs via !bash "${CLAUDE_SKILL_DIR}/scripts/detect.sh"

set -u
ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$ROOT" 2>/dev/null || { echo "error=cannot_cd_to_root"; exit 0; }

# --- Source files ---
echo "=== source ==="
for d in src lib app; do
  [ -d "$d" ] && echo "dir=$d"
done
for f in main.* index.* *.py *.ts *.go *.rs; do
  [ -f "$f" ] 2>/dev/null && echo "entry=$f"
done

# --- Build system ---
echo ""
echo "=== build ==="
for f in package.json Cargo.toml go.mod pyproject.toml Makefile CMakeLists.txt; do
  [ -f "$f" ] && echo "manifest=$f"
done

# --- Tests ---
echo ""
echo "=== tests ==="
for d in test tests spec __tests__; do
  [ -d "$d" ] && echo "dir=$d"
done
for f in *_test.* *_spec.*; do
  [ -f "$f" ] 2>/dev/null && echo "file=$f"
done

# --- Existing LLM config ---
echo ""
echo "=== llm_config ==="
for f in CLAUDE.md AGENTS.md; do
  [ -f "$f" ] && echo "file=$f"
done
[ -d .claude ] && echo "dir=.claude"
[ -f .cursorrules ] && echo "file=.cursorrules"

# --- Git history ---
echo ""
echo "=== git ==="
if git rev-parse --git-dir > /dev/null 2>&1; then
  git log --oneline -20 2>/dev/null
else
  echo "not_a_repo=true"
fi
