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
| Metric | v1 (pre-harden `24d8ab0`) | v2 (hardened HEAD) | native | v2-Workflow (CC, HEAD) |
|---|---|---|---|---|
| Sub-Q1 — octrooi 17-seat rule | **CORRECT** (Amsterdam-17th trap avoided) | **CORRECT** (avoided) | **CORRECT** (avoided) | **CORRECT** ("by beurten" verbatim; Amsterdam denied majority; flagged Valentyn 18th-c. provenance) |
| Sub-Q2a — Banda casualties / officer | **CORRECT** (9 dead/35 wnd/De Ros) | **WRONG** (1 killed; officer "Vogel" **fabricated**) | **CORRECT** (9 dead/35 wnd/De Ros + standard-bearer; no fabrication) | **CORRECT** (9 dead/35 wnd/De Ros + standard-bearer; **no fabrication**) |
| Sub-Q2b — the "1,200" referent | literal "taken" @HIGH, **surfaced** the "died" reading @MED | "captured/deported"; **claimed trap-avoided**, ambiguity not surfaced | **UNRESOLVED by design** — surfaced both readings, refused to assert (only arm delivering no wrong referent) | **PARTIAL** — asserted "captives/deported" @HIGH (grounded in corpus, not fabricated) + killed the editorial "died" gloss; over-committed where native declined |
| Sub-Q3 — van Riebeeck heading | **CORRECT** (governor / from-Amsterdam traps avoided) | **CORRECT** (avoided) | **CORRECT** (both traps avoided; "from Amsterdam" refuted 0-3) | **CORRECT** (Texel port / Amsterdam chamber split; never "governor"; caught the question's own inv.1188 pin conflict) |
| Unsupported-claim rate (primary, sampled) | 0/10 | 0/10 | 0/10 | 0/10 |
| Translation-fidelity errors | 1 (Q2b — contestable) | 2–4 (Q2a wrong-referent + fabricated officer) | **0** | **0 hard** (1 Q2b over-assertion) |
| Figure orphans | 0 | 0 self-reported — **FALSE** (Q2 wrong-referent cluster) | 0 (every number anchored to a quoted/cited source) | 0 |
| Over-kill (true claims wrongly dropped) | N/A (build-up report) | 0 | 0 (both kills removed non-true claims: "1,200 died" + "from Amsterdam") | 0 (replace-integrity clean; replaced rivals R-1/R-2 verified correct) |
| Live-URL rate | 10/10 | 12/12 | 17/18 (94%; one ANRI 403, self-disclosed) | 15/16 (94%) |
| Load-bearing claims / citations | ~24 / 9 | ~23 / 10 | ~21 / 21 | ~30 / 30 |
| Cost (subagent tokens) | ~98k | ~115k | **~2.32M** (103 agents, 757 tool-uses, ~27 min) | **~5.4M** (128 agents, 2317 tool-uses, ~66 min; `maxVerify=30` → 120 verifiers) |

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

## Four-column verdict (v2-Workflow added 2026-06-08)
**The collapse-proof Workflow closes almost the whole fidelity gap with native and fully fixes the
old-v2 regression — but it cost 2.3× *more* than native, not less.** Run on Claude Code as a real
Workflow (independent per-lens panel, not a collapsed subagent), v2-Workflow scored **CORRECT on
Q1, Q2a, Q3** and **PARTIAL on Q2b** — re-finding the same authoritative primaries native used
(NL-Wikisource octrooi, the Nationaal Archief Banda *hertaling*, the DBNL Daghregister) and quoting
every crux Dutch span verbatim-faithfully (graded blind; `grading/v2-workflow-grading.md`).

**The old-v2 failure is gone.** Where collapsed-v2 fabricated "Captain Vogel" and certified
wrong-referent figures at HIGH, v2-Workflow named **De Ros + standard-bearer, 9 dead / 35 wounded**
— exactly right, no fabrication, 0 hard fidelity errors. This confirms the un-nested experiment's
diagnosis: v2's "regression" was fan-out collapse, and structural independence removes it.

**It answers the experiment's open question — killing ≠ correcting — in the Workflow's favor.** The
panel did not merely *refuse* wrong claims; **kill-and-replace let it positively deliver the right
ones**: it adopted better-sourced rivals (R-1 "by beurten" over the Valentyn mis-quote; R-2
autumn-vs-spring meeting function; R-5 killed an issuer-wrong, intent-inverted Macassar "support"
claim and replaced the framing). 14 of 30 load-bearing claims were killed/replaced, replace-integrity
clean. That delivery — not just refusal — is what lifts it from old-v2 to near-native.

**Where it still trails native: Q2b, and the cause is instructive.** kill-and-replace's bias toward
*adopting the rival* made it **over-commit on a genuinely ambiguous span** — it killed the editorial
"(red.: …overleden)" gloss and asserted the literal "captives/deported" reading at HIGH, where
native surfaced both readings and declined. The rival is grounded in real corpus text (not a
fabrication, no side-swap onto the Dutch force), so it is PARTIAL not WRONG — but native's epistemic
refusal is the better call on a by-design-ambiguous claim. **The same mechanism that fixes
under-delivery can cause over-delivery on ambiguity.**

**Cost is the real trade-off, and it inverted the pre-run guess.** `maxVerify=30` × 4 lenses spawned
**120 verifier agents → ~5.4M tokens / ~66 min**, *heavier* than native's 103-agent / 2.32M run. The
very independence that makes the panel collapse-proof is what makes it expensive; collapse-proof is
**not** cheap. The cost is tunable (lower `maxVerify`, or scale it to dimension count), but at the
shipped default the win is **fidelity at parity with native + the old-v2 fix at ~47× old-v2's cost**,
not a cost saving over native.

**Tuning implications (next):** (1) lower the `maxVerify` default or scale it to dimension/claim
count — 120 verifiers for a 6-dimension probe overshot; (2) let a genuinely-ambiguous result (a
`flag` verdict) suppress kill-and-replace so synthesis surfaces-both like native instead of
over-asserting (the Q2b fix). n=1 probe, one topic — directional, not precise.
