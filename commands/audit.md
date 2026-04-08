---
description: "Audit project docs/session drift. Presents three depths and recommends one based on audit history."
argument-hint: ""
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "Agent", "WebSearch"]
---

# /pm:audit

## Step 0: Check recency, then present menu

Find when each mode was last run. Run in parallel:

```bash
grep -nE "audit (light|standard|heavy)" docs/pm/PM-LOG.md 2>/dev/null | tail -30
ls -t docs/pm/reviews/*.md 2>/dev/null | head -5
```

From the output, extract the most recent date for each mode (look for
`YYYY-MM-DD` near `audit light`/`audit standard`/`audit heavy`).
Anything not found is "never".

**Pick the recommendation** using this rule:

- No audit history at all → recommend **light** (start cheap)
- Last audit was **light** → recommend **standard** (fix what light surfaced)
- Last audit was **standard** → recommend **heavy** (periodic deep review)
- Last audit was **heavy** → recommend **light** (routine check; heavy is expensive)

If multiple modes tie, prefer the one that's been longest since last run.

Print this menu (substituting real dates and marking the recommended row
with ⭐) and STOP. Wait for the user to reply `1`, `2`, or `3`:

```
## /pm:audit — pick a depth

| # | Mode | What it does | Output | Last run |
|---|------|--------------|--------|----------|
| 1 | light | Quick staleness dashboard: file existence, mod dates, broken refs, CLAUDE.md size, NOT_IMPLEMENTED stubs. | Findings table + 1-line PM-LOG entry | {date or never} |
| 2 | standard | Mechanical scan (docs, coherence, LLM-effectiveness, session drift) → scored findings → fix what you pick. | Scored fix queue, doc edits, PM-LOG detail, PM.md row | {date or never} |
| 3 | heavy | Full consultant review. Investigate → research (multiple /deep-research agents) → judge across 6 dimensions. | Executive summary, plan + full report in `reviews/` | {date or never} |

⭐ Recommended: **{mode}** — {one-line reason based on recency rule}

Reply `1`, `2`, or `3`.
```

When the user replies, jump to the matching mode below.

---

## Shared: Interactive Findings Menu

Used by **light** and **standard** modes whenever findings are presented.
Each row starts unmarked (`·`). The user marks rows fix/skip, can inspect
any row for details, and executes from the bottom row.

### Display

```
## Audit findings — {date} ({N} findings)

| # |   | Finding                                | Priority | Effort |
|---|---|----------------------------------------|----------|--------|
| 1 | · | {title}                                | HIGH     | Small  |
| 2 | · | {title}                                | HIGH     | Small  |
| 3 | · | {title}                                | MED      | Medium |
| e | ▶ | **Execute marked actions**             |          |        |

Mark   `<#>y` fix · `<#>x` skip · `yy` all fix · `xx` all skip
Inspect `<#>` (number alone) — full details, then redraw
Execute `e`  ·  Cancel `q`
```

Symbols: `·` unmarked · `✓` fix · `✗` skip. In standard mode replace the
`Priority` column with `Score` (0–100).

### Reply grammar

| Input | Effect |
|-------|--------|
| `<#>y` | Mark row # as fix (✓) |
| `<#>x` | Mark row # as skip (✗) |
| `<#>` (bare number) | Inspect — show location, evidence, proposed fix; redraw menu. **Does not execute.** |
| `yy` | Mark every row as fix |
| `xx` | Mark every row as skip |
| `1y 2x 3y` | Multiple ops in one reply, applied left-to-right, then redraw |
| `e` / `execute` / `go` | Run the Execute step below with current marks |
| `q` / `cancel` | Abort — no changes, log the run as cancelled |

Interpret replies liberally: `y1`, `1 y`, `fix 1`, and `inspect 2` all
map to the obvious action. When in doubt, ask.

### Loop

After any mark or inspect, redraw the updated menu and wait for the next
reply. Only `e` or `q` exits the loop.

### Execute

When the user types `e`:

1. For each ✓ finding: apply the fix, verify, record result.
2. For each ✗ or still-unmarked row: record as skipped.
3. Display a result summary:

   ```
   | # | Result         | Finding |
   |---|----------------|---------|
   | 1 | ✅ fixed        | ...     |
   | 2 | ⏭ skipped      | ...     |
   | 3 | ❌ failed — {reason} | ... |
   ```

Then continue to the mode's logging step.

---

## Mode: Light

Quick staleness scan — no background agent, no deep research.

Scan the project inline (not a subagent):

- All `.md` / `.org` docs: existence, mod date, line count
- CLAUDE.md line count (warn >120, critical >150)
- Broken file references (anything in backticks that looks like a path)
- `NOT_IMPLEMENTED` stubs
- Task tracker freshness (`FUTURE.org` or equivalent)

Assemble findings as a priority-ordered list (HIGH / MED / LOW) and
present via the **Shared: Interactive Findings Menu**. The user marks,
inspects, and executes from that menu.

### Logging

After the Execute step completes (or the user cancels with `q`), append
one line to `docs/pm/PM-LOG.md` Audit History (create the `## Audit
History` heading if missing):

```
- YYYY-MM-DD — audit light — N surfaced, M fixed, K skipped
```

Cancelled runs log as `N surfaced, 0 fixed, cancelled`.

---

## Mode: Standard

Mechanical doc validity check, then fix what's broken.

### Phase 1: Scan (background agent)

Launch a background agent to scan without editing:

```
Read-only audit. Do NOT edit files.

1. DISCOVER: Scan for all .md files (root, docs/, .claude/, specs/).
   Get line counts and last-modified dates.

2. VALIDITY: For each doc, verify:
   - File path references resolve on disk
   - Status claims match actual state
   - Cross-references are bidirectional
   - Commands/endpoints still exist
   Labels: VALID | STALE | CONTRADICTORY | MISSING

3. COHERENCE: Verify docs agree with each other:
   - Status alignment across trackers
   - Index accuracy (every entry resolves)
   - Deferred work consistency (grep NOT_IMPLEMENTED vs doc claims)

4. LLM-EFFECTIVENESS:
   - CLAUDE.md under 150 lines?
   - Structure score (% tables/lists vs prose)
   - Duplication scan
   - Hook coverage: every hard CLAUDE.md rule has a hook?

5. GUIDANCE ALIGNMENT: Read all memory files of type "feedback".
   For each, check if codified in CLAUDE.md, tier-2 docs, skills, hooks.
   Classify: CODIFIED | PARTIAL | GAP | STALE

6. GAP ANALYSIS: Simulate critical workflows (build, test, deploy,
   add feature). Would the LLM succeed using only docs?

7. FUTURE TRACKER & SESSION DISCIPLINE:
   - `FUTURE.org` (or equivalent) exists and consistent with `PRESENT.md`?
   - IN-PROGRESS items dated? Stale (>3 sessions)?
   - CLAUDE.md instruction count (warn >120, critical >150)

8. SESSION DRIFT: Mine recent sessions for undocumented changes.
   Session data: ~/.claude/projects/$(pwd | sed 's|/|-|g; s|^-||')/*.jsonl
   For unreviewed sessions (most recent first, max 5):
   - Extract user messages and file-modifying tool calls
   - Classify drift as JUSTIFIED or UNJUSTIFIED
   For unjustified: recommend hook > CLAUDE.md > wording

Report format:
## Audit Report — {date}
### Summary: N scanned, N valid, N stale, N contradictory, N missing
### Findings (each with Confidence 0-100)
### Session Drift table
```

### Phase 2: Score findings, present menu

When the agent completes, score each finding:

**Confidence = severity (0-40) + evidence strength (0-30) + fix clarity (0-30)**

- Severity: Critical=40, High=30, Medium=20, Low=10
- Evidence: multiple sources=30, single clear source=20, inferred=10
- Fix clarity: exact steps known=30, direction clear=20, needs investigation=10

**Only present findings scoring ≥ 60.** Below that, log to PM-LOG.md
but don't bother the user.

Present findings (sorted by score, highest first) via the **Shared:
Interactive Findings Menu**. Use `Score` (0–100) instead of `Priority`
in the menu table. Below the menu, note any low-confidence findings
that were suppressed: `(N low-confidence findings logged but not shown)`.

### Phase 3: Post-execute — hookify repeat offenders

After the menu's Execute step completes, for each ✓ fix that addresses
a CLAUDE.md rule violation flagged **2+ times across audits**, offer
to codify it:

> "This rule has been violated before. Want me to create a hook to
> enforce it? I'll write a `.claude/hookify.{name}.local.md` rule."

If the user agrees, create the hookify rule file:

```markdown
---
name: {descriptive-name}
enabled: true
hook_type: PreToolUse
matcher: "{tool pattern}"
---

{Description of what this rule enforces and why}

## Conditions
- {condition}: {pattern}

## Action
deny with message: "{explanation}"
```

### Phase 4: Log results

After the Execute step (or a cancelled run):

- Append a one-line run marker to `docs/pm/PM-LOG.md` Audit History:
  `- YYYY-MM-DD — audit standard — N findings, M fixed, K skipped`
  (cancelled runs: `N findings, cancelled`)
- Append findings detail below the marker
- Add one-liner to `docs/pm/PM.md` Prior Findings table
- Update Sessions Reviewed table if session drift was checked

---

## Mode: Heavy

Full consultant review with external research. You are NOT an expert
in this project's domain — investigate before judging.

**Three phases: Investigate → Research → Judge.** Do not skip to judgment.

### Phase 1: Investigate (gather evidence, don't opine yet)

Read project state in parallel:

- `git log --oneline -30` and `git diff --stat`
- CLAUDE.md, `PRESENT.md`, recent `past/` daily logs, debugging/parity logs
- Memory files (feedback type especially)
- `grep -rn NOT_IMPLEMENTED` across the project's source tree (tune path to layout)
- `docs/pm/PM.md` (project-specific PM context)
- Prior consultant reviews if they exist

Then **probe deeper**:

- **Code structure**: read 2-3 key source files. Most-changed files:
  `git log --format='%H' -30 | xargs -I{} git diff-tree --no-commit-id -r {} | awk '{print $6}' | sort | uniq -c | sort -rn | head -10`
- **Test coverage reality**: what test files exist vs source files?
- **Actual vs claimed architecture**: grep for cross-package imports
- **Build health**: `turbo build` (or project's build command)
- **Dependency freshness**: check package.json for outdated deps

### Phase 2: Research (bring outside expertise)

For each analysis dimension, identify what you DON'T know. Launch
`/deep-research` agents in parallel (min 2). Wait for ALL to complete.

Example questions (adapt to project):

- Architecture best practices for this stack
- Testing strategies for this app type
- LLM workflow best practices at this project's scale
- Domain-specific: how do similar projects handle this?

### Phase 3: Analyze (now you can judge)

Evaluate across these dimensions. Every finding must cite Phase 1
evidence AND Phase 2 research.

1. **Process Health** — workflow followed? measure→change→measure?
2. **Architecture & Code Health** — boundaries clean? complexity proportional?
3. **LLM Workflow** — hooks/skills/memory effective? CLAUDE.md right size?
4. **Risk & Compliance** — untested paths? boundary violations?
5. **Strategic Direction** — time on highest-value work? critical path?
6. **Session Discipline** — tracker maintained? sessions scoped?

If `docs/pm/PM.md` defines project-specific focus areas, evaluate those too.

### Phase 4: Ask questions and refine

If aspects require developer input, ask now — before writing the plan.
Don't defer questions to the plan file.

### Deliverables

#### 1. Executive summary (displayed to user)

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

#### 2. Log the run

Append one line to `docs/pm/PM-LOG.md` Audit History:

```
- YYYY-MM-DD — audit heavy — N findings, plan saved to reviews/YYYY-MM-DD-plan.md
```

#### 3. Plan file (saved to disk)

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
