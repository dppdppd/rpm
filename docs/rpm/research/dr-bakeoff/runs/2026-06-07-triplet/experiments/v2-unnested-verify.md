# Experiment — v2 verification panel run UN-NESTED (independent fan-out) on Sub-Q2

**Date:** 2026-06-07. **Question it answers:** the original bake-off ran the v2 arm *as a single
background subagent*. A subagent has no `Agent`/`Task` tool (verified by probe), so v2's Phase-4
"perspective-diverse panel" could not dispatch its per-lens verifier agents — it collapsed into one
context narrating its own lenses and rubber-stamped an off-corpus fabrication at HIGH confidence.
**Did the panel fail because the prose is broken, or only because fan-out collapsed?**

## Design (isolates one variable)
Took v2's **actual** Sub-Q2 claims and the **actual off-corpus citation** it used (Colenbrander,
*Coen, Bescheiden* I, archive.org djvu — NOT the named NA 1.04.02 inv. 1073). Ran v2's four
Phase-4 lenses as **independent agents**, one per lens, each in a clean context, default-to-kill,
allowed to research live. **Ground truth was withheld** — agents got only the question, v2's
answer, and v2's citation. Then applied v2's OR-kill rule. Same claims, same protocol; only
difference vs the bake-off = independent agents instead of collapsed self-talk.

## Result — the independent panel KILLS everything the collapsed run certified

| v2 Sub-Q2 claim | Provenance | Cross-source | Referent | Corroboration | OR-kill verdict | Collapsed run |
|---|---|---|---|---|---|---|
| 2a casualties (~1 dead / 4–5 wnd, hill engagement) | KILL | KILL | KILL | KILL | **KILLED (4/4)** | kept @HIGH |
| 2a officer ("Vogel" / no officer lost) | KEEP\* | KILL | KILL | KILL | **KILLED (3/4)** | kept @HIGH (fabrication) |
| 2b "1,200 = captured/deported" | KEEP\* | KILL | KEEP | KILL | **KILLED / contested (2/2)** | kept @HIGH ("trap avoided") |

\* the **provenance lens is circular** — it checks only "is this literally present in the source I
cited," so it KEEPs the fabricated officer and the captured-referent. Diversity + OR-kill is what
overrides it. That diversity only exists when the lenses are **independent agents**.

(2b is genuinely ambiguous by source — the held-out key says do not hard-fail either reading. The
panel splitting 2/2 → "contested, not assertable at HIGH" is the *correct* handling; v2-collapsed
asserted it at HIGH and claimed it avoided the trap.)

## Two sharp secondary findings
1. **De Ros was inside v2's OWN cited source.** The referent lens, reading the *same* archive.org
   Colenbrander djvu v2 cited, found the 6 May 1621 dispatch's hill-engagement loss line —
   *"9 dooden ... daeronder cappiteyn de Ros met sijn vendrich"* (≈ line 31764) — within the very
   document v2 quoted. v2 missed it by cherry-picking the Vogel/Lontor passage. So 2a-officer was
   not even a pure off-corpus error: a careful full read of the cited window catches it.
2. **The SIMPLE path would still fail.** v2's SIMPLE strategy = a single skeptical pass that
   "walks the kill-list" — effectively the provenance lens alone. Provenance KEEPs both the
   fabricated officer and the captured-referent. Only the multi-lens COMPLEX panel kills them. So
   the fix is not just "fan out" — it's "run the *diverse multi-lens* panel, independently, for
   load-bearing primary-source claims."

## Conclusion
**The v2 "regression" was the collapse of fan-out, not broken lens prose.** When v2's panel runs
as independent agents it kills exactly the claims the collapsed run certified — converting a
confident Frankenstein into a correct refusal / contested flag. Implications:

- The bake-off **under-measured v2**: it ran v2 in the one mode that disables its central control.
  v2-with-real-fan-out would not have delivered the HIGH-confidence fabrication.
- **But killing ≠ correcting.** The panel removes the wrong answer; v2's protocol then sends killed
  claims to "could not verify." The corroboration lens *did* independently surface the right answer
  (NA bronnenbox: 9 dead / 35 wounded / Capt. De Ros; ~1,200 glossed as died). To deliver the
  correct answer rather than a hole, v2's synthesis must **adopt the better-sourced rival the
  corroboration lens finds**, not merely kill the wrong one. Native did this; v2 does not yet.

## Candidate v2 fixes (revised priority, from this experiment)
1. **Never run the panel collapsed.** Detect when `research` is executing without the ability to
   fan out (nested as a subagent / no `Agent` tool) and either refuse HIGH confidence on
   primary-source claims (label "single-context — unverified") or hand off. The panel is the
   load-bearing control; it must be independent to function.
2. **Make the diverse multi-lens panel non-optional** for load-bearing primary-source claims (not
   only COMPLEX runs) — a single provenance-style skeptic passes the fabrication.
3. **Kill-and-replace, not just kill.** When the cross-source / corroboration lens surfaces a
   better-sourced rival reading, synthesis adopts it instead of leaving a "could not verify" hole.
4. **(Secondary)** source-authority binding (cite the named inv./archive, flag substitutes) +
   "read the full cited window, not a cherry-picked line" — would catch De Ros even in degraded
   single-source mode.

## Cost
4 verifier agents · ~158k subagent tokens total · ~3.5 min wall-clock. (vs the full native arm's
~2.32M / 103 agents — the targeted re-verification is ~15× cheaper and decisive on the crux.)
