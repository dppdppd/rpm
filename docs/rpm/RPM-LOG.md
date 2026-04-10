# RPM Log — rpm plugin

Append-only history of audits, reviews, and session reviews.
Not loaded automatically — referenced from `docs/rpm/RPM.md` when needed.

## Audit History

- 2026-04-10 — audit project — 7 findings, plan saved to reviews/2026-04-10-plan.md
  - Phase 2 (Inward): Claude Code hooks spec (once: true, $CLAUDE_PLUGIN_DATA); agent frontmatter schema (color field valid, plugin security restrictions).
  - Phase 3 (Outward): ccpm, cc-spex, claude-mem, gstack, flow-next. No competitor combines hook-driven automation + doc drift scoring + session lifecycle + task tracking.
  - Critical: 4 of 5 hooks broken — `docs/pm` → `docs/rpm` rename not propagated to bash scripts. All hook automation non-functional.
  - High: project-mode.md WebFetch contradiction with CLAUDE.md; RPM.md stale after rename.
  - Medium: CLAUDE.md stale namespace refs; scan.sh pm_docs_staleness wrong path.
  - Low: `once: true` replaces manual nudge flags; broken_refs blind to bash scripts.
- 2026-04-10 — audit quick — 1 finding, 1 fixed, 0 skipped
- 2026-04-08 — audit light — 5 issues surfaced (2 high, 1 medium, 2 low), all fixed in-session
- 2026-04-08 — audit light — 4 surfaced, 4 fixed, 0 skipped
- 2026-04-08 — audit standard — 3 findings, 3 fixed, 0 skipped (+ auditor rename and deep-research correction handled in same session)
  - PRESENT.md Completed Work referenced nonexistent `progress/STATUS.md` and `TASKS.org`, and stale `howto`/`pm:pm` rename history → cleaned up
  - User-facing docs incorrectly presented `/pm:deep-research` as a slash command. Reality: deep-research is a **skill** (`skills/deep-research/SKILL.md`), not a slash command — there is no `commands/deep-research.md` and no `/pm:deep-research` slash command. Corrected `README.md`, `commands/pm.md`, `CLAUDE.md`, `docs/pm/PM.md`, `skills/deep-research/SKILL.md`, and `commands/audit.md` Heavy mode Phase 2 to describe it accurately.
  - Also this scan: auditor renamed mid-audit (`agents/audit-scanner.md` → `agents/auditor.md`, frontmatter + refs in CLAUDE.md, docs/pm/PM.md)
  - Also this scan: Shared Findings Menu format updated — bold quick-phrase headings, blank line between options (mirrored to `command-version/`)
- 2026-04-08 — audit heavy — 8 findings, plan saved to reviews/2026-04-08-plan.md
  - Phase 2 (Inward Research): plugin manifest/install flow + plugin subagent invocation (code.claude.com/docs).
  - Phase 3 (Outward Research, added mid-run after user flagged the gap): competitive analysis against `claude-sessions` (iannuttall), Superpowers (obra), Cline Memory Bank, Docs Guardian, Claude Code native Tasks (Jan 2025), Spec Kit, Kiro.
  - High: README install instructions wrong (shows dev-mode only); `/pm:audit` Standard Phase 1 never invokes its own `pm:auditor` subagent (dead code, diverged prompts); Heavy mode itself lacked explicit outward-research phase (meta-finding).
  - Medium: duplicate `plugin.json` (root + `.claude-plugin/`) — canonical is `.claude-plugin/` only; no `/pm:session-update` mid-session command (competitive gap vs `claude-sessions`); no integration with Claude Code native `TaskCreate/TaskUpdate` (free functionality ignored).
  - Low: `plugin.json` missing `license`/`keywords` and no LICENSE file (MIT chosen); `deep-research` skill pollutes project-root `research/`, should live under `docs/pm/research/`.
  - User input: repo unpublished → skip `homepage`/`repository`; MIT license; approved deleting root `plugin.json`; approved all 8 findings for execution.
  - Executed this session: all 8 findings applied in-place. Heavy mode in `commands/audit.md` restructured to five phases (Investigate → Inward Research → Outward Research → Analyze → Refine); new `/pm:session-update` command created and propagated through docs; `session-start`/`session-end` now hydrate and reconcile native tasks with `FUTURE.org`. Version bumped to 1.0.13.
- 2026-04-08 — audit restructure (1.0.16) — documents+project split, light depth dropped, drift scan folded into `/pm:session-end` Phase 1e. Commit `0a93738`.
- 2026-04-08 — audit: project-mode scan gap closed (1.0.17) — `/pm:audit project` Phase 1 now launches `pm:auditor` in background (plugin) / inlines Documents scan (dispatcher). VALIDITY/COHERENCE findings feed Phase 4 as evidence. Commit `c6f3492`.
- 2026-04-09 — audit project — 8 findings, plan saved to reviews/2026-04-09-plan.md
  - Phase 2 (Inward): skills unification (`.claude/commands/` merged into `skills/`, deprecation tracking `anthropics/claude-code#37447`); plugin agent frontmatter schema.
  - Phase 3 (Outward): `automazeio/ccpm` — migrated off `/pm:*` slash commands to Agent Skill, preserves legacy on v1 branch; 14 deterministic bash scripts for zero-token status ops. `iannuttall/claude-sessions` re-examined (no change).
  - High (strategic): skills-first migration path — user picked option C, phased migration planned.
  - Medium (mechanical): `docs/pm/PM.md` self-contradicts on version sync (pm:auditor confidence 87); `PM-LOG.md` missing 2 post-1.0.13 sessions (this entry closes that gap). Medium (competitive): deterministic scripts for session-end hygiene, borrowed from ccpm pattern.
  - Low: `commands/init.md:218` + mirror still reference removed audit depth menu; `feedback_read_before_renaming` partially codified in CLAUDE.md; ccpm `/pm:*` naming-collision disambiguation; `agents/auditor.md` frontmatter uses off-schema `color`/`whenToUse` fields.
  - User input: picked option C (commit to phased skills migration) for Finding S1. No other questions required developer input.
  - First Project-target audit after the 1.0.17 scan-gap fix. Validated the fix — 4 mechanical findings (A1–A4) came from the background `pm:auditor` scan, confirming the subagent feeds Phase 4 as designed.

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
