#!/bin/bash
# Mirror plugin/{skills,agents} into opencode/.opencode/{skills,agents}
# so opencode sees rpm's full surface. Run after editing anything under
# plugin/skills or plugin/agents.

set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SRC="$REPO_ROOT/plugin"
DST="$REPO_ROOT/opencode/.opencode"

mkdir -p "$DST"

# Skills copy straight across so opencode can load their body as
# tool-invoked context when an agent calls skill({name}). Frontmatter
# fields opencode doesn't recognize are silently ignored per docs.
rm -rf "$DST/skills"
cp -a "$SRC/skills" "$DST/skills"

# Slash-command surface: rpm's entry points (/backlog, /session-end,
# etc.) are slash-commands in spirit. opencode's commands support
# $ARGUMENTS and `!bash` block injection identically to Claude Code
# slash commands, so the skill body can be reused; only frontmatter
# needs translation. See scripts/translate-skill.py.
rm -rf "$DST/commands"
mkdir -p "$DST/commands"
for skill_dir in "$SRC"/skills/*/; do
  name=$(basename "$skill_dir")
  src_md="$skill_dir/SKILL.md"
  [ -f "$src_md" ] || continue
  python3 "$REPO_ROOT/scripts/translate-skill.py" "$src_md" "$DST/commands/$name.md"
done

# Agents need per-file translation: tools list → record, drop name:
# and model:, add mode: subagent. See scripts/translate-agent.py.
rm -rf "$DST/agents"
mkdir -p "$DST/agents"
for f in "$SRC"/agents/*.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f")
  python3 "$REPO_ROOT/scripts/translate-agent.py" "$f" "$DST/agents/$name"
done

echo "sync-opencode: mirrored skills + translated agents + commands"
echo "  $SRC/skills/  -> $DST/skills/"
echo "  $SRC/skills/  -> $DST/commands/  (translated to opencode commands)"
echo "  $SRC/agents/  -> $DST/agents/    (translated)"
