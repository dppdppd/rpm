# Project: pm — Claude Code Plugin

Project-management layer for LLM-assisted development. Provides
`/pm:*` slash commands for session lifecycle, doc auditing, task
tracking, and deep research.

## Layout
- `skills/` — command surface (`pm`, `init`, `audit`,
  `session-start`, `session-update`, `session-end`, `deep-research`);
  each is a directory with `SKILL.md` plus optional supporting files
- `agents/` — subagents (currently `auditor.md`, namespaced
  `pm:auditor`)
- `hooks/` — `hooks.json` + `session-start-reminder.sh`
- `.claude-plugin/` — canonical plugin manifest (`plugin.json`) and
  `marketplace.json`
- `command-version/` — **legacy dispatcher install, frozen.** Drop
  into `~/.claude/` as monolithic `pm.md` dispatcher. Not maintained.
- `docs/pm/` — PM context, log, reviews, past/present/future trackers

## Editing the plugin
- Primary surface is `skills/<name>/SKILL.md`. Frontmatter:
  `name`, `description`, optional `argument-hint`, `allowed-tools`,
  `disable-model-invocation`, `user-invocable`, `context`, etc.
- Bundle deterministic ops as bash scripts under
  `skills/<name>/scripts/` and invoke via `${CLAUDE_SKILL_DIR}`
  (see `skills/session-end/scripts/scan.sh` for the pattern).
- Auto-inject (`!…`) lines must use `bash "…"` wrapping:
  `!bash "${CLAUDE_SKILL_DIR}/scripts/foo.sh"`, not bare
  `!${CLAUDE_SKILL_DIR}/scripts/foo.sh`. The raw form expands
  to an absolute path that won't match `Bash(bash:*)` rules.
- After meaningful changes, bump `version` in
  `.claude-plugin/plugin.json`.
- No build, test, or lint toolchain. Verify changes by re-installing
  the plugin and running the skill in a real Claude Code session.
- Recent commit style: short conventional-ish prefixes (`chore:`,
  `audit:`, `pm:`). One commit per deliverable.

## Workflow
- Plan → edit → verify → commit. No spec ceremony for skill-sized
  changes.
- Keep README, `skills/pm/SKILL.md`, and individual skill bodies in
  sync when renaming or removing a slash command — they all describe
  the same surface.
- Update `docs/pm/PM-LOG.md` after audits or noteworthy sessions.
- Use `/pm:session-start` at the start of a real work session to
  load context and pick a task.

## Guardrails
- 3 attempts max to fix an issue, then STOP and report
- Same error twice → change strategy, do not retry blindly
- Ask before: renaming user-facing commands, changing command
  argument shape, restructuring directories, adding new top-level
  scaffolding to what `/pm:init` generates
- Read command body + referenced subagents/skills end-to-end before
  proposing any rename or regrouping
- **No ADRs.** This project does not use Architecture Decision
  Records — do not propose ADR templates or directories.

## WebFetch
Do not use WebFetch — it has no tool-level timeout and a hung
request stalls the entire session (anthropics/claude-code#34565).
Use `curl --max-time 30 -sL <url>` via Bash instead.
