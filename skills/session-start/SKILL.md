---
name: session-start
description: Begin a new pm work session. Loads context from docs/pm/PRESENT.md, the most recent daily log in docs/pm/past/, FUTURE.org, and CLAUDE.md; checks for leftover uncommitted work; writes a session marker; states a plan; hydrates a native task for the picked FUTURE.org item. Use at the start of a fresh /clear'd conversation on a repo with pm infrastructure, or when the user says "let's start working", "begin session", "start a new pm session", or similar.
argument-hint: ""
allowed-tools: Read Write Bash(git status:*) Bash(git stash:*) Bash(git log:*) Bash(ls:*) Bash(mkdir:*) Bash(cat:*)
---

# /pm:session-start

Start a new work session. Follow these steps in order:

1. **Recover context (read all in parallel — single message, multiple Read calls):**
   - `docs/pm/PRESENT.md` — current project state
   - Most recent daily file in `docs/pm/past/` — what happened last
   - `docs/pm/FUTURE.org` — current IN-PROGRESS or next TODO
   - `CLAUDE.md` — rules and key documents

2. **Check for leftover state and tracker drift:**
   - `git status` — uncommitted work from a prior session?
   - `git stash list` — stashed changes?
   - **PRESENT.md drift** — list any commits that have landed since
     `PRESENT.md` was last updated:
     ```bash
     LAST=$(git log -1 --format=%H -- docs/pm/PRESENT.md 2>/dev/null)
     [ -n "$LAST" ] && git log --oneline "${LAST}..HEAD" 2>/dev/null
     ```
     If output is non-empty, `PRESENT.md` may be stale (version
     bumps or completed work from commits that didn't go through
     `/pm:session-end`). Surface the commit list to the user and
     ask whether to reconcile `PRESENT.md` + `FUTURE.org` before
     picking a task — reconciliation is usually the right first
     move because the rest of the session plan depends on the
     trackers reflecting reality.
   - If leftover work or tracker drift exists, present to user
     before planning.

3. **Mark session active:**
   Write a session marker with metadata:
   ```bash
   cat > docs/pm/~pm-session-active << MARKER
   ---
   session_id: ${CLAUDE_CODE_SESSION_ID:-unknown}
   started: $(date -Iseconds)
   task: {planned task from FUTURE.org}
   ---
   MARKER
   ```

4. **State the plan:**
   - "This session: [task from FUTURE.org], because [reason]"
   - If the plan deviates from tracker priorities, say so and get approval

5. **Hydrate native task tracker:**
   For the picked task from `FUTURE.org`, create a matching native
   task via `TaskCreate`:
   - `subject` = the org heading text
   - `description` = task body (or a one-line restatement)
   - `activeForm` = present-continuous phrase for the in-progress spinner
   This gives you cross-session persistence and a visible
   in-progress indicator. Create subtasks with `TaskCreate` as work
   branches. **Leave existing native tasks from prior sessions
   alone** — they're picked up by `/pm:session-end` reconciliation.
