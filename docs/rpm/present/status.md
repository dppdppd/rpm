# rpm — Present State

## Project Status
- **Current phase**: Active development
- **Last updated**: 2026-04-11
- **Version**: 2.3.0

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
- File rename migration (FUTURE.org/PRESENT.md/RPM.md/RPM-LOG.md to tasks.org/status.md/context.md/log.md)
- Bootstrap with single detect.sh script, permissions-first flow
- Context.md auto-injection at session start

## Active Specs

## Known Issues
- context.md broken_refs scanner flags relative paths (e.g. `future/tasks.org`) as false positives — paths are relative to docs/rpm/ but scanner resolves from project root
