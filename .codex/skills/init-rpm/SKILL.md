---
name: init-rpm
description: First-run rpm plugin setup for a project. Detects project state, scaffolds docs/rpm/ infrastructure (context.md, past/, present/, future/, reviews/), and creates an agent instructions file if missing. Run ONCE per project. User-invocable only — never auto-trigger.
---

# /init-rpm — Full Instructions

First-run setup. Creates or updates rpm context for a project. Run once per project,
or run once after installing rpm in a new agent runtime such as Codex.
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

Before running anything, tell the user what /init-rpm will do. Use
roughly this wording (adapt freely):

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

### Agent instructions file (if missing)

Target 60-120 lines for greenfield, up to 150 for existing projects.
If an agent instructions file already exists, augment it only when a
short rpm section is clearly missing; never overwrite it.

Default target file by runtime:

- Claude Code: `CLAUDE.md`
- Codex: `AGENTS.md`
- opencode: `AGENTS.md`
- Unknown/generic runtime: `AGENTS.md`

If both `AGENTS.md` and `CLAUDE.md` exist, prefer updating `AGENTS.md`
with generic instructions and leave `CLAUDE.md` untouched unless it
already contains rpm-specific guidance.

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
#+TODO: TODO IN-PROGRESS BLOCKED | DONE

* {Current Phase}
** TODO {first task} [[file:YYYY-MM-DD-slug.md]]
   :PROPERTIES:
   :ID: {slug}
   :END:
```

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
