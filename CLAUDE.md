# Project: rpm — Relentless Project Manager

Claude Code plugin that tracks what shipped, what's next, and what's
drifting across LLM-assisted dev sessions.

## Commands
- Build: n/a (no build toolchain)
- Test: `bash plugin/tests/run.sh` (bats suite, covers hooks)
- Lint: shellcheck on `plugin/hooks/*.sh` (CI runs this)
- Publish plugin: `git subtree split --prefix=plugin -b plugin-only && git push plugin plugin-only:master --force`
- Push dev tree: `git push dev master` (full repo incl. docs/rpm, reviews, specs)

## Architecture
- `plugin/` — publishable plugin root (skills, agents, hooks, tests)
- `plugin/skills/` — command surface (audit, init-rpm, deep-research, rpm, session-end, tasks)
- `plugin/agents/` — subagents (auditor.md)
- `plugin/hooks/` — lifecycle hooks (session-start, session-end, stop-learn, context-monitor, pre-compact, post-compact, handoff-validator, task-capture)
- `plugin/tests/` — bats suite + helpers (fixtures built on the fly)
- `plugin/.github/workflows/` — CI (bats + shellcheck on push/PR)
- `docs/rpm/` — PM state (context.md, past/, present/, future/, reviews/)
- `docs/spec/` — feature specs

## Workflow
Plan → edit → verify → commit. No spec ceremony for skill-sized changes.

- Keep README, `plugin/skills/rpm/SKILL.md`, and skill bodies in sync
  when renaming or removing commands
- Session context auto-loads via SessionStart hook
- One commit per deliverable

## Guardrails
- 3 attempts max to fix an issue, then STOP and report
- Same error twice → change strategy
- Ask before: renaming commands, changing argument shapes, restructuring dirs
- Read command body + subagents end-to-end before proposing renames
- No ADRs — do not propose ADR templates or directories
- Parallel Bash calls cancel each other on error — bundle into a single script
