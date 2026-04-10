---
name: init
description: First-run pm plugin setup for a project. Detects project state, scaffolds docs/rpm/ infrastructure (RPM.md, RPM-LOG.md, PRESENT.md, FUTURE.org, past/, reviews/), and creates CLAUDE.md if missing. Run ONCE per project. User-invocable only — never auto-trigger.
disable-model-invocation: true
argument-hint: ""
allowed-tools: Read Write Bash(ls:*) Bash(mkdir:*) Bash(git:*) Glob Grep
---

# /rpm:init — Full Instructions

First-run setup. Creates PM context for a project. Run once per project.
If `docs/rpm/RPM.md` already exists, read it and **augment** — do not
overwrite. Merge in missing sections only.

## Phase 1: Detect Project State

Determine silently (do NOT ask the user):
- **GREENFIELD**: Empty or near-empty directory
- **EXISTING**: Has source code, build system, tests
- **HAS_CLAUDE_MD**: Already has CLAUDE.md or AGENTS.md

```bash
ls src/ lib/ app/ main.* index.* *.py *.ts *.go *.rs 2>/dev/null
ls package.json Cargo.toml go.mod pyproject.toml Makefile CMakeLists.txt 2>/dev/null
ls -d test/ tests/ spec/ __tests__/ *_test.* *_spec.* 2>/dev/null
ls CLAUDE.md AGENTS.md .claude/ .cursorrules 2>/dev/null
git log --oneline -20 2>/dev/null
```

## Phase 2: Gather Project Context

Ask the user ONLY these questions (skip any answerable from codebase):

1. **What is this project?** (one sentence)
2. **What's the tech stack?** (or confirm what was detected)
3. **What's the team size?** (solo / small 2-5 / medium 5-10 / large 10+)

Do NOT ask more than 3 questions.

## Phase 3: Create PM Infrastructure

Create or update these files:

### 3a. `docs/rpm/RPM.md` — project-local PM context

```markdown
# {Project Name} — PM Context

Project-specific guidance for the `/pm` engineering consultant.
Read by the global `/pm` skill at Step 0.

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
| Date | Key Finding |
|------|-------------|
```

### 3b. `docs/rpm/RPM-LOG.md` — append-only PM history

```markdown
# PM Log — {project name}

Append-only history of PM audits, reviews, and session reviews.
Not loaded automatically — referenced from `docs/rpm/RPM.md` when needed.

## Audit History

## Sessions Reviewed

## PM Notes
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

Create `docs/rpm/PRESENT.md` for current project state:

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
written by `/rpm:session-end`).

### Future tracker (if none exists)

Create `docs/rpm/FUTURE.org`:

```org
#+TITLE: {Project Name} Future
#+TODO: TODO IN-PROGRESS BLOCKED | DONE

* {Current Phase}
** TODO {first task}
```

## Phase 5: Adapt for Team Size

**Solo/Small:** Use template as-is. Single agent with spec workflow.

**Medium (5-10):** Consider adding agent roles when a single agent
demonstrably struggles. Cap at 4. Communicate via typed artifacts.

**Large (10+):** Module ownership, git worktrees for parallel agent isolation.

## Phase 6: Present and Confirm

Do NOT create or modify files yet. Present all planned changes as a
numbered checklist:

```
## /rpm:init — proposed changes

| # | Action | File |
|---|--------|------|
| 1 | Create | docs/rpm/RPM.md |
| 2 | Create | docs/rpm/RPM-LOG.md |
| 3 | Create | docs/rpm/reviews/ |
| 4 | Create | CLAUDE.md |
| ... | ... | ... |

(Only files that don't already exist are listed)

Which to create? (e.g., "1", "1,2,3", "all", "none")
```

Execute only what the user selects. After completing:

```
## /rpm:init complete

Created: {list of created files}

Next steps:
- Start a new conversation — PM context auto-loads via SessionStart hook
- `/rpm:audit project` — run a full consultant review when you want
  outside perspective on code, architecture, and competitive positioning
```

## Scaling Notes

- **CLAUDE.md too long/stale** → Split into root + per-service files
- **Tasks parallelizable** → Multi-agent with git worktrees
- **Context bottleneck** → Three-tier knowledge with MCP retrieval

**Cost awareness:** Multi-agent = 4-220x more tokens. Monitor weekly.
