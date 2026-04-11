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
## Tasks
When the user mentions work to do later, capture it as a task.
When you suggest work, offer to add it as a task.
When the user shifts to a new task and current context has little carry-over value,
suggest /session-end first so trackers stay current.
Format: one-liner in `future/tasks.org` + detail in `future/<date>-<slug>.md`.

## Prior Findings
See `docs/rpm/past/log.md` Audit History for full list.
