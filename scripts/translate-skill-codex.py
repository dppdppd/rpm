#!/usr/bin/env python3
"""
Translate a Claude Code skill SKILL.md file to a Codex skill SKILL.md.

Codex skill frontmatter recognizes only `name` and `description`
(see openai/codex/.codex/skills/*/SKILL.md). Body is plain markdown
read by the model when the skill triggers. This converter:

- Keeps `name:` (Codex uses it; same key, same value)
- Keeps `description:` verbatim, including multi-line forms
- Drops `allowed-tools:` (Codex doesn't recognize it; permissions
  are handled by config.toml + sandbox)
- Drops `argument-hint:` (Codex doesn't recognize it)
- Drops `disable-model-invocation:` (Claude-Code-specific)

Body is copied verbatim. Tool-name references in the body
(`WebSearch`, `Bash`, etc.) are NOT rewritten — modern models
generally interpret them correctly against whichever tool surface
is actually available, and regex rewrites risk false positives in
prose. If a specific skill needs Codex-flavored tool names, hand-
edit the synced file and add the manual-sync sentinel near the top
so sync-codex.sh skips it on subsequent runs:

    <!-- codex-sync: manual -->

(See sync-codex.sh for the exact match — first 20 lines, literal
substring.)

Usage: translate-skill-codex.py <input.md> <output.md>
"""

import re
import sys
from pathlib import Path

FRONTMATTER_RE = re.compile(r"^---\n(.*?)\n---\n(.*)$", re.S)
DROP_KEYS = {
    "allowed-tools",
    "argument-hint",
    "disable-model-invocation",
}
CODEX_PLUGIN_ROOT = (
    "${RPM_PLUGIN_ROOT:-${CODEX_HOME:-$HOME/.codex}/.tmp/"
    "marketplaces/dppdppd-rpm/.codex}"
)


def translate(src: str) -> str:
    m = FRONTMATTER_RE.match(src)
    if not m:
        return src

    fm, body = m.group(1), m.group(2)
    lines = fm.split("\n")
    out: list[str] = []
    skill_name = ""
    i = 0
    while i < len(lines):
        line = lines[i]
        key_match = re.match(r"^([A-Za-z][A-Za-z0-9_-]*):(\s|$)", line)
        if key_match and key_match.group(1) in DROP_KEYS:
            # Drop the key line plus any indented continuation lines
            # (block scalars, folded/literal forms).
            i += 1
            while i < len(lines) and (
                lines[i].startswith(" ") or lines[i].startswith("\t")
            ):
                i += 1
            continue
        if key_match and key_match.group(1) == "name":
            skill_name = line.split(":", 1)[1].strip().strip('"').strip("'")
        out.append(line)
        i += 1

    if skill_name:
        body = body.replace(
            "${CLAUDE_SKILL_DIR}/scripts/",
            f"{CODEX_PLUGIN_ROOT}/skills/{skill_name}/scripts/",
        )
    body = body.replace("${CLAUDE_PLUGIN_ROOT}", CODEX_PLUGIN_ROOT)
    body = body.replace("/.claude-plugin/plugin.json", "/.codex-plugin/plugin.json")

    return "---\n" + "\n".join(out).strip() + "\n---\n" + body


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: translate-skill-codex.py <input.md> <output.md>", file=sys.stderr)
        return 2
    src_path = Path(sys.argv[1])
    dst_path = Path(sys.argv[2])
    dst_path.parent.mkdir(parents=True, exist_ok=True)
    dst_path.write_text(translate(src_path.read_text()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
