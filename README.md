# pm — Claude Code Plugin

Project management layer for LLM-assisted development.

## Commands

| Command | Description |
|---------|-------------|
| `/pm:pm` | Explain the plugin and list its commands |
| `/pm:session-end` | End session: drift scan, survey findings, action menu, handoff |
| `/pm:init` | First-run project setup |
| `/pm:audit documents` | On-demand deep scan: docs + CLAUDE.md + memory + session drift |
| `/pm:audit project` | On-demand consultant review: code, architecture, research, plan file |

## Skills

| Skill | Description |
|-------|-------------|
| `deep-research` | Multi-agent deep research. Auto-triggers on questions needing external knowledge, or ask Claude to "run deep research on \<topic\>". Not a slash command. |

## Installation

This plugin is currently unpublished. Install from a local clone.

### Session-scoped (quick trial)

```bash
claude --plugin-dir /path/to/claude-plugin-pm
```

### Persistent local install

```
/plugin marketplace add /path/to/claude-plugin-pm
/plugin install pm@dppdppd-plugins
```

### Marketplace install (when published)

Once published, add the marketplace by its source identifier, then
install the plugin:

```
/plugin marketplace add <owner>/<repo>
/plugin install pm@dppdppd-plugins
```

## What a session looks like

Once installed, sessions start automatically. The `SessionStart`
hook injects your project's PM context — git state, open tasks,
latest daily log, tracker drift — so Claude proposes a task and
gets to work without ceremony. A real session opener looks like:

```
> let's work on the plugin

Context loaded. Clean tree, no stashes, no leftover work.

Open FUTURE.org TODOs:
1. Add homepage/repository fields  (blocked — unpublished)
2. Compaction guard hooks

This session: TODO #2 — compaction guard. It's the highest
priority unblocked item. Proceed?
```

Nothing is committed, no files are written beyond a session marker
at `docs/pm/~pm-session-active`. You confirm the task, work
happens, then `/pm:session-end` surveys findings and presents a
commit menu. Mid-session checkpoints happen automatically before
context compaction — no manual step needed.

## Project Structure Created by /pm:init

```
docs/pm/
├── PM.md              — PM context (loaded every session)
├── PM-LOG.md          — Append-only audit/review history
├── PRESENT.md         — Current project state
├── FUTURE.org         — Org-mode task tracker (planned work)
├── past/              — Daily session logs (YYYY-MM-DD.md)
└── reviews/           — Audit plans and reports
```

The three trackers map to the timeline:
- **past/** — what happened (daily session notes from `/pm:session-end`)
- **PRESENT.md** — where things stand now (project status)
- **FUTURE.org** — what's planned (task tracker)

## Hooks

- **SessionStart**: Auto-injects PM context (git state, open tasks,
  daily log, tracker drift). Detects unclean exits from previous
  sessions.
- **PreCompact / PostCompact**: Checkpoints session state to daily
  log before compaction; re-injects recovery state after.
- **Stop**: Captures learning signals from assistant responses to
  JSONL for session-end review.
- **UserPromptSubmit**: Nudges for session-end after ~90 minutes.
