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

## What a session looks like

Once installed, start your first session with `/pm:session-start`.
It reads your project state, surfaces any leftover work, and states
a plan before touching anything. A real session opener looks like:

```
> /pm:session-start

Context loaded. Clean tree, no stashes, no leftover work.

Recent state: last session (2026-04-08) shipped 8 audit findings
and bumped version to 1.0.13.

Open FUTURE.org TODOs:
1. Add a sample /pm:session-start dry-run to README
2. On publish: add homepage/repository fields  (blocked — unpublished)

This session: TODO #1 — add a dry-run walkthrough to README.
It's the only actionable item in the backlog and closes a real
UX gap for new users. Proceed?
```

Nothing is committed, no files are written beyond a session marker
at `docs/pm/~pm-session-active`. You confirm the plan, work
happens, then `/pm:session-end` surveys findings and presents a
commit menu. Mid-session, `/pm:session-update` checkpoints
progress to today's daily log without ending the session.

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
