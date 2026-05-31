# Tier 4 spike — /audit fan-out vs single-auditor bake-off (2026-05-31)

Documents mode, same scan seed, same target (/home/coder/projects/rpm).
Both arms read-only `rpm:auditor` (sonnet). All numbers below are MEASURED
(from the task-completion notifications), not estimated.

## Arm B — baseline (single rpm:auditor, today's /audit documents)
- agent id: a9fe319dec119ac7c
- **1 agent, 62,635 tokens, 61 tool_uses, 358s**
- findings: **7** (conf 85/72/70/68/65/60/55)
- ran full protocol: Phase 0 noun cross-check + 3-session drift table (all JUSTIFIED)

## Arm A — fan-out Workflow (audit-workflow.js)
- run id: wf_aeaad7b0-7c4
- **23 agents, 584,064 tokens, 383 tool_uses, 419s**
- counts: raw 17 → verified 14 → deduped 14 (killRate 0.18; 3 killed by adversarial verify)
- findings: **14** (6 medium, 8 low)

## Head-to-head (measured)

| | Arm B (single) | Arm A (fan-out) | ratio |
|---|---|---|---|
| Agents | 1 | 23 | 23× |
| Tokens | 62,635 | 584,064 | **9.3×** |
| Wall-clock | 358s | 419s | 1.2× |
| Findings | 7 | 14 | 2× |
| Tokens / finding | 8,948 | 41,719 | **4.7×** |
| Adversarial verify | none (direct, confidence-scored) | yes (17→14) | — |

## Coverage analysis — NEITHER arm dominates

**Both caught:** context.md 31-day stale (B-F7 = A-M2); two untracked
session deliverables (B-F6 = A-L8); backlog-reconciliation drift (B-F3
Tier-4-TODO ~ A-M6/L7 Tier-3 + canary TODO — same theme, different items).

**Only Arm B (single) caught — HOLISTIC, cross-file:**
- F1 (conf 85, its HIGHEST): CLAUDE.md hook list omits codex-sync-reminder
- F2: tasks.org BLOCKED items lack :BLOCKED_BY:
- F4 + F5: two guidance-alignment PARTIALs (memory feedback_*.md rules not
  fully codified in _directives.sh) — requires comparing memory files
  AGAINST directive files; no single dimension scanner owns this.

**Only Arm A (fan-out) caught — MECHANICAL, literal:**
- M1/M3/M4: agent-surface drift (docs omit guidance-aligner.md + preflight.md)
- M5: SKILL.md says "7-dimension" but project-mode.md defines 8
- L3: README example shows stale `rpm 2.7.4` (vs 2.20.0)
- L4: status.md says 111 bats tests (actual 206)
- L5: status.md v2.19 date mislabel
- L1/L6: log.md May session/audit gap; L2: hooks.json path phrasing

**The tell:** both arms found a "CLAUDE.md architecture list is incomplete"
finding — but DIFFERENT halves. Arm B caught the *hooks* line omission, Arm A
caught the *agents* line omission. Neither caught both. Fan-out grinds each
dimension deeper (more literal staleness); the single agent reasons across the
whole picture (catches holistic gaps fan-out structurally misses).

## Verdict — DO NOT adopt fan-out as the /audit default

1. **Cost:** 9.3× total tokens, 4.7× per finding. Wall-clock barely better
   (1.2×) — parallelism didn't even buy much speed here.
2. **No coverage win:** fan-out found 2× findings but did NOT dominate —
   it MISSED Arm B's single highest-confidence finding (F1@85) and both
   guidance-alignment findings. More findings ≠ better coverage.
3. **Its marginal findings are mostly low-severity + MECHANICAL** (stale
   version strings, test counts, dates, file enumerations) — exactly the
   class detectable by `scan.sh` at ~0 tokens. Paying a 9.3× LLM premium to
   surface mechanically-detectable literals is the wrong trade.
4. Consistent with prior rpm evidence: Tier-3 deep-research bake-off (native
   fan-out 101 agents/2.74M tok, no rigor win) and the /next concurrency
   audit (saturating to 4 → 8.4% hit rate). Same pattern.

## The actually-valuable follow-up (file to backlog)

The high-leverage move is NOT fan-out — it's adding **mechanical scan.sh
checks** for the literal-drift class fan-out uniquely caught: README/example
version strings, status.md test count, agent-file enumeration in
context.md/CLAUDE.md. Captures most of fan-out's unique value at ~0 tokens,
no LLM premium, runs every session.

## Disposition
- `audit-workflow.js` (in this dir; moved here from `plugin/` at session-end so
  the non-wired spike doesn't ship) kept as a reference artifact for a possible
  future re-test on a heavily-drifted tree. NOT referenced from SKILL.md.
  Portable single-auditor path unchanged; read-only contract intact.
- The 14 verified findings are real drift in THIS repo — route to /session-end
  for actual fixing (they are a by-product of the spike, not its deliverable).
