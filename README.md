# pm — Claude Code Plugin

Project management layer for LLM-assisted development.

## Commands

| Command | Description |
|---------|-------------|
| `/pm:pm` | Explain the plugin and list its commands |
| `/pm:session-start` | Begin session: load context, pick task, state plan |
| `/pm:session-update` | Mid-session checkpoint: append progress, refresh PRESENT.md |
| `/pm:session-end` | End session: survey findings, present action menu, then handoff |
| `/pm:init` | First-run project setup |
| `/pm:audit` | Audit project health |

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

- **SessionStart**: Reminds to run `/pm:session-start`. Detects
  unclean exits from previous sessions and shows what was in progress.
