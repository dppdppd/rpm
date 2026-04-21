---
description: Manage the rpm backlog (long-term project tasks in docs/rpm/future/tasks.org — distinct from Claude's native TaskCreate list, which is session-scoped). Add, list, review, postpone, or complete entries. Use when the user wants to add a backlog item, see what's on the rpm backlog, reorder the execution sequence, defer to the bottom of a group, mark something done, or evaluate backlog health.
---

# /backlog

Manage the **rpm backlog** — persisted at `docs/rpm/future/tasks.org`.
All operations read and write this file using org-mode format.

The backlog is sorted in **execution order** (top-to-bottom = the
order in which tasks need to get done). "Take from the top" is the
expected read pattern.

Within each `* Parent` group, keep this band order top-to-bottom:

1. **Actionable** — `** IN-PROGRESS` or `** TODO` with all
   `:BLOCKED_BY:` deps DONE
2. **Blocked** — `** BLOCKED`, or `** TODO` with unresolved
   `:BLOCKED_BY:`
3. **Postponed** — `** TODO` with a `:POSTPONED:` stamp

Closed entries (`** DONE` / `** CANCELLED`) are archived to
`docs/rpm/future/done.org` by `/session-end` and do not live in
tasks.org long-term. `/backlog done` toggles `TODO → DONE` in place;
the archive sweep runs at the next session-end.

Blocked and postponed items drift to the bottom of their band
automatically whenever this file is written (during `add`,
`postpone`, `review`, or session-end Phase 3b). Moves are mechanical
— no user question. Preserve relative order within each band.
New `add` entries land at the bottom of the **actionable band**
(not the absolute bottom); user promotes upward explicitly if
something needs to happen sooner.

**Pivot capture (automatic, no user question).** When the user
redirects mid-session to new multi-step work that meets the
`TaskCreate` bar, the LLM must insert a `** TODO` at the **top** of
the actionable band AND update `docs/rpm/~rpm-session-start` to set
the `task:` field to the new work. The ask IS the confirmation —
don't prompt. Skip for tactical single-step follow-ups. Rationale:
the backlog should always represent current state, so a dropped
session (without `/session-end`) still hands off accurately. Full
rule lives in `plugin/hooks/_directives.sh`.

## Routing

Parse `$ARGUMENTS`:

- `add <description>` → **Add** below
- `list` → **List** below
- `review` → **Review** below
- `postpone <task text or number>` → **Postpone** below
- `done <task text or number>` → **Done** below
- empty or natural language → infer intent from context. If unclear,
  show usage:

  ```
  /backlog add <description>   — add a backlog entry
  /backlog list                — show all entries with statuses
  /backlog review              — evaluate and reorganize
  /backlog postpone <task>     — defer to the bottom of its group
  /backlog done <task>         — mark an entry complete
  ```

---

## Add

**Do NOT call `TaskCreate` for backlog additions.** Your rpm backlog
is long-term; native tasks (`TaskCreate`/`TaskList`) are reserved for
work actually happening *this session*. Adding to your rpm backlog
without a mirrored native task is the correct, intended behavior.

1. Read `docs/rpm/future/tasks.org` to see existing parent headings
   and task structure.
2. Ask which parent heading the task belongs under (suggest one if
   obvious). If no headings exist, create one.
3. Add as `** TODO <one-sentence description> [[file:YYYY-MM-DD-slug.md]]`
   at the bottom of the **actionable band** in the chosen heading
   (above any blocked / postponed / DONE entries).
4. Create the detail file at `docs/rpm/future/YYYY-MM-DD-slug.md`
   with a brief description — at minimum a `# Title` and
   `## Description` section. Ask the user for details if the task
   is complex.
5. If the task has obvious dependencies on existing tasks, suggest
   adding `:BLOCKED_BY:` properties. Don't add dependencies the
   user hasn't confirmed.
6. Confirm: print the new entry and its location.

---

## List

1. Read `docs/rpm/future/tasks.org`.
2. Print a summary line and the active task list:

   ```
   ## Tasks — N in-progress · N todo · N blocked

   <Parent Heading>
      1. [TODO] <description>
      2. [IN-PROGRESS] <description>
         blocked-by: <id>
   ```

   Grouped by parent heading. Number sequentially for reference.
   Closed entries live in `docs/rpm/future/done.org` — read that
   file directly if the user asks for history.

---

## Review

1. Read `docs/rpm/future/tasks.org` and all linked detail files.
2. Evaluate:
   - **Organization:** tasks under logical parent headings?
   - **Dependencies:** relationships correct? Missing or circular?
   - **Staleness:** TODOs with no activity across multiple sessions?
   - **Scope:** any tasks too large for one session (~35 min)?
     Suggest decomposition.
   - **Duplicates:** overlapping tasks?
   - **Order:** work is sorted top-to-bottom by execution order
     (when it needs to get done)? Anything that should happen sooner
     than what's currently above it?
   - **Deferrals:** anything the user has set aside or signaled they
     want to come back to later? Surface as candidates for **Postpone**.
3. Present findings and proposed changes. Wait for confirmation
   before editing. For postpones, apply the move using the
   **Postpone** procedure below.

---

## Postpone

Defer a task to the bottom of its `* Parent` group. Status stays
`TODO` (the task isn't dropped, just moved later in the execution
order). Adds a `:POSTPONED: YYYY-MM-DD` property so the deferral is
auditable.

1. Read `docs/rpm/future/tasks.org`.
2. Match the argument to a task — by number (from most recent
   `/backlog list`), by text match, or by asking if ambiguous.
3. Identify the task's `* Parent` heading. Find the last `**` task
   under that parent (any status — active, blocked, or postponed).
4. Edit the file to move the matched task's heading + its property
   drawer to just below that last sibling. **Do not change status**;
   keep `** TODO`.
5. Add (or update) `:POSTPONED: YYYY-MM-DD` inside the property
   drawer with today's date. Create the drawer if the task didn't
   have one.
6. Confirm: print the moved task's new position.

If the task is already at the bottom of its group, just stamp the
`:POSTPONED:` property and note "already at bottom".

---

## Done

1. Read `docs/rpm/future/tasks.org`.
2. Match the argument to a task — by number (from most recent
   `/backlog list`), by text match, or by asking if ambiguous.
3. Change `** TODO` to `** DONE` and append today's date:
   `** DONE <description> :CLOSED: [YYYY-MM-DD]`
4. Confirm what was marked done.
