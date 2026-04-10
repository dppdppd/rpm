---
name: session-end
description: End the current pm work session. Five phases — analyze → auto-apply PM updates (past/present/future) → present action menu → execute → handoff. Commits PM bookkeeping. Invoke when the user signals wrap-up, OR recommend proactively when conversation context grows long enough to degrade response quality (long-context productivity drop-off). Auto-invocations MUST propose first and wait for confirmation before Phase 1 — do not auto-commit.
argument-hint: ""
allowed-tools: Read Write Edit Bash(bash:*) Bash(git:*) Bash(rm:*) Glob Grep
---

# /pm:session-end

End the current work session in five phases:
**Analyze → Auto-apply core PM updates → Present menu → Execute → Handoff**.

Core PM bookkeeping (`docs/pm/past/YYYY-MM-DD.md`, `docs/pm/PRESENT.md`,
`docs/pm/FUTURE.org`) is updated automatically during Phase 2 — **no
prompts, no diff approval**. Only ask the user about actions outside
that scope: committing uncommitted items, recording findings
(promoting learnings to permanent docs), and anything else specific
to the session.

**Response rules:**
- Questions go at the **end** of a response, never mid-stream.
- When asking the user to choose, use a numbered menu (e.g.,
  `1,2` · `all` · `none`).
- Never present an action whose precondition is empty (e.g., don't
  offer "Commit changes" when nothing is uncommitted).

---

## Pre-flight: Auto-invocation check

**If this skill was auto-loaded** — because Claude noticed the user
seems ready to wrap up, or because conversation context has grown
long enough to hurt response quality — **STOP before Phase 1** and
propose session-end to the user first:

> "Context is getting long / you seem ready to wrap up. Want me to
> run `/pm:session-end`? It'll auto-update past/present/future,
> surface uncommitted work, and present an action menu."

Only proceed to Phase 1 after the user confirms. The reason: Phase 2
auto-applies PM updates and commits them without further approval —
that side effect must not happen on a false-positive auto-trigger.

**If the user explicitly typed `/pm:session-end`**, skip this
pre-flight and proceed directly to Phase 1.

**Research context for proactive recommendation:** LLM response
quality degrades as context length grows (lost-in-the-middle,
recency bias, context dilution). Recommending `/pm:session-end` +
`/clear` when context starts costing productivity is a legitimate
and useful intervention — not an interruption.

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
  `README.md`, `docs/pm/PM.md` that don't resolve on disk.
  `count > 0` is always actionable. (`PRESENT.md`, `PM-LOG.md`,
  and `past/*.md` are deliberately excluded as historical.)
- `daily_log` — today's date, most recent log date, days since,
  commits since. If `today_exists=false` and `commits_since > 0`,
  Phase 2 needs to create today's log.
- `session_marker` — whether `docs/pm/~pm-session-active` exists.
  Phase 5 will remove it only if it exists.
- `specs_inventory` — if a spec dir exists, `total` / `listed` /
  `unlisted` counts against `PRESENT.md`. `unlisted > 0` is a
  drift signal — PRESENT.md isn't enumerating all specs. Up to
  10 `unlisted_sample=` lines identify which. `status=no_spec_dir`
  means the project has no spec directory (no action).
- `pm_docs_staleness` — `file=<path> days=<N>` pairs for loose
  log/tracker/inventory files under `docs/` and `docs/pm/`. Flag
  as possible drift if `days > 3` AND the session touched related
  work — the file may need an entry. `days=0` means freshly
  updated (no action). `count=0` means nothing to check.

### 1b. Fire remaining reads in parallel

In a SINGLE message, issue all of these concurrently — do NOT
sequence them:

- Read `docs/pm/FUTURE.org` — tasks to mark DONE, IN-PROGRESS
  updates, new TODOs surfaced this session
- Read `docs/pm/PRESENT.md` — which fields still reflect reality
- Call `TaskList` — native task state for reconciliation

(The scan in 1a has already covered git state, CLAUDE.md size,
NOT_IMPLEMENTED, broken refs, today's daily log existence, the
session marker, spec inventory drift, and loose log/tracker
staleness. Do not duplicate those checks.)

### 1c. Synthesize the conversation (concurrent with 1b)

While the 1b reads are in flight, look back through this session's
conversation for:

- **Accomplishments**: features built, bugs fixed, tests passing
- **Decisions**: architectural choices, tradeoffs made
- **Discoveries**: things you learned about the code/system
- **Learnings**: corrections from the user, new patterns, debugging
  approaches that worked or didn't
- **Mid-task state**: anything left unfinished

This is main-thread-only work (subagents can't see the parent
conversation), so the win is running it CONCURRENTLY with the 1b
tool calls, not sequentially after them.

### 1d. Assemble `drift_findings`

From the 1a scan output and the 1b tracker reads, collect any
drift items that warrant user action into a `drift_findings`
list for Phase 3 presentation. Suppress trivial meta-matches.

---

## Phase 2: Auto-apply core PM updates (parallel writes)

Apply these updates immediately without asking. No previews, no
diff approval. If a particular file genuinely has nothing to
update, skip it and note "no changes" in the Phase 3 report.

**In a SINGLE message, issue all three writes concurrently:**

1. **Write** `docs/pm/past/YYYY-MM-DD.md` — append if exists,
   create if not. Sections: Accomplished, Key Discoveries, What
   Didn't Work, Next.
2. **Edit** `docs/pm/PRESENT.md` — update only the fields that
   actually changed this session.
3. **Edit** `docs/pm/FUTURE.org` — mark completed tasks DONE with
   today's date, update IN-PROGRESS items, append discovered TODOs.
   Reconcile with native tasks per the rules below.

### Native task reconciliation (within the FUTURE.org edit above)

- For each native task **completed this session**, mark the
  corresponding `FUTURE.org` entry DONE with today's date. If no
  matching entry exists, append a DONE line.
- For each native task still **in-progress or pending** created
  this session without a `FUTURE.org` counterpart, append as
  TODO (or IN-PROGRESS if active).
- **Do not delete** native tasks — they persist for the next session.

### Commit the PM updates

After all three writes land, commit the PM bookkeeping in a single
bash invocation:

```bash
git add docs/pm/past/$(date +%Y-%m-%d).md docs/pm/PRESENT.md docs/pm/FUTURE.org 2>/dev/null
git diff --cached --quiet || git commit -m "pm: session end — update past/present/future"
```

If nothing was staged (all three were "no changes"), skip the
commit silently. If the commit fails (e.g., pre-commit hook
rejection), note it in the Phase 3 report and continue — do not
block the session end on it.

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

**Only list items that are actionable this session.** Omit any
action whose precondition is empty (e.g., don't show "Commit
changes" when there are no uncommitted files; don't show "Fix
drift" when `drift_findings` is empty). Number the items that
remain sequentially — the numbers are session-specific, not fixed.

Possible actions (include only when applicable):

- **Commit changes** — group and commit uncommitted files
  *(only if scan shows modified/untracked/staged > 0)*

- **Record findings** — promote session learnings to permanent docs
  *(only if the Discovered learnings section is non-empty)*

- **Fix drift** — apply the doc-drift findings
  *(only if `drift_findings` is non-empty)*

- **Other** — anything else specific to this session
  *(always include as the last numbered item)*

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
- Present all learnings as a numbered menu with a proposed
  destination for each (CLAUDE.md, memory file, etc.):
  ```
  1. [learning summary] → CLAUDE.md
  2. [learning summary] → memory file
  ```
  Then ask: "Which to promote? (e.g., `1,2` · `all` · `none`)"
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

### Action 4: Other
- Handle whatever the user asks

After each action, briefly confirm completion. After ALL chosen
actions complete, move to Phase 5.

---

## Phase 5: Handoff

Only after Phase 4 is done.

First, clear the session marker:
- `rm -f docs/pm/~pm-session-active`

Then present the handoff — these must be the **very last lines**
of output in the conversation:

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

Do not continue the conversation after this.
