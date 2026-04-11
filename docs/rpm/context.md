# rpm — rpm Context

Injected at session start. Keep under 30 lines.

## Project Summary
Claude Code plugin (pure markdown + bash) that tracks what shipped,
what's next, and what's drifting across LLM-assisted dev sessions.
Solo developer. Published via git subtree split to GitHub.

## Key Files
| What | Where |
|------|-------|
| Plugin manifest | `plugin/.claude-plugin/plugin.json` |
| Skills | `plugin/skills/{name}/SKILL.md` |
| Hooks | `plugin/hooks/` + `hooks.json` |
| Agent | `plugin/agents/auditor.md` |
| README | `plugin/README.md` |
| Plugin CLAUDE.md | `plugin/CLAUDE.md` |

## Focus Areas for Review
- Skill instructions producing correct LLM behavior
- Hook reliability (bash scripts, no LLM tokens)
- CLAUDE.md staying under 150 lines
- Tracker file consistency across renames

## Tasks
New tasks in `future/tasks.org`: one short sentence + link to
`future/<date>-<slug>.md` with details. Never inline task details
in tasks.org itself.

## Prior Findings
| Date | Key Finding |
|------|-------------|
| 2026-04-08 | command-version drift; CLAUDE.md effectiveness baseline |
| 2026-04-09 | scan gap fix validation; project-mode protocol refinement |
| 2026-04-10 | docs/pm→docs/rpm rename gap in hooks; skills migration |
| 2026-04-11 | stale `init`/`/pm:` refs in CLAUDE.md + memory; empty audit log backfilled |
