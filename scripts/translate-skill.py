#!/usr/bin/env python3
"""
Translate a Claude Code skill SKILL.md file to an opencode command.

Claude Code skills and opencode commands share the body format
($ARGUMENTS expansion, ! `bash ...` shell output injection), but
their recognized frontmatter differs. This converter:

- Drops `name:` (opencode derives the command name from the filename)
- Drops `allowed-tools:` (opencode uses a different permission model)
- Drops `argument-hint:` (opencode doesn't recognize it)
- Drops `disable-model-invocation:` (Claude-Code-specific)
- Keeps `description:` verbatim, including multi-line forms
  (block scalar `>` / quoted)

Body (everything after the closing `---`) is copied with one
rewrite: `${CLAUDE_SKILL_DIR}` references are rewritten to
`${CLAUDE_PLUGIN_ROOT}/skills/<name>` so a single env var
(injected by the opencode plugin's `shell.env` hook) covers both
Claude Code path contracts. `$ARGUMENTS`, `$1`, `$2`, and
`` !`bash ...` `` blocks are preserved unchanged.

`${CLAUDE_PLUGIN_ROOT}` itself is left intact — the opencode TS
plugin injects it via `shell.env` for every shell invocation.

Usage: translate-skill.py <input.md> <output.md>
"""

import re
import sys
from pathlib import Path

FRONTMATTER_RE = re.compile(r"^---\n(.*?)\n---\n(.*)$", re.S)
DROP_KEYS = {
    "name",
    "allowed-tools",
    "argument-hint",
    "disable-model-invocation",
}


def translate(src: str, skill_name: str) -> str:
    m = FRONTMATTER_RE.match(src)
    if not m:
        return src

    fm, body = m.group(1), m.group(2)
    lines = fm.split("\n")
    out: list[str] = []
    i = 0
    while i < len(lines):
        line = lines[i]
        key_match = re.match(r"^([A-Za-z][A-Za-z0-9_-]*):(\s|$)", line)
        if key_match and key_match.group(1) in DROP_KEYS:
            # Drop the key line and any continuation (indented or
            # block-scalar folded/literal) lines that belong to it.
            i += 1
            while i < len(lines) and (
                lines[i].startswith(" ") or lines[i].startswith("\t")
            ):
                i += 1
            continue
        out.append(line)
        i += 1

    # Rewrite ${CLAUDE_SKILL_DIR} → ${CLAUDE_PLUGIN_ROOT}/skills/<name>
    # so the opencode plugin's single shell.env injection covers
    # both path contracts. ${CLAUDE_PLUGIN_ROOT} itself is left alone.
    body = re.sub(
        r"\$\{CLAUDE_SKILL_DIR\}",
        f"${{CLAUDE_PLUGIN_ROOT}}/skills/{skill_name}",
        body,
    )

    return "---\n" + "\n".join(out).strip() + "\n---\n" + body


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: translate-skill.py <input.md> <output.md>", file=sys.stderr)
        return 2
    src_path = Path(sys.argv[1])
    dst_path = Path(sys.argv[2])
    skill_name = dst_path.stem  # <name>.md → <name>
    dst_path.write_text(translate(src_path.read_text(), skill_name))
    return 0


if __name__ == "__main__":
    sys.exit(main())
