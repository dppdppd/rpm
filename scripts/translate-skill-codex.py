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


def codex_next_body(body: str) -> str:
    """Rewrite Claude /loop phrasing into Codex directive language."""
    replacements = [
        ("# /next", "# rpm:next"),
        (
            "A normal direct `/next` turn should end by",
            "A normal direct `rpm:next` turn should end by",
        ),
        (
            "clarify what should be next. A looped `/next` turn must not expect user\n"
            "input;",
            "clarify what should be next. An autonomous Codex directive must not\n"
            "expect user input;",
        ),
        (
            "expect user input; it dispatches only unambiguous work and otherwise idles until the\n"
            "loop-exhausted guard stops it.",
            "expect user input; it dispatches only unambiguous work and otherwise\n"
            "idles until the loop-exhausted guard stops it.",
        ),
        (
            "loop-exhausted guard stops it. **Never loops internally.** Wrap with\n"
            "`/loop /next` for self-paced execution.",
            "loop-exhausted guard stops it. **Never loops internally.** For\n"
            "self-paced execution, use a directive such as\n"
            "`do rpm:next until blocked`.",
        ),
        (
            "/next        — one orchestrator step (use `/loop /next` for autonomous mode)",
            "rpm:next     — one orchestrator step; for autonomous mode, ask `do rpm:next until blocked`",
        ),
        ("/next status — show in-flight", "rpm:next status — show in-flight"),
        (
            "Infer loop mode when the current invocation is visibly part of\n"
            "`/loop /next`, an unattended dynamic loop, or repeated automatic\n"
            "invocation.",
            "Infer autonomous directive mode when the current invocation is visibly\n"
            "part of a Codex directive such as `do rpm:next until blocked`, an\n"
            "unattended dynamic run, or repeated automatic invocation.",
        ),
        (
            "unattended dynamic run, or repeated automatic invocation. Otherwise treat it as direct interactive mode.",
            "unattended dynamic run, or repeated automatic invocation.\n"
            "Otherwise treat it as direct interactive mode.",
        ),
        (
            "- **Loop mode** must not ask for input. If there is no unambiguous\n"
            "  action,",
            "- **Autonomous directive mode** must not ask for input. If there is no\n"
            "  unambiguous action,",
        ),
        (
            "unambiguous action, log `idle` with the reason and stop. After 3 consecutive idle\n"
            "  ticks,",
            "unambiguous action, log `idle` with the reason and stop. After 3\n"
            "  consecutive idle ticks,",
        ),
        (
            "when loop mode has no\n"
            "unambiguous next action.",
            "when autonomous directive mode has no unambiguous next action.",
        ),
        (
            "when autonomous directive mode has no unambiguous next action.",
            "when autonomous directive mode has no\n"
            "unambiguous next action.",
        ),
        ("   - Loop mode:", "   - Autonomous directive mode:"),
        (
            "   - Autonomous directive mode: do not ask again. Log `idle` with rationale",
            "   - Autonomous directive mode: do not ask again. Log `idle` with\n"
            "     rationale",
        ),
        (
            "   - Autonomous directive mode: log `idle` with the ambiguity, then stop or exhaust.",
            "   - Autonomous directive mode: log `idle` with the ambiguity, then\n"
            "     stop or exhaust.",
        ),
        (
            "Idle is for loop-mode ambiguity or waiting on in-flight work, not for a",
            "Idle is for autonomous directive ambiguity or waiting on in-flight work, not for a",
        ),
        (
            "when task selection is unclear. In loop mode, never ask; log idle and\n"
            "let the 3-idle threshold stop runaway autonomous loops. The user can\n"
            "resume by running `/next` directly; the next invocation reads the log",
            "when task selection is unclear. In autonomous directive mode, never ask; log idle and\n"
            "let the 3-idle threshold stop runaway autonomous runs. The user can\n"
            "resume by asking for `rpm:next` directly; the next invocation reads the log",
        ),
        ("`/next` itself is a single", "`rpm:next` itself is a single"),
        (
            "Does not pick up tactical user requests — `/next` is for unattended",
            "Does not pick up tactical user requests — `rpm:next` is for unattended",
        ),
        ("job. `/next` only reads.", "job. `rpm:next` only reads."),
        ("the next `/next` tick picks", "the next `rpm:next` tick picks"),
        ("Looped run with mechanical", "Autonomous Codex directive run with mechanical"),
        ("$ /loop /next", "User directive: do rpm:next until blocked"),
        ("Looped run with no", "Autonomous Codex directive run with no"),
        ("loop mode will not ask", "autonomous directive mode will not ask"),
    ]
    for old, new in replacements:
        body = body.replace(old, new)
    return body


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
        if key_match and key_match.group(1) == "description" and skill_name == "next":
            line = (
                "description: One-step rpm orchestrator. Runs preflight maintenance, "
                "then either starts the next obvious backlog action or asks for "
                "clarification when direct use leaves no clear next task. Designed "
                "for Codex directives such as `do rpm:next until blocked` — never "
                "loops internally. In autonomous directive mode it never waits for "
                "input; it dispatches only unambiguous work and otherwise idles or "
                "exhausts after 3 idle ticks. Use when the user wants the session "
                "to autonomously work the rpm backlog."
            )
        out.append(line)
        i += 1

    if skill_name:
        body = body.replace(
            "${CLAUDE_SKILL_DIR}/scripts/",
            f"{CODEX_PLUGIN_ROOT}/skills/{skill_name}/scripts/",
        )
    body = body.replace("${CLAUDE_PLUGIN_ROOT}", CODEX_PLUGIN_ROOT)
    body = body.replace("/.claude-plugin/plugin.json", "/.codex-plugin/plugin.json")
    if skill_name == "next":
        body = codex_next_body(body)

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
