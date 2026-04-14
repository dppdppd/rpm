---
name: tasks
description: Manage the project task backlog. Add, list, review, postpone, or complete tasks. Use when the user wants to add a task, see what's on the backlog, reorganize or reprioritize tasks, defer a task to the bottom of its group, mark something done, or evaluate task health.
argument-hint: "[add <description> | list | review | postpone <#> | done <#>]"
allowed-tools: Read Write Edit Glob Grep
---

# /tasks

Manage `docs/rpm/future/tasks.org`. All operations read and write
this file using org-mode format.

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
  /tasks add <description>   — add a new task
  /tasks list                — show all tasks with statuses
  /tasks review              — evaluate and reorganize backlog
  /tasks postpone <task>     — defer to the bottom of its group
  /tasks done <task>         — mark a task complete
  ```

---

## Add

1. Read `docs/rpm/future/tasks.org` to see existing parent headings
   and task structure.
2. Ask which parent heading the task belongs under (suggest one if
   obvious). If no headings exist, create one.
3. Add as `** TODO <one-sentence description> [[file:YYYY-MM-DD-slug.md]]`
   under the chosen heading.
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
2. Print a summary line and the full task list:

   ```
   ## Tasks — N done · N in-progress · N todo · N blocked

   <Parent Heading>
      1. [TODO] <description>
      2. [DONE 2026-04-10] <description>

   <Parent Heading>
      3. [IN-PROGRESS] <description>
         blocked-by: <id>
   ```

   Show ALL tasks including DONE, grouped by parent heading.
   Number them sequentially for reference.

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
   - **Priority:** highest-value work at the top?
   - **Deferrals:** anything the user has set aside or signaled they
     want to come back to later? Surface as candidates for **Postpone**.
3. Present findings and proposed changes. Wait for confirmation
   before editing. For postpones, apply the move using the
   **Postpone** procedure below.

---

## Postpone

Defer a task to the bottom of its `* Parent` group. Status stays
`TODO` (the task isn't dropped, just deprioritized). Adds a
`:POSTPONED: YYYY-MM-DD` property so the deferral is auditable.

1. Read `docs/rpm/future/tasks.org`.
2. Match the argument to a task — by number (from most recent
   `/tasks list`), by text match, or by asking if ambiguous.
3. Identify the task's `* Parent` heading. Find the last `**` task
   under that parent (regardless of status — DONE/CANCELLED count
   for positioning).
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
   `/tasks list`), by text match, or by asking if ambiguous.
3. Change `** TODO` to `** DONE` and append today's date:
   `** DONE <description> :CLOSED: [YYYY-MM-DD]`
4. Confirm what was marked done.
