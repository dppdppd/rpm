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
progress. Use `/tasks` to add, list, review, or complete tasks from
your backlog. If you run `/compact`, rpm saves your state before
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

### `/tasks`

Manage the task backlog. Add new tasks, list all tasks with statuses,
review and reorganize the backlog, or mark tasks done. Also
auto-triggers when you mention tasks naturally ("add a task", "what's
on my backlog").

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

## Examples

### Session start

Each session opens with a scoreboard and a task menu pulled from your
backlog. Pick a number to start working, add `?` to read the detail
file first, or choose `S` to name your own task:

```
rpm: session active

2 untracked files, 3 commits of drift since status.md updated.

rpm: 5 done · 1 in-progress · 6 todo · 1 blocked

What would you like to work on? Open tasks from your backlog:
API Layer
   1. Rate limiter middleware (in-progress)
      detail: future/2026-04-08-rate-limiter.md
   2. Request validation

Data Layer
   3. Migration rollback support
   4. Connection pool tuning
      detail: future/2026-04-05-pool-tuning.md

Polish
   5. Error message consistency
   6. OpenAPI spec generation

S: something else
R: review tasks

Pick #, #? for details, S, or R.
```

### `/audit quick`

Fast mechanical scan, zero LLM tokens:

```
## /audit quick — 2 findings

A. 2 broken refs in docs/rpm/context.md                        [70]
   context.md:12 → api/routes.md (deleted in abc1234)
   context.md:18 → docs/setup.md (moved to docs/guides/setup.md)

B. Daily log gap — 3 commits since last entry                  [65]

Fix A, B, all, or skip?
```

### `/audit documents`

Deep doc scan via background subagent:

```
## /audit documents — 3 findings

A. CLAUDE.md § Build command outdated — says `npm run build`,     [85]
   codebase switched to `pnpm build` 12 commits ago

B. docs/api-design.md contradicts implementation —                [72]
   doc says auth uses JWT, code uses session tokens since Phase 4

C. 2 memory files reference renamed src/utils/ directory          [65]

(1 low-confidence finding logged but not shown)

Fix all, pick by letter, or skip?
```

### `/audit project`

Full consultant review with external research:

```
## rpm Review — 2026-04-10

### Health
API layer well-structured. Auth middleware and public endpoint
exposure are the main risks.

### Research Conducted
- Inward — session token storage — confirmed non-compliant
  with SOC2 control CC6.1; tokens stored in plaintext cookies
- Outward — Hono, Fastify, Express — all three default to
  httpOnly signed cookies; current impl skips signing

### Findings
- Auth token storage (Critical) — session tokens stored unsigned
  in plaintext cookies. Industry standard is httpOnly + signed.
  Outward research confirms all three comparable frameworks
  default to signed cookies.
- Unprotected public endpoints (High) — 3 public routes have no
  rate limiting. Inward research confirms no middleware registered.

### Plan
Plan saved to docs/rpm/reviews/2026-04-10-plan.md
- Fix auth token storage — Critical, ~2 sessions
- Add rate limiting to public endpoints — High, ~1 session
```

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
