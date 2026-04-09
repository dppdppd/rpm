# Project: pm — Claude Code Plugin

Project-management layer for LLM-assisted development. Provides
`/pm:*` slash commands for session lifecycle, doc auditing, task
tracking, and deep research.

## Layout
- `commands/` — slash commands (`init`, `session-start`,
  `session-update`, `session-end`, `audit`, `pm`)
- `agents/` — subagents (currently `auditor.md`)
- `hooks/` — `hooks.json` + `session-start-reminder.sh`
- `skills/` — `deep-research/` (skill, **not a slash command** — no
  `/pm:deep-research`; auto-triggers on research questions. Edit the
  skill, not `commands/`.)
- `.claude-plugin/` — canonical plugin manifest (`plugin.json`) and
  `marketplace.json`
- `command-version/` — **non-plugin install variant** (drop into
  `~/.claude/`): monolithic `pm.md` dispatcher routing to bodies in
  `pm-commands/`. Maintained in parallel with `commands/` — keep in
  sync when editing commands
- `docs/pm/` — PM context, log, reviews, past/present/future trackers

## Editing the plugin
- Commands are pure markdown with YAML frontmatter (`description`,
  `argument-hint`, `allowed-tools`)
- After meaningful changes, bump `version` in
  `.claude-plugin/plugin.json`
- No build, test, or lint toolchain. Verify changes by re-installing
  the plugin and running the command in a real Claude Code session.
- Recent commit style: short conventional-ish prefixes (`chore:`,
  `audit:`, `Rename …`). One commit per deliverable.
- When editing `commands/*.md`, mirror the change into
  `command-version/pm-commands/*.md` (strip frontmatter; rewrite
  `/pm:foo` refs as `/pm foo` dispatcher style).
- Dispatcher lacks the subagent and skill mechanisms. When a plugin
  command invokes a subagent (`pm:auditor`) or skill
  (`deep-research`), the dispatcher mirror must inline the spec
  inside the command body instead. Pattern examples:
  `command-version/pm-commands/audit.md` (Documents scan inline),
  `command-version/pm-commands/deep-research.md` (skill inlined).

## Workflow
- Plan → edit → verify → commit. No spec ceremony for command-sized
  changes.
- Keep README, `commands/pm.md`, and individual command bodies in
  sync when renaming or removing commands — they all describe the
  same surface.
- Update `docs/pm/PM-LOG.md` after audits or noteworthy sessions.
- Use `/pm:session-start` at the start of a real work session to
  load context and pick a task.

## Guardrails
- 3 attempts max to fix an issue, then STOP and report
- Same error twice → change strategy, do not retry blindly
- Ask before: renaming user-facing commands, changing command
  argument shape, restructuring directories, adding new top-level
  scaffolding to what `/pm:init` generates
- **No ADRs.** This project does not use Architecture Decision
  Records — do not propose ADR templates or directories.
