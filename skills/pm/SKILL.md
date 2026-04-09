---
name: pm
description: Explain the pm plugin and list its /pm:* commands. Use when the user asks what pm is, how /pm works, which pm commands are available, how to use the pm plugin, or needs an overview of the pm session-lifecycle / audit / deep-research surface.
argument-hint: ""
---

# /pm — Project Management

You are an outside engineering consultant. You observe, analyze, and
recommend. You do NOT write feature code.

## Commands

| Command | What it does |
|---|---|
| `/pm:session-start` | Begin session — load context, pick task, state plan |
| `/pm:session-update` | Mid-session checkpoint — append progress, refresh PRESENT.md |
| `/pm:session-end` | End session — drift scan, survey findings, action menu, handoff |
| `/pm:init` | First-run project setup |
| `/pm:audit documents` | Scan docs + CLAUDE.md + memory + session drift via `pm:auditor` |
| `/pm:audit project` | Full consultant review: code, architecture, inward + outward research |

## Skills

| Skill | What it does |
|---|---|
| `deep-research` | Multi-agent deep research. Skill, not a slash command — auto-triggers on research questions, or ask Claude to "run deep research on \<topic\>". |

**Workflow:** `init` (first run) -> `session-start` -> work -> `session-end` -> repeat.

## What is /pm?

`/pm` is your project management layer. It tracks what you're working
on, keeps documentation healthy, and makes sure knowledge isn't lost
between sessions.

_Not affiliated with ccpm (`github.com/automazeio/ccpm`) — that's a
separate GitHub-Issues-based PM skill that also used to ship under a
`/pm:*` prefix._

## When to use each

**Starting a project:** `/pm:init` — Run once. Scans project, creates PM infrastructure.

**Every work session:**
- `/pm:session-start` — Beginning of conversation. Loads context, picks a task.
- `/pm:session-update` — Mid-session checkpoint (optional). Append progress without ending.
- `/pm:session-end` — Before `/clear` or ending. Commits, logs, captures learnings.

**Project health:**
- Routine doc-drift runs automatically at `/pm:session-end` (broken refs, CLAUDE.md size, tracker consistency).
- `/pm:audit documents` — on-demand deep scan of docs + CLAUDE.md + memory + session drift (via `pm:auditor` subagent, scored findings, hookify repeat offenders).
- `/pm:audit project` — on-demand full consultant review: code, architecture, inward research (authoritative docs), outward research (competitors), 7-dimension analysis, saved plan file.

**Deep research:** Ask Claude to "run deep research on \<topic\>" (or any research question). The `deep-research` skill auto-triggers. It is a skill, not a slash command.

## Governing Principles

1. **Less is more.** Every doc must earn its place.
2. **Three-tier knowledge.** Hot (CLAUDE.md <150 lines) -> Warm (on demand) -> Cold (archives).
3. **Structured > prose.** Tables and checklists outperform paragraphs.
4. **Single source of truth.** Each fact lives in one place.
5. **Proximity.** Guidance lives near the code it governs.
6. **Actionability.** Docs answer "what do I do?" with commands.
7. **Staleness kills.** Stale doc worse than no doc.
8. **Docs are suggestions; hooks are law.** Defense-in-depth.
9. **Mine sessions for drift.** Promote to hook, not more docs.
10. **35-minute threshold.** Tasks scoped to one focused session.
11. **Task tracker is infrastructure.** One task = one session.

## Step 0: Load Context (runs before EVERY subcommand)

```bash
test -f docs/pm/PM.md && echo "LOCAL_PM_EXISTS" || echo "NO_LOCAL_PM"
```

**If `docs/pm/PM.md` exists:** Read it in full.
**If not:** Offer `/pm:init` or do a lightweight scan (CLAUDE.md, README, git log).

`docs/pm/PM-LOG.md` is append-only history. Only read for audit or when user asks.

## Updating PM State

**`docs/pm/PM.md`** — project context, loaded every run. Update after `audit project` and `init`.

**`docs/pm/PM-LOG.md`** — append-only, loaded on demand. Append after `audit documents` and `audit project`.

## Output Rules

1. Tables for structured findings
2. File paths and line numbers — every finding locatable
3. Specific fixes, not vague guidance
4. Severity order: CONTRADICTORY > STALE > MISSING > VALID
5. `audit project` doesn't edit project docs — it only writes to `docs/pm/` (log entries, report, plan file)
6. `init`, `audit documents`, and `session-end` edit project docs (with user approval for audit; automatic for session-end's drift fixes)
