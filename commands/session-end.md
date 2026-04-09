---
description: "End a session — survey, auto-update core PM state, present action menu, then handoff"
argument-hint: ""
allowed-tools: ["Read", "Write", "Edit", "Bash(git:*)", "Bash(rm:*)", "Glob", "Grep"]
---

# Session End

End the current work session in five phases:
**Analyze → Auto-apply core PM updates → Present menu → Execute → Handoff**.

Core PM bookkeeping (`docs/pm/past/YYYY-MM-DD.md`, `docs/pm/PRESENT.md`,
`docs/pm/FUTURE.org`) is updated automatically — **no prompts, no diff
approval**. Only ask the user about actions outside that scope:
committing uncommitted items, recording findings (promoting learnings
to permanent docs), and anything else specific to the session.

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

### 1e. Doc-drift quick scan (inline, no subagent)

Fast hygiene pass. Do NOT launch the `pm:auditor` subagent — this is
the cheap automatic check that used to live in `/pm:audit light`.
Scope is small enough to run inline every session end.

Check:
- **Broken file references** — scan `CLAUDE.md`, `README.md`, and
  `docs/pm/*.md` for backticked paths (`` `path/to/file` ``); verify
  each resolves on disk
- **CLAUDE.md size** — warn if line count > 120, critical if > 150
- **`NOT_IMPLEMENTED` stubs** — `grep -rn NOT_IMPLEMENTED` across
  source; compare count against any claims in `PRESENT.md`
- **Tracker consistency** — any `PRESENT.md` "Completed Work" entry
  that doesn't appear as DONE in `FUTURE.org`? Any `FUTURE.org` DONE
  item that isn't reflected in `PRESENT.md`?
- **Stale daily log** — most recent file in `docs/pm/past/` older
  than 7 days while work has been committed since?

Collect any findings into a `drift_findings` list for Phase 3. If
nothing surfaces, the list is empty and Phase 3 reports "no drift".
This is an observation pass only — no fixes yet.

---

## Phase 2: Auto-apply core PM updates

Apply these updates immediately without asking. No previews, no diff
approval. If a particular file genuinely has nothing to update, skip
it and note "no changes" in the Phase 3 report.

### Update past log
- Append to (or create) `docs/pm/past/YYYY-MM-DD.md`
- Sections: Accomplished, Key Discoveries, What Didn't Work, Next

### Update PRESENT.md
- Update only the fields that actually changed this session

### Update FUTURE.org (with native task reconciliation)
- Mark completed tasks DONE with today's date
- Update IN-PROGRESS items with current state
- Add discovered TODOs
- **Reconcile with native tasks.** Read the current `TaskList`:
  - For each native task **completed this session**, mark the
    corresponding `FUTURE.org` entry DONE with today's date. If no
    matching entry exists, append a DONE line.
  - For each native task still **in-progress or pending** created
    this session without a `FUTURE.org` counterpart, append as
    TODO (or IN-PROGRESS if active).
  - **Do not delete** native tasks — they persist for the next session.

### Commit the PM updates

After writing the files, commit just the core PM bookkeeping as a
dedicated commit — keeping it separate from any source-code changes
the user may still have uncommitted.

```bash
# Stage only the files Phase 2 may have touched
git add docs/pm/past/$(date +%Y-%m-%d).md docs/pm/PRESENT.md docs/pm/FUTURE.org 2>/dev/null

# Commit only if something was actually staged
git diff --cached --quiet || git commit -m "pm: session end — update past/present/future"
```

If nothing was staged (all three files were "no changes"), skip the
commit silently. If the commit fails (e.g., pre-commit hook rejection),
note it in the Phase 3 report and continue — do not block the session
end on it.

---

## Phase 3: Present findings + action menu

Show a structured summary of the session and the core PM updates just
applied, then present the non-PM action menu. **Wait for the user to
pick.**

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

### Core PM state updated
- `docs/pm/past/YYYY-MM-DD.md` — [what was logged, or "no changes"]
- `docs/pm/PRESENT.md` — [what changed, or "no changes"]
- `docs/pm/FUTURE.org` — [what was marked/added, or "no changes"]

### Doc-drift scan
- [one-line per finding, or "no drift detected"]

---

## Actions (pick any, multiple OK)

1. **Commit changes** — group and commit uncommitted files

2. **Record findings** — promote session learnings to permanent docs (CLAUDE.md, debugging guide, memory file, etc.)

3. **Fix drift** — apply the doc-drift findings from 1e (only shown if `drift_findings` is non-empty)

4. **Other** — anything else specific to this session

Which actions? (e.g., `1,2` · `all` · `none`)
```

Wait for the user's choice. Do not proceed without it.

---

## Phase 4: Execute chosen actions

Only run the actions the user picked. For each action, ask any
followup questions needed before acting.

### Action 1: Commit changes
- If multiple logical groups exist, ask whether to commit them as
  one commit or split into several
- Confirm files to include (avoid `git add .` — list files explicitly)
- Draft a commit message and show it before committing
- For commit message format, follow the project's existing style
  (check `git log --oneline -10`)

### Action 2: Record findings
- For each learning, ask:
  > "This session established [learning]. Should this become permanent
  > guidance in [CLAUDE.md / debugging-workflow.md / a memory file]?"
- Only promote if the user agrees
- Show the addition before writing

### Action 3: Fix drift
- For each `drift_findings` entry the user accepted, apply the
  obvious fix (repair the broken ref, update the contradictory
  tracker, etc.). For ambiguous drift (e.g. a NOT_IMPLEMENTED stub
  whose implementation path isn't clear), surface it back to the
  user instead of guessing.
- After fixes land, note them in the today's past log under a
  "Doc-drift fixes" subsection.

### Action 4: Other
- Handle whatever the user asks

After each action, briefly confirm completion. After ALL chosen
actions complete, move to Phase 5.

---

## Phase 5: Handoff

Only after Phase 4 is done. Present the handoff in this exact form:

```
## Session done

**What's next:** [specific task for the next session, or
"unknown — pick from FUTURE.org"]

[If mid-task: note exactly where it left off so the next session
can resume without re-investigation]

---

To start a new session:
1. Run `/clear` to clear this context
2. Run `/pm:session-start` in the fresh session
```

Then clear the session marker:
- `rm -f docs/pm/~pm-session-active`

That's the end. Do not continue the conversation after this.
