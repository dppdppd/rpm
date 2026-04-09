# /pm session update — Full Instructions

Lightweight mid-session checkpoint. Append progress to today's daily
log and refresh `docs/pm/PRESENT.md` fields that changed.

**Does not** show an action menu, commit, touch `FUTURE.org`, or
handoff. Use this between `/pm session start` and `/pm session end`
for long sessions that benefit from explicit bookmarks — especially
before a risky operation or right before context gets crowded.

---

## Phase 1: Analyze (read-only)

### 1a. Confirm the session is active
- Check that `docs/pm/tmp/pm-session-active` exists. If missing,
  warn that `/pm session start` was not run and stop — there is no
  session to update.

### 1b. Detect scope of the checkpoint
- `git status --short` — what files have been modified since the last
  checkpoint?
- Read `docs/pm/past/$(date +%Y-%m-%d).md` — what update sections
  already exist today? The new update appends below the latest one.
- Read `docs/pm/PRESENT.md` — which fields still reflect reality?

### 1c. Review the conversation since the last checkpoint
Look back through the conversation for:
- **Accomplished since last checkpoint** — features built, bugs fixed,
  decisions made
- **In progress** — what you're in the middle of right now
- **Discoveries** — new learnings about the code or system
- **Native tasks** (optional) — read `TaskList` for a status snapshot

---

## Phase 2: Write the checkpoint

Apply updates without asking. No diff approval, no menu.

### Append to `docs/pm/past/YYYY-MM-DD.md`

Append a timestamped subsection below any existing content for today:

```markdown
### HH:MM update
- Accomplished since last checkpoint: [bullet list]
- In progress: [one sentence]
- Discoveries: [brief]
- Native tasks: M completed · N in-progress · K pending   ← optional
```

If the daily file doesn't exist yet, create it with the standard
header first, then append the update.

### Refresh `docs/pm/PRESENT.md`

Update only fields that actually changed since the last read. If
nothing material changed, skip.

### Do NOT touch `FUTURE.org`

`FUTURE.org` edits — marking tasks DONE, reconciling native tasks,
adding discovered TODOs — belong to `/pm session end`, not here.
Checkpoints are observation, not reconciliation.

### Do NOT commit

A checkpoint is a lightweight bookmark. Committing belongs to
`/pm session end`.

---

## Phase 3: One-line confirmation

Print a single line and stop. Do not continue into session-end logic.

```
Checkpointed at HH:MM — appended to past/YYYY-MM-DD.md, PRESENT.md refreshed.
```
