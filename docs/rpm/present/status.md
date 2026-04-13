# rpm — Present State

## Project Status
- **Current phase**: Active development
- **Last updated**: 2026-04-13
- **Version**: 2.5.4

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
- bats test suite (`plugin/tests/`, 69 tests — full hook coverage) + GitHub Actions CI (bats + shellcheck)
- Session-start empty-backlog brainstorm flow — when no actionable tasks, review tasks.org for miscategorized items, otherwise draft 2–4 candidates
- Session-start stale detection via session_id mismatch (v2.5.2) — works across `--continue` / new-process flows, not just `SOURCE=startup`
- Proactive session marker written on every fresh session — any work survives the next session's stale check even if the user skips the task menu
- `/session-end` Phase 1e — auto-derive a task title when the marker says `(unassigned)`; no prompt, no "(unassigned)" leaking into daily log / last-session
- Paired session markers (v2.5.3) — `~rpm-session-start` (SessionStart) + `~rpm-session-end` (/session-end) pair on session_id for deterministic orphan detection; softer "wasn't ended with /session-end" stale UX, no task menu on stale path
- v2.5.3 published — plugin-only split at `7f21ead`, tagged `v2.5.3`
- Softened session-end nudges (v2.5.4) — context-monitor drops "HARD WRAP-UP GATE" / "do not start new tasks" language; session-end hook stops printing stderr warnings on unclean exit; session-start stale path becomes a soft note that falls through to the task menu instead of blocking; handoff-validator drops the "review trackers" directive; session-end SKILL description no longer pushes proactive auto-invocation

## Active Specs

## Known Issues
