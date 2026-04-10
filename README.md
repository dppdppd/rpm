# rpm — Relentless Project Manager

A Claude Code plugin that manages your project across sessions.

## Why

Claude Code sessions are disposable. You start one, do some work,
and when you're done the context is gone. The next session starts
cold — it doesn't know what you did yesterday, what you decided, or
what's next. You end up re-explaining context, redoing work, and
watching docs drift from reality because nothing checks whether
yesterday's documentation still matches today's code.

rpm fixes this. It maintains a persistent project state across
sessions — what happened (past), where things stand (present), and
what's planned (future). Each session starts with full context and
ends with a clean handoff to the next one.

## The workflow

**First time:** Run `/bootstrap`. It scans your project, asks a few
questions, and scaffolds the tracking infrastructure under `docs/rpm/`.

**Every session after that:** Just start working. rpm automatically
loads your project context — git state, open tasks, daily log,
recent drift — and proposes a task from the backlog. You confirm and
work.

**Mid-session:** rpm quietly captures learnings and checkpoints your
progress. If you run `/compact`, rpm saves your state before
compaction and restores it after — so you pick up exactly where you
left off without re-explaining anything. After about 90 minutes it
nudges you to wrap up before context quality degrades.

**End of session:** Run `/session-end`. It auto-updates all three
trackers, surfaces uncommitted work and learnings, and writes a
handoff for the next session. Start a new conversation and the cycle
repeats.

The result: every session starts informed and ends clean. Nothing
falls through the cracks between sessions.

## Commands

### `/bootstrap`

First-run setup. Run once per project. Scans the codebase, asks 3
questions, scaffolds `docs/rpm/` (trackers, daily logs, task
backlog), and creates a CLAUDE.md if one doesn't exist.

### `/session-end`

Wrap up the current session. Auto-updates past/present/future
trackers, surfaces uncommitted work and learnings, presents an action
menu, then writes handoff notes. Run when you're done working or when
context is getting long.

### `/audit quick`

Fast mechanical scan. Zero LLM tokens. Checks git state, CLAUDE.md
size, broken refs, daily-log gaps, spec inventory drift. Use when you
want a quick "anything broken?" check. ~5 seconds.

### `/audit documents`

Deep doc scan via background subagent. Checks every markdown file for
staleness, contradictions, broken references, and session drift.
Scored findings, only high-confidence results shown. Use when you
suspect docs have drifted but aren't sure where. ~3 minutes.

### `/audit project`

Full consultant review. Reads the codebase, validates against vendor
docs, runs competitive research against real alternatives. Outputs an
executive summary and a plan file. Use when you want outside
perspective on the project's overall health. ~30 minutes.

## Installation

### From marketplace

```
/plugin marketplace add https://github.com/dppdppd/rpm
/plugin install rpm@dppdppd-plugins
```

### Local development

```bash
claude --plugin-dir /path/to/rpm
```

Then start a new conversation and run `/bootstrap`.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- No other dependencies. Pure markdown and bash.

## Hooks

Five hooks drive the automatic behavior:

| Hook | What it does |
|------|-------------|
| **SessionStart** | Loads git state, open tasks, daily log, tracker drift. Proposes a task. |
| **Stop** | Captures learning signals after each response. |
| **PreCompact** | Checkpoints progress before context compaction. |
| **PostCompact** | Re-injects session state after compaction. |
| **UserPromptSubmit** | Nudges for wrap-up after ~90 minutes. |

## License

MIT
