#!/usr/bin/env bash
# Run the bats suite locally. CI uses .github/workflows/test.yml.
set -e
cd "$(dirname "$0")"
if ! command -v bats >/dev/null 2>&1; then
  echo "bats not found. Install: sudo apt-get install bats  (or: brew install bats-core)" >&2
  exit 2
fi
bats .
