#!/usr/bin/env python3
"""
Translate a Claude Code agent .md file to opencode agent format.

Differences handled:
- Drop `name:` — opencode derives from filename.
- Drop `model:` — Claude Code shortnames ("sonnet") don't map to
  opencode's provider-prefixed model IDs; let opencode default.
- Transform `tools: [...]` (YAML array) → `tools: {name: true, ...}`
  (YAML record) with lowercased tool names (Read → read, etc.).
- Insert `mode: subagent` if not already present.

Body content (after the frontmatter delimiter) is copied unchanged.

Usage: translate-agent.py <input.md> <output.md>
"""

import re
import sys
from pathlib import Path

FRONTMATTER_RE = re.compile(r"^---\n(.*?)\n---\n(.*)$", re.S)
TOOLS_HEADER_RE = re.compile(r"^tools:\s*$")
TOOL_ITEM_RE = re.compile(r"^\s+-\s+(.+?)\s*$")
KEY_RE = lambda k: re.compile(rf"^{k}:\s")


def translate(src: str) -> str:
    m = FRONTMATTER_RE.match(src)
    if not m:
        return src  # no frontmatter — leave as-is

    fm, body = m.group(1), m.group(2)
    lines = fm.split("\n")
    out: list[str] = []
    has_mode = False
    i = 0
    while i < len(lines):
        line = lines[i]
        if KEY_RE("name").match(line):
            i += 1
            continue
        if KEY_RE("model").match(line):
            i += 1
            continue
        if TOOLS_HEADER_RE.match(line):
            names: list[str] = []
            j = i + 1
            while j < len(lines):
                tm = TOOL_ITEM_RE.match(lines[j])
                if not tm:
                    break
                names.append(tm.group(1))
                j += 1
            out.append("tools:")
            for n in names:
                out.append(f"  {n.lower()}: true")
            i = j
            continue
        if KEY_RE("mode").match(line):
            has_mode = True
        out.append(line)
        i += 1

    if not has_mode:
        out.insert(0, "mode: subagent")

    return "---\n" + "\n".join(out) + "\n---\n" + body


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: translate-agent.py <input.md> <output.md>", file=sys.stderr)
        return 2
    src_path = Path(sys.argv[1])
    dst_path = Path(sys.argv[2])
    dst_path.write_text(translate(src_path.read_text()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
