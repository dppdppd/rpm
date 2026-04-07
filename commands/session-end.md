---
description: "End a session — commit, update progress + tasks, capture learnings"
argument-hint: ""
allowed-tools: ["Read", "Write", "Edit", "Bash(git:*)", "Bash(rm:*)", "Glob", "Grep"]
---

# Session End

End the current work session. Follow these steps:

## 1. Commit outstanding work
- `git status` — check for uncommitted changes
- Commit or ask the user what to do with them
- Nothing left uncommitted silently

## 2. Update progress
- Append session notes to `docs/pm/progress/YYYY-MM-DD.md` (create if needed):
  - What was accomplished
  - Key discoveries or decisions
  - What didn't work and why
- Update `docs/pm/progress/STATUS.md` if project status changed

## 3. Update task tracker
- Update `docs/pm/TASKS.org`:
  - Mark completed tasks DONE with date
  - Update IN-PROGRESS items with current state
  - Add any discovered TODO items

## 4. Capture session learnings
Review the session for new processes, conventions, or corrections.
Look for:
- Corrections the user made ("don't do X", "always do Y")
- New workflows or patterns that emerged
- Debugging approaches that worked (or didn't)
- Decisions about architecture, tooling, or process

For each learning found, write it to the progress daily file and ask:
> "This session established [learning]. Should this become permanent
> guidance in [CLAUDE.md / a project doc / a memory file]?"

Only promote if the user agrees.

## 5. State handoff
- "Session done. Next session should start with: [specific task]"
- If mid-task, note exactly where it left off
- `rm -f docs/pm/tmp/pm-session-active` — clear the session marker
