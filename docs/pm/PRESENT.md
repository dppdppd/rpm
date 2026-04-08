# claude-plugin-pm — Present State

## Project Status
- **Current phase**: Iterating on command surface (post-1.0.4)
- **Last updated**: 2026-04-08

## Completed Work
- 2026-04-08 — `command-version/` (non-plugin install variant) brought in sync with the current plugin command surface
- v1.0.4 — bump, marketplace manifest added, stale docs cleaned up
- v1.0.3 — `howto` command renamed to `guide`, description improved
- v1.0.2 — `pm:pm` command renamed to `pm:howto`
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
