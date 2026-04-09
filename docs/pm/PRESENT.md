# claude-plugin-pm — Present State

## Project Status
- **Current phase**: audit restructure shipped — split into `/pm:audit documents` + `/pm:audit project`, routine drift folded into `/pm:session-end`; project mode now runs mechanical scan alongside consultant review
- **Last updated**: 2026-04-08
- **Version**: 1.0.17

## Completed Work
- 2026-04-08 — **project-mode scan gap closed** (1.0.17): `/pm:audit project` Phase 1 now launches `pm:auditor` in the background (plugin version) / runs the Documents scan inline (dispatcher version) so VALIDITY/COHERENCE/tracker findings become Phase 4 evidence. Closes the gap where a `project` run could silently miss broken refs that a `documents` run would catch.
- 2026-04-08 — **audit restructure** (1.0.16): `/pm:audit` split into `documents` (doc + CLAUDE.md + memory + session-drift scan via `pm:auditor`) and `project` (full consultant review). Dropped `light` as a separate mode — its cheap checks are now automatic in `/pm:session-end` Phase 1e. Removed depth menu and recency recommendation. Mirror synced.
- 2026-04-08 — session marker relocated to `docs/pm/~pm-session-active` (no more `mkdir -p`); added `.gitignore` entry. Plugin → 1.0.15 (`e65ff57`).
- 2026-04-08 — README gains "What a session looks like" dry-run example; plugin → 1.0.14 (`c2475ce`).
- 2026-04-08 — first `/pm:audit heavy` run on self: 8 findings, all executed in-session. See `docs/pm/reviews/2026-04-08.md` and `…-plan.md`.
- 2026-04-08 — new `/pm:session-update` command (mid-session checkpoint, competitive gap vs `claude-sessions`). Propagated through all command tables.
- 2026-04-08 — `/pm:audit` Heavy mode restructured into 5 phases (Investigate → Inward Research → Outward Research → Analyze → Refine). Outward research now REQUIRED; added `Competitive Gaps` analyze dimension.
- 2026-04-08 — `agents/auditor.md` is now the single source of truth for the Standard-mode scan spec; `commands/audit.md` Standard Phase 1 invokes `pm:auditor` by name.
- 2026-04-08 — native `TaskCreate/TaskUpdate/TaskList` integrated with `FUTURE.org` as source of truth; `session-start` hydrates, `session-end` reconciles.
- 2026-04-08 — root `plugin.json` mirror deleted; `.claude-plugin/plugin.json` is sole canonical manifest. Added `license: MIT`, `keywords`. `LICENSE` file created at repo root.
- 2026-04-08 — `deep-research` output path moved to `docs/pm/research/<topic-slug>/`.
- 2026-04-08 — README install instructions rewritten with dev / persistent-local / "when published" blocks.
- 2026-04-08 — `/pm:audit` menus simplified to compact numbered lists; AskUserQuestion removed.
- 2026-04-08 — `/pm:audit` gains **Shared: Findings Menu**; Light + Standard modes route findings through it.
- 2026-04-08 — light audit run on self: 5 findings surfaced, all fixed in-session.
- 2026-04-08 — `command-version/` (non-plugin install variant) brought in sync with the current plugin command surface.
- 2026-04-08 — `agents/audit-scanner.md` renamed to `agents/auditor.md`.
- 2026-04-08 — audit standard run on self: PRESENT.md cleaned up, user-facing docs corrected to stop presenting `/pm:deep-research` as a slash command (deep-research is a skill — no command file, no slash command). Fixed in `README.md`, `commands/pm.md`, `CLAUDE.md`, `docs/pm/PM.md`, `skills/deep-research/SKILL.md`, `commands/audit.md`.
- marketplace manifest added, stale docs cleaned up
- audit commands consolidated into a single `/pm:audit` with
  recency-based depth recommendation
- `/pm:init` run on this repo: scaffolded `docs/pm/` tree and
  `CLAUDE.md`. ADR scaffolding stripped from the plugin's own
  `commands/init.md`.

## Active Specs
_(none — plugin uses no spec workflow)_

## Known Issues
- **Session marker disappeared once at `/exit`→resume boundary** — observed 2026-04-08 between marker creation at 17:16 and resume at 17:21. Marker recreated and persisted fine through the rest of the session. Root cause unknown. Tracked in `FUTURE.org`.
