# rpm — Relentless Project Manager

A Claude Code plugin that prevents documentation drift and keeps
you on task across LLM-assisted development sessions.

## The problem

LLM-assisted development generates a lot of documentation. CLAUDE.md
files, specs, trackers, session logs, memory files, READMEs — each
created with good intentions, each drifting from reality the moment
the session that wrote it ends. Within a few sessions the docs
contradict each other. Within a few more they contradict the code.
The LLM reads stale guidance, follows it, and the drift compounds.

The usual fixes — memory systems, rules files, RAG — solve context
injection but not documentation alignment. They help the LLM
*remember* things; they don't check whether those things are still
true.

rpm does. It sits in every session like a product manager sits in
every standup: it knows what happened yesterday, what's planned
today, and what's falling through the cracks. It doesn't write your
code — it keeps your project's documentation aligned with reality
and flags drift before it rots.

## How it's different

**Memory systems** (claude-mem, Memento) inject context into
sessions. rpm audits whether that context is still accurate — did
the doc get updated after the code changed? Does the tracker match
what actually shipped?

**Rules files** (.cursorrules, CLAUDE.md) tell the LLM how to
behave. rpm checks whether those rules still reflect the codebase
and promotes recurring corrections into hooks so they can't be
ignored.

**Meta-frameworks** (everything-claude-code, gstack) bundle tools
and roles. rpm is a single discipline: documentation stays aligned
with code, trackers stay aligned with work, and nothing falls
through the cracks between sessions.

## What rpm does automatically

No commands needed. Five hooks run the session lifecycle:

| Hook | What happens |
|------|-------------|
| **SessionStart** | Briefs you: git state, open tasks, daily log, tracker drift. Proposes a task from the backlog. |
| **Stop** | Captures learning signals (root causes, discoveries, corrections) to a session journal after each response. |
| **PreCompact** | Saves progress to the daily log before context compaction wipes the conversation. |
| **PostCompact** | Re-injects session state so you don't lose your place. |
| **UserPromptSubmit** | Nudges for wrap-up after ~90 minutes, when context starts degrading. |

No background services. No databases. No external dependencies.
Pure markdown and bash.

## What you run

| Command | What it does |
|---------|-------------|
| `/rpm:init` | First-run setup. Scans the project, asks 3 questions, scaffolds PM infrastructure. Run once. |
| `/rpm:session-end` | Wraps up: auto-updates past/present/future trackers, surfaces findings, commits, writes handoff notes. |
| `/rpm:audit documents` | Deep doc scan via background subagent: staleness, contradictions, broken refs, session drift. Scored findings. |
| `/rpm:audit project` | Full consultant review: code health, architecture, competitive research against real alternatives, plan file. |

| Skill | What it does |
|-------|-------------|
| `deep-research` | Multi-agent research. Parallel web search, URL fetching, gap analysis, adversarial validation. Auto-triggers when external knowledge is needed. |

## What a session looks like

```
> let's work on the plugin

Context loaded. Clean tree, no stashes, no leftover work.

Open FUTURE.org TODOs:
1. Add homepage/repository fields  (blocked — unpublished)
2. Compaction guard hooks

This session: TODO #2 — compaction guard. It's the highest
priority unblocked item. Proceed?
```

rpm proposes a task and waits for confirmation. You work.
When you're done, `/rpm:session-end` wraps up — updates the
trackers, surfaces uncommitted work and learnings, and writes
handoff notes for the next session. The cycle repeats.

## Session lifecycle

```
 ┌─ SessionStart hook ─────────────────────────────────┐
 │  Load git state, PRESENT.md, FUTURE.org, daily log  │
 │  Propose task → user confirms → create task marker   │
 └──────────────────────────────────────────────────────┘
                          │
                          ▼
 ┌─ Work ──────────────────────────────────────────────┐
 │  Stop hook captures learning signals after each      │
 │  response (root cause, discovery, correction)        │
 │                                                      │
 │  PreCompact hook checkpoints before compaction       │
 │  PostCompact hook recovers state after compaction    │
 │                                                      │
 │  ~90 min nudge: "context degrading, wrap up soon"    │
 └──────────────────────────────────────────────────────┘
                          │
                          ▼
 ┌─ /rpm:session-end ──────────────────────────────────┐
 │  Phase 1: Analyze (git, trackers, learnings)         │
 │  Phase 2: Auto-update past/present/future (no ask)   │
 │  Phase 3: Present findings + action menu             │
 │  Phase 4: Execute chosen actions                     │
 │  Phase 5: Handoff (cleanup, restart instructions)    │
 └──────────────────────────────────────────────────────┘
```

## Project structure

`/rpm:init` creates this:

```
docs/rpm/
├── RPM.md          — PM context (loaded every session)
├── RPM-LOG.md      — Append-only audit/review history
├── PRESENT.md      — Current project state
├── FUTURE.org      — Task tracker (org-mode, with dependency IDs)
├── past/           — Daily session logs (YYYY-MM-DD.md)
└── reviews/        — Audit plans and reports
```

Three files map to the timeline:

- **past/** — what happened (daily notes written by session-end)
- **PRESENT.md** — where things stand now (status, active work, known issues)
- **FUTURE.org** — what's planned (org-mode TODOs with `:BLOCKED_BY:` dependencies)

Session-end auto-updates all three: marks completed tasks DONE,
appends to the daily log, and edits PRESENT.md to reflect current
state. No manual bookkeeping.

## Audit: three levels of scrutiny

**Quick** — `/rpm:audit quick`. Runs a bash script. Zero LLM tokens.
Checks git state, CLAUDE.md size, `NOT_IMPLEMENTED` stubs, broken
refs, daily-log gaps, spec inventory drift. Takes ~5 seconds.

**Documents** — `/rpm:audit documents`. Launches a background
subagent that scans every markdown file across 8 dimensions:
validity, coherence, LLM-effectiveness, guidance alignment, gap
analysis, future-tracker health, and session drift. Findings scored
0–100; only ≥60 confidence presented. Offers to hookify repeat
offenders.

**Project** — `/rpm:audit project`. Full consultant review. Reads
the codebase, validates against vendor docs, then *requires*
competitive research against 3–5 real alternatives (fetches their
actual docs, not search summaries). Analyzes across 7 dimensions
including architecture health, LLM workflow efficiency, and
strategic direction. Outputs an executive summary and a plan file.

## Deep research

When any task needs external knowledge — during an audit, planning,
or on its own — the deep-research skill fires. It scales from a
single-agent quick lookup to 4 concurrent search agents depending on
scope. All search results, fetched URLs, gap analyses, and
validation artifacts are saved to `docs/rpm/research/<topic>/` as a
permanent record.

## Governing principles

1. **Staleness kills.** A stale doc is worse than no doc. Alignment is the priority.
2. **Single source of truth.** Each fact lives in one place. Duplication is how contradictions start.
3. **Less is more.** Every doc earns its place or gets cut.
4. **Docs are suggestions; hooks are law.** If it matters, enforce it mechanically.
5. **Mine sessions for drift.** Promote recurring corrections to hooks, not more docs.
6. **Three-tier knowledge.** Hot (CLAUDE.md, <150 lines) → Warm (read on demand) → Cold (archived past sessions).
7. **Structured > prose.** Tables and checklists beat paragraphs.
8. **35-minute threshold.** Scope tasks to one focused session.

## Installation

### From marketplace

```
/plugin marketplace add https://github.com/dppdppd/rpm
/plugin install rpm@dppdppd-plugins
```

### Local development

```bash
claude --plugin-dir /path/to/rpm/plugin
```

Then start a new conversation and run `/rpm:init` to set up PM
infrastructure for your project.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- No other dependencies. rpm runs on markdown, bash, and Claude Code hooks.

## License

MIT
