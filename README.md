# rpm — Relentless Project Manager

A Claude Code plugin that keeps your project's documentation aligned
with reality across sessions. It tracks what shipped, what's next,
and what's drifting — so you can focus on building.

LLM-assisted development generates documentation (CLAUDE.md, specs,
trackers, session logs, memory files) that drifts from reality the
moment the session that wrote it ends. rpm sits in every session like
a product manager in a standup: it knows what happened yesterday,
what's planned today, and what's falling through the cracks.

## What happens automatically

Five hooks run the session lifecycle with no commands needed:

| Hook | What happens |
|------|-------------|
| **SessionStart** | Briefs you: git state, open tasks, daily log, tracker drift. Proposes a task from the backlog. |
| **Stop** | Captures learning signals (root causes, discoveries, corrections) after each response. |
| **PreCompact** | Checkpoints progress before context compaction. |
| **PostCompact** | Re-injects session state so you don't lose your place. |
| **UserPromptSubmit** | Nudges for wrap-up after ~90 minutes, when context starts degrading. |

## Commands

### `/bootstrap`

First-run setup. Run once per project. Scans the codebase, asks 3
questions, then scaffolds rpm infrastructure under `docs/rpm/`
(trackers, daily logs, task backlog) and creates a CLAUDE.md if one
doesn't exist.

### `/session-end`

Wrap up the current session. Auto-updates all three trackers
(past/present/future), surfaces uncommitted work and learnings,
presents an action menu, then writes handoff notes for the next
session. Run this when you're done working or when context is getting
long.

### `/audit quick`

Fast mechanical scan. Zero LLM tokens. Checks git state, CLAUDE.md
size, `NOT_IMPLEMENTED` stubs, broken refs, daily-log gaps, spec
inventory drift. Use between session-ends when you want a quick
"anything broken right now?" check. ~5 seconds.

### `/audit documents`

Deep doc scan via background subagent. Scans every markdown file
across 8 dimensions (validity, coherence, LLM-effectiveness, guidance
alignment, gap analysis, future-tracker health, session drift).
Findings scored 0-100; only high-confidence results presented. Use
when you suspect docs have drifted but aren't sure where. ~3 minutes.

### `/audit project`

Full consultant review. Reads the codebase, validates against vendor
docs, then runs competitive research against 3-5 real alternatives.
Analyzes across 7 dimensions including architecture health, LLM
workflow efficiency, and strategic direction. Outputs an executive
summary and a plan file. Use when you want outside perspective on the
project's overall health. ~30 minutes.

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
- No other dependencies. rpm runs on markdown, bash, and Claude Code hooks.

## License

MIT
