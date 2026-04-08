# PM Log — pm plugin

Append-only history of PM audits, reviews, and session reviews.
Not loaded automatically — referenced from `docs/pm/PM.md` when needed.

## Audit History

- 2026-04-08 — audit light — 5 issues surfaced (2 high, 1 medium, 2 low), all fixed in-session
- 2026-04-08 — audit light — 4 surfaced, 4 fixed, 0 skipped

## Sessions Reviewed

_(none yet)_

## PM Notes

### 2026-04-08 — `/pm:init` run on plugin's own repo
- Detected EXISTING project, no `CLAUDE.md`, no prior `docs/pm/`.
- Scaffolded: `docs/pm/PM.md`, `docs/pm/PM-LOG.md`, `docs/pm/reviews/`,
  `docs/pm/PRESENT.md`, `docs/pm/FUTURE.org`, `docs/pm/past/`, `CLAUDE.md`.
- Skipped per user direction: spec template, ADR template.
- Edited `commands/init.md` to remove ADR scaffolding (CLAUDE.md
  template guardrail line, full ADR template section, scaling-notes
  reference). User explicitly said "delete ADRs from the plugin.
  they're not useful". Saved as feedback memory.
- `command-version/pm-commands/init.md` still contains ADR references
  but is an archived snapshot; left untouched (flag if user wants it
  swept too).

### 2026-04-08 — `command-version/` synced to plugin
- Confirmed `command-version/` is the **non-plugin install variant**
  (drop into `~/.claude/`): monolithic `pm.md` dispatcher routing to
  bodies in `pm-commands/`. Decision recorded after offering A/B/C.
- Rewrote `command-version/pm.md` dispatcher to reflect current
  command set (`init`, `audit` consolidated, `session start|end`,
  `deep-research`). Removed `audit (light|normal|heavy)` routing
  (now handled inside `audit.md` Step 0).
- Added `pm-commands/audit.md` (consolidated; replaces
  `audit-normal.md` + `audit-heavy.md`).
- Added `pm-commands/session-start.md`, `pm-commands/session-end.md`
  (previously inline in dispatcher).
- Renamed `research.md` → `deep-research.md` to match plugin.
- Stripped frontmatter from each subcommand body and replaced
  plugin-style `/pm:foo` references with dispatcher-style `/pm foo`.
- Updated `init.md` to drop ADR scaffolding (matches the plugin's
  active `commands/init.md`).
