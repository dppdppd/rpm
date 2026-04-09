## Project Summary

`pm` is a Claude Code plugin that provides a project-management
layer for LLM-assisted development: session lifecycle commands, doc
auditing, task tracking, and deep research. It's pure markdown +
shell — no build, test, or lint toolchain. Solo author (`dppdppd`).
Stage: actively iterating on command surface — audit recently
restructured into two targets (`documents`, `project`), with routine
doc-drift folded into `/pm:session-end`.

Current command surface: `/pm:pm` (entry), `/pm:init`,
`/pm:session-start`, `/pm:session-update`, `/pm:session-end`,
`/pm:audit documents`, `/pm:audit project`. Plus a `deep-research`
skill (no slash command — auto-triggers on research questions).

The repo dogfoods its own `/pm:*` commands, so changes to the plugin
should be evaluated by re-running them in a real Claude Code session.

## Key Files

| What | Where |
|------|-------|
| Plugin manifest | `.claude-plugin/plugin.json` (canonical; no root mirror) |
| Marketplace manifest | `.claude-plugin/marketplace.json` |
| Slash commands | `commands/*.md` |
| Subagents | `agents/*.md` (currently `auditor.md`) |
| Hooks | `hooks/hooks.json`, `hooks/session-start-reminder.sh` |
| Skills | `skills/deep-research/` |
| Non-plugin install variant | `command-version/` (dispatcher + pm-commands/, kept in sync with `commands/`) |
| README | `README.md` |
| PM context | `docs/pm/PM.md` (this file) |
| PM history | `docs/pm/PM-LOG.md` |

## Focus Areas for Review

This is a solo plugin project with no automated tests, so reviews
should emphasize:

1. **Command coherence** — frontmatter (`description`, `argument-hint`,
   `allowed-tools`) consistent across `commands/*.md`; user-facing
   names match what's referenced in README, `pm.md`, and other commands.
2. **Documentation drift** — README, `commands/pm.md`, and individual
   command bodies all describe the same surface. Check after every
   command rename or removal.
3. **Version sync** — bump `version` in `.claude-plugin/plugin.json`
   after meaningful changes. No root mirror.
4. **`command-version/` sync** — non-plugin install variant maintained
   in parallel with `commands/`. Flag any drift between the two trees.
5. **Hook reliability** — `session-start-reminder.sh` runs every
   session start; failures here block onboarding.
6. **No ADR ceremony** — user has rejected ADR scaffolding; do not
   propose adding ADR templates or directories.

## Prior Findings

| Date | Key Finding |
|------|-------------|
| 2026-04-08 | `/pm:init` ran on plugin's own repo. ADR scaffolding removed from `commands/init.md` per user direction. |
| 2026-04-08 | audit standard — PRESENT.md staleness cleaned, audit.md Heavy mode slash syntax fixed, deep-research skill/command distinction noted in CLAUDE.md. Also: `auditor` rename + findings menu format update (bold quick-phrase headings). |
