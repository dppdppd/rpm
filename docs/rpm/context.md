# rpm — rpm Context

Injected at session start. Keep under 30 lines.

## Project Summary
Claude Code plugin (pure markdown + bash) tracking what shipped, next,
and drift across LLM sessions. Solo dev; published via git subtree split.

## Key Files
| What | Where |
|------|-------|
| Plugin manifest | `plugin/.claude-plugin/plugin.json` |
| Skills | `plugin/skills/{name}/SKILL.md` |
| Hooks | `plugin/hooks/` + `hooks.json` |
| Agent | `plugin/agents/auditor.md` |
| README | `plugin/README.md` |

## Focus Areas for Review
- Skill instructions producing correct LLM behavior
- Hook reliability (bash scripts, no LLM tokens)
- CLAUDE.md staying under 150 lines

## Tasks
- User mentions future work → capture as a task.
- You suggest deferrable work ("we could X later", "worth Y eventually", "follow up on Z") → STOP and ask "Add to the rpm backlog?" before moving on — don't just suggest and continue.
- User shifts to a new task with little carry-over → suggest /session-end first; one-liner in the rpm backlog (`future/tasks.org`) + detail in `future/<date>-<slug>.md`.

## Prior Findings
See `docs/rpm/past/log.md` Audit History.
