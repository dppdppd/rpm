# Round-2 tune rpm-research workflow — contested calibration + fetch coverage + cost guard

**Created / done:** 2026-06-08. **Target:** `plugin/skills/research/rpm-research.workflow.js`.

**Why.** The tuned VOC re-grade (`scorecard.md` "Tuned re-run" section; grading
`grading/v2-workflow-tuned-grading.md`, commit `3b2e2fe`) confirmed the round-1 fixes worked on
their target (Sub-Q2b PARTIAL→correct surface-both, fidelity 4→0) but exposed three weaknesses.
This round-2 pass addresses all three. Validated by `node --check` + an extended deterministic
`decide()` unit test (8/8) + bats; **no live re-run** (token budget).

## Fix A — tighten `contested` (was trigger-happy: 3/8 over-hedged)
Round-1 made *any* single `flag` contest a claim, so a lone cautious flag hedged determinable
answers. Now `contested = flags.length >= 2 || flagsWithRival.length >= 1` — a claim is contested
only when **two lenses independently flag** OR **one flag names a concrete rival reading**
(`betterSourceRival`). The lens contract now states a flag with no rival is treated as a KEEP.
Keeps the Sub-Q2b fix (that ambiguity is corroborated and carries a rival) while letting
determinable claims through. Wrong-referent claims (Sub-Q2a) still route via kills, never flags.

## Fix B — fetch coverage (Sub-Q3 was never fetched)
The regressed run made 4 dimensions (not 6) and fetched no van Riebeeck source. Two changes:
- **Scope** now must keep EVERY named-primary-source sub-question as its OWN dimension (never merge
  two, never fold into a broad theme); dimension budget raised 3-6 → 3-8.
- **Fetch** now guarantees each dimension's top-`PER_DIM` (2) URLs are in the fetch set before
  filling the rest to `MAX_FETCH`, so a named primary can't be crowded out by a noisier dimension.

## Fix C — cost guard (a 2.79 MB PDF inflated the run)
The fetch agent must never store a multi-MB artifact: for a PDF it saves a **text rendering capped
at 100 KB** (`pdftotext … | head -c 100000`) as `NN-slug.pdf.txt`, or falls back to the HTML
landing page; no stored artifact over ~150 KB. Downstream verify/synth agents then read a capped
extract, not multi-MB binary.

## Follow-ups not done here
- Cost parity with native still unproven (round-1 cap dropped verifiers 120→48 but tokens only
  ~28%, muddied by the PDF). Re-measure on a future live re-run when budget allows.
- Scope determinism (4-vs-6 dimensions across runs) is mitigated by Fix B's "own-dimension" rule
  but not eliminated; watch on the next re-run.
