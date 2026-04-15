# Tighten session-end native-task reconciliation

## Description

Session-end Phase 1 prep ("Native task reconciliation") currently says:

> Native task still in-progress/pending → append as TODO/IN-PROGRESS
> if no tasks.org counterpart.

That rule made sense when the native task list was treated as a
secondary authoritative source. Under the new rule
([feedback_native_tasks_short_term.md](../../../.claude/projects/-home-coder-projects-rpm/memory/feedback_native_tasks_short_term.md)),
native tasks are ephemeral — they represent current-session sub-work
only, not future backlog.

The existing reconciliation logic therefore over-promotes: a native
task Claude created to track "write the test" as a sub-step of a
session-picked backlog item will survive to session-end and get
appended to `tasks.org` as a TODO, even though it's just internal
workflow scaffolding.

## Proposed change

In `plugin/skills/session-end/SKILL.md`, update the "Native task
reconciliation" section under Phase 1 prep:

- **Default: let ephemeral natives die.** Don't auto-append.
- **Only promote** when Claude judges the native task represents
  genuine future work (e.g., user said "let's do this later" mid-work
  and it became a native task by mistake, or the task is clearly
  scoped beyond the current session).
- Orphan entries in `~rpm-native-tasks.jsonl` from prior unwrapped
  sessions (different session IDs) are the exception — still offer
  to promote those, since they came from an abandoned previous
  session and the user's intent isn't clear.

## Notes

- Candidate matching (`~rpm-task-candidates.jsonl`) stays the same —
  it correctly maps completed natives to existing tasks.org entries
  without creating new backlog items.
- The behavior change only affects the "no tasks.org counterpart"
  branch.
