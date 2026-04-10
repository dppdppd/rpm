## Project Summary

`pm` is a Claude Code plugin — your AI product manager. It tracks
what shipped, what's next, and what's drifting: session lifecycle,
doc auditing, task tracking, and deep research — all via hooks and
auto-loadable skills. Pure markdown + bash; no build, test, or lint toolchain.
Solo author (`dppdppd`). Stage: skills-first command surface
(migrated from legacy `commands/*.md` in April 2026; legacy
directory removed at 2.0.0). Deterministic ops (drift scan, git
state) bundled as bash scripts under `skills/<name>/scripts/` at
zero LLM token cost.

Current command surface: `/rpm:pm` (entry), `/rpm:init`,
`/rpm:session-end`, `/rpm:audit documents`, `/rpm:audit project`.
Plus a `deep-research` skill (no slash command — auto-triggers on
research questions). Session context auto-loads via SessionStart
hook; mid-session checkpoints fire automatically before context
compaction (PreCompact hook).

The repo dogfoods its own `/rpm:*` commands, so changes to the plugin
should be evaluated by re-running them in a real Claude Code session.

## Key Files

| What | Where |
|------|-------|
| Plugin manifest | `.claude-plugin/plugin.json` (canonical) |
| Marketplace manifest | `.claude-plugin/marketplace.json` |
| Skills (command surface) | `skills/<name>/SKILL.md` + supporting files |
| Bundled scripts | `skills/<name>/scripts/*.sh` (e.g. `skills/session-end/scripts/scan.sh`) |
| Subagents | `agents/*.md` (currently `auditor.md`) |
| Hooks | `hooks/hooks.json` + lifecycle scripts (auto-start, compact guard, learn capture, session nudge) |
| Non-plugin install variant | `command-version/` (legacy dispatcher, frozen) |
| README | `README.md` |
| PM context | `docs/rpm/RPM.md` (this file) |
| PM history | `docs/rpm/RPM-LOG.md` |

## Focus Areas for Review

This is a solo plugin project with no automated tests, so reviews
should emphasize:

1. **Skill coherence** — frontmatter (`name`, `description`,
   `argument-hint`, `allowed-tools`, `disable-model-invocation`,
   `user-invocable`, etc.) consistent across `skills/*/SKILL.md`;
   user-facing slash command names match what's referenced in
   README, `skills/rpm/SKILL.md`, and other skills.
2. **Documentation drift** — README, `skills/rpm/SKILL.md`, and
   individual skill bodies all describe the same surface. Check
   after every skill rename or removal.
3. **Version sync** — bump `version` in `.claude-plugin/plugin.json`
   after meaningful changes. No root mirror.
4. **`command-version/` is frozen** — legacy dispatcher install, not
   maintained. Flag only regressions within `command-version/` itself.
5. **Hook reliability** — `session-start-auto.sh` runs every
   session start; failures here block context loading.
6. **No ADR ceremony** — user has rejected ADR scaffolding; do not
   propose adding ADR templates or directories.

## Prior Findings

| Date | Key Finding |
|------|-------------|
| 2026-04-08 | `/rpm:init` ran on plugin's own repo. ADR scaffolding removed from init per user direction. |
| 2026-04-08 | audit standard — PRESENT.md staleness cleaned, audit.md Heavy mode slash syntax fixed, deep-research skill/command distinction noted in CLAUDE.md. Also: `auditor` rename + findings menu format update (bold quick-phrase headings). |
