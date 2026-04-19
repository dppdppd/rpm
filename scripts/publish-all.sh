#!/bin/bash
# Publish a full rpm release: both the Claude Code plugin and the
# opencode port, tagged at the current plugin.json version.
#
# Usage:
#   publish-all.sh             # publish both + push version tag
#   publish-all.sh --dry-run   # stage + split both, skip pushes
#
# Assumes the `plugin` remote points at the public GitHub repo
# (https://github.com/<owner>/rpm.git). Both releases land there —
#   master  = CC subtree split (from plugin/)
#   opencode = opencode subtree split (from opencode/)

set -euo pipefail

DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=1
fi

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$REPO"

# Require a clean working tree.
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "publish-all: working tree has uncommitted changes — commit or stash first" >&2
  exit 1
fi

# Extract the current version from plugin.json.
VERSION=$(jq -r '.version' "$REPO/plugin/.claude-plugin/plugin.json")
TAG="v$VERSION"
if [ -z "$VERSION" ] || [ "$VERSION" = "null" ]; then
  echo "publish-all: could not read version from plugin/.claude-plugin/plugin.json" >&2
  exit 1
fi

echo "publish-all: version=$VERSION tag=$TAG"

# --- Step 1: CC plugin (subtree split from plugin/ → plugin/master) ---

echo "publish-all: step 1/3 — CC plugin"
git subtree split --prefix=plugin -b plugin-only >/dev/null

if [ "$DRY_RUN" -eq 1 ]; then
  CC_SHA=$(git rev-parse plugin-only)
  echo "publish-all: cc split sha=$CC_SHA (dry-run, skipping push)"
else
  git push plugin plugin-only:master --force
fi
git branch -D plugin-only >/dev/null

# --- Step 2: opencode port (delegates to publish-opencode.sh) ---

echo "publish-all: step 2/3 — opencode port"
if [ "$DRY_RUN" -eq 1 ]; then
  "$REPO/scripts/publish-opencode.sh" --dry-run >/dev/null
  echo "publish-all: opencode split verified (dry-run, skipping push)"
else
  "$REPO/scripts/publish-opencode.sh"
fi

# --- Step 3: version tag ---

echo "publish-all: step 3/3 — tag $TAG"

if git rev-parse --verify --quiet "$TAG" >/dev/null; then
  echo "publish-all: tag $TAG already exists locally — skipping create"
else
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "publish-all: would create tag $TAG (dry-run, skipping)"
  else
    git tag "$TAG"
  fi
fi

if [ "$DRY_RUN" -eq 1 ]; then
  echo "publish-all: dry-run, skipping tag push"
else
  git push plugin "$TAG"
fi

echo "publish-all: done"
