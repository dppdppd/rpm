# /pm session end — Full Instructions

End the current work session in four phases:
**Analyze → Present menu → Execute → Handoff**.

Do NOT proactively commit, write progress files, or update tasks.
Survey what's available, present findings, wait for the user to pick
which actions to take.

---

## Phase 1: Analyze (read-only, no edits)

Gather findings without taking any action yet.

### 1a. Check uncommitted state
- `git status` — list modified, staged, untracked files
- `git stash list` — note any stashes
- Group files by category (source, docs, tests, tools, build artifacts)

### 1b. Review the session
Look back through this conversation for:
- **Accomplishments**: features built, bugs fixed, tests passing
- **Decisions**: architectural choices, tradeoffs made
- **Discoveries**: things you learned about the code/system
- **Learnings**: corrections from the user, new patterns, debugging
  approaches that worked or didn't
- **Mid-task state**: anything left unfinished

### 1c. Check the future tracker
- Read `docs/pm/FUTURE.org` (or equivalent)
- Identify tasks that should be marked DONE
- Identify IN-PROGRESS tasks that need a status update
- Identify TODO items discovered during the session

### 1d. Check the present tracker
- Note whether `docs/pm/PRESENT.md` reflects current state
- Check if a daily file in `docs/pm/past/YYYY-MM-DD.md` already
  exists for today

---

## Phase 2: Present findings + action menu

Show the user a structured summary, then present a numbered menu of
actions they can take. **Wait for the user to pick.**

### Format

```
## Session End — Findings

### Accomplishments
- [Bullet list of what was completed]

### Uncommitted changes
- N modified files: [brief categories]
- N untracked files: [brief categories]
- N staged files

### Discovered learnings
- [Bullet list of learnings, corrections, patterns]

### Future tracker state
- Tasks to mark DONE: [list]
- IN-PROGRESS to update: [list]
- New TODOs to add: [list]

---

## Available actions (pick any, multiple OK)

1. **Commit changes** — group and commit uncommitted files
2. **Update past log** — write today's session notes to
   `docs/pm/past/YYYY-MM-DD.md`
3. **Update PRESENT.md** — refresh current project state if it changed
4. **Update FUTURE.org** — mark DONE, update IN-PROGRESS, add TODOs
5. **Promote learnings** — move session learnings to permanent docs
   (CLAUDE.md, debugging guide, memory file, etc.)
6. **Other** — anything else specific to this session

Which actions? (e.g., "1,2,4", "all", "skip everything")
```

Wait for the user's choice. Do not proceed without it.

---

## Phase 3: Execute chosen actions

Only run the actions the user picked. For each action, ask any
followup questions needed before acting.

### Action 1: Commit changes
- If multiple logical groups exist, ask whether to commit them as
  one commit or split into several
- Confirm files to include (avoid `git add .` — list files explicitly)
- Draft a commit message and show it before committing
- For commit message format, follow the project's existing style
  (check `git log --oneline -10`)

### Action 2: Update past log
- Append to or create `docs/pm/past/YYYY-MM-DD.md`
- Sections: Accomplished, Key Discoveries, What Didn't Work, Next
- Show the user the draft before writing

### Action 3: Update PRESENT.md
- Update only the fields that actually changed
- Show diff before saving

### Action 4: Update FUTURE.org
- Mark completed tasks DONE with date
- Update IN-PROGRESS items with current state
- Add discovered TODOs
- Show diff before saving

### Action 5: Promote learnings
- For each learning, ask:
  > "This session established [learning]. Should this become permanent
  > guidance in [CLAUDE.md / debugging-workflow.md / a memory file]?"
- Only promote if the user agrees
- Show the addition before writing

### Action 6: Other
- Handle whatever the user asks

After each action, briefly confirm completion. After ALL chosen
actions complete, move to Phase 4.

---

## Phase 4: Handoff

Only after Phase 3 is done. Present the handoff in this exact form:

```
## Session done

**What's next:** [specific task for the next session, or
"unknown — pick from FUTURE.org"]

[If mid-task: note exactly where it left off so the next session
can resume without re-investigation]

---

To start a new session:
1. Run `/clear` to clear this context
2. Run `/pm session start` in the fresh session
```

Then clear the session marker:
- `rm -f docs/pm/tmp/pm-session-active`

That's the end. Do not continue the conversation after this.
