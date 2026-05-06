#!/bin/bash
# Print the installed rpm plugin version.

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  PLUGIN_ROOT="$CLAUDE_PLUGIN_ROOT"
elif [ -n "${RPM_PLUGIN_ROOT:-}" ]; then
  PLUGIN_ROOT="$RPM_PLUGIN_ROOT"
else
  PLUGIN_ROOT=$(cd "$SCRIPT_DIR/../../.." && pwd)
fi

MANIFEST="$PLUGIN_ROOT/.claude-plugin/plugin.json"
if [ ! -f "$MANIFEST" ]; then
  MANIFEST="$PLUGIN_ROOT/.codex-plugin/plugin.json"
fi

VERSION="unknown"
if [ -f "$MANIFEST" ]; then
  if command -v jq >/dev/null 2>&1; then
    VERSION=$(jq -r '.version // "unknown"' "$MANIFEST" 2>/dev/null || printf unknown)
  else
    VERSION=$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$MANIFEST" | head -1)
    VERSION="${VERSION:-unknown}"
  fi
fi

printf 'rpm v%s\n' "$VERSION"
