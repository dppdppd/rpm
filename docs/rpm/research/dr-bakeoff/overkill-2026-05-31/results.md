# Over-kill A/B/C measurement — results (2026-05-31)

5 blind lens agents, 8 claims, frozen `voc-decline-era` corpus. Verdict matrix
(KILL / KEEP / FLAG), truth labels from `design.md` held out from the agents.

## Verdict matrix

| Claim | TRUTH | Provenance | Consistency | Methodology | Recency | Alt-Hyp |
|-------|-------|-----------|-------------|-------------|---------|---------|
| C1 ƒ219M debt | TRUE | **KILL** (amateur sole src) | KEEP | KEEP | KEEP | KEEP |
| C2 ƒ134M | ORPHAN | KILL (absent) | KEEP | FLAG | FLAG | FLAG |
| C3 ƒ120M | ORPHAN | KILL (absent) | KEEP | FLAG | FLAG | FLAG |
| C4 ƒ20M | ORPHAN | KILL | KEEP | **KILL** (referent) | KEEP | **KILL** (rival ƒ6.5M cap) |
| C5 ƒ15M cargo | true* | KILL (tertiary) | KEEP | **KILL** (Dutch≠VOC) | KEEP | KEEP |
| C6 200/300 ships | true* | KILL (tertiary) | KEEP | **KILL** (Dutch≠VOC) | KEEP | KEEP |
| C7 10,000 toll | TRUE | **KILL** (tertiary) | KEEP | KEEP | KEEP | KEEP |
| C8 ƒ43/62M | ORPHAN | KILL (absent) | KEEP | FLAG | FLAG | FLAG |

\* C5/C6: the figure is real but the methodology lens shows the source says "Dutch
merchantmen," not the VOC specifically — a referent stretch. Treated as ambiguous,
not a clean over-kill canary. Clean TRUE canaries = {C1, C7}. Clean ORPHANS = {C2,C3,C4,C8}.

## Three keep-rules applied (deterministic)

over-kill = clean TRUE claims {C1,C7} killed.  recall = clean ORPHANS {C2,C3,C4,C8} killed.

| Config | kill set | over-kill {C1,C7} | recall {C2,C3,C4,C8} |
|--------|----------|-------------------|----------------------|
| **A** single provenance skeptic (de-facto pre-#4) | all 8 | **2/2** | 4/4 |
| **B** diverse panel, OR-kill (#4 AS COMMITTED) | all 8 | **2/2** | 4/4 |
| **C** diverse panel, majority (≥3) keep | {C4} | **0/2** | **1/4** |

(A single *consistency/recency/alt-hyp* skeptic instead = 0 over-kill but **0 recall** —
those lenses never kill an absent orphan; only provenance does.)

## What the numbers say

1. **The committed OR-kill rule (B) gives ZERO over-kill reduction and renders the lens
   diversity INERT.** Provenance kills all 8 on its own; the union with the other lenses
   is still all 8. Panel output ≡ provenance-only output. Diversity changes the *reasons
   recorded* (methodology's referent catches on C4/C5/C6) but not a single kill/keep
   outcome. #4-under-OR-kill is behaviorally identical to a provenance-only skeptic here.

2. **Majority-keep (C) "reduces over-kill" only by destroying recall.** It rescues C1/C7
   (over-kill 2→0) but lets the absent orphans C2/C3/C8 survive (recall 4→1), because the
   *only* lens that catches an absent figure is provenance — and voting outvotes it 1-to-4.
   The consistency lens actively votes KEEP on orphans ("nothing to contradict"), diluting
   the one correct killer. Naive voting diversity is recall-toxic.

3. **The over-killing lens is non-redundant.** Provenance is simultaneously the sole
   orphan-catcher AND the sole over-killer. You cannot decorrelate your way out: any rule
   that softens provenance to cut over-kill also blinds the panel to orphans. Perspective-
   diversity (#4) does not separate the good kills from the over-kills — they're one lens.

4. **There is no clean over-kill canary in this corpus.** Every TRUE figure (C1,C5,C6,C7)
   is tertiary/amateur-sourced, so provenance killing it is *Principle-3-correct discipline*
   ("a tertiary reference cannot be sole support for a load-bearing number"), not a clear
   over-kill. A clean over-kill = a *primary-sourced* true claim wrongly killed by a soft
   lens — which does not occur here. So #4's "over-kill ↓" is undemonstrable even WITH the
   trap, for a deeper reason than headroom: the true claims are genuinely under-sourced.

## The actual over-kill lever (constructive)

The over-kill, where it exists, comes from the provenance lens conflating two cases:
ABSENT (orphan → correctly KILL) and PRESENT-but-tertiary-only (true but weakly sourced →
should FLAG/keep-with-caveat, not hard-KILL). Split them:

- Provenance KILL only if ABSENT; FLAG if present-but-tertiary →
  over-kill {C1,C7} = **0**, recall {C2,C3,C4,C8} = **4/4** (C2/C3/C8 absent→kill,
  C4 referent→kill via methodology). **Both objectives met** — which neither OR-kill nor
  majority-voting #4 achieves.

That is a **provenance / Principle-3 calibration** fix, orthogonal to lens diversity.

## Verdict on #4 (dr-diverse-verify)

Pre-registered prediction was over-kill(C) < over-kill(B) *with recall preserved*. The
over-kill direction held but **recall preservation FAILED** — the decisive caveat. Net,
three measured strikes against #4-as-committed:
- (B) OR-kill: inert, no over-kill benefit.
- (C) voting: over-kill↓ only by wrecking recall.
- no clean over-kill canary exists here, so the eval is undemonstrable on this corpus.

**Recommendation: do NOT commit #4 as written.** Its genuine value (methodology lens
catching the C4 referent and the C5/C6 VOC-vs-Dutch stretch) is a *precision* gain — #3's
metric, not over-kill — and is partly already covered by the shipped number-provenance
gate. The real over-kill lever is the provenance/Principle-3 absent-vs-tertiary split above.

Side-finding worth noting: the provenance lens calls ƒ219M (C1) *amateur-sourced* (Reynders
/ Project Gutenberg Australia) and KILLs it — stricter than the dr-verification-hardening
replay, which shipped ƒ219M as "specialist-sourced." The two disagree on that source's tier.
