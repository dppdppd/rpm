# /pm session start — Full Instructions

Start a new work session. Follow these steps in order:

1. **Recover context (read all in parallel — single message, multiple Read calls):**
   - `docs/pm/PRESENT.md` — current project state
   - Most recent daily file in `docs/pm/past/` — what happened last
   - `docs/pm/FUTURE.org` — current IN-PROGRESS or next TODO
   - `CLAUDE.md` — rules and key documents

2. **Check for leftover state:**
   - `git status` — uncommitted work from a prior session?
   - `git stash list` — stashed changes?
   - If leftover work exists, present to user before planning

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
   alone** — they're picked up by `/pm session end` reconciliation.
