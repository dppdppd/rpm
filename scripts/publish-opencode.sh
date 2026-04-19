#!/bin/bash
# Publish opencode/ as a subtree split to a remote branch. Users
# install by curling the install.sh shipped at the root of that
# branch.
#
# The mirrored files under opencode/.opencode/{skills,agents,commands,
# plugins/hooks,.claude-plugin} are gitignored in the monorepo (derived
# from plugin/); this script materializes them on a throwaway staging
# branch so the subtree split includes a complete, runnable tree.
#
# Usage:
#   publish-opencode.sh [remote] [branch]   # defaults: plugin opencode
#   publish-opencode.sh --dry-run           # do everything except push

set -euo pipefail

DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=1
  shift
fi

REMOTE="${1:-plugin}"
BRANCH="${2:-opencode}"

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$REPO"

# Require a clean working tree so we don't accidentally bake
# unreviewed changes into the published branch.
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "publish-opencode: working tree has uncommitted changes — commit or stash first" >&2
  exit 1
fi

STARTING_REF=$(git rev-parse --abbrev-ref HEAD)
STAGING_BRANCH="opencode-publish-$(date +%s)"

cleanup() {
  local rc=$?
  git checkout -q "$STARTING_REF" 2>/dev/null || true
  git branch -D "$STAGING_BRANCH" 2>/dev/null || true
  git branch -D opencode-only 2>/dev/null || true
  exit $rc
}
trap cleanup EXIT

echo "publish-opencode: running sync"
"$REPO/scripts/sync-opencode.sh" >/dev/null

echo "publish-opencode: staging mirrors on $STAGING_BRANCH"
git checkout -q -b "$STAGING_BRANCH"
# Force-add ONLY the derived mirror paths (everything else in
# opencode/ is already tracked). Using `git add -f opencode/` would
# sweep in node_modules/ and other gitignored cruft.
git add -f \
  opencode/.opencode/skills \
  opencode/.opencode/agents \
  opencode/.opencode/commands \
  opencode/.opencode/plugins/hooks \
  opencode/.opencode/.claude-plugin
git commit -q -m "chore: materialize opencode mirrors for publish"

echo "publish-opencode: subtree split"
git subtree split --prefix=opencode -b opencode-only >/dev/null

SPLIT_SHA=$(git rev-parse opencode-only)
SPLIT_FILES=$(git ls-tree -r --name-only opencode-only | wc -l)
echo "publish-opencode: split sha=$SPLIT_SHA files=$SPLIT_FILES"

if [ "$DRY_RUN" -eq 1 ]; then
  echo "publish-opencode: dry-run, skipping push to $REMOTE/$BRANCH"
else
  echo "publish-opencode: pushing to $REMOTE/$BRANCH"
  git push "$REMOTE" "opencode-only:$BRANCH" --force
fi

echo "publish-opencode: done"
