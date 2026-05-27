---
name: audit
description: On-demand audit. Target `quick` runs the mechanical scan.sh only (zero-LLM drift check). Target `documents` scans docs + agent instructions + memory + session drift via the rpm:auditor review agent. Target `project` runs a full consultant review — code, architecture, inward + outward research, 7-dimension analysis, saved plan file. Routine doc-drift is handled automatically by /session-end — run audit only when you have a specific concern.
---

# /audit

On-demand audits. Three distinct targets, no depth menu, no recency
recommendation. Routine doc-drift is handled automatically by
`/session-end` — run `/audit` only when you have a specific
concern that warrants a deeper look.

## Project Amendments

At the start of every invocation, check whether
`docs/rpm/skills/audit.md` exists in the consuming project. If it
does, read it and apply its contents as additional project-specific
instructions for this skill. Amendments may add audit dimensions,
require extra scans, or extend the report format. They cannot remove
or override plugin defaults — on conflict, this SKILL.md wins.

## Routing

Parse `$ARGUMENTS`:

- `quick` → run the **Quick** audit below (mechanical scan.sh only,
  no LLM scan)
- `documents` (or `docs`) → run the **Documents** audit below
- `project` → run the **Project** audit described in
  [project-mode.md](project-mode.md). Read that file and follow it
  end-to-end — it contains the full 5-phase protocol, the analyze
  dimensions, and the deliverables spec.
- empty or unrecognized → print the usage block and stop:

  ```
  ## /audit — pick a target

  - `/audit quick` — mechanical scan.sh only. Git state,
    agent instructions size, NOT_IMPLEMENTED, broken refs,
    daily-log gap, session marker, spec inventory drift,
    log/tracker staleness.
    Zero LLM tokens for the scan itself. ~5sec.
  - `/audit documents` — scan docs + agent instructions + memory +
    session drift via the rpm:auditor review agent. Scored findings,
    codify repeat offenders. ~3min.
  - `/audit project` — full consultant review: code, architecture,
    inward + outward research, 7-dimension analysis, saved plan file.
    ~30min+.

  Routine doc-drift runs automatically at /session-end.
  ```

---

## Target: Quick

Mechanical drift scan only — no `rpm:auditor` subagent, no LLM
scan, no 110-doc walk. Runs `skills/session-end/scripts/scan.sh`
via direct shell injection and interprets the output.

Use when you want a fast "anything broken right now?" check
between session-ends, or to verify a fix landed, without committing
to a full documents audit.

### Phase 1: Scan (auto-injected, no tool call needed)

The `scan.sh` output below was produced by the shell before this
skill body reached you. Its results are already in this message —
do NOT re-run these checks as tool calls.

!`bash "${RPM_PLUGIN_ROOT:-${CODEX_HOME:-$HOME/.codex}/.tmp/marketplaces/dppdppd-rpm/.codex}/skills/session-end/scripts/scan.sh"`

Interpret the sections exactly as `skills/session-end/SKILL.md`
Phase 1a describes — the interpretation rules are identical.

### Phase 2: Assemble findings

From the scan output, collect actionable items into a findings list:

- `git` — only flag if the user seems unaware of uncommitted work
- `agent_instructions` — flag if `status=warn` or `status=critical`
  (fall back to legacy `claude_md` only if `agent_instructions` is
  absent from older scan output)
- `not_implemented` — flag only real source stubs, suppress meta
- `broken_refs` — always flag if `count > 0`
- `daily_log` — flag if `today_exists=false` AND `commits_since > 0`
- `session_marker` — informational, not a finding
- `specs_inventory` — flag if `unlisted > 0`
- `pm_docs_staleness` — flag if any `days > 3`
- `migration` — if `count > 0`, auto-migrate before presenting
  findings: `mkdir -p` target dirs, `mv` each `move=old→new` pair,
  `git add` both old and new paths. This is safe and non-destructive
  (git tracks the rename). Print a brief summary of what was moved.

### Phase 3: Present findings menu

Present via the **Shared Findings Menu** format described in
[findings-menu.md](findings-menu.md). Read that file for the exact
format, reply grammar, and execute flow.

Score each finding with `severity (0-40) + evidence (0-30) +
fix clarity (0-30)`. For scan.sh findings, evidence is generally
"single clear source" (20) since the scan is mechanical.

If no findings, print:

```
## /audit quick — no drift detected
```

and stop. Do NOT append to `past/log.md` for clean runs — quick mode
is meant to be cheap and invisible when nothing's wrong.

### Phase 4: Log results (only if findings were present)

Append a one-line run marker to `docs/rpm/past/log.md` Audit History:
`- YYYY-MM-DD — audit quick — N findings, M fixed, K skipped`

No findings detail beneath — keep quick mode's log footprint
minimal. If the user wants detail, they can re-run or upgrade to
`/audit documents`.

---

## Target: Documents

Scan docs, agent instructions, memory files, trackers, and recent
session logs for drift. Runs via the `rpm:auditor` review agent when
the current runtime can dispatch one. Scored, confidence-gated,
codifies repeat offenders.

### Phase 1: Dispatch (review agent)

Launch the `rpm:auditor` review agent using the current runtime's
agent mechanism. In Claude Code, use the `Agent` tool with
`subagent_type: "rpm:auditor"` and `run_in_background: true`, then
return immediately. In runtimes without a compatible background-agent
notification path, run the same auditor protocol synchronously in the
main session. The scan spec lives in `agents/auditor.md` (or the
Codex reference copy) — do not duplicate it here.

In the same response, surface a one-line dispatch confirmation to
the user (`audit: dispatched rpm:auditor in background — results
will appear when ready`) and stop. Do NOT invent findings or guess
at outcomes.

When the runtime reports the agent result, re-enter the skill at
Phase 2 with the report content. For Claude Code task notifications,
read the output via the file referenced in the `<output-file>` tag.

### Phase 2: Score findings, present menu

When the agent completes, score each finding:

**Confidence = severity (0-40) + evidence strength (0-30) + fix clarity (0-30)**

- Severity: Critical=40, High=30, Medium=20, Low=10
- Evidence: multiple sources=30, single clear source=20, inferred=10
- Fix clarity: exact steps known=30, direction clear=20, needs investigation=10

**Only present findings scoring ≥ 60.** Below that, log to past/log.md
but don't bother the user.

Present findings (sorted by score, highest first) using the **Shared
Findings Menu** format described in
[findings-menu.md](findings-menu.md). Read that file for the exact
format, reply grammar, and execute flow.

Below the menu, note any low-confidence findings that were
suppressed: `(N low-confidence findings logged but not shown)`.

### Phase 3: Post-execute — codify repeat findings

After the menu's Execute step completes, for each ✓ fix, scan
`docs/rpm/past/log.md` Audit History for thematically-similar prior
findings. If this drift has appeared **2+ times across audits**, the
mechanical fix isn't enough — propose a structural follow-up so it
stops recurring.

Pick the intervention by finding type — not always a hook. Often
the right answer is just guidance:

| Finding type | Intervention |
|---|---|
| Hard rule, tool-enforceable (editing wrong file, skipping a flow) | Runtime hook/rule file where supported; Claude Code uses PreToolUse hook -> `.claude/hookify.{name}.local.md` |
| Detection-side gap (scan.sh missed a category, recurring scan blind spot) | Edit `plugin/skills/session-end/scripts/scan.sh` |
| LLM behavior pattern (wrong command name, missed convention, repeated word choice) | New `feedback_*.md` memory rule or one-line addition to the active agent instructions file |
| Skill output drift (session-end / audit / etc. keeps producing wrong format) | Edit the relevant skill body |
| Doc/tracker rot (status.md keeps going stale, log gaps) | Add a check to scan.sh, or codify the update in the originating skill |

Propose **one** concrete intervention per repeat finding — name the
exact file you'd create or edit and what the change is. Wait for
confirmation before applying.

**Hookify rule format** (only for the PreToolUse-hook case):

```markdown
---
name: {descriptive-name}
enabled: true
hook_type: PreToolUse
matcher: "{tool pattern}"
---

{What this rule enforces and why}

## Conditions
- {condition}: {pattern}

## Action
deny with message: "{explanation}"
```

For non-hook interventions, edit the target file directly — no
hookify file is created.

### Phase 4: Log results

After the Execute step (or a cancelled run):

- Append a one-line run marker to `docs/rpm/past/log.md` Audit History:
  `- YYYY-MM-DD — audit documents — N findings, M fixed, K skipped`
  (cancelled runs: `N findings, cancelled`)
- Append findings detail below the marker
- Add one-liner to `docs/rpm/context.md` Prior Findings table
- Update Sessions Reviewed table if session drift was checked

---

## Target: Project

Full consultant review with external research. You are NOT an expert
in this project's domain — investigate before judging.

**The full 5-phase protocol is in [project-mode.md](project-mode.md).**
Read it in full and follow it end-to-end. It contains:

- Phase 1: Investigate (including background `rpm:auditor` scan for
  Phase 4 evidence)
- Phase 2: Inward Research (validate against authoritative sources)
- Phase 3: Outward Research (competitive analysis — REQUIRED)
- Phase 4: Analyze across 7 dimensions
- Phase 5: Ask questions and refine
- Deliverables (executive summary + `docs/rpm/past/log.md` entry +
  `docs/rpm/reviews/YYYY-MM-DD-plan.md` + `docs/rpm/reviews/YYYY-MM-DD.md`)

Do not skip phases. Outward research is **required**, not optional —
without it you over-index on "does the project match its own spec?"
and miss whether the spec itself is best-in-class.
