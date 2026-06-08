# Tune rpm-research workflow from the VOC bake-off

**Created:** 2026-06-08. **Target:** `plugin/skills/research/rpm-research.workflow.js`.

**Why now.** The 2026-06-08 v2-Workflow arm of the VOC triplet bake-off scored near-native
Dutch-primary fidelity (Q1/Q2a/Q3 CORRECT, Q2b PARTIAL) and fully fixed the old-v2 "Captain
Vogel" fabrication — but it cost ~5.4M tokens (≈2.3× native) and over-asserted the one
genuinely-ambiguous claim. Both are tunable defects in the script, not in the approach.

**Evidence.** `docs/rpm/research/dr-bakeoff/runs/2026-06-07-triplet/scorecard.md` (four-column
verdict) + `grading/v2-workflow-grading.md` (blind grade).

## Fix 1 — rein in verification fan-out cost
`maxVerify=30` × 4 lenses spawned **120 verifier agents → ~5.4M tokens / ~66 min**, heavier than
native's 103-agent / 2.32M run, on a 6-dimension probe. The independence that makes the panel
collapse-proof is exactly what makes it expensive, so the default must be cost-aware.

- Lower the default `MAX_VERIFY` (try 8–12), and/or cap on total *verifier agents* rather than
  *claims* (claims × 4 lenses is the real blow-up), and/or gate on `budget` when a target is set.
- Keep the logged-drop behavior (no silent truncation — the "no silent caps" rule).
- Re-measure on a re-run; target cost ≤ native on a comparable probe while holding fidelity.

## Fix 2 — let a `flag` verdict suppress kill-and-replace on ambiguous claims
On Sub-Q2b the panel killed the editorial "(red.: …overleden)" gloss and asserted the literal
"captives/deported" reading at **HIGH**, where native surfaced both readings and declined — the
better epistemic call on a by-design-ambiguous span. kill-and-replace's bias toward adopting the
rival caused over-delivery (PARTIAL instead of CORRECT).

- In `decide()` / synthesis: when a claim is genuinely contested (a lens returns `flag`, or votes
  split without a clear better-sourced rival), do NOT replace-and-assert at HIGH — surface both
  readings and decline, like native. A `flag` should outrank a lone rival on ambiguous claims.
- Add the "surface-both, don't over-assert on ambiguity" rule to the synthesis prompt's
  kill-and-replace section.

## Scope / estimate
Single-file edit to `rpm-research.workflow.js` + a smoke re-run to confirm. ~1 session. Validate
with a small re-run at the lower `maxVerify` and, ideally, a cheap re-grade of the Q2b handling to
confirm it now surfaces-both. CC-only; opencode/codex fall back to prose and are unaffected.
