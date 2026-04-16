---
name: session-end
description: End the current rpm session. Four user-visible phases — Collecting Findings (auto-applied tracker updates + summary) → Housekeeping (commit/record/fix) → Reviewing Tasks → Handing Off. Commits rpm bookkeeping. Invoke when the user signals wrap-up. Do not auto-run — if you think it's time, propose first and wait for confirmation.
argument-hint: ""
allowed-tools: Read Write Edit Bash(bash:*) Bash(git:*) Bash(rm:*) Glob Grep
---

# /session-end

End the current work session in four user-visible phases:

1. **Collecting Findings** — analyze, auto-apply tracker updates, present summary + actions menu
2. **Housekeeping** — execute chosen actions (commit, record findings, fix drift)
3. **Reviewing Tasks** — reconcile rpm backlog priority, decide What's next
4. **Handing Off** — write last-session info, output the handoff text

**Print a phase header** (`## Phase N (of 4): Title`) at the start of
each user-visible response. Sub-sections inside a phase use letters
(`### 1b. Uncommitted changes`).

Core rpm bookkeeping (`docs/rpm/past/YYYY-MM-DD.md`,
`docs/rpm/present/status.md`, `docs/rpm/future/tasks.org`) is updated
automatically during Phase 1's prep — no prompts, no diff approval.
Ask only about commits, promoting findings, drift fixes, and
rpm backlog reordering.

## Pre-flight

If this skill auto-loaded (you judged the user is wrapping up), ask
first — "You seem ready to wrap up. Want me to run `/session-end`?"
— and wait. Phase 1 commits tracker updates; don't trigger on a
false positive, and don't ask twice. If the user explicitly typed
`/session-end`, skip this and go to Phase 1.

---

## Phase 1 (of 4): Collecting Findings

Analyze, auto-apply tracker updates, then emit one user-visible
response with the findings block + actions menu. The prep steps
below run silently (no intermediate output).

### Prep (not user-visible)

#### Mechanical scan (auto-injected, no tool call needed)

The `scan.sh` output below was produced by a shell script that ran
**before** this skill body reached you. Its results are already in
this message — do NOT re-run these checks as tool calls.

!`bash "${CLAUDE_SKILL_DIR}/scripts/scan.sh"`

**Interpreting the sections:**

- `git` — modified / untracked / staged file counts + stash count.
  Your Phase 1 uncommitted-state summary.
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
  the auto-apply writes need to create today's log.
- `session_marker` — whether `docs/rpm/~rpm-session-start` exists.
  Phase 4 removes it only if it exists.
- `specs_inventory` — if a spec dir exists, `total` / `listed` /
  `unlisted` counts against `present/status.md`. `unlisted > 0` is a
  drift signal — status.md isn't enumerating all specs. Up to
  10 `unlisted_sample=` lines identify which. `status=no_spec_dir`
  means the project has no spec directory (no action).
- `pm_docs_staleness` — `file=<path> days=<N>` pairs for loose
  log/tracker/inventory files under `docs/` and `docs/rpm/`. Flag
  as possible drift if `days > 3` AND the session touched related
  work. `days=0` means freshly updated. `count=0` means nothing to
  check.
- `task_deps` — `future/tasks.org` dependency graph validation.
  `dangling=` lines are broken references. `ready=` lines are tasks
  newly unblocked by this session's work. Surface both in findings.
- `migration` — if `count > 0`, auto-migrate before continuing:
  `mkdir -p` target dirs, `mv` each `move=old→new` pair, `git add`
  both old and new paths. Print what was moved, then proceed.
- `learnings_capture` — auto-captured learning excerpts from the
  Stop hook. `entries > 0` means the hook found learning signals
  during this session. Use these as pre-populated input for the
  conversation synth below — they supplement (not replace)
  conversation review.

#### Fire remaining reads in parallel

In a SINGLE message, issue all of these concurrently — do NOT
sequence them:

- Read `docs/rpm/future/tasks.org` — tasks to mark DONE, IN-PROGRESS
  updates, new TODOs surfaced this session
- Read `docs/rpm/present/status.md` — which fields still reflect reality
- Read `docs/rpm/past/YYYY-MM-DD.md` (today's date) — **only if
  `today_exists=true` in the scan**. The auto-apply step appends to
  this file; reading it now lets those writes fire in parallel.
- Call `TaskList` — native task state for reconciliation

#### Synthesize the conversation (concurrent with the reads)

While the reads are in flight, look back through this session's
conversation for:

- **Accomplishments**: features built, bugs fixed, tests passing
- **Decisions**: architectural choices, tradeoffs made
- **Discoveries**: things you learned about the code/system
- **Learnings**: corrections from the user, new patterns, debugging
  approaches that worked or didn't
- **Mid-task state**: anything left unfinished

If the scan shows `learnings_capture entries > 0`, use those
excerpts as a head start. Deduplicate against conversation review.

#### Assemble `drift_findings`

From the scan output and the tracker reads, collect any drift items
that warrant user action into a `drift_findings` list for the
user-visible findings section. Suppress trivial meta-matches.

#### Backfill an unassigned task title

If `docs/rpm/~rpm-session-start` has `task: (unassigned)` — the
user started the session without picking from the menu — derive a
concise title (5–8 words, imperative form) from the synthesis, git
log, and modified files. Do NOT ask the user; auto-assign.

Edit the marker to replace `task: (unassigned)` with the derived
title. Downstream (daily log header, `~rpm-last-session`, handoff)
will see the real title instead of "(unassigned)".

#### Auto-apply tracker updates (parallel writes)

Apply these updates immediately without asking. No previews, no
diff approval. If a particular file genuinely has nothing to
update, skip it and note "no changes" in the user-visible Tracker
updates section.

**In a SINGLE message, issue all three writes concurrently:**

1. **Write** `docs/rpm/past/YYYY-MM-DD.md` — append if exists,
   create if not. Sections: Accomplished, Key Discoveries, What
   Didn't Work, Next.
2. **Edit** `docs/rpm/present/status.md` — update only the fields
   that actually changed this session.
3. **Edit** `docs/rpm/future/tasks.org` — mark completed tasks DONE
   with today's date, update IN-PROGRESS items, append discovered
   TODOs. New TODOs: one short sentence + link to
   `future/<date>-<slug>.md`. Write the detail file for each new
   task. Reconcile with native tasks per the rules below.

##### Native task reconciliation (within the `future/tasks.org` edit)

- Completed native with a high-confidence candidate match (≥80 via
  `~rpm-task-candidates.jsonl`, see "Task candidates" below) → mark
  that backlog entry DONE.
- Completed native with no backlog counterpart → let it die. It was
  ephemeral session sub-work, not backlog material.
- **In-progress or pending natives → do NOT append here.**
  **Phase 3 (Reviewing Tasks → 3a)** auto-promotes them to the
  backlog and clears the live list via `TaskUpdate`. No user
  question — creation-time was the vetting step.

##### Task candidates (from TaskCompleted hook)

If `docs/rpm/~rpm-task-candidates.jsonl` exists, each line is a
completed native task scored against an rpm backlog heading by the
`task-capture.sh` hook. Schema:

```jsonl
{"ts":"...","session":"...","event":"complete","native_id":"t7","native_subject":"...","match":{"heading":"...","id":"...","confidence":85}}
{"ts":"...","session":"...","event":"complete","native_id":"t9","native_subject":"...","match":null}
```

Consume as follows:

- **`match.confidence >= 80`**: auto-mark your rpm backlog entry DONE
  with today's date. No question. Note it in the Tracker updates
  section.
- **`match.confidence` 40–79**: surface as one consolidated finding
  — list `native_subject → heading (confidence N)` and ask yes/no
  per row (or `all`/`none`). Apply DONE edits on the user's picks.
- **`match:null`** or missing: ignore mechanically; conversation
  synthesis may still catch it.

Prefer `match.id` (via the `:ID:` property) over heading-text edits
when the entry has one — ID-targeted edits survive heading rewrites.

#### Commit tracker updates (same response as user-visible output)

After all three writes land, combine the commit and the user-visible
findings response into a **single message** — commit as a tool call,
findings as text alongside.

```bash
git add docs/rpm/past/$(date +%Y-%m-%d).md docs/rpm/present/status.md docs/rpm/future/tasks.org 2>/dev/null
git diff --cached --quiet || git commit -m "rpm: session end — update past/present/future"
```

If nothing was staged (all three were "no changes"), skip the
commit silently. If the commit fails (e.g., pre-commit hook
rejection), note it in the findings and continue.

### User-visible output

Print this block. The Actions menu at the bottom is what waits for
the user's pick.

```
## Phase 1 (of 4): Collecting Findings

### 1a. Accomplishments
- [Bullet list of what was completed]

### 1b. Uncommitted changes
- N modified files: [brief categories]
- N untracked files: [brief categories]
- N staged files

### 1c. Discovered learnings
- [Bullet list of learnings, corrections, patterns]

### 1d. Tracker updates
- `docs/rpm/past/YYYY-MM-DD.md` — [what was logged, or "no changes"]
- `docs/rpm/present/status.md` — [what changed, or "no changes"]
- `docs/rpm/future/tasks.org` — [what was marked/added, or "no changes"]

### 1e. Doc-drift scan
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
proceed directly to Phase 3 (Reviewing Tasks).

Otherwise wait for the user's choice.

---

## Phase 2 (of 4): Housekeeping

Start this response with `## Phase 2 (of 4): Housekeeping`. Only run the
actions the user picked; for each, ask any followup questions before
acting.

### 2a. Commit changes
- If multiple logical groups exist, ask whether to commit them as
  one commit or split into several
- Confirm files to include (avoid `git add .` — list files explicitly)
- Draft a commit message and show it before committing
- For commit message format, follow the project's existing style
  (check `git log --oneline -10`)

### 2b. Record findings
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

### 2c. Fix drift
- For each `drift_findings` entry the user accepted, apply the
  obvious fix (repair the broken ref, update the contradictory
  tracker, etc.). For ambiguous drift (e.g. a NOT_IMPLEMENTED stub
  whose implementation path isn't clear), surface it back to the
  user instead of guessing.
- After fixes land, note them in today's past log under a
  "Doc-drift fixes" subsection.

After ALL chosen actions complete, proceed to Phase 3.

---

## Phase 3 (of 4): Reviewing Tasks

Start this response with `## Phase 3 (of 4): Reviewing Tasks`. Two
sub-steps before handoff: dispose of remaining native tasks, then
reconcile rpm backlog priority.

### 3a. Clear native tasks (auto-promote then clear)

Native tasks are session-scoped and need clearing before handoff.
A native task's creation *is* the vetting step — if Claude put it
on the list, it was worth tracking — so every uncleared native
auto-promotes to your rpm backlog. No user question.

1. Call `TaskList`. Collect every task with status `in_progress`
   or `pending` (completed ones were handled in Phase 1 prep via
   candidate matching — skip them).

2. For each, append `** TODO <subject>` under a sensible `* Parent`
   group in your rpm backlog (match the native's scope; create a
   group if no fit). Order within the parent: append to the bottom
   (priority is the user's call at the next 3b reconciliation).

3. Call `TaskUpdate` on every surfaced task to set status=`completed`.
   This clears the live native list.

4. Report what was promoted in one line at the start of this
   response (e.g., `Promoted 3 native tasks to backlog.`), then
   proceed to 3b. No question for 3a.

If there were zero in-progress/pending natives, skip 3a silently.

### 3b. Reconcile rpm backlog priority

Your rpm backlog is priority-ordered; the top actionable task (topmost
`** TODO` or `** IN-PROGRESS` with all `:BLOCKED_BY:` deps DONE) is
the default `What's next`. Re-read the file (post-auto-apply,
post-3a-promotions) and check for a mismatch:

- User worked below the top → order probably doesn't reflect priority.
- Top is blocked by an incomplete dep → blocker moves up, or blocked moves down.
- User flagged the list during the session.
- **User deferred a task** during the session ("let's do X later",
  "postpone Y", "that can wait") → apply `/tasks postpone <task>`
  to move it to the bottom of its `* Parent` group and stamp
  `:POSTPONED: YYYY-MM-DD`.

If any holds, end this response with ONE question (e.g. "You worked
on X today, but Y is at the top of your rpm backlog. Should X move
to the top?" or "You said Y can wait — postpone it to the bottom
of its group?") and wait. Apply the agreed change by editing your
rpm backlog (use the Postpone procedure in the `/tasks` skill for
deferrals; otherwise just reorder), commit as
`rpm: session end — reorder backlog priority`. Otherwise briefly
state the top as `What's next` and proceed to Phase 4.

---

## Phase 4 (of 4): Handing Off

Only after Phase 3 is resolved. **Single response** — the rm tool
call and the handoff text go in the same message:

- Save last session info before cleanup:
  ```bash
  TASK=$(grep -oP 'task: \K.*' docs/rpm/~rpm-session-start 2>/dev/null | head -1)
  SID=$(grep -oP 'session_id: \K.*' docs/rpm/~rpm-session-start 2>/dev/null | head -1)
  printf 'task: %s\nended: %s\nnext: %s\n' "${TASK:-unknown}" "$(date -Iseconds)" "{reconciled What's next from Phase 3}" > docs/rpm/~rpm-last-session
  # Handoff marker — session-start consumes this to silently clear any
  # orphan ~rpm-session-start left behind by /clear in this same process.
  printf 'session_id: %s\n' "${SID:-unknown}" > docs/rpm/~rpm-session-end
  ```
- Clear session files: `rm -rf docs/rpm/~rpm-session-start docs/rpm/~rpm-compact-state docs/rpm/~rpm-learnings.jsonl docs/rpm/~rpm-native-tasks.jsonl docs/rpm/~rpm-task-candidates.jsonl`
- Output the handoff text below as the **very last lines**:

```
## Phase 4 (of 4): Handing Off

**What's next:** [reconciled top task from Phase 3, or
"unknown — pick from your rpm backlog" if the list is empty]

[If mid-task: note exactly where it left off so the next session
can resume without re-investigation]

---

To start a new session:
1. Run `/clear` to clear this context
2. Start a new conversation — rpm context auto-loads
```

Do not continue the conversation after this.
