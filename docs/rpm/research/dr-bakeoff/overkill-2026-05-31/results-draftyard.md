# Over-kill replication #2 — draftyard `competitive-polish-gap-audit` (2026-05-31)

n=1 was voc-decline (quantitative history, **tertiary** sources). This is a different
domain (software-UX) with **primary** sources (VS Code / Zed / Obsidian official docs,
W3C WCAG, Nielsen Norman Group) — the condition under which a clean over-kill canary
*could* appear (provenance won't auto-kill a primary-sourced true claim). Answer key
built by a blind builder agent + spot-checked by the orchestrator (C1 "last resort"
verbatim at notifications:761; C7 error-recovery ranked #9/10 in ten-heuristics:850,1067).

## Claim set & truth
TRUE (SUPPORTED-PRIMARY): C1 VS Code progress-notification "last resort"; C2 VS Code
explicit-save + Hot Exit; C3 NN/g 0.1/1/10 s limits; C4 Obsidian `.canvas` JSON +
Zoom-to-fit; C5 Obsidian local-graph depth; C6 Obsidian auto-update links on rename.
FALSE: C7 "NN/g ranks error recovery near the top" (over-reach — it's #9/10); C8 "VS Code
views guidelines document inline rename/create + reveal-in-tree" (referent-stretch — those
are Zed's project-panel, absent from the VS Code views doc).

## Verdict matrix (5 blind lenses)

| Claim | TRUTH | Prov | Consist | Method | Recency | AltHyp |
|-------|-------|------|---------|--------|---------|--------|
| C1 | TRUE | KEEP | KEEP | KEEP | KEEP | KEEP |
| C2 | TRUE | KEEP | KEEP | KEEP | KEEP | KEEP |
| C3 | TRUE | KEEP | KEEP | KEEP | KEEP | KEEP |
| C4 | TRUE | KEEP | KEEP | KEEP | KEEP | KEEP |
| C5 | TRUE | KEEP | KEEP | KEEP | KEEP | KEEP |
| C6 | TRUE | KEEP | KEEP | KEEP | KEEP | KEEP |
| C7 | FALSE | FLAG | **KILL** | **KILL** | **KILL** | **KILL** |
| C8 | FALSE | **KILL** | KEEP | **KILL** | FLAG | **KILL** |

over-kill = TRUE {C1–C6} killed.  recall = FALSE {C7,C8} killed.

| Config | over-kill {C1–C6} | recall {C7,C8} |
|--------|-------------------|----------------|
| A single skeptic — best lens (methodology / alt-hyp) | 0/6 | 2/2 |
| A single skeptic — worst lens (provenance / consistency / recency) | 0/6 | **1/2** |
| B diverse panel, OR-kill (#4 AS COMMITTED) | **0/6** | **2/2** |
| C diverse panel, majority-keep | 0/6 | 2/2 |

## What this tree shows

1. **Over-kill is ZERO everywhere — including for provenance.** With primary sources, no
   lens over-kills any true claim. This is the control that confirms the voc-decline
   diagnosis: voc-decline's "over-kill" was a **tertiary-sourcing artifact** (provenance
   killing true-but-tertiary figures per Principle 3), NOT voter correlation. Feed the
   pipeline good sources and the over-kill #4 targets simply does not occur.

2. **No clean over-kill canary appears even here.** I built this tree specifically to give
   a soft lens the chance to over-kill a primary-sourced true claim (the only condition
   where #4's voting rescue helps). It never happened — all 5 lenses KEEP all 6 true
   claims. Across BOTH trees (14 claims, 2 domains): **zero** instances of a soft lens
   over-killing a well-sourced true claim. #4's premise has no supporting case.

3. **The committed OR-kill rule is OPTIMAL here** (0 over-kill, 2/2 recall) — the opposite
   of voc-decline (where provenance-on-tertiary made OR-kill inert/max-over-kill). So
   OR-kill's quality tracks **source tier**, not the rule itself. The fix that makes
   OR-kill safe on weak sources too is the provenance **absent-vs-tertiary split** from the
   n=1 analysis (`results.md`).

4. **Diversity's genuine measured benefit is RECALL on present-but-wrong claims, not
   over-kill.** Methodology and alt-hyp each caught BOTH C7 (ranking over-reach) and C8
   (referent-stretch); provenance/consistency/recency each MISSED one (provenance FLAGs
   C7 — the heuristic is primary-sourced, it just can't judge the ranking; consistency &
   recency miss C8 — absence isn't a contradiction or a temporal regression). So the panel
   lifts recall from **1/2 (worst single lens) → 2/2**. That is a real win — but it is
   #3's metric (catch bad claims), mis-labeled as #4's "over-kill ↓."

## Unified verdict (n=2, two domains)

- **Over-kill is a SOURCE-TIER artifact, not a voter-correlation one.** Perspective-
  diversity (#4) does not reduce a genuine over-kill in either test — because a genuine
  over-kill (soft lens killing a well-sourced true claim) never occurred.
- **#4 DOES have a real, measured benefit: +1 recall on present-but-wrong claims**
  (draftyard), via the methodology + alternative-hypothesis lenses. That is worth keeping —
  under **#3's precision/recall eval**, not the false "over-kill ↓" eval.
- **The actual over-kill lever** (where it bites, on weak sources) is the provenance
  absent-vs-tertiary calibration, which scored 0 over-kill + full recall on voc-decline.

**Recommendation (unchanged from n=1, now corroborated):** do NOT commit #4 as an
"over-kill ↓" change. Re-scope it to "perspective-diverse lenses → recall on
present-but-wrong claims" (validate against #3's metric — draftyard already shows the
gain), and pair it with the provenance absent-vs-tertiary split so OR-kill is safe on weak
sources. Or revert and re-file both as properly-scoped tasks.
