# pm — Claude Code Plugin

Project management layer for LLM-assisted development.

## Commands

| Command | Description |
|---------|-------------|
| `/pm` | Guide — explains all commands |
| `/pm:session-start` | Begin session: load context, pick task, state plan |
| `/pm:session-end` | End session: commit, log progress, capture learnings |
| `/pm:init` | First-run project setup |
| `/pm:audit` | Scan docs + fix issues |
| `/pm:audit-light` | Quick dashboard (read-only) |
| `/pm:audit-heavy` | Deep review with external research |
| `/pm:deep-research` | Multi-agent deep research |

## Installation

```bash
claude --plugin-dir /path/to/claude-plugin-pm
```

## Project Structure Created by /pm:init

```
docs/pm/
├── PM.md              — PM context (loaded every session)
├── PM-LOG.md          — Append-only audit/review history
├── TASKS.org          — Org-mode task tracker
├── progress/
│   ├── STATUS.md      — Project status
│   └── YYYY-MM-DD.md  — Daily session logs
├── reviews/           — Audit plans and reports
└── tasks/             — Detailed task files
```

## Hooks

- **SessionStart**: Reminds to run `/pm:session-start`. Detects
  unclean exits from previous sessions and shows what was in progress.
