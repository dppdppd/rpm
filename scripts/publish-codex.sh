#!/bin/bash
# Publish codex/ as a subtree split to a remote branch.
#
# Usage:
#   publish-codex.sh [remote] [branch]   # defaults: plugin codex
#   publish-codex.sh --dry-run           # do everything except push

set -euo pipefail

DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=1
  shift
fi

REMOTE="${1:-plugin}"
BRANCH="${2:-codex}"

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$REPO"

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "publish-codex: working tree has uncommitted changes — commit or stash first" >&2
  exit 1
fi

echo "publish-codex: running sync"
"$REPO/scripts/sync-codex.sh" >/dev/null

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "publish-codex: sync-codex.sh changed files — commit regenerated codex/ before publishing" >&2
  exit 1
fi

cleanup() {
  local rc=$?
  git branch -D codex-only 2>/dev/null || true
  exit $rc
}
trap cleanup EXIT

echo "publish-codex: subtree split"
git subtree split --prefix=codex -b codex-only >/dev/null

SPLIT_SHA=$(git rev-parse codex-only)
SPLIT_FILES=$(git ls-tree -r --name-only codex-only | wc -l)
echo "publish-codex: split sha=$SPLIT_SHA files=$SPLIT_FILES"

if [ "$DRY_RUN" -eq 1 ]; then
  echo "publish-codex: dry-run tree:"
  git ls-tree -r --name-only codex-only | sed 's/^/  /'
  echo "publish-codex: dry-run, skipping push to $REMOTE/$BRANCH"
else
  echo "publish-codex: pushing to $REMOTE/$BRANCH"
  git push "$REMOTE" "codex-only:$BRANCH" --force
fi

echo "publish-codex: done"
