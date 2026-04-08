## Project Summary

`pm` is a Claude Code plugin (v1.0.4) that provides a project-management
layer for LLM-assisted development: session lifecycle commands, doc
auditing, task tracking, and deep research. It's pure markdown +
shell — no build, test, or lint toolchain. Solo author (`dppdppd`).
Stage: actively iterating on command surface; recently consolidated
audit commands and renamed `pm` → `howto` → `guide` → settled shape.

The repo dogfoods its own `/pm:*` commands, so changes to the plugin
should be evaluated by re-running them in a real Claude Code session.

## Key Files

| What | Where |
|------|-------|
| Plugin manifest | `plugin.json`, `.claude-plugin/plugin.json` |
| Marketplace manifest | `.claude-plugin/marketplace.json` |
| Slash commands | `commands/*.md` |
| Subagents | `agents/*.md` (currently `audit-scanner.md`) |
| Hooks | `hooks/hooks.json`, `hooks/session-start-reminder.sh` |
| Skills | `skills/deep-research/` |
| Archived command snapshots | `command-version/` (not loaded by plugin) |
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
3. **Version sync** — `plugin.json` and `.claude-plugin/plugin.json`
   carry the same version after edits.
4. **Archive hygiene** — `command-version/` is historical; flag if it
   contradicts current commands in a way that could mislead a reader.
5. **Hook reliability** — `session-start-reminder.sh` runs every
   session start; failures here block onboarding.
6. **No ADR ceremony** — user has rejected ADR scaffolding; do not
   propose adding ADR templates or directories.

## Prior Findings

| Date | Key Finding |
|------|-------------|
| 2026-04-08 | `/pm:init` ran on plugin's own repo. ADR scaffolding removed from `commands/init.md` per user direction. |
