# Tier 4 — CC-only Workflow fast path for /audit project mode (spike)

Source: 2026-05-30 rpm-vs-ultracode-mode evaluation.
**Deferred — do after Tier 1–3 land.**

## Context
`/audit` project mode is multi-dimension and maps cleanly onto the
Workflow "review" pattern: fan-out dimensions → adversarially verify each
finding → synthesize → dedupe. It is lower-stakes than deep-research (no
untrusted-fetch injection surface; internal docs only). Today it uses a
single `rpm:auditor` agent — no fan-out.

## Action steps (spike)
1. Prototype a Workflow script: parallel dimension-scanners (schema'd
   findings) → adversarial verify each finding → synthesize → dedupe.
2. Gate behind CC + Workflow availability; the single-`auditor` prose path
   stays the portable fallback (opencode/codex).
3. Compare findings quality + token cost vs the current single-auditor run.

## Constraints
- CC-only fast path, never the foundation. Portable fallback required.
- Don't regress the auditor's read-only / no-edit contract.

Estimate: 1–2 hr spike. Status: deferred.

---

## Worker Result (2026-05-31)

**Summary.** Spike executed — built the fan-out prototype and ran a live
documents-mode bake-off (Arm A fan-out vs Arm B single auditor). **Verdict: do
NOT adopt fan-out as the /audit default.** Fan-out cost **9.3× the tokens**
(584,064 vs 62,635; 23 agents vs 1) and found **14 findings vs 7 — MORE, not
fewer.** It still doesn't win: it MISSED Arm B's highest-confidence finding
(CLAUDE.md hook-list omission, conf 85) and both guidance-alignment findings —
holistic cross-file checks no single dimension scanner owns. Its 2× extra
findings are mostly low-severity MECHANICAL staleness (stale version strings,
test counts, dates) that `scan.sh` could catch at ~0 tokens — so the 9.3×
premium buys the wrong class of finding. Consistent with the Tier-3
deep-research bake-off and the /next concurrency audit.

**Files changed.**
- `docs/rpm/research/audit-fastpath/audit-workflow.js` (new; moved out of
  `plugin/` at session-end so the non-wired spike doesn't ship) — prototype,
  kept as a reference artifact; NOT referenced from SKILL.md, no regression to
  the portable single-auditor path or its read-only contract.
- `docs/rpm/research/audit-fastpath/bakeoff.md` (new) — full head-to-head,
  metrics, overlap analysis, verdict.
- `docs/rpm/research/audit-fastpath/scan-seed.txt` (new) — shared seed.

**Verification run.** Both arms live, same seed/target, read-only rpm:auditor
(sonnet). Arm B: 1 agent / 62,635 tok / 358s / 7 findings. Arm A: 23 agents /
584,064 tok / 419s / raw17→verified14→deduped14 / killRate 0.18 / 14 findings.
All measured from task-completion notifications. Full analysis +
coverage/overlap breakdown: `docs/rpm/research/audit-fastpath/bakeoff.md`.

**Remaining risks / follow-ups.**
- Repo had real drift (14 verified findings), so the quality signal was stronger
  than feared. A re-test on a HEAVILY-drifted tree could still revisit whether
  fan-out's throughput ever pays off — prototype preserved for that.
- **File to backlog:** add mechanical `scan.sh` checks for the literal-drift
  class fan-out uniquely caught (version strings in README/examples, status.md
  test count, agent-file enumeration in context.md/CLAUDE.md) — most of
  fan-out's unique value at ~0 tokens.
- Both auditors independently flagged this session's own untracked artifacts +
  stale TODO state (Tier-3, canary) → reconcile at /session-end.
- The 14 verified findings are real drift — route to /session-end for fixing.
