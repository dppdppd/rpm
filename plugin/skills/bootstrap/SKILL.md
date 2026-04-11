---
name: bootstrap
description: First-run rpm plugin setup for a project. Detects project state, scaffolds docs/rpm/ infrastructure (context.md, past/, present/, future/, reviews/), and creates CLAUDE.md if missing. Run ONCE per project. User-invocable only — never auto-trigger.
disable-model-invocation: true
argument-hint: ""
allowed-tools: Read Write Bash(bash:*) Bash(mkdir:*) Bash(git:*) Glob Grep
---

# /bootstrap — Full Instructions

First-run setup. Creates rpm context for a project. Run once per project.
If `docs/rpm/context.md` already exists, read it and **augment** — do not
overwrite. Merge in missing sections only.

## Phase 1: Detect Project State

!bash "${CLAUDE_SKILL_DIR}/scripts/detect.sh"

Classify silently (do NOT ask the user):
- **GREENFIELD**: Empty or near-empty directory
- **EXISTING**: Has source code, build system, tests
- **HAS_CLAUDE_MD**: Already has CLAUDE.md or AGENTS.md

## Phase 2: Gather Project Context

Ask the user ONLY these questions (skip any answerable from codebase):

1. **What is this project?** (one sentence)
2. **What's the tech stack?** (or confirm what was detected)
3. **What's the team size?** (solo / small 2-5 / medium 5-10 / large 10+)

Do NOT ask more than 3 questions.

## Phase 3: Create rpm Infrastructure

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

## Tasks
New tasks in `future/tasks.org`: one short sentence + link to
`future/<date>-<slug>.md` with details. Never inline task details
in tasks.org itself.

## Prior Findings
| Date | Key Finding |
|------|-------------|
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

For each item below, **check if it exists first**. Only create what's
missing. Never overwrite existing files.

### CLAUDE.md (if missing)

Target 60-120 lines for greenfield, up to 150 for existing projects.

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
Spec → Approve → Build → Verify → Checkpoint.

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
```

Each task entry is one short sentence + a link to a detail file
(`future/<date>-<slug>.md`). Never inline task details in tasks.org.

## Phase 5: Adapt for Team Size

**Solo/Small:** Use template as-is. Single agent with spec workflow.

**Medium (5-10):** Consider adding agent roles when a single agent
demonstrably struggles. Cap at 4. Communicate via typed artifacts.

**Large (10+):** Module ownership, git worktrees for parallel agent isolation.

## Phase 6: Permissions

rpm hooks and skills frequently read/write files under `docs/rpm/`.
Without explicit permissions, every file operation prompts the user.

Check whether `Read(./docs/rpm/**)` and `Edit(./docs/rpm/**)` already
appear in `.claude/settings.local.json` (or `.claude/settings.json`).
If they do, skip this phase silently.

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

## Phase 7: Create All Files

Create all files from Phase 3 and Phase 4 that do not already exist.
Do NOT prompt the user to select which files to create — all are
required for the plugin to function. After creating files, proceed to
Phase 8.

## Phase 8: Present and Confirm

```
## /bootstrap complete

Created: {list of created files}

Next steps:
- Start a new conversation — rpm context auto-loads via SessionStart hook
- `/tasks add <description>` — add tasks to your backlog
- `/audit project` — run a full consultant review when you want
  outside perspective on code, architecture, and competitive positioning
```

## Scaling Notes

- **CLAUDE.md too long/stale** → Split into root + per-service files
- **Tasks parallelizable** → Multi-agent with git worktrees
- **Context bottleneck** → Three-tier knowledge with MCP retrieval

**Cost awareness:** Multi-agent = 4-220x more tokens. Monitor weekly.
