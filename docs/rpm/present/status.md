# rpm — Present State

## Project Status
- **Current phase**: Active development
- **Last updated**: 2026-04-21
- **Version**: 2.7.7

## Completed Work
- Plugin architecture (skills, hooks, agents)
- Session lifecycle (start, compact, end)
- Session-start task menu (hierarchical, interactive)
- Session continuity across /clear and resume (source field detection)
- Audit system (quick, documents, project) with 8 analysis dimensions
- Deep research skill
- /tasks skill for mid-session backlog management
- Learning capture pipeline (Stop hook + "Key finding:" contract)
- PostCompact compact_summary for better continuity after compaction
- Random tips at session start (stderr, not model context)
- /rpm ? quick-reference command
- Context-aware session-end suggestion (replaces time-based nudge)
- Post-clear continuity: next field in ~rpm-last-session, branched startup flow
- File rename migration (FUTURE.org/PRESENT.md/RPM.md/RPM-LOG.md to tasks.org/status.md/context.md/log.md)
- Bootstrap with single detect.sh script, permissions-first flow
- Context.md auto-injection at session start
- SessionEnd hook — warns + stubs daily log when session ends without /session-end
- PostToolUse context monitor — 40/60/70% transcript-size thresholds for wrap-up pressure
- Stop handoff validator — checks /session-end output completeness (Accomplished/Next sections, status.md date)
- TaskCreated/TaskCompleted capture — native task lifecycle persisted to ~rpm-native-tasks.jsonl
- Always-on resume prompt + handoff marker checks (v2.5.1)
- bats test suite (`plugin/tests/`, 111 tests — full hook + scan.sh + score-natives coverage) + GitHub Actions CI (bats + shellcheck)
- Session-start empty-backlog brainstorm flow — when no actionable tasks, review tasks.org for miscategorized items, otherwise draft 2–4 candidates
- Session-start stale detection via session_id mismatch (v2.5.2) — works across `--continue` / new-process flows, not just `SOURCE=startup`
- Proactive session marker written on every fresh session — any work survives the next session's stale check even if the user skips the task menu
- `/session-end` Phase 1e — auto-derive a task title when the marker says `(unassigned)`; no prompt, no "(unassigned)" leaking into daily log / last-session
- Paired session markers (v2.5.3) — `~rpm-session-start` (SessionStart) + `~rpm-session-end` (/session-end) pair on session_id for deterministic orphan detection; softer "wasn't ended with /session-end" stale UX, no task menu on stale path
- v2.5.3 published — plugin-only split at `7f21ead`, tagged `v2.5.3`
- Softened session-end nudges (v2.5.4) — context-monitor drops "HARD WRAP-UP GATE" / "do not start new tasks" language; session-end hook stops printing stderr warnings on unclean exit; session-start stale path becomes a soft note that falls through to the task menu instead of blocking; handoff-validator drops the "review trackers" directive; session-end SKILL description no longer pushes proactive auto-invocation
- Context monitor reads real tokens (v2.5.5) — pulls `input + cache_read + cache_creation` from the latest assistant `usage` block instead of transcript byte size; defaults to a 1M-token window with `RPM_CONTEXT_TOKENS` env override for 200K users; bats coverage extended to override path + transcripts without usage
- Context monitor thresholds raised to 75% / 90% (v2.5.6) — drops the early 40% heads-up and 60% mid-tier; lower thresholds were noisy on the 1M window and triggered session-end pressure long before context loss was real
- Context monitor filters sidechain entries (v2.5.7) — `jq first()` with `isSidechain != true` picks the most recent main-chain assistant usage; subagent/Task runs no longer mask the parent session's true context size
- Single-option menu forms (v2.5.8) — audit findings, /session-end Actions, and /session-end Record findings now switch to a direct `yes / no` prompt when only one option remains, instead of the awkward `1 · all · none` grammar
- marketplace.json source → object form (v2.5.9) — Claude Code marketplace spec requires `{ source: "url", url: "..." }`; a bare URL string was breaking `/plugin marketplace add dppdppd/rpm`
- Session-lifecycle hooks optimized (v2.6.0) — task_menu parser rewritten with bash builtins (~4.6× faster, 900ms→200ms on a 30-task backlog); `session-end.sh` daily-log stub bug fixed (`0\n0` corruption); `scan.sh` caches `git status`; "first response" boilerplate compressed in 4 hooks; `/effort` stderr nag removed
- Task/backlog overhaul (v2.7.0) — session-end restructured into four user-visible phases with printed headers (`Phase N (of 4): Title`): Collecting Findings → Housekeeping → Reviewing Tasks → Handing Off. New behaviors: `TaskCompleted` hook scores completions against `tasks.org` headings (auto-apply DONE ≥80 confidence, ask 40–79); `CANCELLED` workflow state recognized as terminal by parser + scan; Phase 3 reconciles `tasks.org` priority against session reality with 4 mismatch signals; `/tasks postpone` defers a task to the bottom of its `* Parent` group with `:POSTPONED:` stamp; `/tasks review` gets Deferrals dimension. SKILL.md trimmed 47 lines, then re-expanded for the 4-phase structure
- Native task / Key finding fixes (v2.7.1) — `/tasks add` now explicitly forbids `TaskCreate` for backlog additions (native tasks = current session only, `tasks.org` = long-term backlog); session-start injection states the distinction; "Key finding:" guidance carried into resume + post-compact paths so it survives `/clear` and compaction
- Deferred-work capture + backlog rename (v2.7.2) — sharpened the "suggest deferrable work → ask" rule with concrete trigger phrases and promoted it into SessionStart/resume/post-compact instruction blocks. Assistant-facing text now says "your rpm backlog" (path literals still read `docs/rpm/future/tasks.org`). New **Phase 3a: Clear native tasks** sweeps `TaskList` at session-end — dedups against your backlog (≥80 match → flip TODO→IN-PROGRESS, <80 → append as new TODO), then `TaskUpdate`s all surfaced natives to `completed`. Creation-time was the vetting step, so no user question is asked.
- Version tags + bootstrap UX polish (v2.7.3) — session-start hook reads `plugin.json` via `$CLAUDE_PLUGIN_ROOT` and appends ` (rpm <version>)` to the `session active` / `resuming` / stale-wrap-up headers. session-end scan emits `version=<X.Y.Z>`; Phase 1 header renders as `## Phase 1 (of 4): Collecting Findings (rpm X.Y.Z)`. When `docs/rpm/` is missing, session-start now emits a one-line `/bootstrap` hint to stderr (user terminal, not model context) so the plugin is discoverable — stdout stays empty. `/bootstrap` Phase 7 writes `~rpm-session-start` after scaffolding so runtime hooks (`context-monitor`, `stop-learn-capture`, `pre-compact`, `session-end`, `task-capture`) activate immediately, no restart. `deep-research` description broadened to general research phrasings + Offer gate prompts `quick` vs `deep` before the full multi-agent protocol. README restructured — install + `/bootstrap` as a prominent two-step "Getting started".
- Full opencode port + two-remote git layout + v2.7.6 dual release (2026-04-18). Renamed `origin` → `plugin` (GitHub subtree) and added `dev` → Gitea (york:3333). New `opencode/` sibling: TS plugin bridging opencode's event stream to rpm's existing bash hooks; `scripts/sync-opencode.sh` + `scripts/translate-{skill,agent}.py` mirror skills → commands and translate agents; `scripts/publish-opencode.sh` force-pushes a full .opencode/ tree as a subtree split to `plugin/opencode`; `scripts/publish-all.sh` is the one-shot CC + opencode + tag release. All six rpm slash commands (`/backlog`, `/audit`, `/session-end`, `/init-rpm`, `/rpm`, `/deep-research`) + the `auditor` agent discovered by opencode and end-to-end validated under opencode Zen (`minimax-m2.5-free`, no API key needed). `v2.7.6` tagged on GitHub as the first unified release covering both plugins; users install opencode via `curl -fsSL https://raw.githubusercontent.com/dppdppd/rpm/opencode/install.sh | bash`.

## Active Specs

## Known Issues
