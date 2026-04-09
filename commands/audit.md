---
description: "On-demand project audit. Pick a target: documents (docs + LLM workflow + session drift) or project (full consultant review)."
argument-hint: "documents | project"
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "Agent", "WebSearch"]
---

# /pm:audit

On-demand audits. Two distinct targets, no depth menu, no recency
recommendation. Routine doc-drift is handled automatically by
`/pm:session-end` — run `/pm:audit` only when you have a specific
concern that warrants a deeper look.

## Routing

Parse `$ARGUMENTS`:

- `documents` (or `docs`) → run the **Documents** audit below
- `project` → run the **Project** audit below
- empty or unrecognized → print the usage block and stop:

  ```
  ## /pm:audit — pick a target

  - `/pm:audit documents` — scan docs + CLAUDE.md + memory + session
    drift via the pm:auditor subagent. Scored findings, hookify
    repeat offenders. ~3min.
  - `/pm:audit project` — full consultant review: code, architecture,
    inward + outward research, 7-dimension analysis, saved plan file.
    ~30min+.

  Routine doc-drift runs automatically at /pm:session-end.
  ```

---

## Shared: Findings Menu

Used by **Documents** mode to present findings. Print a compact
numbered list, then wait for a reply.

### Format

```
## Audit findings — {date} ({N} findings)

1. **{quick phrase}** — {description} ({score})

2. **{quick phrase}** — {description} ({score})

3. **{quick phrase}** — {description} ({score})

Reply: `fix 1 2 4` · `all` · `none` · `<#>?` for details
```

Each option leads with a bolded 2–4 word phrase (no line break after),
then the full finding inline. Blank line between options.

### Reply grammar (interpret liberally)

- `fix 1 2 4` / `1 2 4` / `1,2,4` → fix those rows
- `all` / `fix all` → fix every finding
- `none` / `skip all` / `cancel` → skip every finding; log as cancelled
- `<#>?` / `<#>` alone / `tell me about 2` → show full details
  (location, evidence, proposed fix) for that finding, then re-print
  the list and wait for another reply
- natural phrasings like `fix the first two` → map to the obvious action

When in doubt, ask.

### Execute

Once the user confirms a fix set (anything but `none`/`cancel`):

1. For each fix: apply, verify, record result.
2. For each skipped row: record as skipped.
3. Print a compact summary:

   ```
   | # | Result   | Finding |
   |---|----------|---------|
   | 1 | ✅ fixed | ...     |
   | 2 | ⏭ skipped | ...    |
   | 3 | ❌ failed — {reason} | ... |
   ```

Then continue to the mode's logging step.

---

## Target: Documents

Scan docs, CLAUDE.md, memory files, trackers, and recent session
jsonl logs for drift. Runs via the `pm:auditor` subagent. Scored,
confidence-gated, hookifies repeat offenders.

### Phase 1: Scan (background agent)

Launch the `pm:auditor` subagent in background
(`subagent_type: "pm:auditor"`). It returns a structured audit report
containing a scan summary, findings (each scored 0–100), and a session
drift table. The scan spec lives in `agents/auditor.md` — do not
duplicate it here.

Wait for the subagent to complete, then proceed to Phase 2.

### Phase 2: Score findings, present menu

When the agent completes, score each finding:

**Confidence = severity (0-40) + evidence strength (0-30) + fix clarity (0-30)**

- Severity: Critical=40, High=30, Medium=20, Low=10
- Evidence: multiple sources=30, single clear source=20, inferred=10
- Fix clarity: exact steps known=30, direction clear=20, needs investigation=10

**Only present findings scoring ≥ 60.** Below that, log to PM-LOG.md
but don't bother the user.

Present findings (sorted by score, highest first) via the **Shared:
Findings Menu**. Below the menu, note any low-confidence findings that
were suppressed: `(N low-confidence findings logged but not shown)`.

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
  `- YYYY-MM-DD — audit documents — N findings, M fixed, K skipped`
  (cancelled runs: `N findings, cancelled`)
- Append findings detail below the marker
- Add one-liner to `docs/pm/PM.md` Prior Findings table
- Update Sessions Reviewed table if session drift was checked

---

## Target: Project

Full consultant review with external research. You are NOT an expert
in this project's domain — investigate before judging.

**Five phases: Investigate → Inward Research → Outward Research →
Analyze → Refine.** Do not skip phases. Outward research is
**required**, not optional — without it you over-index on "does the
project match its own spec?" and miss whether the spec itself is
best-in-class.

### Phase 1: Investigate (gather evidence, don't opine yet)

**At the start of Phase 1, launch `pm:auditor` in the background**
(`subagent_type: "pm:auditor"`) so its structured scan runs in
parallel with the reads below. Without this, a Project audit can
silently miss broken file refs and tracker drift that a Documents
audit would catch. Wait for the scan to return before Phase 4; its
VALIDITY / COHERENCE / tracker findings become Phase 4 evidence
inputs.

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

### Phase 2: Inward Research (validate against authoritative sources)

Goal: confirm the project's current approach aligns with authoritative
references for its stack, frameworks, and domain.

For each dimension the project touches, identify what you DON'T know
*about how it's supposed to work*. Research against authoritative
docs (vendor docs, RFCs, spec repos). **Min 2 dimensions.**

Either:

- Use WebSearch / WebFetch directly for narrow lookups, or
- Invoke the `deep-research` skill in parallel for complex,
  multi-angle topics. (`deep-research` is a skill in this plugin,
  not a slash command.)

Example inward questions:

- Is the plugin manifest schema current with vendor docs?
- Does our testing strategy match the framework's recommended approach?
- Are we using current API versions / avoiding deprecated patterns?
- Architecture best practices for this stack?

### Phase 3: Outward Research (competitive analysis — REQUIRED)

Goal: compare the project against real alternatives. This is where
you find out whether the spec *itself* is best-in-class, not just
whether the project matches its own spec. Skipping this phase is the
single biggest failure mode of Project mode.

**Discover 3–5 direct competitors or comparable tools.** For at least
**2**, actually `WebFetch` their docs or README — do not rely on
search-result titles or summaries.

For each competitor, note:

- **What they do** — one-sentence summary of their approach
- **What they do better** — specific features/patterns worth stealing
- **What we do better** — things they lack that we should preserve
- **Verdict** — adopt, reject, or flag as complementary (with rationale)

Example outward queries (adapt to project):

- "What other tools in {this domain} exist as of {year}?"
- "How does {competitor A} handle {our core concern}?"
- "What do best-in-class {category} tools do that we don't?"

If a competitor has a feature worth adopting, emit it as a **gap
finding** in Phase 4. Gap findings carry equal weight to
spec-conformance findings.

### Phase 4: Analyze (now you can judge)

Evaluate across these dimensions. Every finding must cite Phase 1
evidence AND either Phase 2 or Phase 3 research — ideally both.
**Mechanical findings from the `pm:auditor` scan (Phase 1) count as
Phase 1 evidence** — promote anything material into the dimension
list below (VALIDITY → LLM Workflow; tracker drift → Session
Discipline). Trivial hygiene drops out.

1. **Process Health** — workflow followed? measure→change→measure?
2. **Architecture & Code Health** — boundaries clean? complexity proportional?
3. **LLM Workflow** — hooks/skills/memory effective? CLAUDE.md right size?
4. **Risk & Compliance** — untested paths? boundary violations?
5. **Strategic Direction** — time on highest-value work? critical path?
6. **Session Discipline** — tracker maintained? sessions scoped?
7. **Competitive Gaps** — features/patterns from Phase 3 the project
   should adopt or explicitly reject (with rationale).

If `docs/pm/PM.md` defines project-specific focus areas, evaluate those too.

### Phase 5: Ask questions and refine

If aspects require developer input, ask now — before writing the plan.
Don't defer questions to the plan file.

### Deliverables

#### 1. Executive summary (displayed to user)

```
## PM Review — YYYY-MM-DD

### Health
[1-2 sentences]

### Research Conducted
- **Inward — [Topic]** — [what you asked, learned, how it changed assessment]
- **Outward — [Competitor]** — [what they do, what you learned]

### Findings
- **[Title] (Severity)** — [2-3 sentences: what, why, research context]

### Plan
**Plan saved to** `docs/pm/reviews/YYYY-MM-DD-plan.md`
[1-line per task: title + effort]
```

#### 2. Log the run

Append one line to `docs/pm/PM-LOG.md` Audit History:

```
- YYYY-MM-DD — audit project — N findings, plan saved to reviews/YYYY-MM-DD-plan.md
```

#### 3. Plan file (saved to disk)

`docs/pm/reviews/YYYY-MM-DD-plan.md`:

```markdown
# PM Plan — YYYY-MM-DD

## Context
[what was reviewed, what inward + outward research was conducted]

## Tasks
### Task 1: [title]
- **Severity:** Critical | High | Medium | Low
- **Dimension:** Process | Architecture | LLM Workflow | Risk | Strategy | Session Discipline | Competitive
- **What's wrong:** [evidence]
- **Why it matters:** [impact]
- **Research says:** [inward docs + outward competitors, both if relevant]
- **Fix:** [concrete steps]
- **Effort:** Small | Medium | Large

## What's Working (don't break these)
```

Ordered by severity then effort. Also save full report to
`docs/pm/reviews/YYYY-MM-DD.md`.
