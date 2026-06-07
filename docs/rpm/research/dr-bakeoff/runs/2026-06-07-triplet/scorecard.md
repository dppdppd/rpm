# Triplet bake-off scorecard — v1 │ v2 │ native

**Probe:** VOC expedition goals/issuing-documents 1602–1700 + 3 Dutch-primary-only sub-questions.
**Date:** 2026-06-07. **Design:** all arms answered ONE identical question. v1/v2 ran as
background subagents following their respective `SKILL.md` bodies (v1 = pre-hardening body at
`24d8ab0`; v2 = current hardened `research/SKILL.md` at HEAD). Grading was blind against a
held-out key + the frozen VOC corpus; each grader re-translated the cited Dutch itself, and the
orchestrator spot-checked the crux passages directly.

## Orchestrator-verified ground truth (frozen corpus `nationaalarchief-banda.html`)
- Casualties: *"In deze ontmoeting kregen wij 35 gewonden en 9 doden, waaronder kapitein De Ros
  met zijn vaandeldrager"* → **35 wounded, 9 dead, Capt. De Ros + standard-bearer lost.**
- The 1,200: *"omtrent 1200 zielen gekregen (red.: zijn circa 1200 man overleden)"* → literal
  **"obtained ~1,200 souls" (taken)**; "~1,200 died" is an **editorial (red.) gloss**, not the
  primary text. Genuinely ambiguous-by-source.

## Scorecard
| Metric | v1 (pre-harden `24d8ab0`) | v2 (hardened HEAD) | native |
|---|---|---|---|
| Sub-Q1 — octrooi 17-seat rule | **CORRECT** (Amsterdam-17th trap avoided) | **CORRECT** (avoided) | **CORRECT** (avoided) |
| Sub-Q2a — Banda casualties / officer | **CORRECT** (9 dead/35 wnd/De Ros) | **WRONG** (1 killed; officer "Vogel" **fabricated**) | **CORRECT** (9 dead/35 wnd/De Ros + standard-bearer; no fabrication) |
| Sub-Q2b — the "1,200" referent | literal "taken" @HIGH, **surfaced** the "died" reading @MED | "captured/deported"; **claimed trap-avoided**, ambiguity not surfaced | **UNRESOLVED by design** — surfaced both readings, refused to assert (only arm delivering no wrong referent) |
| Sub-Q3 — van Riebeeck heading | **CORRECT** (governor / from-Amsterdam traps avoided) | **CORRECT** (avoided) | **CORRECT** (both traps avoided; "from Amsterdam" refuted 0-3) |
| Unsupported-claim rate (primary, sampled) | 0/10 | 0/10 | 0/10 |
| Translation-fidelity errors | 1 (Q2b — contestable) | 2–4 (Q2a wrong-referent + fabricated officer) | **0** |
| Figure orphans | 0 | 0 self-reported — **FALSE** (Q2 wrong-referent cluster) | 0 (every number anchored to a quoted/cited source) |
| Over-kill (true claims wrongly dropped) | N/A (build-up report) | 0 | 0 (both kills removed non-true claims: "1,200 died" + "from Amsterdam") |
| Live-URL rate | 10/10 | 12/12 | 17/18 (94%; one ANRI 403, self-disclosed) |
| Load-bearing claims / citations | ~24 / 9 | ~23 / 10 | ~21 / 21 |
| Cost (subagent tokens) | ~98k | ~115k | **~2.32M** (103 agents, 757 tool-uses, ~27 min) |

## Primary verdict (v1 vs v2)
On this single Dutch-primary probe, the **v1→v2 hardening did not improve Dutch-source fidelity,
and showed one false-confidence regression.** Both arms cleanly handled Sub-Q1, Sub-Q3, and the
primary goal/document question, with zero unsupported primary claims. The discriminator was
Sub-Q2: reading the **same** Dutch primary (Colenbrander, *Bescheiden* I), v1 extracted the
corpus-corroborated casualties (9 dead / 35 wounded / De Ros), while v2 extracted wrong figures
and **fabricated an officer ("Captain Vogel")** — and v2's figure-ledger / kill-list certified
those wrong-referent figures as **HIGH-confidence, zero-orphan**, the exact ƒ20M wrong-referent
failure the hardening was built to catch. The kill-list guards against figures absent from *any*
source, not against extraction from the *wrong passage* of a correctly-cited source.

**Caveats:** n=1 probe, one topic. The hardening still added value on dimensions this probe
barely exercised (URL liveness, figure-presence, over-kill avoidance = 0). The Sub-Q2b "trap"
is itself contestable (literal "gekregen/obtained" vs. an editorial "died" gloss), so it is not
scored as a hard fail for either arm; v1 was the more epistemically humble of the two there.
Consistent with the 2026-05-30/31 finding that the hardening's measured benefit is narrow.

## Three-column verdict (native added 2026-06-07)
**On Dutch-source fidelity, native is the strongest arm — but at ~20× the token cost.**
Native scored a clean sweep: **Sub-Q1 CORRECT, Sub-Q2a CORRECT (De Ros + standard-bearer named,
no fabrication), Sub-Q3 CORRECT (both traps avoided), zero translation-fidelity errors, 0/10
unsupported, 0 figure orphans, 0 over-kill.** It is the **only arm that delivered no wrong
answer on Sub-Q2**: where v1 reported the 1,200 as "taken" @HIGH and v2 fabricated Captain Vogel
plus an inverted referent, native got Q2a exactly right and **explicitly left Q2b unresolved**,
surfacing both the "captured" and "died" readings and refusing to assert one — the epistemically
correct call on a genuinely ambiguous source. Its adversarial 3-vote verifier actively *killed*
the two wrong claims (the "1,200 died" reading 1-2, and "departed from Amsterdam" 0-3), the same
two traps that snagged v2 and (partly) v1.

**The cost asymmetry is the headline trade-off.** Native is a 103-agent Workflow that burned
**~2.32M subagent tokens over ~27 minutes** to reach this; v1 and v2 were single background
subagents at **~98k / ~115k tokens**. So native bought the best fidelity at roughly **20× the
cost** of either rpm arm. Native also did NOT route through the frozen corpus — it researched
live from the open web and independently re-found the authoritative Nationaal Archief / DBNL /
Wikisource primaries, which is part of why it avoided v2's off-corpus Frankenstein failure.

**What this says about the hardening (the bake-off's actual question):** the v2 hardening's
kill-list/figure-ledger did not beat v1 on fidelity and regressed on Sub-Q2; native's
*adversarial multi-vote verification* (refute-by-majority) is the mechanism that actually caught
the wrong-referent traps. The lesson is that **independent adversarial verification beats
literal-presence self-certification** for Dutch-primary fidelity — but it is expensive, so it is
worth reserving for high-stakes primary-source claims rather than every run. n=1 probe, one
topic; treat the cost/fidelity ratio as directional, not precise.
