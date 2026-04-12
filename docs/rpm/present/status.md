# rpm — Present State

## Project Status
- **Current phase**: Active development
- **Last updated**: 2026-04-11
- **Version**: 2.5.0

## Completed Work
- Plugin architecture (skills, hooks, agents)
- Session lifecycle (start, compact, end)
- Session-start task menu (hierarchical, interactive, scoreboard)
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

## Active Specs

## Known Issues
