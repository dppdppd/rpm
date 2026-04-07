---
description: "Start a work session — load context, pick task, state plan"
argument-hint: ""
allowed-tools: ["Read", "Bash(git status:*)", "Bash(git stash:*)", "Bash(ls:*)", "Bash(mkdir:*)", "Bash(cat:*)", "Write"]
---

# Session Start

Start a new work session. Follow these steps in order:

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
   cat > docs/pm/tmp/pm-session-active << MARKER
   ---
   session_id: ${CLAUDE_CODE_SESSION_ID:-unknown}
   started: $(date -Iseconds)
   task: {planned task from TASKS.org}
   ---
   MARKER
   ```

4. **State the plan:**
   - "This session: [task from TASKS.org], because [reason]"
   - If the plan deviates from tracker priorities, say so and get approval
