---
name: session-end
description: End the current rpm session. Five phases — analyze → auto-apply tracker updates (past/present/future) → present action menu → execute → handoff. Commits rpm bookkeeping. Invoke when the user signals wrap-up. Do not auto-run — if you think it's time, propose first and wait for confirmation.
argument-hint: ""
allowed-tools: Read Write Edit Bash(bash:*) Bash(git:*) Bash(rm:*) Glob Grep
---

# /session-end

End the current work session in five phases:
**Analyze → Auto-apply tracker updates → Present menu → Execute → Handoff**.

Core rpm bookkeeping (`docs/rpm/past/YYYY-MM-DD.md`, `docs/rpm/present/status.md`,
`docs/rpm/future/tasks.org`) is updated automatically during Phase 2 — **no
prompts, no diff approval**. Only ask the user about actions outside
that scope: committing uncommitted items, recording findings
(promoting learnings to permanent docs), and anything else specific
to the session.

## Pre-flight

If this skill auto-loaded (you judged the user is wrapping up), ask
first — "You seem ready to wrap up. Want me to run `/session-end`?"
— and wait. Phase 2 commits tracker updates; don't trigger on a
false positive, and don't ask twice. If the user explicitly typed
`/session-end`, skip this and go to Phase 1.

---

## Phase 1: Analyze (parallel, read-only)

### 1a. Mechanical scan (auto-injected, no tool call needed)

The `scan.sh` output below was produced by a shell script that ran
**before** this skill body reached you. Its results are already in
this message — do NOT re-run these checks as tool calls.

!`bash "${CLAUDE_SKILL_DIR}/scripts/scan.sh"`

**Interpreting the sections:**

- `git` — modified / untracked / staged file counts + stash count.
  This is your Phase 1a uncommitted-state summary.
- `claude_md` — line count + status (`ok` / `warn` >120 / `critical`
  >150). Only raise as a finding if `warn` or `critical`.
- `not_implemented` — count and up to 20 matches. Meta-references
  inside audit/session-end skill bodies (matches on files under
  `skills/audit/`, `skills/session-end/`, `command-version/`,
  `agents/auditor.md`) are expected and should be **suppressed**.
  Only flag real stubs in source.
- `broken_refs` — backticked path references in `CLAUDE.md`,
  `README.md`, `docs/rpm/context.md` that don't resolve on disk.
  `count > 0` is always actionable. (`present/status.md`, `past/log.md`,
  and `past/*.md` are deliberately excluded as historical.)
- `daily_log` — today's date, most recent log date, days since,
  commits since. If `today_exists=false` and `commits_since > 0`,
  Phase 2 needs to create today's log.
- `session_marker` — whether `docs/rpm/~rpm-session-start` exists.
  Phase 5 will remove it only if it exists.
- `specs_inventory` — if a spec dir exists, `total` / `listed` /
  `unlisted` counts against `present/status.md`. `unlisted > 0` is a
  drift signal — status.md isn't enumerating all specs. Up to
  10 `unlisted_sample=` lines identify which. `status=no_spec_dir`
  means the project has no spec directory (no action).
- `pm_docs_staleness` — `file=<path> days=<N>` pairs for loose
  log/tracker/inventory files under `docs/` and `docs/rpm/`. Flag
  as possible drift if `days > 3` AND the session touched related
  work — the file may need an entry. `days=0` means freshly
  updated (no action). `count=0` means nothing to check.
- `task_deps` — `future/tasks.org` dependency graph validation. `dangling=`
  lines are broken references (task references a non-existent ID).
  `ready=` lines are tasks newly unblocked by this session's work.
  Surface both in Phase 3 findings.
- `migration` — if `count > 0`, auto-migrate before continuing:
  `mkdir -p` target dirs, `mv` each `move=old→new` pair, `git add`
  both old and new paths. Print what was moved, then proceed.
- `learnings_capture` — auto-captured learning excerpts from the
  Stop hook. `entries > 0` means the hook found learning signals
  during this session. Use these as pre-populated input for
  Phase 1c — they supplement (not replace) conversation review.

### 1b. Fire remaining reads in parallel

In a SINGLE message, issue all of these concurrently — do NOT
sequence them:

- Read `docs/rpm/future/tasks.org` — tasks to mark DONE, IN-PROGRESS
  updates, new TODOs surfaced this session
- Read `docs/rpm/present/status.md` — which fields still reflect reality
- Read `docs/rpm/past/YYYY-MM-DD.md` (today's date) — **only if
  `today_exists=true` in the 1a scan**. Phase 2 appends to this
  file; reading it now means the Phase 2 writes can all fire in
  parallel with no hidden pre-read.
- Call `TaskList` — native task state for reconciliation

### 1c. Synthesize the conversation (concurrent with 1b)

While the 1b reads are in flight, look back through this session's
conversation for:

- **Accomplishments**: features built, bugs fixed, tests passing
- **Decisions**: architectural choices, tradeoffs made
- **Discoveries**: things you learned about the code/system
- **Learnings**: corrections from the user, new patterns, debugging
  approaches that worked or didn't
- **Mid-task state**: anything left unfinished

If the 1a scan shows `learnings_capture entries > 0`, use those
excerpts as a head start — they were auto-captured by the Stop
hook when learning signals were detected mid-session. Deduplicate
against what you find in the conversation review.

### 1d. Assemble `drift_findings`

From the 1a scan output and the 1b tracker reads, collect any
drift items that warrant user action into a `drift_findings`
list for Phase 3 presentation. Suppress trivial meta-matches.

### 1e. Backfill an unassigned task title

If `docs/rpm/~rpm-session-start` has `task: (unassigned)` — the
user started the session without picking from the menu — derive a
concise title (5–8 words, imperative form) from the 1c synthesis,
git log, and modified files. Do NOT ask the user; auto-assign.

Edit the marker to replace `task: (unassigned)` with the derived
title. All downstream phases (daily log header, `~rpm-last-session`,
handoff text) will then see the real title instead of "(unassigned)".

---

## Phase 2: Auto-apply tracker updates (parallel writes)

Apply these updates immediately without asking. No previews, no
diff approval. If a particular file genuinely has nothing to
update, skip it and note "no changes" in the Phase 3 report.

**In a SINGLE message, issue all three writes concurrently:**

1. **Write** `docs/rpm/past/YYYY-MM-DD.md` — append if exists,
   create if not. Sections: Accomplished, Key Discoveries, What
   Didn't Work, Next.
2. **Edit** `docs/rpm/present/status.md` — update only the fields that
   actually changed this session.
3. **Edit** `docs/rpm/future/tasks.org` — mark completed tasks DONE with
   today's date, update IN-PROGRESS items, append discovered TODOs.
   New TODOs: one short sentence + link to `future/<date>-<slug>.md`.
   Write the detail file for each new task. Reconcile with native
   tasks per the rules below.

### Native task reconciliation (within the `future/tasks.org` edit above)

- Native task done this session → mark its tasks.org entry DONE
  (append if missing).
- Native task still in-progress/pending → append as TODO/IN-PROGRESS
  if no tasks.org counterpart.
- Never delete native tasks; they persist across sessions.
- Orphan entries in `~rpm-native-tasks.jsonl` from prior sessions →
  offer to promote as TODOs before Phase 5 cleanup.

### Task candidates (from TaskCompleted hook)

If `docs/rpm/~rpm-task-candidates.jsonl` exists, each line is a
completed native task scored against a tasks.org heading by the
`task-capture.sh` hook. Schema:

```jsonl
{"ts":"...","session":"...","event":"complete","native_id":"t7","native_subject":"...","match":{"heading":"...","id":"...","confidence":85}}
{"ts":"...","session":"...","event":"complete","native_id":"t9","native_subject":"...","match":null}
```

Consume as follows:

- **`match.confidence >= 80`**: auto-mark the tasks.org entry DONE
  with today's date. No question. Note it in Phase 3 under
  "Tracker updates".
- **`match.confidence` 40–79**: surface as one consolidated finding
  in Phase 3 — list `native_subject → heading (confidence N)` and
  ask yes/no per row (or `all`/`none`). Apply DONE edits on the
  user's picks.
- **`match:null`** or missing: ignore mechanically; conversation
  synthesis in Phase 1c may still catch it.

Prefer `match.id` (via the `:ID:` property) over heading-text edits
when the entry has one — ID-targeted edits survive heading rewrites.

### Commit tracker updates + present findings (same response)

After all three writes land, combine the commit and the Phase 3
findings presentation in a **single response** — the commit as a
tool call, the findings as text output alongside it. This saves a
round trip.

```bash
git add docs/rpm/past/$(date +%Y-%m-%d).md docs/rpm/present/status.md docs/rpm/future/tasks.org 2>/dev/null
git diff --cached --quiet || git commit -m "rpm: session end — update past/present/future"
```

If nothing was staged (all three were "no changes"), skip the
commit silently. If the commit fails (e.g., pre-commit hook
rejection), note it in the findings and continue — do not block
the session end on it.

---

## Phase 3: Present findings + action menu

**This output goes in the same response as the Phase 2 commit
above.** Show a structured summary of the session and the tracker
updates just applied, then present the action menu. **Wait
for the user to pick.**

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

### Tracker updates
- `docs/rpm/past/YYYY-MM-DD.md` — [what was logged, or "no changes"]
- `docs/rpm/present/status.md` — [what changed, or "no changes"]
- `docs/rpm/future/tasks.org` — [what was marked/added, or "no changes"]

### Doc-drift scan
- [one-line per finding, or "no drift detected"]

---

## Actions (pick any, multiple OK)

List only actions whose precondition holds (e.g. `Commit changes`
only if something's uncommitted). Number sequentially — numbers are
session-specific.

Possible actions:

- **Commit changes** — group and commit uncommitted files
  *(only if scan shows modified/untracked/staged > 0)*

- **Record findings** — promote session learnings to permanent docs
  *(only if the Discovered learnings section is non-empty)*

- **Fix drift** — apply the doc-drift findings
  *(only if `drift_findings` is non-empty)*

Which actions? (e.g., `1,2` · `all` · `none`)
```

If exactly one action remains after filtering, drop the numbered
list and the `all · none` grammar — ask directly:

```
Run **{action name}**? (yes / no)
```

If no actions remain after filtering, skip the menu entirely and
proceed directly to Phase 5.

Otherwise, wait for the user's choice. Do not proceed without it.

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
- Filter out learnings already captured (in code comments, specs,
  existing memory files, etc.) — do NOT show them.
- Present only unrecorded learnings as a single numbered menu with
  a proposed destination for each:
  ```
  1. [learning summary] → memory file
  2. [learning summary] → CLAUDE.md
  ```
  Then ask: "Which to promote? (e.g., `1,2` · `all` · `none`)"
- If only one learning remains, skip the numbered list and ask
  directly: `Promote **[summary]** → {destination}? (yes / no)`
- One list, one question. Do not pre-filter, recommend, or renumber.
- Only promote the ones the user picks
- Show the addition before writing

### Action 3: Fix drift
- For each `drift_findings` entry the user accepted, apply the
  obvious fix (repair the broken ref, update the contradictory
  tracker, etc.). For ambiguous drift (e.g. a NOT_IMPLEMENTED stub
  whose implementation path isn't clear), surface it back to the
  user instead of guessing.
- After fixes land, note them in the today's past log under a
  "Doc-drift fixes" subsection.

After each action, briefly confirm completion. After ALL chosen
actions complete, move to Phase 5.

---

## Phase 5: Handoff

Only after Phase 4 is done.

### 5a. Decide What's next (reconcile tasks.org priority)

`tasks.org` is priority-ordered; the top actionable task (topmost
`** TODO` or `** IN-PROGRESS` with all `:BLOCKED_BY:` deps DONE) is
the default `What's next`. Re-read the file (post-Phase 2) and check
for a mismatch:

- User worked below the top → order probably doesn't reflect priority.
- Top is blocked by an incomplete dep → blocker moves up, or blocked moves down.
- User flagged the list during the session.

If any holds, end this response with ONE question (e.g. "You worked
on X today; move it above Y?") and wait. Apply the agreed reordering
by editing `tasks.org`, commit as `rpm: session end — reorder
tasks.org priority`. Otherwise proceed to 5b with the top as
`What's next`.

### 5b. Finalize handoff (single response)

**Single response** — the rm tool call and the handoff text go in
the same message:

- Save last session info before cleanup:
  ```bash
  TASK=$(grep -oP 'task: \K.*' docs/rpm/~rpm-session-start 2>/dev/null | head -1)
  SID=$(grep -oP 'session_id: \K.*' docs/rpm/~rpm-session-start 2>/dev/null | head -1)
  printf 'task: %s\nended: %s\nnext: %s\n' "${TASK:-unknown}" "$(date -Iseconds)" "{reconciled What's next from 5a}" > docs/rpm/~rpm-last-session
  # Handoff marker — session-start consumes this to silently clear any
  # orphan ~rpm-session-start left behind by /clear in this same process.
  printf 'session_id: %s\n' "${SID:-unknown}" > docs/rpm/~rpm-session-end
  ```
- Clear session files: `rm -rf docs/rpm/~rpm-session-start docs/rpm/~rpm-compact-state docs/rpm/~rpm-learnings.jsonl docs/rpm/~rpm-native-tasks.jsonl docs/rpm/~rpm-task-candidates.jsonl`
- Output the handoff text below as the **very last lines**:

```
## Session done

**What's next:** [reconciled top task from 5a, or
"unknown — pick from future/tasks.org" if the list is empty]

[If mid-task: note exactly where it left off so the next session
can resume without re-investigation]

---

To start a new session:
1. Run `/clear` to clear this context
2. Start a new conversation — rpm context auto-loads
```

Do not continue the conversation after this.
