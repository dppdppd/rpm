---
name: init-rpm
description: rpm project setup and verification. First run scaffolds docs/rpm/ infrastructure and agent instructions; repeat runs verify and migrate an existing rpm setup to the latest expected layout. User-invocable only — never auto-trigger.
---

# /init-rpm — Full Instructions

Project setup and verification. First run creates rpm context for a
project. Repeat runs verify that an existing rpm setup matches the
latest expected layout and apply safe migrations.

Run once per project, or run again after installing rpm in a new agent
runtime such as Codex. On repeat runs, do not re-ask first-run
project context questions unless a required canonical file is missing
and the answer cannot be inferred from existing files.
If `docs/rpm/context.md` already exists, read it and **augment** — do not
overwrite. Merge in missing sections only.

If any `docs/rpm/` content already exists, treat this as an rpm migration/update,
not a brand-new install. Preserve existing rpm files, create only missing
canonical files (`context.md`, `past/log.md`, `present/status.md`,
`future/tasks.org`, `future/done.org`, `reviews/`), and migrate legacy names
when present:

- `docs/rpm/FUTURE.org` or `docs/rpm/future/FUTURE.org` -> `docs/rpm/future/tasks.org`
- `docs/rpm/PRESENT.md` or `docs/rpm/present/PRESENT.md` -> `docs/rpm/present/status.md`
- `docs/rpm/RPM-LOG.md` or `docs/rpm/past/RPM-LOG.md` -> `docs/rpm/past/log.md`
- `docs/rpm/RPM.md` -> `docs/rpm/context.md`

Narrate as you go. At each phase, tell the user what's about to happen
in one short sentence before doing it — users should never be surprised
by what `/init-rpm` creates or writes.

## Phase 0: Introduce

Before running anything, detect whether this is a first run:

- If `docs/rpm/` does not exist, use the first-run introduction below.
- If any `docs/rpm/` content exists, this is a repeat run. Use the
  verification introduction below, then follow **Repeat-run
  verification mode**.

First-run wording (adapt freely):

```
## /init-rpm — rpm first-run setup

I'll set up rpm (Relentless Project Manager) for this project. Here's
what I'm about to do:

1. Detect the project — language, tests, existing docs
2. Ask 1–3 questions I can't answer from the codebase
3. Create `docs/rpm/` scaffolding (context, trackers, past/future/reviews)
4. Create an agent instructions file if one is missing
5. Ask once for runtime permissions if the active agent supports them
6. Summarize what was created

Starting with detection.
```

Do NOT wait for confirmation — this is informative, not gating.
Proceed immediately to Phase 1.

Repeat-run wording (adapt freely):

```
## /init-rpm — rpm setup verification

I found existing rpm state. I won't re-bootstrap this project or ask
first-run questions. I'll verify it against the latest rpm layout,
apply safe migrations for missing canonical files or legacy names, and
ask before changing agent guidance.

Starting with verification.
```

Do NOT wait for confirmation — this is informative, not gating.

### Repeat-run verification mode

Run this mode when `docs/rpm/` exists, `docs/rpm/context.md` exists,
or any legacy rpm file exists (`docs/rpm/RPM.md`,
`docs/rpm/FUTURE.org`, `docs/rpm/PRESENT.md`,
`docs/rpm/RPM-LOG.md`).

1. **Scan current state.** Run the Phase 1 detector and read existing
   `docs/rpm/context.md`, `docs/rpm/present/status.md`,
   `docs/rpm/future/tasks.org`, `docs/rpm/future/done.org`, and
   `docs/rpm/past/log.md` only when they exist.
2. **Verify canonical rpm files.** Create only missing canonical
   files/directories:
   - `docs/rpm/context.md`
   - `docs/rpm/past/log.md`
   - `docs/rpm/present/status.md`
   - `docs/rpm/future/tasks.org`
   - `docs/rpm/future/done.org`
   - `docs/rpm/reviews/`
3. **Apply safe legacy migrations.** Move legacy names listed above
   to the canonical paths only when the canonical target is missing.
   If both old and new paths exist, do not overwrite; report the old
   path as leftover legacy state.
4. **Verify agent guidance layout.** If `CLAUDE.md` exists and
   `AGENTS.md` is missing or `CLAUDE.md` appears to contain general
   project guidance, ask the Claude guidance migration question from
   Phase 4. Do not move guidance without confirmation.
5. **Verify runtime-specific permissions.** Run Phase 6 checks, but
   only apply permission changes for runtimes that support them.
6. **Verify current-session activation.** Ensure
   `docs/rpm/~rpm-session-start` exists for the current session when
   the active runtime uses rpm lifecycle hooks.
7. **Summarize and stop.** Print:

   ```
   ## /init-rpm verification complete

   Verified: {list}
   Created: {list or "nothing"}
   Migrated: {list or "nothing"}
   Needs attention: {list or "nothing"}
   ```

Do not continue into the first-run Phase 2 question flow after repeat
verification mode completes.

## Phase 1: Detect Project State

**Say to user:** "Scanning the project…"

!bash "${RPM_PLUGIN_ROOT:-${CODEX_HOME:-$HOME/.codex}/.tmp/marketplaces/dppdppd-rpm/.codex}/skills/init-rpm/scripts/detect.sh"

Classify silently (do NOT ask the user):
- **GREENFIELD**: Empty or near-empty directory
- **EXISTING**: Has source code, build system, tests
- **HAS_AGENT_INSTRUCTIONS**: Already has `AGENTS.md`, `CLAUDE.md`,
  `.cursorrules`, or another project-level agent instructions file

## Phase 2: Gather Project Context

**Say to user:** "A few quick questions I can't answer from the code:"

Ask the user ONLY these questions (skip any answerable from codebase).
Ask **one at a time** — each question ends its response, and you wait
for the answer before asking the next. Never stack multiple questions
in a single response.

1. **What is this project?** (one sentence)
2. **What's the tech stack?** (or confirm what was detected)
3. **What's the team size?** (solo / small 2-5 / medium 5-10 / large 10+)

Do NOT ask more than 3 questions.

## Phase 3: Create rpm Infrastructure

**Say to user:** "Creating the rpm scaffolding under `docs/rpm/` —
context.md, past/log.md, reviews/ directory."

Create or update these files:

### 3a. `docs/rpm/context.md` — project-local rpm context

Injected into every session via the SessionStart hook. Keep it
under 30 lines — this is hot context, not documentation.

```markdown
# {Project Name} — rpm Context

Injected at session start. Keep under 30 lines.

## Project Summary
{One paragraph: what, tech stack, stage, team size, key constraints}

## Key Files
| What | Where |
|------|-------|
{Table of important files discovered in Phase 1}

## Focus Areas for Review
{Project-specific dimensions to evaluate, adapted from what was
discovered. E.g., for a clean-room project: compliance checks.
For a startup: velocity vs quality tradeoffs.}

## Prior Findings
See `docs/rpm/past/log.md` Audit History.
```

### 3b. `docs/rpm/past/log.md` — append-only history

```markdown
# rpm Log — {project name}

Append-only history of audits, reviews, and sessions.
Referenced from `docs/rpm/context.md` when needed.

## Audit History

## Sessions Reviewed

## Notes
```

### 3c. `docs/rpm/reviews/` — plan file directory

```bash
mkdir -p docs/rpm/reviews
```

## Phase 4: Scaffold Missing Project Infrastructure

**Say to user:** "Checking for missing project files (agent
instructions, spec template, trackers) and creating only what isn't
already there."

For each item below, **check if it exists first**. Only create what's
missing. Never overwrite existing files.

### Agent instructions file and Claude guidance migration

Target 60-120 lines for greenfield, up to 150 for existing projects.
If an agent instructions file already exists, augment it only when a
short rpm section is clearly missing; never overwrite it.

Default general-purpose target file:

- Codex: `AGENTS.md`
- opencode: `AGENTS.md`
- Unknown/generic runtime: `AGENTS.md`
- Claude Code: use `AGENTS.md` for general project/agent guidance
  and keep `CLAUDE.md` only for Claude Code-exclusive directives.

If `CLAUDE.md` exists, do not silently leave general guidance trapped
there. Tell the user:

```
I found `CLAUDE.md`. rpm works across Claude Code, Codex, and
opencode, so I want to move guidance that is not Claude-specific into
`AGENTS.md` and leave `CLAUDE.md` for Claude Code-only directives.

QUESTION: Move general guidance from `CLAUDE.md` to `AGENTS.md` now?
(`yes` / `no`)
```

If the user says `yes`:

1. Read `CLAUDE.md` and classify each section:
   - **General guidance**: project summary, commands, architecture,
     workflow, testing, guardrails, coding conventions, repository
     paths, domain notes, rpm process.
   - **Claude-exclusive guidance**: Claude Code tool names, Claude
     permissions, Claude hook behavior, Claude native tasks,
     Claude-specific slash-command mechanics, `.claude/` settings,
     model-specific Claude instructions.
2. Create or update `AGENTS.md` with the general guidance. Preserve
   existing `AGENTS.md` content and merge without duplication.
3. Rewrite `CLAUDE.md` so it keeps only Claude-exclusive directives
   and includes this policy near the top:

   ```markdown
   # Claude Code Directives

   General project and agent guidance belongs in `AGENTS.md` by
   default. Keep this file limited to Claude Code-exclusive
   directives: Claude-specific tools, hooks, permissions, native task
   behavior, and slash-command mechanics.

   Claude Code should read `AGENTS.md` first, then apply the
   Claude-only directives below.
   ```

4. If there is no Claude-exclusive guidance, leave `CLAUDE.md` as the
   policy stub above plus a short pointer to `AGENTS.md`.

If the user says `no`, preserve `CLAUDE.md` exactly as-is. Still
create `AGENTS.md` if missing, using the template below, so future
general guidance has a runtime-neutral home.

If only `AGENTS.md` exists, update it directly. If neither exists,
create `AGENTS.md` from the template below. Do not create
`CLAUDE.md` unless Claude Code-exclusive guidance exists or the
project already had `CLAUDE.md`.

```markdown
# Project: {name}

{One-sentence description}

## Commands
- Build: `{build_cmd}`
- Test all: `{test_cmd}`
- Test single: `{test_single_cmd}`
- Lint: `{lint_cmd}`
- Dev server: `{dev_cmd}`

## Architecture
{2-5 bullet points with explicit paths}

## Workflow
Spec -> Approve -> Build -> Verify -> Checkpoint.

- Create specs before coding: `/spec {feature-name}`
- Run `{build_cmd} && {test_cmd} && {lint_cmd}` after every task
- Commit after every deliverable, one task at a time
- Stop at human checkpoints — present results
- **Plan before coding.** Get approval before writing code.

## Testing
- Write tests alongside code, not just after
- Test files: `{test_dir}`
- Focus on behavior and edge cases, not snapshots
- ALWAYS run `{test_cmd}` after changes

## Guardrails
- 3 attempts max to fix a failing issue, then STOP and report
- Same error twice → change strategy
- Ask before: adding dependencies, architecture decisions, deviating from spec
```

### Spec template (if no spec workflow exists)

Create `docs/spec/_template.md`:

```markdown
# Spec: {Feature Name}

**Status:** DRAFT | APPROVED | IMPLEMENTED | DEPRECATED
**Date:** {date}

## Background
## Requirements
## Design
## Tasks
## Acceptance Criteria
## Human Checkpoint
## Out of Scope
```

### Present tracker (if none exists)

Create `docs/rpm/present/status.md` for current project state:

```markdown
# {Project Name} — Present State

## Project Status
- **Current phase**: {phase}
- **Last updated**: {date}

## Completed Work
## Active Specs
## Known Issues
```

### Past directory (if none exists)

Create `docs/rpm/past/` for daily session logs (`YYYY-MM-DD.md` files
written by `/session-end`).

### Future tracker (if none exists)

Create `docs/rpm/future/tasks.org`:

```org
#+TITLE: {Project Name} Future
#+TODO: TODO IN-PROGRESS BLOCKED WATCH | DONE

* {Current Phase}
** TODO {first task} [[file:YYYY-MM-DD-slug.md]]
   :PROPERTIES:
   :ID: {slug}
   :END:
```

`WATCH` is for entries that are observe-only / deferred until a
trigger condition appears. `/next` treats `WATCH` as closed for
task-selection purposes: it skips `WATCH` the same way it skips
`DONE`. Use it instead of `TODO` when a follow-up should remain
visible in the backlog without triggering a worker dispatch.

**Format rule (enforce from day one):** each entry is the
heading line (with `[[file:...]]` link) plus the standard
`:PROPERTIES: / :ID: / :END:` drawer. Body content (anything
outside the drawer) caps at 3 lines and is usually empty —
all task details live in the detail file at
`future/<date>-<slug>.md`. The drawer doesn't count toward
the 3-line body budget; add `:BLOCKED_BY: <other-slug>` inside
it when there's a dependency on another task.

Never inline bullet lists, prose, or implementation notes in
your rpm backlog. The full rule lives in
`plugin/skills/backlog/SKILL.md`.

Also create `docs/rpm/future/done.org` (archive for closed entries
swept out of tasks.org by `/session-end`):

```org
#+TITLE: {Project Name} Archive
#+TODO: TODO IN-PROGRESS BLOCKED | DONE CANCELLED

Closed entries swept from tasks.org by session-end. Newest first.
```

## Phase 5: Adapt for Team Size

**Say to user:** "Tuning the scaffolding for your team size."

**Solo/Small:** Use template as-is. Single agent with spec workflow.

**Medium (5-10):** Consider adding agent roles when a single agent
demonstrably struggles. Cap at 4. Communicate via typed artifacts.

**Large (10+):** Module ownership, git worktrees for parallel agent isolation.

## Phase 6: Permissions

**Say to user:** "Checking whether this runtime needs an rpm
permissions entry."

rpm hooks and skills frequently read/write files under `docs/rpm/`.
Some runtimes support project-local allowlists; others use sandbox or
approval policy outside the project.

Only perform the `.claude` permissions edit when running under Claude
Code or when `.claude/settings.local.json` / `.claude/settings.json`
already exists. Do not create `.claude/` for Codex, opencode, or an
unknown runtime.

For Claude Code: check whether `Read(./docs/rpm/**)` and
`Edit(./docs/rpm/**)` already appear in `.claude/settings.local.json`
(or `.claude/settings.json`). If they do, skip this phase silently.

If not, ask:

```
Grant rpm read/write access to docs/rpm/?
This lets hooks and skills manage session files, daily logs, and
trackers without per-file permission prompts.
(y/n)
```

If yes: read `.claude/settings.local.json` (create if missing), merge
`Read(./docs/rpm/**)` and `Edit(./docs/rpm/**)` into
`permissions.allow`, and write the file back. Do not overwrite
existing entries.

For Codex, opencode, and unknown runtimes: do not prompt for this
permission. Continue to Phase 7.

## Phase 7: Create All Files

**Say to user:** "Writing the scaffolding now."

Create all files from Phase 3 and Phase 4 that do not already exist.
Do NOT prompt the user to select which files to create — all are
required for the plugin to function.

**Then activate hooks for the current session when supported.** The
runtime startup hook may already have run before `docs/rpm/` existed
and exited without writing `~rpm-session-start` — so lifecycle hooks
can be gated off until the next session. Write the marker now so hooks
activate immediately in runtimes that use the rpm marker, no restart
needed:

```bash
SID="${CLAUDE_CODE_SESSION_ID:-${CODEX_SESSION_ID:-${OPENCODE_SESSION_ID:-unknown}}}"
cat > docs/rpm/~rpm-session-start <<EOF
---
session_id: $SID
started: $(date -Iseconds)
task: (unassigned)
---
EOF
```

After the marker is written, proceed to Phase 8.

## Phase 8: Present and Confirm

Print the completion summary exactly like this (fill in the created
files list):

```
## /init-rpm complete

Created: {list of created files}

Next steps:
- rpm is active in this session already — hooks will fire as you work
  where the active runtime exposes lifecycle hooks
- `/backlog add <description>` — add entries to your rpm backlog
- `/audit project` — run a full consultant review when you want
  outside perspective on code, architecture, and competitive positioning

To de-rpm this project later: delete `docs/rpm/`. The plugin hooks
exit silently when that directory is missing, so nothing else needs
changing.
```

## Scaling Notes

- **Agent instructions too long/stale** -> Split into root +
  per-service files
- **Tasks parallelizable** -> Multi-agent with git worktrees
- **Context bottleneck** -> Three-tier knowledge with MCP retrieval

**Cost awareness:** Multi-agent = 4-220x more tokens. Monitor weekly.
