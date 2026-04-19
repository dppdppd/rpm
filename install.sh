#!/bin/bash
# rpm-opencode install — copies the .opencode/ tree into a target
# project so opencode auto-discovers the plugin, commands, skills,
# and agents.
#
# Usage (run inside the target project's root):
#   curl -fsSL https://raw.githubusercontent.com/dppdppd/rpm/opencode/install.sh | bash
#
# Or with an explicit target:
#   curl -fsSL .../install.sh | bash -s -- /path/to/project

set -euo pipefail

TARGET="${1:-$PWD}"
BRANCH="opencode"
REPO_URL="https://github.com/dppdppd/rpm.git"

if [ ! -d "$TARGET" ]; then
  echo "rpm-opencode: target '$TARGET' is not a directory" >&2
  exit 1
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "rpm-opencode: fetching $BRANCH branch"
git clone --depth 1 --branch "$BRANCH" --quiet "$REPO_URL" "$TMP/rpm-opencode"

mkdir -p "$TARGET/.opencode"
# Copy without clobbering a user's own .opencode/ additions. Existing
# rpm-owned files DO get replaced on reinstall (that's how updates work);
# only merges at the top level.
cp -a "$TMP/rpm-opencode/.opencode/." "$TARGET/.opencode/"

echo "rpm-opencode: installed into $TARGET/.opencode"
echo ""
echo "Next steps:"
echo "  1. Run '/init-rpm' once to bootstrap docs/rpm/"
echo "  2. Start a session — rpm is now active"
