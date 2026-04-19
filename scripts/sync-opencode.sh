#!/bin/bash
# Mirror plugin/{skills,agents} into opencode/.opencode/{skills,agents}
# so opencode sees rpm's full surface. Run after editing anything under
# plugin/skills or plugin/agents.

set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SRC="$REPO_ROOT/plugin"
DST="$REPO_ROOT/opencode/.opencode"

mkdir -p "$DST"

# Hooks bundle alongside the plugin so rpm.ts can resolve them at a
# stable path (${plugin-file-dir}/hooks) whether running from the
# monorepo or a published package.
rm -rf "$DST/plugins/hooks"
cp -a "$SRC/hooks" "$DST/plugins/hooks"

# plugin.json bundles so /rpm version lookup
# (${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json) resolves off
# the self-contained tree, no reach back into plugin/.
rm -rf "$DST/.claude-plugin"
cp -a "$SRC/.claude-plugin" "$DST/.claude-plugin"

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

echo "sync-opencode: mirrored hooks + skills + commands + agents"
echo "  $SRC/hooks/   -> $DST/plugins/hooks/"
echo "  $SRC/skills/  -> $DST/skills/"
echo "  $SRC/skills/  -> $DST/commands/  (translated to opencode commands)"
echo "  $SRC/agents/  -> $DST/agents/    (translated)"
