---
name: session-start
description: Begin a new pm work session. Loads context from docs/pm/PRESENT.md, the most recent daily log in docs/pm/past/, FUTURE.org, and CLAUDE.md; checks for leftover uncommitted work; writes a session marker; states a plan; hydrates a native task for the picked FUTURE.org item. Use at the start of a fresh /clear'd conversation on a repo with pm infrastructure, or when the user says "let's start working", "begin session", "start a new pm session", or similar.
argument-hint: ""
allowed-tools: Read Write Bash(bash:*) Bash(cat:*) Glob TaskCreate
---

# /pm:session-start

Start a new work session. Follow these steps in order.

**Response rules:**
- Questions go at the **end** of a response, never mid-stream.
- When asking the user to choose, use a numbered menu.
- Never present an action whose precondition is empty.

---

## Phase 1: Mechanical scan (auto-injected, zero tool calls)

The scan output below was produced by a shell script that ran
**before** this skill body reached you. Do NOT re-run these checks.

!`bash "${CLAUDE_SKILL_DIR}/scripts/scan.sh"`

**Interpreting the sections:**

- `latest_past` — `file=YYYY-MM-DD.md` or `file=none`. Use this
  filename for the Phase 2 read of the most recent daily log.
- `git` — modified / untracked / staged / stashes. If any > 0,
  that's leftover work from a prior session.
- `present_drift` — `drift_count=0` means PRESENT.md is current.
  `drift_count > 0` lists commits since PRESENT.md was last
  touched — trackers may need reconciliation before picking a task.
- `session_marker` — if `exists=true`, a prior session didn't
  run `/pm:session-end`. Marker contents are printed so you can
  report what was in progress.

---

## Phase 2: Recover context (parallel reads — single message)

Using the `latest_past` filename from Phase 1, fire all four reads
concurrently in a SINGLE message:

- `docs/pm/PRESENT.md`
- `docs/pm/past/{file from latest_past}` (skip if `file=none`)
- `docs/pm/FUTURE.org`
- `CLAUDE.md`

---

## Phase 3: Present state + plan

Synthesize the scan + reads into a single response. Include:

- **Leftover state** (if any): uncommitted files, stashes, stale
  session marker. Ask user how to handle.
- **Tracker drift** (if `drift_count > 0`): list the commits and
  ask whether to reconcile PRESENT.md + FUTURE.org before picking
  a task. Reconciliation is usually the right first move.
- **Session plan**: "This session: [task from FUTURE.org], because
  [reason]". If the plan deviates from tracker priorities, say so.

If there's nothing to resolve (clean state, no drift), go straight
to the plan. End the response with any questions that need answers
before proceeding.

---

## Phase 4: Mark session active + hydrate task

After the user confirms (or if no confirmation was needed):

1. Write the session marker:
   ```bash
   cat > docs/pm/~pm-session-active << MARKER
   ---
   session_id: ${CLAUDE_CODE_SESSION_ID:-unknown}
   started: $(date -Iseconds)
   task: {planned task from FUTURE.org}
   ---
   MARKER
   ```

2. Create a native task via `TaskCreate`:
   - `subject` = the org heading text
   - `description` = task body (or a one-line restatement)
   - `activeForm` = present-continuous phrase for the spinner
   Leave existing native tasks from prior sessions alone.
