# rpm — Present State

## Project Status
- **Current phase**: Plugin restructured into `plugin/` subdirectory for subtree publishing. T6 (`once:true` nudge) completed. 1 finding deferred (T7: bash path scanner). 10 broken path refs in RPM.md from subdirectory move need fixing. Uncommitted: `command-version/` removal + CLAUDE.md update.
- **Last updated**: 2026-04-10
- **Version**: 2.2.0

## Completed Work
- 2026-04-10 — **once:true nudge hook + publish prep** (`dba0b58`): adopted `once: true` for UserPromptSubmit nudge hook, replacing manual flag-file system. Added homepage + repository to plugin.json. Created public GitHub repo dppdppd/rpm.
- 2026-04-10 — **plugin/ subdirectory restructure** (`e015ee8`, `7efeb92`): moved plugin into `plugin/` subdirectory for subtree publishing. Reverted complex source URL to simple form.
- 2026-04-10 — **audit project + 9 fixes**: third `/rpm:audit project`. Critical finding: `docs/pm/` → `docs/rpm/` rename broke 4 of 5 hooks. Fixed hooks, skill bodies (PM.md→RPM.md refs), marketplace.json, CLAUDE.md namespace, scan.sh path, project-mode.md WebFetch→curl, deep-research stale /pm ref, FUTURE.org marker name. Also: strengthened auditor gate in project-mode.md. Plan + report saved to `reviews/2026-04-10*`.
- 2026-04-10 — **README rewrite**: reframed around documentation alignment (not session statefulness). Competitive positioning vs claude-mem, gstack, cc-spex, ccpm, flow-next.
- 2026-04-10 — **rename to rpm** (`d443ba6`, `83020ea`): plugin renamed from pm to rpm (Relentless Product Manager). All command prefixes, skill directory, agent namespace, docs/pm/ → docs/rpm/ updated.
- 2026-04-10 — **hook-driven session lifecycle** (2.2.0, `c53f699`): 5 new hooks (SessionStart auto-inject, PreCompact checkpoint, PostCompact recovery, Stop learning capture, UserPromptSubmit nudge). Deleted session-start, session-update, and context-scouts skills. Added structured task deps (:ID:/:BLOCKED_BY:) with scan.sh validation. Competitive audit against 8 plugins informed feature priorities.
- 2026-04-10 — **session-end latency optimizations** (`f605ead`): pre-read today's past log in Phase 1b to eliminate hidden dependency; merge Phase 2 commit + Phase 3 presentation into one response; merge Phase 5 rm + handoff into one response. ~4 tool-call rounds instead of ~6.
- 2026-04-10 — **session-start scan.sh auto-inject** (2.1.3, `c17dbcf`): new `skills/session-start/scripts/scan.sh` bundles latest past-file lookup, git status/stash, and PRESENT.md drift check. Auto-injects before skill body loads, cutting session-start from ~5 sequential tool-call rounds to ~2. Rewrote SKILL.md to consume scan output and fire all reads in one parallel message.
- 2026-04-10 — **session-end UX improvements** (`b50423a`): Phase 3 action menu omits empty items and renumbers dynamically. Phase 4 Record findings uses a single numbered menu instead of mid-response questions. Phase 5 runs rm before handoff text. Added top-level "Response rules" block.
- 2026-04-10 — **CLAUDE.md auto-inject guidance** (`fb55c1a`): added rule that auto-inject `!…` lines must use `bash "…"` wrapping so expanded absolute paths match `Bash(bash:*)` permission rules.
- 2026-04-09 — **auto-inject + drift-check permission fixes** (2.1.2): root cause — `!${CLAUDE_SKILL_DIR}/scripts/scan.sh` expands to an absolute path that doesn't match any `Bash(...)` allow rule. Fix wraps the auto-inject in `bash "..."` so it matches the existing `Bash(bash:*)` permission (same shape `hooks/hooks.json` already uses). Applied in `skills/session-end/SKILL.md` (auto-inject + `allowed-tools` addition) and `skills/audit/SKILL.md` (the `/pm:audit quick` target's cross-skill auto-inject). Secondary fix: `skills/session-start/SKILL.md` drift-check split into two sequential `git log` calls because `LAST=$(…)` pipelines don't match `Bash(git log:*)`. **Dogfood-verified in the 2026-04-09 Session 3 `/pm:session-end` invocation** — scan.sh auto-inject ran without permission prompt; split drift-check pipeline also verified via session-start's own drift-catch firing on this session. `029c62b`.
- 2026-04-09 — **session-start PRESENT.md drift check** (2.1.1): one git-log check added to `skills/session-start/SKILL.md` Phase 2. At session open, after the leftover-state check, lists any commits landed since `PRESENT.md` was last updated and asks the user to reconcile before picking a task. Closes the "commits outside session-end don't update PRESENT.md" drift-slip loop that forced this session's reconciliation. Five lines of skill body + one frontmatter entry, no new scripts. `222eb03`.
- 2026-04-09 — **scan.sh inventory/staleness checks + audit quick mode** (2.1.0): extended `skills/session-end/scripts/scan.sh` with `specs_inventory` (recursive search over specs/, spec/, docs/specs/, docs/spec/ against PRESENT.md mentions) and `pm_docs_staleness` (log/tracker/inventory files under docs/ and docs/rpm/ with days-since-last-commit). Added `/pm:audit quick` as a new audit target — runs scan.sh only via cross-skill `${CLAUDE_PLUGIN_ROOT}` reference, no `pm:auditor` subagent, for fast on-demand drift checks between session-ends. Motivated by the volta session trawl: these are the exact drift patterns the commands-era auditor was catching that scan.sh previously missed. Dogfooded against volta (total=107 listed=106 unlisted=1, 2 loose log files detected). `7242f34`.
- 2026-04-09 — **skills migration phase 6: legacy `commands/` removed** (2.0.0): deleted all 6 `commands/*.md` files. `CLAUDE.md` Layout swept for stale `commands/` references; `PM.md` Project Summary + Key Files + Focus Areas rewritten to describe the skills-first state. `command-version/` dispatcher untouched (frozen per Phase 5). Verified via scan.sh — 0 broken refs. Dogfood cycle the phase was gated on = the 2026-04-09 session that shipped it. `d85c66a`.
- 2026-04-09 — **session-end parallelization + scan.sh bundle + audit LLM-workflow dimension** (1.0.23): three coupled changes. (1) `skills/session-end/scripts/scan.sh` bundled — six sections in key=value, auto-injected via `!${CLAUDE_SKILL_DIR}/scripts/scan.sh` so output is in context before Phase 1 begins, zero tool calls for the scan. Tightened to zero false-positive broken_refs. (2) Session-end Phase 1 + 2 restructured for parallel reads/writes; 2-3× wall-clock speedup on the analyze+apply block. (3) `skills/audit/project-mode.md` gained "repetitive LLM work → scripts" as a Phase 1 probe + Phase 4 dimension. Closes Task 4 from the 2026-04-09 plan. `06c7d5d`.
- 2026-04-09 — **skills migration phase 5: `command-version/` frozen** (1.0.22): chose option B — no ongoing mirror maintenance. `CLAUDE.md` Layout/Editing sections rewritten; `skills/` is now primary surface. `command-version/pm.md` gets a legacy-install header note. `3b37c88`.
- 2026-04-09 — **skills migration phase 4: session trio** (1.0.21): `session-start`, `session-update`, `session-end` all shipped as skills. `session-end` has a pre-flight auto-invocation gate so Claude can proactively recommend wrapping up on long contexts without auto-committing. `61eca6b`.
- 2026-04-09 — **skills migration phase 3: `/pm:audit` decomposed** (1.0.20): split into `skills/audit/SKILL.md` (routing + Documents mode) + `findings-menu.md` + `project-mode.md`. `disable-model-invocation: true`. `f8b0b1b`.
- 2026-04-09 — **skills migration phase 2: `/pm:init`** (1.0.19): migrated to `skills/init/SKILL.md` with `disable-model-invocation: true` (destructive scaffolder). `9cf1438`.
- 2026-04-09 — **skills migration phase 1: `/pm:pm`** (1.0.18): first migration. `skills/pm/SKILL.md` with auto-invocation on pm-overview questions. Legacy `commands/pm.md` kept for rollback; skill takes precedence per unification docs. `a7df55b`.
- 2026-04-09 — **second `/pm:audit project` run**: 8 findings, plan + report saved. First project-target audit after the 1.0.17 scan-gap fix — validated that `pm:auditor` feeds Phase 4 as designed. User picked C (commit to phased migration) for S1. See `docs/rpm/reviews/2026-04-09.md`. `c39cf0c`.
- 2026-04-09 — **mechanical audit findings executed** (`f972ab8` + `28f337d`): PM.md version-sync contradiction fixed, `init.md` stale depth-menu text replaced, `CLAUDE.md` read-first guardrail added, `auditor.md` off-schema frontmatter cleaned up, ccpm disambiguation note added to `pm.md` + mirror.
- 2026-04-08 — **project-mode scan gap closed** (1.0.17): `/pm:audit project` Phase 1 now launches `pm:auditor` in the background (plugin version) / runs the Documents scan inline (dispatcher version) so VALIDITY/COHERENCE/tracker findings become Phase 4 evidence. Closes the gap where a `project` run could silently miss broken refs that a `documents` run would catch.
- 2026-04-08 — **audit restructure** (1.0.16): `/pm:audit` split into `documents` (doc + CLAUDE.md + memory + session-drift scan via `pm:auditor`) and `project` (full consultant review). Dropped `light` as a separate mode — its cheap checks are now automatic in `/pm:session-end` Phase 1e. Removed depth menu and recency recommendation. Mirror synced.
- 2026-04-08 — session marker relocated to `docs/rpm/~pm-session-active` (no more `mkdir -p`); added `.gitignore` entry. Plugin → 1.0.15 (`e65ff57`).
- 2026-04-08 — README gains "What a session looks like" dry-run example; plugin → 1.0.14 (`c2475ce`).
- 2026-04-08 — first `/pm:audit heavy` run on self: 8 findings, all executed in-session. See `docs/rpm/reviews/2026-04-08.md` and `…-plan.md`.
- 2026-04-08 — new `/pm:session-update` command (mid-session checkpoint, competitive gap vs `claude-sessions`). Propagated through all command tables.
- 2026-04-08 — `/pm:audit` Heavy mode restructured into 5 phases (Investigate → Inward Research → Outward Research → Analyze → Refine). Outward research now REQUIRED; added `Competitive Gaps` analyze dimension.
- 2026-04-08 — `agents/auditor.md` is now the single source of truth for the Standard-mode scan spec; `commands/audit.md` Standard Phase 1 invokes `pm:auditor` by name.
- 2026-04-08 — native `TaskCreate/TaskUpdate/TaskList` integrated with `FUTURE.org` as source of truth; `session-start` hydrates, `session-end` reconciles.
- 2026-04-08 — root `plugin.json` mirror deleted; `.claude-plugin/plugin.json` is sole canonical manifest. Added `license: MIT`, `keywords`. `LICENSE` file created at repo root.
- 2026-04-08 — `deep-research` output path moved to `docs/rpm/research/<topic-slug>/`.
- 2026-04-08 — README install instructions rewritten with dev / persistent-local / "when published" blocks.
- 2026-04-08 — `/pm:audit` menus simplified to compact numbered lists; AskUserQuestion removed.
- 2026-04-08 — `/pm:audit` gains **Shared: Findings Menu**; Light + Standard modes route findings through it.
- 2026-04-08 — light audit run on self: 5 findings surfaced, all fixed in-session.
- 2026-04-08 — `command-version/` (non-plugin install variant) brought in sync with the current plugin command surface.
- 2026-04-08 — `agents/audit-scanner.md` renamed to `agents/auditor.md`.
- 2026-04-08 — audit standard run on self: PRESENT.md cleaned up, user-facing docs corrected to stop presenting `/pm:deep-research` as a slash command (deep-research is a skill — no command file, no slash command). Fixed in `README.md`, `commands/pm.md`, `CLAUDE.md`, `docs/rpm/PM.md`, `skills/deep-research/SKILL.md`, `commands/audit.md`.
- marketplace manifest added, stale docs cleaned up
- audit commands consolidated into a single `/pm:audit` with
  recency-based depth recommendation
- `/pm:init` run on this repo: scaffolded `docs/rpm/` tree and
  `CLAUDE.md`. ADR scaffolding stripped from the plugin's own
  `commands/init.md`.

## Active Specs
_(none — plugin uses no spec workflow)_

## Known Issues
- **Session marker disappeared once at `/exit`→resume boundary** — observed 2026-04-08 between marker creation at 17:16 and resume at 17:21. Marker recreated and persisted fine through the rest of the session. Root cause unknown. Tracked in `FUTURE.org`.
