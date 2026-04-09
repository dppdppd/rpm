# claude-plugin-pm — Present State

## Project Status
- **Current phase**: skills-first migration complete at 2.0.0 (legacy `commands/` deleted). 2.1.0 extends `scan.sh` with `specs_inventory` + `pm_docs_staleness` checks and adds a new `/pm:audit quick` target — a fast scan-only tier between session-end and the full `pm:auditor` documents scan. Next: dogfood 2.1.0 on a real project (volta is the natural target).
- **Last updated**: 2026-04-09
- **Version**: 2.1.0

## Completed Work
- 2026-04-09 — **scan.sh inventory/staleness checks + audit quick mode** (2.1.0): extended `skills/session-end/scripts/scan.sh` with `specs_inventory` (recursive search over specs/, spec/, docs/specs/, docs/spec/ against PRESENT.md mentions) and `pm_docs_staleness` (log/tracker/inventory files under docs/ and docs/pm/ with days-since-last-commit). Added `/pm:audit quick` as a new audit target — runs scan.sh only via cross-skill `${CLAUDE_PLUGIN_ROOT}` reference, no `pm:auditor` subagent, for fast on-demand drift checks between session-ends. Motivated by the volta session trawl: these are the exact drift patterns the commands-era auditor was catching that scan.sh previously missed. Dogfooded against volta (total=107 listed=106 unlisted=1, 2 loose log files detected). `7242f34`.
- 2026-04-09 — **skills migration phase 6: legacy `commands/` removed** (2.0.0): deleted all 6 `commands/*.md` files. `CLAUDE.md` Layout swept for stale `commands/` references; `PM.md` Project Summary + Key Files + Focus Areas rewritten to describe the skills-first state. `command-version/` dispatcher untouched (frozen per Phase 5). Verified via scan.sh — 0 broken refs. Dogfood cycle the phase was gated on = the 2026-04-09 session that shipped it. `d85c66a`.
- 2026-04-09 — **session-end parallelization + scan.sh bundle + audit LLM-workflow dimension** (1.0.23): three coupled changes. (1) `skills/session-end/scripts/scan.sh` bundled — six sections in key=value, auto-injected via `!${CLAUDE_SKILL_DIR}/scripts/scan.sh` so output is in context before Phase 1 begins, zero tool calls for the scan. Tightened to zero false-positive broken_refs. (2) Session-end Phase 1 + 2 restructured for parallel reads/writes; 2-3× wall-clock speedup on the analyze+apply block. (3) `skills/audit/project-mode.md` gained "repetitive LLM work → scripts" as a Phase 1 probe + Phase 4 dimension. Closes Task 4 from the 2026-04-09 plan. `06c7d5d`.
- 2026-04-09 — **skills migration phase 5: `command-version/` frozen** (1.0.22): chose option B — no ongoing mirror maintenance. `CLAUDE.md` Layout/Editing sections rewritten; `skills/` is now primary surface. `command-version/pm.md` gets a legacy-install header note. `3b37c88`.
- 2026-04-09 — **skills migration phase 4: session trio** (1.0.21): `session-start`, `session-update`, `session-end` all shipped as skills. `session-end` has a pre-flight auto-invocation gate so Claude can proactively recommend wrapping up on long contexts without auto-committing. `61eca6b`.
- 2026-04-09 — **skills migration phase 3: `/pm:audit` decomposed** (1.0.20): split into `skills/audit/SKILL.md` (routing + Documents mode) + `findings-menu.md` + `project-mode.md`. `disable-model-invocation: true`. `f8b0b1b`.
- 2026-04-09 — **skills migration phase 2: `/pm:init`** (1.0.19): migrated to `skills/init/SKILL.md` with `disable-model-invocation: true` (destructive scaffolder). `9cf1438`.
- 2026-04-09 — **skills migration phase 1: `/pm:pm`** (1.0.18): first migration. `skills/pm/SKILL.md` with auto-invocation on pm-overview questions. Legacy `commands/pm.md` kept for rollback; skill takes precedence per unification docs. `a7df55b`.
- 2026-04-09 — **second `/pm:audit project` run**: 8 findings, plan + report saved. First project-target audit after the 1.0.17 scan-gap fix — validated that `pm:auditor` feeds Phase 4 as designed. User picked C (commit to phased migration) for S1. See `docs/pm/reviews/2026-04-09.md`. `c39cf0c`.
- 2026-04-09 — **mechanical audit findings executed** (`f972ab8` + `28f337d`): PM.md version-sync contradiction fixed, `init.md` stale depth-menu text replaced, `CLAUDE.md` read-first guardrail added, `auditor.md` off-schema frontmatter cleaned up, ccpm disambiguation note added to `pm.md` + mirror.
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
