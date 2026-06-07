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
| Sub-Q1 — octrooi 17-seat rule | **CORRECT** (Amsterdam-17th trap avoided) | **CORRECT** (avoided) | _pending_ |
| Sub-Q2a — Banda casualties / officer | **CORRECT** (9 dead/35 wnd/De Ros) | **WRONG** (1 killed; officer "Vogel" **fabricated**) | _pending_ |
| Sub-Q2b — the "1,200" referent | literal "taken" @HIGH, **surfaced** the "died" reading @MED | "captured/deported"; **claimed trap-avoided**, ambiguity not surfaced | _pending_ |
| Sub-Q3 — van Riebeeck heading | **CORRECT** (governor / from-Amsterdam traps avoided) | **CORRECT** (avoided) | _pending_ |
| Unsupported-claim rate (primary, sampled) | 0/10 | 0/10 | _pending_ |
| Translation-fidelity errors | 1 (Q2b — contestable) | 2–4 (Q2a wrong-referent + fabricated officer) | _pending_ |
| Figure orphans | 0 | 0 self-reported — **FALSE** (Q2 wrong-referent cluster) | _pending_ |
| Over-kill (true claims wrongly dropped) | N/A (build-up report) | 0 | _pending_ |
| Live-URL rate | 10/10 | 12/12 | _pending_ |
| Load-bearing claims / citations | ~24 / 9 | ~23 / 10 | _pending_ |
| Cost (subagent tokens) | ~98k | ~115k | _pending_ |

## Primary verdict (v1 vs v2 — native still pending)
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
