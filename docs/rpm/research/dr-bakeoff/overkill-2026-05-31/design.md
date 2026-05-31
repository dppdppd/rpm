# Over-kill A/B/C measurement — perspective-diverse verification (#4)

**Date:** 2026-05-31. **Purpose:** the promotion gate the user required before committing
`dr-diverse-verify`. MEASURE whether perspective-diverse verification actually lowers
**over-kill** (false-KILL of a TRUE claim) vs a single / correlated skeptic, and under
which keep-rule. Governing principle: a gap is not real until a test exercises it and the
pipeline fails; trust nothing prose merely claims.

This file is **pre-registered** — written before the lens agents run. Results in
`results.md`.

## Corpus (frozen)
`/home/coder/projects/VOC/docs/research/voc-decline-era-1680-1800/fetched/` (14 `*.html.md`).

## Labeled claim set (truth HELD OUT from the lens agents)

| ID | Claim (as a report asserted it) | TRUTH | Why |
|----|----|----|----|
| C1 | VOC total debt at dissolution ≈ ƒ219M | **SUPPORTED** | `14-gutenberg`:120 verbatim "debt of 219 million Dutch guilders" |
| C2 | VOC debt at state takeover (~1796) ≈ ƒ134M | ORPHAN | absent from corpus (model-memory) |
| C3 | VOC book debt ≈ ƒ120M | ORPHAN | absent from corpus |
| C4 | VOC capital drawdown ≈ ƒ20M | ORPHAN/Frankenstein | "20 million" present but referent = Dutch foreign lending / modern population, not VOC capital |
| C5 | ≈ ƒ15M cargo captured, 4th Anglo-Dutch War | **SUPPORTED** | `11-fourth-war`:755 verbatim |
| C6 | 200 VOC merchantmen captured / 300 locked in port, 4th war | **SUPPORTED** | `11-fourth-war`:755 verbatim |
| C7 | ≈ 10,000 ethnic Chinese killed, 1740 Batavia massacre | **SUPPORTED** | `07-massacre`:722 "at least 10,000 … were massacred" |

SUPPORTED = {C1, C5, C6, C7}.  ORPHAN = {C2, C3, C4, C8}.  (C8 below.)

| C8 | VOC war-cost totals ≈ ƒ43M and ƒ62M | ORPHAN | absent from corpus |

## The over-kill traps (TRUE claims a single skeptic can wrongly kill)

- **C7 (primary trap, in-corpus conflict).** `07-massacre`:722 supports "at least 10,000
  massacred" (true). But the SAME source, :737, says "up to 10,000 ethnic Chinese"
  **attacked** the walls and "Raffles wrote that **1,789** Chinese died in this attack."
  And the source is Wikipedia (tertiary). So three single-skeptic kill paths on a true
  claim: (a) referent — 10,000 = attackers, not deaths; (b) consistency — conflicts with
  the 1,789 figure; (c) provenance — tertiary-only (Principle 3). A correctness/“at-least”
  reading of :722 KEEPS it. Genuine decorrelation.
- **C1 (secondary).** True (Gutenberg) but in-report-contested by 134/120 — however those
  rivals are NOT in the corpus, so corpus-grounded lenses likely KEEP it. Weaker trap.
- Note: C5/C6/C7 rest on tertiary (Wikipedia) sources → a Principle-3-strict provenance
  lens may KILL them as tertiary-only even though they are historically true. This is the
  core tension #4 probes: should perspective-diversity soften Principle 3's deliberate
  kill-bias when other lenses confirm correctness?

## Method
5 **blind** lens agents (the 5 committed lenses: provenance/source-tier,
internal-consistency/cross-source, methodology/unit/referent, recency/temporal,
alternative-hypothesis). Each verdicts all 8 claims against the frozen corpus, blind to
truth and to each other. Orchestrator builds the 5×8 verdict matrix and applies three
keep-rules **deterministically** (not delegated):

- **A — single / correlated skeptic:** each lens alone; `over-kill_A` = max over-kill of
  any single lens (identical voters inherit one lens's bias → that lens's verdict).
- **B — diverse panel, OR-kill (AS COMMITTED in the diff):** KILL if ANY lens kills.
- **C — diverse panel, majority-keep + provenance-priority:** KILL only if ≥3 lenses kill;
  a figure confirmed present+correct by the provenance AND methodology lenses is immune to
  soft-lens (consistency/recency/alt-hyp) kills.

## Metrics
- **over-kill** = # SUPPORTED claims (of C1,C5,C6,C7) killed. Lower = better. This IS #4's eval.
- **recall** = # ORPHAN claims (of C2,C3,C4,C8) killed. Must stay = 4 (kill-bias must not soften).

## Pre-registered hypothesis
The lenses decorrelate on the traps: provenance and/or methodology diverge from the soft
lenses on C7 (and maybe C1/C5/C6). Prediction:
`over-kill(A) ≥ 1` and `over-kill(B) ≥ over-kill(A)` (OR-kill can only add kills) and
`over-kill(C) < over-kill(B)` with `recall(C) = 4` preserved.
→ If borne out: **#4 reduces over-kill only under keep-rule C, NOT the committed OR-kill
rule B** — the diff must change its panel rule before commit.
→ If no lens kills any SUPPORTED claim: over-kill is unfalsifiable even with the trap →
**reframe #4** (its real benefit is precision-on-traps, already covered by #3).
