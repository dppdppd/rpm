---
description: "Scan docs, memories, and session drift for issues. Present scored findings, fix what user picks, offer hookify rules for repeated violations."
argument-hint: ""
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "Agent"]
---

# /pm audit — Full Instructions

Mechanical doc validity check, then fix what's broken. Default when
running `/pm:audit` with no argument.

## Phase 1: Scan (background agent)

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

7. TASK TRACKER & SESSION DISCIPLINE:
   - Task tracker exists and consistent with progress?
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

## Phase 2: Score and filter findings

When the agent completes, score each finding:

**Confidence score = severity (0-40) + evidence strength (0-30) + fix clarity (0-30)**

- Severity: Critical=40, High=30, Medium=20, Low=10
- Evidence: multiple sources=30, single clear source=20, inferred=10
- Fix clarity: exact steps known=30, direction clear=20, needs investigation=10

**Only present findings scoring >= 60.** Below that, log to PM-LOG.md
but don't bother the user.

Present as a numbered menu, ordered by score:

```
## Audit — YYYY-MM-DD (N findings above threshold)

| # | Finding | Score | Effort |
|---|---------|-------|--------|
| 1 | Screenshot hook allows wrong directory | 95 | Small |
| 2 | 48 specs unlisted in inventory | 85 | Small |
| ... | ... | ... | ... |

(N low-confidence findings logged but not shown)

Which to fix? (e.g., "1", "1,2", "all", "none", or ask about any)
```

## Phase 3: Fix and enforce

Handle the response:
- **Number(s) or "all":** Fix those issues now. For each:
  read the finding, execute the fix, verify, report result.
- **"none":** Save findings to `docs/pm/reviews/YYYY-MM-DD-plan.md`.
- **Question:** Explain the finding in detail, re-prompt.

**After each fix, check if the finding indicates a repeated violation.**
If a CLAUDE.md rule was violated and this is the 2nd+ time it's been
flagged, offer to create a hookify rule:

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

## Phase 4: Log results

After fixing (or choosing "none"):
- Append findings to `docs/pm/PM-LOG.md` audit history
- Add one-liner to `docs/pm/PM.md` Prior Findings table
- Update Sessions Reviewed table if session drift was checked
