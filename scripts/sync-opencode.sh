#!/bin/bash
# Mirror plugin/{skills,agents} into opencode/.opencode/{skills,agents}
# so opencode sees rpm's full surface. Run after editing anything under
# plugin/skills or plugin/agents.

set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SRC="$REPO_ROOT/plugin"
DST="$REPO_ROOT/opencode/.opencode"

mkdir -p "$DST"

# Skills copy straight across — SKILL.md format is identical.
rm -rf "$DST/skills"
cp -a "$SRC/skills" "$DST/skills"

# Agents need per-file translation: tools list → record, drop name:
# and model:, add mode: subagent. See scripts/translate-agent.py.
rm -rf "$DST/agents"
mkdir -p "$DST/agents"
for f in "$SRC"/agents/*.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f")
  python3 "$REPO_ROOT/scripts/translate-agent.py" "$f" "$DST/agents/$name"
done

echo "sync-opencode: mirrored skills + translated agents"
echo "  $SRC/skills/  -> $DST/skills/"
echo "  $SRC/agents/  -> $DST/agents/  (translated)"
