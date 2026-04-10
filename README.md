# rpm — Your Relentless Product Manager

Tracks what shipped, what's next, and what's drifting — so you
can focus on building.

rpm sits in every session like a product manager sits in every
standup: it knows what happened yesterday, what's planned today,
and what's falling through the cracks. It doesn't write code — it
keeps the project's memory intact, flags drift before it rots, and
makes sure nothing gets lost between sessions.

## What rpm does automatically

- **Briefs you at the start** — SessionStart hook loads git state,
  open tasks, daily log, and tracker drift. No command needed.
- **Takes notes during work** — Stop hook captures learning signals
  (root causes, discoveries, corrections) to a session journal.
- **Checkpoints before you lose context** — PreCompact hook saves
  progress to the daily log before compaction wipes the conversation.
- **Nudges when you're going long** — reminds you to wrap up after
  ~90 minutes.

## What you run manually

| Command | What rpm does |
|---------|-------------------|
| `/rpm:session-end` | Wraps up: updates trackers, presents findings, commits, hands off |
| `/rpm:init` | First-run onboarding: scaffolds the PM infrastructure |
| `/rpm:audit documents` | Deep doc scan: staleness, contradictions, broken refs, session drift |
| `/rpm:audit project` | Full review: code, architecture, competitive research, plan file |

## Skills

| Skill | What rpm does |
|-------|-------------------|
| `deep-research` | Multi-agent research. Auto-triggers on questions needing external knowledge. |

## Installation

This plugin is currently unpublished. Install from a local clone.

### Session-scoped (quick trial)

```bash
claude --plugin-dir /path/to/claude-plugin-pm
```

### Persistent local install

```
/plugin marketplace add /path/to/claude-plugin-pm
/plugin install rpm@dppdppd-plugins
```

### Marketplace install (when published)

Once published, add the marketplace by its source identifier, then
install the plugin:

```
/plugin marketplace add <owner>/<repo>
/plugin install rpm@dppdppd-plugins
```

## What a session looks like

Sessions start automatically — rpm briefs you the moment you
open a conversation. A real session opener looks like:

```
> let's work on the plugin

Context loaded. Clean tree, no stashes, no leftover work.

Open FUTURE.org TODOs:
1. Add homepage/repository fields  (blocked — unpublished)
2. Compaction guard hooks

This session: TODO #2 — compaction guard. It's the highest
priority unblocked item. Proceed?
```

rpm proposes a task and waits for you to confirm. Then you
work. When you're done, `/rpm:session-end` wraps up — rpm
updates the trackers, surfaces findings, and writes handoff notes
for the next session.

## Project Structure Created by /rpm:init

```
docs/rpm/
├── RPM.md              — PM context (loaded every session)
├── RPM-LOG.md          — Append-only audit/review history
├── PRESENT.md         — Current project state
├── FUTURE.org         — Org-mode task tracker (planned work)
├── past/              — Daily session logs (YYYY-MM-DD.md)
└── reviews/           — Audit plans and reports
```

The three trackers map to the timeline:
- **past/** — what happened (daily session notes from `/rpm:session-end`)
- **PRESENT.md** — where things stand now (project status)
- **FUTURE.org** — what's planned (task tracker)

## How it works

rpm runs on five Claude Code hooks — no background services, no
databases, no external dependencies. Pure markdown + bash.

| Hook | What rpm does |
|------|-------------------|
| **SessionStart** | Briefs you: git state, open tasks, daily log, tracker drift |
| **PreCompact** | Checkpoints progress to daily log before context compaction |
| **PostCompact** | Re-injects session state so you don't lose your place |
| **Stop** | Captures learning signals from each response |
| **UserPromptSubmit** | Nudges for wrap-up after ~90 minutes |
