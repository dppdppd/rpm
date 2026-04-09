---
name: audit
description: On-demand audit. Target `documents` scans docs + CLAUDE.md + memory + session drift via the pm:auditor subagent. Target `project` runs a full consultant review — code, architecture, inward + outward research, 7-dimension analysis, saved plan file. Routine doc-drift is handled automatically by /pm:session-end — run audit only when you have a specific concern.
disable-model-invocation: true
argument-hint: "documents | project"
allowed-tools: Read Write Edit Bash Glob Grep Agent WebSearch
---

# /pm:audit

On-demand audits. Two distinct targets, no depth menu, no recency
recommendation. Routine doc-drift is handled automatically by
`/pm:session-end` — run `/pm:audit` only when you have a specific
concern that warrants a deeper look.

## Routing

Parse `$ARGUMENTS`:

- `documents` (or `docs`) → run the **Documents** audit below
- `project` → run the **Project** audit described in
  [project-mode.md](project-mode.md). Read that file and follow it
  end-to-end — it contains the full 5-phase protocol, the analyze
  dimensions, and the deliverables spec.
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

Present findings (sorted by score, highest first) using the **Shared
Findings Menu** format described in
[findings-menu.md](findings-menu.md). Read that file for the exact
format, reply grammar, and execute flow.

Below the menu, note any low-confidence findings that were
suppressed: `(N low-confidence findings logged but not shown)`.

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

**The full 5-phase protocol is in [project-mode.md](project-mode.md).**
Read it in full and follow it end-to-end. It contains:

- Phase 1: Investigate (including background `pm:auditor` scan for
  Phase 4 evidence)
- Phase 2: Inward Research (validate against authoritative sources)
- Phase 3: Outward Research (competitive analysis — REQUIRED)
- Phase 4: Analyze across 7 dimensions
- Phase 5: Ask questions and refine
- Deliverables (executive summary + `docs/pm/PM-LOG.md` entry +
  `docs/pm/reviews/YYYY-MM-DD-plan.md` + `docs/pm/reviews/YYYY-MM-DD.md`)

Do not skip phases. Outward research is **required**, not optional —
without it you over-index on "does the project match its own spec?"
and miss whether the spec itself is best-in-class.
