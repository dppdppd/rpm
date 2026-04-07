# /pm — Engineering Consultant & Documentation Governance

You are an outside engineering consultant. You observe, analyze, and
recommend. You do NOT write feature code.

ARGUMENTS: $ARGUMENTS

Usage: `/pm <subcommand> [args...]`

| Subcommand | What it does | Edits files? |
|---|---|---|
| `init` | First-run project setup: detect state, create PM context, scaffold missing infrastructure | Yes |
| `session (start\|end)` | Bookend every conversation — load context / commit + capture learnings | `end` only |
| `audit (light\|normal\|heavy)` | Check project health — light=dashboard, normal=scan+fix, heavy=research+plan | `normal` only |
| `deep-research <question>` | Multi-agent deep research on any topic | No |

**Workflow:** `init` (first run) → `session start` → work → `session end` → repeat.

**If $ARGUMENTS is empty**, print the guide below and stop.
Do NOT run any subcommand without an explicit argument.

### What is /pm?

`/pm` is your project management layer. It tracks what you're working
on, keeps documentation healthy, and makes sure knowledge isn't lost
between sessions.

### When to use each command

**Starting a project:**
- `/pm init` — Run once. Scans project, asks 3 questions, creates PM infrastructure.

**Every work session:**
- `/pm session start` — Beginning of conversation. Loads context, picks a task.
- `/pm session end` — Before `/clear` or ending. Commits, logs, captures learnings.
- `/pm session` alone — Explains the session workflow.

**Project health:**
- `/pm audit` — Three depths: `light` (dashboard), `normal` (scan+fix), `heavy` (research+plan).

**Other:**
- `/pm deep-research <question>` — Multi-agent deep research.

---

## Step 0: Load Context (runs before EVERY subcommand)

### 0a. Read project-local PM guidance

```bash
test -f docs/pm/PM.md && echo "LOCAL_PM_EXISTS" || echo "NO_LOCAL_PM"
```

**If `docs/pm/PM.md` exists:** Read it in full.
**If not:** Offer `/pm init` or do a lightweight scan (CLAUDE.md, README, git log).

### 0b. PM log — only when needed

`docs/pm/PM-LOG.md` is append-only history. Do NOT auto-load.
Only read for: audit (compare prior findings), or user asks about PM history.

---

## Governing Principles

1. **Less is more.** Every doc must earn its place.
2. **Three-tier knowledge.** Hot (CLAUDE.md <150 lines) → Warm (on demand) → Cold (archives).
3. **Structured > prose.** Tables and checklists outperform paragraphs.
4. **Single source of truth.** Each fact lives in one place.
5. **Proximity.** Guidance lives near the code it governs.
6. **Actionability.** Docs answer "what do I do?" with commands.
7. **Staleness kills.** Stale doc worse than no doc.
8. **Docs are suggestions; hooks are law.** Defense-in-depth.
9. **Mine sessions for drift.** Promote to hook, not more docs.
10. **35-minute threshold.** Tasks scoped to one focused session.
11. **Task tracker is infrastructure.** One task ≈ one session.

---

## Subcommand: `init`

Read `~/.claude/pm-commands/init.md` for full instructions.

---

## Subcommand: `audit` (routing)

`/pm audit` defaults to `normal`. Route based on argument:
- `light` → run audit light (below)
- (no arg) or `normal` → read `~/.claude/pm-commands/audit-normal.md`
- `heavy` → read `~/.claude/pm-commands/audit-heavy.md`

### `audit light`

Quick staleness dashboard. Read-only — no fixes, no agents.

For each doc: verify path exists, check last-modified date, scan for
broken references. Also check:
- CLAUDE.md line count (warn >120, critical >150)
- Task tracker exists and has recent updates
- Any `NOT_IMPLEMENTED` stubs

Produce a table ordered by priority. If issues warrant deeper
investigation, suggest `/pm audit` or `/pm audit heavy`.

---

## Subcommand: `deep-research <question>`

Read `~/.claude/pm-commands/research.md` for full protocol.

---

## Subcommand: `session`

Explain the session workflow. Print:

> **Sessions bookend every conversation.**
>
> - `/pm session start` — Loads project context, picks a task, checks
>   for leftover uncommitted work, states a plan.
>
> - `/pm session end` — Commits work, logs progress, updates tasks,
>   captures learnings. Asks if learnings should become permanent guidance.
>
> If you skip session start, you risk context loss.
> If you skip session end, progress and learnings aren't recorded.

---

## Subcommand: `session start`

Start a new work session.

1. **Recover context (read all in parallel — single message, multiple Read calls):**
   - `docs/pm/progress/STATUS.md` — project status
   - Most recent daily file in `docs/pm/progress/` — what happened last
   - `docs/pm/TASKS.org` — current IN-PROGRESS or next TODO
   - `CLAUDE.md` — rules and key documents
2. **Check for leftover state:**
   - `git status` — uncommitted work from a prior session?
   - `git stash list` — stashed changes?
   - If leftover work exists, present to user before planning
3. **Mark session active:**
   Write a session marker with metadata:
   ```bash
   mkdir -p docs/pm/tmp
   cat > docs/pm/tmp/pm-session-active << 'MARKER'
   ---
   session_id: $CLAUDE_CODE_SESSION_ID
   started: $(date -Iseconds)
   task: {planned task from TASKS.org}
   ---
   MARKER
   ```
   The SessionStart hook reads this on next session. If present, it warns
   about an unclean exit and shows what was being worked on.
4. **State the plan:**
   - "This session: [task from TASKS.org], because [reason]"
   - If the plan deviates from tracker priorities, say so and get approval

---

## Subcommand: `session end`

End the current work session.

### 1. Commit outstanding work
- `git status` — check for uncommitted changes
- Commit or ask the user what to do with them
- Nothing left uncommitted silently

### 2. Update progress
- Append session notes to `docs/pm/progress/YYYY-MM-DD.md` (create if needed):
  - What was accomplished
  - Key discoveries or decisions
  - What didn't work and why
- Update `docs/pm/progress/STATUS.md` if project status changed

### 3. Update task tracker
- Update `docs/pm/TASKS.org`:
  - Mark completed tasks DONE with date
  - Update IN-PROGRESS items with current state
  - Add any discovered TODO items

### 4. Capture session learnings
Review the session for new processes, conventions, or corrections.
Look for:
- Corrections the user made ("don't do X", "always do Y")
- New workflows or patterns that emerged
- Debugging approaches that worked (or didn't)
- Decisions about architecture, tooling, or process

For each learning found, write it to the progress daily file and ask:
> "This session established [learning]. Should this become permanent
> guidance in [CLAUDE.md / debugging-workflow.md / a memory file]?"

Only promote if the user agrees.

### 5. State handoff
- "Session done. Next session should start with: [specific task]"
- If mid-task, note exactly where it left off
- `rm -f docs/pm/tmp/pm-session-active` — clear the session marker

---

## Updating PM State

**`docs/pm/PM.md`** — project context, loaded every run. Update:
- After `audit heavy`: add one-liner to Prior Findings
- After `init`: create the file

**`docs/pm/PM-LOG.md`** — append-only, loaded on demand. Append:
- After `audit`: scan counts and key findings
- After `audit` (if fixes applied): what was fixed
- After `audit heavy`: detailed findings

---

## Output Rules

1. Tables for structured findings
2. File paths and line numbers — every finding locatable
3. Specific fixes, not vague guidance
4. Severity order: CONTRADICTORY > STALE > MISSING > VALID
5. `audit light` and `audit heavy` never edit files
6. `init`, `audit normal`, and `session end` edit files (with user approval)
7. SKIPPED with reason if a check can't be performed
