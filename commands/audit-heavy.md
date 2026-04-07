---
description: "Deep project review with external research. Investigate, research best practices, produce executive summary + action plan."
argument-hint: ""
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "Agent", "WebSearch"]
---

# /pm audit-heavy — Full Instructions

Full consultant review with external research. You are NOT an expert
in this project's domain — investigate before judging.

**Three phases: Investigate → Research → Judge.** Do not skip to judgment.

## Phase 1: Investigate (gather evidence, don't opine yet)

Read project state in parallel:
- `git log --oneline -30` and `git diff --stat`
- CLAUDE.md, progress tracker, debugging/parity logs
- Memory files (feedback type especially)
- `grep -rn NOT_IMPLEMENTED packages/`
- `docs/pm/PM.md` (project-specific PM context)
- Prior consultant reviews if they exist

Then **probe deeper**:
- **Code structure**: read 2-3 key source files. Most-changed files:
  `git log --format='%H' -30 | xargs -I{} git diff-tree --no-commit-id -r {} | awk '{print $6}' | sort | uniq -c | sort -rn | head -10`
- **Test coverage reality**: what test files exist vs source files?
- **Actual vs claimed architecture**: grep for cross-package imports
- **Build health**: `turbo build` (or project's build command)
- **Dependency freshness**: check package.json for outdated deps

## Phase 2: Research (bring outside expertise)

For each analysis dimension, identify what you DON'T know. Launch
`/deep-research` agents in parallel (min 2). Wait for ALL to complete.

Example questions (adapt to project):
- Architecture best practices for this stack
- Testing strategies for this app type
- LLM workflow best practices at this project's scale
- Domain-specific: how do similar projects handle this?

## Phase 3: Analyze (now you can judge)

Evaluate across these dimensions. Every finding must cite Phase 1
evidence AND Phase 2 research.

1. **Process Health** — workflow followed? measure→change→measure?
2. **Architecture & Code Health** — boundaries clean? complexity proportional?
3. **LLM Workflow** — hooks/skills/memory effective? CLAUDE.md right size?
4. **Risk & Compliance** — untested paths? boundary violations?
5. **Strategic Direction** — time on highest-value work? critical path?
6. **Session Discipline** — tracker maintained? sessions scoped?

If `docs/pm/PM.md` defines project-specific focus areas, evaluate those too.

## Phase 4: Ask questions and refine

If aspects require developer input, ask now — before writing the plan.
Don't defer questions to the plan file.

## Deliverables

### 1. Executive summary (displayed to user)

```
## PM Review — YYYY-MM-DD

### Health
[1-2 sentences]

### Research Conducted
- **[Topic]** — [what you asked, learned, how it changed assessment]

### Findings
- **[Title] (Severity)** — [2-3 sentences: what, why, research context]

### Plan
**Plan saved to** `docs/pm/reviews/YYYY-MM-DD-plan.md`
[1-line per task: title + effort]
```

### 2. Plan file (saved to disk)

`docs/pm/reviews/YYYY-MM-DD-plan.md`:

```markdown
# PM Plan — YYYY-MM-DD

## Context
[what was reviewed, what research was conducted]

## Tasks
### Task 1: [title]
- **Severity:** Critical | High | Medium | Low
- **Dimension:** Process | Architecture | LLM Workflow | Risk | Strategy
- **What's wrong:** [evidence]
- **Why it matters:** [impact]
- **Research says:** [finding]
- **Fix:** [concrete steps]
- **Effort:** Small | Medium | Large

## What's Working (don't break these)
```

Ordered by severity then effort. Also save full report to
`docs/pm/reviews/YYYY-MM-DD.md`.
