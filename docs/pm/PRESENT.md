# claude-plugin-pm — Present State

## Project Status
- **Current phase**: iterating on `/pm:audit` menu UX
- **Last updated**: 2026-04-08

## Completed Work
- 2026-04-08 — `/pm:audit` menus simplified to compact numbered lists; AskUserQuestion removed
- 2026-04-08 — `/pm:audit` gains **Shared: Findings Menu** (later simplified); Light + Standard modes route findings through it
- 2026-04-08 — light audit run on self: 5 findings surfaced (stale docs refs, packages/ template residue, casing mismatch), all fixed in-session; depth-selector menu picked up `Output` column in place of `Writes?`/`Cost`
- 2026-04-08 — `command-version/` (non-plugin install variant) brought in sync with the current plugin command surface
- marketplace manifest added, stale docs cleaned up
- `howto` command renamed to `guide`, description improved
- `pm:pm` command renamed to `pm:howto`
- audit commands consolidated into a single `/pm:audit` with
  recency-based depth recommendation
- `init`/`audit`/`audit-heavy` moved from skills to commands
- `/pm:init` run on this repo: scaffolded `docs/pm/`, `CLAUDE.md`,
  `progress/STATUS.md`, `TASKS.org`. ADR scaffolding stripped from
  the plugin's own `commands/init.md`.

## Active Specs
_(none — plugin uses no spec workflow)_

## Known Issues
_(none open)_
