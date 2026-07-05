---
name: session-end
description: End the current rpm session. Three modes — Express (silent, one message), Inline (asks decisions one at a time in short round-trips), Phased (four-phase ceremony for complex sessions). Never batches questions — exactly one question per message. Picks the leanest that fits. Commits rpm bookkeeping. Invoke when the user signals wrap-up. Do not auto-run — if you think it's time, propose first and wait for confirmation.
argument-hint: ""
allowed-tools: Read Write Edit Bash(bash:*) Bash(git:*) Bash(rm:*) Glob Grep
---

# /session-end

End the current work session. Default to the leanest mode that fits:
small sessions should be cheap to close, while complicated sessions can
still use the full ceremony.

## Project Amendments

At the start of every invocation, check whether
`docs/rpm/skills/session-end.md` exists in the consuming project. If
it does, read it and apply its contents as additional project-specific
instructions for this skill. Amendments may add Prep steps, extra
decision surfaces, or extend the handoff cleanup. They cannot remove
or override plugin defaults — on conflict, this SKILL.md wins.

- **Express** — clean wrap-up. One message, no questions.
- **Inline** — a few small decision surfaces. Asks them one at a time in
  short round-trips (never batched), then hands off.
- **Phased** — genuine multi-decision complexity. Four numbered phases,
  still one question at a time.

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
dangling task deps, migrations, and `overridden_skills.count > 0` are
actionable; stale pm docs matter only when this session touched
related work; create today's log when missing and commits exist; use
captured learnings as inputs.

### 1b. Guidance Alignment

Dispatch the `rpm:guidance-aligner` subagent in `full` mode (foreground).
Inputs:

- `mode=full`
- `memory_dir=$HOME/.claude/projects/$(printf '%s' "$PWD" | sed 's|/|-|g')/memory`
- `instructions`: existing combination of `CLAUDE.md`, `AGENTS.md`,
  `MEMORY.md` at project root, plus every `plugin/skills/*/SKILL.md`.

Persist the JSON reply to `docs/rpm/~rpm-guidance-report.json` and
also pipe it through
`bash "${CLAUDE_PLUGIN_ROOT}/skills/next/scripts/contradiction-check.sh" save $(date +%s)`
so /next reuses the fresh result instead of re-dispatching.

Counts feed the Guidance Surface (see Shared Mechanics). Any
`CONTRADICTED > 0` or `STALE > 0` forces at least Inline mode in
Mode Selection.

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
- `docs/rpm/present/status.md`: update only fields that changed. When
  scan.sh `specs_inventory` reports `unlisted > 0`, append a fresh
  `Behavioral spec inventory (YYYY-MM-DD): N specs total` line — the
  inventory self-heals each session instead of drifting until an audit.
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

After Prep, count decision surfaces: commit, learning, drift,
guidance, native cleanup, and backlog ordering.

Use **Express** only when the post-tracker git tree is clean and every
surface is empty.

Use **Phased** when any complex trigger exists: 3+ untracked files,
multiple unrelated commit groups, 5+ learnings, backlog mismatch
requiring discussion, 2+ CONTRADICTED guidance items, or 3+ decision
surfaces.

Use **Inline** otherwise. Inline is the default for normal non-clean
sessions, and forced whenever the guidance report shows any
`CONTRADICTED > 0` or `STALE > 0`.

## Shared Mechanics

### Question Discipline

**Ask exactly one question per message, and make it the last line.** This
governs every mode. A message may end with at most one `QUESTION:` line;
never stack two distinct decisions in one message. The user must never be
in a state where a positional answer (`all`, `yes`, `1,2`) could resolve
more than one question — that ambiguity is the failure this rule exists to
prevent.

A single multi-select menu (e.g. "Which learnings to promote? 1,2 / all /
none") is **one** question and is allowed — every option answers the same
decision. Two different decisions (promote a learning **and** dispose of a
file) are **two** questions and must be asked in separate messages.

When several decision surfaces need the user, ask them **sequentially**:
ask the first, wait, apply the answer, then ask the next. Order them
commit → drift/overrides → memory drift → learnings → backlog, skipping
any that need no input. Everything the skill can decide on its own (see
the auto-apply steps) is done silently and never becomes a question.

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

**Overridden skills.** Treat every `override=<old>→<new>` line from
scan.sh's `overridden_skills` section as ambiguous drift — never
auto-migrate. For each, surface a one-line recommendation:

```
Overridden plugin skill: .claude/skills/<name>/SKILL.md
  → migrate to docs/rpm/skills/<name>.md (additive amendment)
```

Ask once whether to migrate (move the project-specific delta into
the amendment file and delete the override), keep the override
(note rationale in the amendment file's body), or defer. Hard
overrides silently replace the plugin default and survive plugin
updates as forks — flag them every session until resolved.

### Guidance Surface

Read `docs/rpm/~rpm-guidance-report.json` (written in Prep step 1b).
Surface only when `CONTRADICTED + STALE > 0`. Format:

```
Memory drift: <C> contradicted, <S> stale, <G> gap, <P> partial
  - feedback_xxx.md — CONTRADICTED by CLAUDE.md:42 ("...")
  - feedback_yyy.md — STALE: references removed command /old-name
```

For each CONTRADICTED entry, ask which side wins: edit the memory
rule, edit the conflicting directive, or accept the contradiction
(note in the memory body). For STALE entries, ask whether to delete
or update the memory rule. GAP and PARTIAL are informational — do
not ask unless the user wants to address them.

Cap shown entries at 5; reference the report file for the rest.

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
conflicts with the top item.

### Resolving What's next

`What's next` is the single most important handoff output — the next
session reads it cold and must know exactly what to do without
re-deriving context. Resolve it in this priority order:

1. **The obvious continuation of this session's work.** If the session
   left something unfinished, or the work just completed has a clear
   immediate follow-up (the next step you would take if you kept going),
   that is `What's next`. This almost always beats an unrelated backlog
   item — the user was just here.
2. **Only if this session's thread is genuinely finished with no obvious
   follow-up:** use the top actionable backlog entry.
3. **If neither exists:** write `next: (no obvious next step — pick from
   backlog)` so the next session knows to offer the menu rather than
   guessing.

Whatever you pick, phrase it as a **concrete, self-contained action**, not
a topic. Name the file, command, or decision so a cold agent can start
immediately. Good: "add the number-provenance gate to Phase 4 of
`plugin/skills/deep-research/SKILL.md`, then run bats." Bad:
"deep-research hardening."

### Handoff Cleanup

Use this cleanup in Express, the Inline final message, and Phased Phase 4.
Substitute `{resolved What's next}` with the value from **Resolving What's
next** — a concrete, self-contained action (or the explicit
`(no obvious next step — pick from backlog)` sentinel). Never leave it
vague, and never leave the literal placeholder.

```bash
TASK=$(grep -oP 'task: \K.*' docs/rpm/~rpm-session-start 2>/dev/null | head -1)
SID=$(grep -oP 'session_id: \K.*' docs/rpm/~rpm-session-start 2>/dev/null | head -1)
printf 'task: %s\nended: %s\nnext: %s\n' "${TASK:-unknown}" "$(date -Iseconds)" "{resolved What's next}" > docs/rpm/~rpm-last-session
printf 'session_id: %s\n' "${SID:-unknown}" > docs/rpm/~rpm-session-end
rm -rf docs/rpm/~rpm-session-start docs/rpm/~rpm-compact-state docs/rpm/~rpm-learnings.jsonl docs/rpm/~rpm-native-tasks.jsonl docs/rpm/~rpm-task-candidates.jsonl docs/rpm/~rpm-context.md
```

## Express

One message, then cleanup. Do not continue the conversation after it.

Output: `## Session end (rpm <version>)`, Accomplished, Tracker
updates, `What's next`, then the two restart lines (`/clear`, then
start a new conversation). Run cleanup in the same response.

## Inline

Inline asks its decisions **one at a time**, in sequence (see Question
Discipline) — not all in one message. It is a short conversation, not a
single batched form.

**First message:** `## Session end (rpm <version>)`, Accomplished, Tracker
updates, then the **first** decision surface that needs the user (in the
order commit → drift/overrides → memory drift → learnings → backlog),
ending with its single `QUESTION:` line. Omit empty sections.

**Each reply:** apply that decision silently, then either ask the **next**
outstanding surface (again, one `QUESTION:` line, last line) or — if none
remain — run native cleanup, sweep the backlog, resolve `What's next`, run
handoff cleanup, and emit the final message.

**Final message:** `**Handoff**`, `What's next`, the two restart lines
(`/clear`, then start a new conversation).

If more than one surface is outstanding, that is normal for Inline — it
just means more than one short round-trip. Only switch to Phased when a
surface needs genuine discussion (see Mode Selection triggers), not merely
because several surfaces exist.

## Phased

Use Phased only for complex sessions. Each visible response starts with
the phase header.

1. `## Phase 1 (of 4): Collecting Findings (rpm <version>)` —
   accomplishments, uncommitted changes, learnings, tracker updates,
   drift.
2. `## Phase 2 (of 4): Housekeeping` — commit changes, record
   findings, fix drift. Ask surfaces one at a time per Question
   Discipline — one `QUESTION:` per message, waiting for each answer
   before the next; do not stack them within the phase.
3. `## Phase 3 (of 4): Reviewing Tasks` — native cleanup, backlog band
   sweep, ordering reconciliation. Same one-question-at-a-time rule if
   any ordering decision needs the user.
4. `## Phase 4 (of 4): Handing Off` — cleanup plus final handoff text.
