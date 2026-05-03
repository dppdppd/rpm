---
name: session-end
description: End the current rpm session. Three modes — Express (silent, one message), Inline (one message + one follow-up), Phased (four-phase ceremony for complex sessions). Picks the leanest that fits. Commits rpm bookkeeping. Invoke when the user signals wrap-up. Do not auto-run — if you think it's time, propose first and wait for confirmation.
---

# /session-end

End the current work session. **Default to the leanest mode that
fits — long wrap-ups discourage frequent /session-end, which leads
to context bloat and lost sessions.** Three modes:

- **Express** — fully clean session. ONE message, no questions,
  Phase 4 cleanup inline. (Current fast-path.)
- **Inline** — has 1–2 small surfaces (a commit, a tiny learnings
  list, a drift line). ONE message containing those asks inline,
  then ONE follow-up that applies decisions + hands off.
- **Phased** — genuine multi-decision complexity. Falls back to
  the four-phase flow (the only path that prints `## Phase N (of 4)` headers).

Core rpm bookkeeping (`docs/rpm/past/YYYY-MM-DD.md`,
`docs/rpm/present/status.md`, `docs/rpm/future/tasks.org`,
`docs/rpm/future/done.org`) is updated automatically during prep
in every mode — no prompts, no diff approval. Ask only about
commits, promoting findings, drift fixes, and rpm backlog order.

Append ` (rpm <version>)` to the first heading in any mode, using
the `version=` value from scan.sh's `=== plugin ===` section —
e.g. `## Session end (rpm 2.15.0)` or
`## Phase 1 (of 4): Collecting Findings (rpm 2.15.0)`.

## Pre-flight

If this skill auto-loaded (you judged the user is wrapping up), ask
first — "You seem ready to wrap up. Want me to run `/session-end`?"
— and wait. The prep step commits tracker updates; don't trigger on
a false positive, and don't ask twice. If the user explicitly typed
`/session-end`, skip this and go straight to Prep.

---

## Prep (silent, runs in every mode)

Analyze, auto-apply tracker updates, then pick a mode and emit
output. The prep below runs without intermediate user-visible output.

### Mechanical scan (auto-injected, no tool call needed)

The `scan.sh` output below was produced by a shell script that ran
**before** this skill body reached you. Its results are already in
this message — do NOT re-run these checks as tool calls.

!`bash "${RPM_PLUGIN_ROOT:-${CODEX_HOME:-$HOME/.codex}/.tmp/marketplaces/dppdppd-rpm/.codex}/skills/session-end/scripts/scan.sh"`

**Interpreting the sections:**

- `plugin` — `version=<X.Y.Z>` from `plugin.json`. Append to the first
  heading as `(rpm <version>)`.
- `git` — modified / untracked / staged file counts + stash count.
  Drives mode selection and Inline/Phased commit handling.
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
  Phase 4 / cleanup removes it only if it exists.
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

### Fire remaining reads in parallel

In a SINGLE message, issue all of these concurrently — do NOT
sequence them:

- Read `docs/rpm/future/tasks.org` — tasks to mark DONE, IN-PROGRESS
  updates, new TODOs surfaced this session
- Read `docs/rpm/present/status.md` — which fields still reflect reality
- Read `docs/rpm/past/YYYY-MM-DD.md` (today's date) — **only if
  `today_exists=true` in the scan**. The auto-apply step appends to
  this file; reading it now lets those writes fire in parallel.
- Call `TaskList` — native task state for reconciliation

### Synthesize the conversation (concurrent with the reads)

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

### Assemble `drift_findings`

From the scan output and the tracker reads, collect any drift items
that warrant user action into a `drift_findings` list. Suppress
trivial meta-matches.

### Backfill an unassigned task title

If `docs/rpm/~rpm-session-start` has `task: (unassigned)` — the user
started the session without picking from the menu — derive a concise
title (5–8 words, imperative form) from the synthesis, git log, and
modified files. Do NOT ask the user; auto-assign.

Edit the marker to replace `task: (unassigned)` with the derived
title. Downstream (daily log header, `~rpm-last-session`, handoff)
will see the real title.

### Auto-apply tracker updates (parallel writes)

Apply these updates immediately without asking. No previews, no diff
approval. If a particular file has nothing to update, skip it and
note "no changes" in the user-visible Tracker updates section.

**In a SINGLE message, issue all three writes concurrently:**

1. **Write** `docs/rpm/past/YYYY-MM-DD.md` — append if exists, create
   if not. Sections: Accomplished, Key Discoveries, What Didn't Work,
   Next.
2. **Edit** `docs/rpm/present/status.md` — update only the fields
   that actually changed this session.
3. **Edit** `docs/rpm/future/tasks.org` — mark completed tasks DONE
   with today's date, update IN-PROGRESS items, append discovered
   TODOs. New TODOs: one short sentence + link to
   `future/<date>-<slug>.md`. Write the detail file for each new
   task. Reconcile with native tasks per the rules below.

#### Archive sweep (same edit pass)

After marking DONE / CANCELLED, cut every such heading (with its
`CLOSED:` line and property drawer) out of `tasks.org` and move it
to `docs/rpm/future/done.org`. Runs every mode — closed entries
never accumulate in the active backlog. Rules:

- Create `done.org` with the header below if it doesn't exist:
  ```org
  #+TITLE: rpm Archive
  #+TODO: TODO IN-PROGRESS BLOCKED | DONE CANCELLED

  Closed entries swept from tasks.org by session-end. Newest first.
  ```
- Mirror the parent-heading structure: an entry under `* Active` in
  tasks.org goes under `* Active` in done.org (create the parent if
  missing).
- Insert each archived entry at the **top** of its parent section in
  done.org (newest-first within a parent).
- Preserve `[[file:...]]` links, `CLOSED: [YYYY-MM-DD]`, and property
  drawers verbatim.
- Cover BOTH entries you just marked DONE AND any pre-existing
  DONE/CANCELLED entries that slipped through.

#### Native task reconciliation (within the `future/tasks.org` edit)

- Completed native with a high-confidence candidate match (≥80 via
  `~rpm-task-candidates.jsonl`, see "Task candidates" below) → mark
  that backlog entry DONE.
- Completed native with no backlog counterpart → let it die. It was
  ephemeral session sub-work, not backlog material.
- **In-progress or pending natives → do NOT append here.** The
  Native Cleanup step (Inline second message, or Phased Phase 3a)
  handles them and clears the live list via `TaskUpdate`. No user
  question — creation-time was the vetting step.

#### Task candidates (from TaskCompleted hook)

If `docs/rpm/~rpm-task-candidates.jsonl` exists, each line is a
completed native task scored against an rpm backlog heading by the
`task-capture.sh` hook. Schema:

```jsonl
{"ts":"...","session":"...","event":"complete","native_id":"t7","native_subject":"...","match":{"heading":"...","id":"...","confidence":85}}
{"ts":"...","session":"...","event":"complete","native_id":"t9","native_subject":"...","match":null}
```

Consume as follows:

- **`match.confidence >= 80`**: auto-mark your rpm backlog entry
  DONE with today's date. No question. Note it in Tracker updates.
- **`match.confidence` 40–79**: surface as one consolidated finding
  — list `native_subject → heading (confidence N)` and ask yes/no
  per row (or `all`/`none`). Apply DONE edits on the user's picks.
  (This is one of the surfaces that may push mode to Inline.)
- **`match:null`** or missing: ignore mechanically; conversation
  synthesis may still catch it.

Prefer `match.id` (via the `:ID:` property) over heading-text edits
when the entry has one — ID-targeted edits survive heading rewrites.

### Commit tracker updates

Combine the commit and the user-visible mode output into a **single
message** — commit as a tool call, mode output as text alongside.

```bash
git add docs/rpm/past/$(date +%Y-%m-%d).md docs/rpm/present/status.md docs/rpm/future/tasks.org docs/rpm/future/done.org 2>/dev/null
git diff --cached --quiet || git commit -m "rpm: session end — update past/present/future"
```

If nothing was staged, skip the commit silently. If the commit fails
(e.g., pre-commit hook rejection), note it in the output and continue.

---

## Mode selection

After the auto-apply commit lands, pick the LEANEST mode whose
conditions hold. The bar climbs only when complexity demands it.

**Use Express** when ALL of:

- `git status --porcelain` empty (post-tracker-commit)
- `drift_findings` empty
- `record_findings` empty (no unrecorded learnings worth promoting)
- No `in_progress`/`pending` natives
- No backlog mismatch signal (top actionable matches session work;
  no deferrals, no dep blocker, no user flag)

**Use Phased** when ANY of:

- 3+ untracked files needing per-file keep/gitignore/delete triage
- User touched multiple unrelated areas → commit needs splitting
- 5+ unrecorded learnings worth promoting
- Backlog mismatch question (user worked below top, top blocked by
  incomplete dep, or user flagged the list this session)
- 3+ decision surfaces simultaneously (commit + learnings + drift +
  native dedup all firing together)

**Use Inline** otherwise — anything in between. This is the default
for most non-trivial sessions.

---

## Express mode

Single message — emit the block below, run Phase 4 cleanup
(`~rpm-last-session` write, marker `rm`) in the same response, do
not continue the conversation after.

```
## Session end (rpm <version>)

**Accomplished**
- [bullet list of what was completed]

**Tracker updates**
- `docs/rpm/past/YYYY-MM-DD.md` — [what was logged]
- `docs/rpm/present/status.md` — [what changed, or "no changes"]
- `docs/rpm/future/tasks.org` — [what was marked/added, or "no changes"]
- `docs/rpm/future/done.org` — [N entries archived, or "no changes"]

**What's next:** [top actionable task, or "unknown — pick from your
rpm backlog" if the list is empty]

[If mid-task: one line on where it left off]

---

To start a new session:
1. Run `/clear` to clear this context
2. Start a new conversation — rpm context auto-loads
```

Phase 4 cleanup commands (run in the same response):

```bash
TASK=$(grep -oP 'task: \K.*' docs/rpm/~rpm-session-start 2>/dev/null | head -1)
SID=$(grep -oP 'session_id: \K.*' docs/rpm/~rpm-session-start 2>/dev/null | head -1)
printf 'task: %s\nended: %s\nnext: %s\n' "${TASK:-unknown}" "$(date -Iseconds)" "{What's next from the block above}" > docs/rpm/~rpm-last-session
printf 'session_id: %s\n' "${SID:-unknown}" > docs/rpm/~rpm-session-end
rm -rf docs/rpm/~rpm-session-start docs/rpm/~rpm-compact-state docs/rpm/~rpm-learnings.jsonl docs/rpm/~rpm-native-tasks.jsonl docs/rpm/~rpm-task-candidates.jsonl
```

---

## Inline mode

TWO messages total. **Message 1** carries the wrap-up summary plus
inline asks for any active surface. **Message 2** applies user
decisions, runs native cleanup, runs Phase 4, and hands off.

### Message 1 — combined wrap-up + asks

```
## Session end (rpm <version>)

**Accomplished**
- [2–4 bullets]

**Tracker updates**
- `docs/rpm/past/YYYY-MM-DD.md` — [one line]
- `docs/rpm/present/status.md` — [one line or "no changes"]
- `docs/rpm/future/tasks.org` — [one line or "no changes"]
- `docs/rpm/future/done.org` — [N archived or "no changes"]

[If uncommitted changes — list files (≤ ~5), draft a commit message,
include all three options:]
**Commit**
Files: [comma-separated list]
Draft message:
> rpm: <subject> — <body line>

QUESTION: Commit as drafted, edit the message, or skip the commit?
(`yes` / `edit` / `skip`)

[If 1–4 unrecorded learnings — present as numbered list with
proposed destinations. Use this format even for a single learning,
to keep the answer pattern consistent:]
**Worth keeping**
1. [learning summary] → memory file
2. [learning summary] → CLAUDE.md

QUESTION: Promote which? (e.g. `1,2` / `all` / `none`)

[If drift_findings non-empty AND fixes are obvious — apply them
silently and just list. If any are ambiguous, surface them as a
question.]
**Drift fixed**
- [one line per fix applied]

[OR, if ambiguous drift:]
**Drift**
- [item that needs a decision]

QUESTION: [single targeted question per ambiguous item]
```

Rules for Message 1:

- Omit any section whose surface is empty. No empty headers.
- ≤ 1 question per surface, ≤ 3 questions total. (More than that =
  escalate to Phased.)
- Untracked files: if 0–2 untracked, list them inline under
  **Commit** with a per-file `keep/gitignore/delete` ask. If 3+,
  escalate to Phased (the per-file triage warrants its own phase).
- All questions go at the END of their section, prefixed `QUESTION:`.
- Do NOT proceed to Message 2 until the user replies.

### Message 2 — apply + handoff

After the user replies:

1. Apply each chosen action (commit per draft / edits, promote picked
   learnings, fix accepted drift items).
2. **Native cleanup** — same logic as Phased Phase 3a:
   - `TaskList`, filter to `in_progress`/`pending`.
   - Pipe to `score-natives.sh` (see Phased Phase 3a for the exact
     script invocation), then per output line:
     - `match.confidence >= 80` → upgrade matching backlog entry
       from TODO to IN-PROGRESS if needed; do not duplicate.
     - else → append `** TODO <subject>` under a sensible parent
       group at the bottom of the actionable band.
   - `TaskUpdate` every surfaced task to `completed`.
   - Note the result in one line ("Promoted 2 natives; 1 deduped").
   - If zero natives, skip silently.
3. **Auto-demote sweep** on `tasks.org` — within each `* Parent`
   group, re-order so bands fall: Actionable → Blocked → Postponed
   (preserve relative order within bands). Apply silently.
4. Run Phase 4 cleanup commands (same as Express mode above).
5. Emit the handoff block:

```
**Handoff**

**What's next:** [reconciled top task, or "unknown — pick from your
rpm backlog"]

[If mid-task: one line on where it left off]

---

To start a new session:
1. Run `/clear` to clear this context
2. Start a new conversation — rpm context auto-loads
```

Do not continue the conversation after.

---

## Phased mode

When mode selection picked Phased (multiple commit groups, untracked
triage, 5+ learnings, mismatch, or 3+ surfaces), use the four-phase
flow below. **Print phase headers** (`## Phase N (of 4): Title`) at
the start of each user-visible response. Append `(rpm <version>)` to
the Phase 1 header.

### Phase 1 (of 4): Collecting Findings

Emit the findings block, then flow into Phase 2.

```
## Phase 1 (of 4): Collecting Findings (rpm <version>)

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
- `docs/rpm/future/done.org` — [N entries archived, or "no changes"]

### 1e. Doc-drift scan
- [one-line per finding, or "no drift detected"]
```

After emitting the block, proceed to Phase 2. **No action menu** —
each Phase 2 sub-section fires only when its surface has content and
asks its own question.

### Phase 2 (of 4): Housekeeping

Start this response with `## Phase 2 (of 4): Housekeeping`. Fire each
sub-section ONLY if its surface has content. If all three surfaces
are empty, skip Phase 2 — this can only happen when Phased was
picked solely on a Phase 3 signal (mismatch, etc.).

#### 2a. Commit changes

- **Untracked files first.** List them and decide per file (or per
  logical group):
  - **keep** → stage and include in this commit
  - **gitignore** → add path/pattern to `.gitignore` (and stage)
  - **delete** → `rm` the file

  Never silently drop untracked files; never `git add .` past them.
- After untracked files are resolved, apply the same lens to
  modified-but-unstaged files: confirm each is intended.
- If multiple logical groups exist, ask whether to commit them as
  one commit or split into several.
- Confirm files explicitly (avoid `git add .`).
- Draft a commit message and show it before committing.
- Follow the project's existing commit message style (`git log --oneline -10`).

#### 2b. Record findings

- Filter out learnings already captured (in code comments, specs,
  existing memory files) — do NOT show them.
- Present unrecorded learnings as a numbered menu with destinations:
  ```
  1. [learning summary] → memory file
  2. [learning summary] → CLAUDE.md
  ```
  Then ask: "Which to promote? (e.g., `1,2` · `all` · `none`)"
- One list, one question. Do not pre-filter, recommend, or renumber.
- Show each addition before writing.

#### 2c. Fix drift

- For each accepted `drift_findings` entry, apply the obvious fix
  (repair broken ref, update contradictory tracker, etc.). For
  ambiguous drift (e.g. NOT_IMPLEMENTED stub with no clear path),
  surface it instead of guessing.
- After fixes land, note them in today's past log under "Doc-drift
  fixes".

After all chosen actions complete, proceed to Phase 3.

### Phase 3 (of 4): Reviewing Tasks

Start this response with `## Phase 3 (of 4): Reviewing Tasks`. Two
sub-steps before handoff: dispose of remaining native tasks, then
reconcile rpm backlog order.

#### 3a. Clear native tasks (dedup, promote, clear)

Native tasks are session-scoped and need clearing before handoff. A
native task's creation *is* the vetting step — every uncleared
native gets captured before the live list is wiped. No user question.

Phase 1 prep already handled completed natives with high-confidence
matches. 3a only deals with in_progress/pending natives. Dedup
against the live backlog *before* appending.

1. Call `TaskList`. Filter to `in_progress` or `pending`. Emit one
   JSONL line per surfaced task and pipe to the scoring script:

   ```bash
   printf '%s\n' \
     '{"id":"t1","subject":"...","status":"in_progress"}' \
     '{"id":"t2","subject":"...","status":"pending"}' \
     | bash "${RPM_PLUGIN_ROOT:-${CODEX_HOME:-$HOME/.codex}/.tmp/marketplaces/dppdppd-rpm/.codex}/skills/session-end/scripts/score-natives.sh"
   ```

   Output: one JSONL line per input with
   `{"native_id":"...","native_subject":"...","match":{"heading","id","confidence"}|null}`.

2. Apply per output line:
   - **`match.confidence >= 80`**: backlog entry exists. If `** TODO`,
     update to `** IN-PROGRESS`. If already IN-PROGRESS or BLOCKED,
     leave alone. Do NOT append.
   - **`match: null` or `< 80`**: append `** TODO <subject>` under a
     sensible parent group at the bottom of the actionable band.

3. `TaskUpdate` every surfaced task to `completed` (clears live list).

4. Report in one line at the start of this response (e.g.
   `Promoted 2 natives; 1 deduped into existing IN-PROGRESS.`).

If zero in-progress/pending natives, skip 3a silently.

#### 3b. Reconcile rpm backlog order

Re-read `tasks.org` (post-auto-apply, post-3a-promotions). Then:

**Auto-demote sweep (mechanical, no user question).** Within each
`* Parent` group, re-order so bands fall:

1. Actionable — `** IN-PROGRESS` or `** TODO` with all `:BLOCKED_BY:`
   deps DONE
2. Blocked — `** BLOCKED`, or `** TODO` with unresolved `:BLOCKED_BY:`
3. Postponed — `** TODO` with a `:POSTPONED:` stamp

Preserve relative order within each band. Apply silently. (DONE /
CANCELLED already moved to `done.org` by the archive sweep.)

**Then check for a mismatch signal:**

- User worked below the top → top probably isn't the right next thing.
- Top blocked by incomplete dep → blocker moves up, or auto-demote handled it.
- User flagged the list during the session.
- **User deferred a task** → apply `/backlog postpone <task>` to move
  it to the bottom of its parent group and stamp
  `:POSTPONED: YYYY-MM-DD`.

If any holds, end this response with ONE question (e.g. "You worked
on X today, but Y is at the top of your rpm backlog. Should X move
to the top?") and wait. Apply the agreed change, commit as
`rpm: session end — reorder backlog`. Otherwise briefly state the
top as `What's next` and proceed to Phase 4.

### Phase 4 (of 4): Handing Off

Only after Phase 3 is resolved. **Single response** — the rm tool
call and the handoff text go in the same message:

- Save last session info before cleanup:
  ```bash
  TASK=$(grep -oP 'task: \K.*' docs/rpm/~rpm-session-start 2>/dev/null | head -1)
  SID=$(grep -oP 'session_id: \K.*' docs/rpm/~rpm-session-start 2>/dev/null | head -1)
  printf 'task: %s\nended: %s\nnext: %s\n' "${TASK:-unknown}" "$(date -Iseconds)" "{reconciled What's next from Phase 3}" > docs/rpm/~rpm-last-session
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
