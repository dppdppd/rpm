# Project: pm — Claude Code Plugin

Project-management layer for LLM-assisted development. Provides
`/pm:*` slash commands for session lifecycle, doc auditing, task
tracking, and deep research.

## Layout
- `commands/` — slash commands (`init`, `session-start`, `session-end`,
  `audit`, `pm`)
- `agents/` — subagents (currently `audit-scanner.md`)
- `hooks/` — `hooks.json` + `session-start-reminder.sh`
- `skills/` — `deep-research/`
- `.claude-plugin/` — `plugin.json` + `marketplace.json`
- `plugin.json` — top-level plugin manifest (mirrored in
  `.claude-plugin/plugin.json`)
- `command-version/` — historical/archived command snapshots; **not
  loaded by the plugin**, do not treat as live source
- `docs/pm/` — PM context, log, reviews, progress, tasks

## Editing the plugin
- Commands are pure markdown with YAML frontmatter (`description`,
  `argument-hint`, `allowed-tools`)
- After meaningful changes, bump `version` in **both** `plugin.json`
  and `.claude-plugin/plugin.json` — they must match
- No build, test, or lint toolchain. Verify changes by re-installing
  the plugin and running the command in a real Claude Code session.
- Recent commit style: short conventional-ish prefixes (`chore:`,
  `audit:`, `Rename …`). One commit per deliverable.

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
