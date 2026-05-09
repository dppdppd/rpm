---
name: session-end
description: End the current rpm session. Three modes — Express (silent, one message), Inline (one message + one follow-up), Phased (four-phase ceremony for complex sessions). Picks the leanest that fits. Commits rpm bookkeeping. Invoke when the user signals wrap-up. Do not auto-run — if you think it's time, propose first and wait for confirmation.
argument-hint: ""
allowed-tools: Read Write Edit Bash(bash:*) Bash(git:*) Bash(rm:*) Glob Grep
---

# /session-end

End the current work session. Default to the leanest mode that fits:
small sessions should be cheap to close, while complicated sessions can
still use the full ceremony.

- **Express** — clean wrap-up. One message, no questions.
- **Inline** — one or two small decision surfaces. One message with
  inline asks, then one follow-up that applies decisions and hands off.
- **Phased** — genuine multi-decision complexity. Four numbered phases.

Append ` (rpm <version>)` to the first visible heading, using
`version=` from scan.sh's `=== plugin ===` section.

## Entry Guard

If this skill was auto-loaded because you inferred the user may be
wrapping up, ask once: "You seem ready to wrap up. Want me to run
`/session-end`?" Then wait. If the user explicitly invoked
`/session-end`, start Prep immediately.

## Prep

Prep is silent and runs before any visible wrap-up output. It updates
rpm bookkeeping without previews or diff approval.

### 1. Mechanical Scan

The scan below is injected into context. Do not re-run it unless the
injected output is unavailable.

!`bash "${CLAUDE_SKILL_DIR}/scripts/scan.sh"`

Interpret scan sections compactly: `plugin.version` supplies the
heading suffix; `git` drives commit and mode selection; instruction
files warn only on `warn`/`critical`; suppress rpm meta
`NOT_IMPLEMENTED` hits; `broken_refs.count > 0`, unlisted specs,
dangling task deps, and migrations are actionable; stale pm docs matter
only when this session touched related work; create today's log when
missing and commits exist; use captured learnings as inputs.

### 2. Read And Synthesize

In one parallel tool batch: read `docs/rpm/future/tasks.org`,
`docs/rpm/present/status.md`, today's past log if it exists, and the
native task list.

While reads run, synthesize this conversation for accomplishments,
decisions, discoveries, learnings, unfinished work, and user corrections.
Deduplicate against existing docs and guidance before promoting a
learning.

If `docs/rpm/~rpm-session-start` says `task: (unassigned)`, replace it
with a 5-8 word imperative title derived from the session. Do not ask.

### 3. Auto-Apply Tracker Updates

Apply obvious tracker updates immediately:

- `docs/rpm/past/YYYY-MM-DD.md`: create or append Accomplished, Key
  Discoveries, What Didn't Work, and Next.
- `docs/rpm/present/status.md`: update only fields that changed.
- `docs/rpm/future/tasks.org`: mark completed backlog items DONE,
  update IN-PROGRESS items, and add clear TODOs with detail files.
- `docs/rpm/future/done.org`: archive every DONE/CANCELLED heading
  from `tasks.org`, newest first under the same parent. Preserve links,
  property drawers, and `CLOSED:` notes. Create the archive header if
  missing.

For completed native candidates, auto-mark `confidence >= 80` matches
DONE by `match.id`, surface 40-79 matches as a decision, and ignore
`match:null`. Pending/in-progress natives are handled later.

### 4. Commit Tracker Updates

Run the tracker commit before selecting the visible mode:

```bash
git add docs/rpm/past/$(date +%Y-%m-%d).md docs/rpm/present/status.md docs/rpm/future/tasks.org docs/rpm/future/done.org 2>/dev/null
git diff --cached --quiet || git commit -m "rpm: session end — update past/present/future"
```

If nothing is staged, continue silently. If commit fails, report it in
the visible output and continue.

## Mode Selection

After Prep, count decision surfaces: commit, learning, drift, native
cleanup, and backlog ordering.

Use **Express** only when the post-tracker git tree is clean and every
surface is empty.

Use **Phased** when any complex trigger exists: 3+ untracked files,
multiple unrelated commit groups, 5+ learnings, backlog mismatch
requiring discussion, or 3+ decision surfaces.

Use **Inline** otherwise. Inline is the default for normal non-clean
sessions.

## Shared Mechanics

### Commit Surface

Do not use `git add .`. List intended files explicitly. Resolve
untracked files before staging. Follow `git log --oneline -10`. Inline
asks for one draft commit; Phased may split logical commits.

### Learning Surface

Read active guidance before proposing a learning. Show only uncaptured
learnings as a numbered menu with destinations. Ask once:
`Which to promote? (e.g. 1,2 / all / none)`.

### Drift Surface

Apply obvious fixes silently and list them. Ask only for ambiguous drift.
If fixes land after the tracker commit, add a "Doc-drift fixes" note to
today's past log and commit the changed docs.

### Native Cleanup

For every pending/in-progress native task:

```bash
printf '%s\n' \
  '{"id":"t1","subject":"...","status":"in_progress"}' \
  | bash "${CLAUDE_PLUGIN_ROOT}/skills/session-end/scripts/score-natives.sh"
```

For each score result, `confidence >= 80` updates an existing TODO to
IN-PROGRESS; `match:null` or `< 80` appends a TODO under the sensible
parent. Then mark every surfaced native task completed. No user question.

### Backlog Reconciliation

After edits, sweep each `* Parent` in `tasks.org` into Actionable,
Blocked, Postponed bands, preserving relative order. Ask one ordering
question only when session work, dependency changes, or user feedback
conflicts with the top item. Otherwise use the top actionable entry as
`What's next`.

### Handoff Cleanup

Use this cleanup in Express, Inline message 2, and Phased Phase 4:

```bash
TASK=$(grep -oP 'task: \K.*' docs/rpm/~rpm-session-start 2>/dev/null | head -1)
SID=$(grep -oP 'session_id: \K.*' docs/rpm/~rpm-session-start 2>/dev/null | head -1)
printf 'task: %s\nended: %s\nnext: %s\n' "${TASK:-unknown}" "$(date -Iseconds)" "{resolved What's next}" > docs/rpm/~rpm-last-session
printf 'session_id: %s\n' "${SID:-unknown}" > docs/rpm/~rpm-session-end
rm -rf docs/rpm/~rpm-session-start docs/rpm/~rpm-compact-state docs/rpm/~rpm-learnings.jsonl docs/rpm/~rpm-native-tasks.jsonl docs/rpm/~rpm-task-candidates.jsonl
```

## Express

One message, then cleanup. Do not continue the conversation after it.

Output: `## Session end (rpm <version>)`, Accomplished, Tracker
updates, `What's next`, then the two restart lines (`/clear`, then
start a new conversation). Run cleanup in the same response.

## Inline

Message 1 contains the summary plus every active ask. Omit empty
sections. Keep to at most one question per surface and at most three
questions total; otherwise switch to Phased.

Message 1 output: `## Session end (rpm <version>)`, Accomplished,
Tracker updates, then only active sections: Commit, Worth keeping,
Drift, Native cleanup, or Backlog. End each active section with one
`QUESTION:` line.

After the user replies, apply decisions, run native cleanup, sweep the
backlog, run handoff cleanup, and end with:

Message 2 output: `**Handoff**`, `What's next`, the two restart lines.

## Phased

Use Phased only for complex sessions. Each visible response starts with
the phase header.

1. `## Phase 1 (of 4): Collecting Findings (rpm <version>)` —
   accomplishments, uncommitted changes, learnings, tracker updates,
   drift.
2. `## Phase 2 (of 4): Housekeeping` — commit changes, record
   findings, fix drift. One question per active section.
3. `## Phase 3 (of 4): Reviewing Tasks` — native cleanup, backlog band
   sweep, ordering reconciliation.
4. `## Phase 4 (of 4): Handing Off` — cleanup plus final handoff text.
