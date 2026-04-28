# DRB2 baseline — findings

**Skill version:** rpm deep-research v2.10.0
**Tasks scored:** 1 of 132 (`task8` — Materials Inverse Design Technology and Databases)
**Date:** 2026-04-28

## Score

| Dimension | Strict | Lenient | DRB2 SOTA reference |
|---|---|---|---|
| info_recall (37) | 51.4% | 70.3% | — |
| analysis (12) | 91.7% | 91.7% | — |
| presentation (3) | 100% | 100% | — |
| **Aggregate (52)** | **63.5%** | **76.9%** | <50% per DRB2 paper |

Single-task baseline; **not** representative of full-benchmark performance.

## Cost

| Metric | Value |
|---|---|
| Total tokens | 29,348 |
| Wall-clock | 180.8 s |
| Tool uses | 17 (12 + 4 parallel WebSearches + final response) |
| Run shape | SURVEY (W&D parallel batches) |

## What the baseline reveals

**Strong points:**
- **Analysis (91.7%)** is the high-scoring dimension. The skill captures the conceptual framing (forward vs inverse design distinction, principles of each method family, role of each algorithm) reliably.
- **Presentation (100%)** is trivially passed — the agent followed the prompt's required structure. Confirms the report-template guidance in Phase 5b is effective.
- **SURVEY mode worked as intended** — 12 parallel WebSearches in one message + 4 in Round 2, no sequential fallback. Confirms v2.9.0 wiring on a fresh task.
- **Source-grounded confidence tags** — every load-bearing claim in the report carried `**Confidence: H/M** (source: URL)`, confirming v2.8.0 wiring.

**Weak points:**
- **Info-recall (51.4% strict)** is the dominant gap, driven by:
  1. **Database identity drift** (5 of 21 database rubrics fail or partial). The skill found 5 of 7 expected databases plus 3 different popular ones (AFLOW, Materials Cloud, JARVIS). Missed the niche/regional ones the rubric expected (DDSE — Dynamic database of solid-state electrolyte; ASM Alloy Center). DRB2's reference report apparently weighted regional/specialized DBs that broad-spectrum web search doesn't surface.
  2. **URL-form mismatch** (4 URL rubrics fail strict / pass lenient). Report has parent domains where rubric expects specific paths or vendor subdomains (e.g., `icsd.nist.gov` vs `icsd.products.fiz-karlsruhe.de`; `materialsproject.org` vs `next-gen.materialsproject.org`). Lenient scoring recovers these.
  3. **Algorithm-classification mismatch** (1 rubric). PSO landed in Optimization-based (where most literature places it) but rubric expected it in Exploration-based.
  4. **Missing specific algorithm names** (Topology Optimization, Forward/Inverse Model Integration, Neural Networks as a standalone family).

## What this baseline does NOT measure

This was an **abridged** skill run. Phases skipped:
- Phase 3 — URL fetching of primary sources (would have improved description-matching and possibly surfaced the missing databases)
- Phase 4 — gap analysis + adversarial validation (would have caught the PSO classification mismatch and the missing algorithm names)
- Phase 5b — inline verification (no fetched/ artifacts to verify against)
- Phase 5c Layer 2 — citation-audit sub-agent

A full-protocol run would presumably add ~30–60k tokens and 100–300s, and likely close some of the info-recall gap. **An honest delta measurement requires running both abridged and full and comparing.**

Other unmeasured factors:
- **n=1**. Single task. One easy task in English (Materials Science). Different domains and the Chinese tasks (66 of 132 are Chinese) may score very differently.
- **No grader LLM**. Scoring done by the orchestrator looking at the rubrics one at a time. DRB2's published methodology uses a separate LLM judge with a calibrated prompt; manual scoring may be more lenient or more strict in different ways.
- **Cherry-picked task**. task8 was chosen for compact prompt + clear SURVEY shape. Tasks with sprawling prompts or DEEP-DIVE shape might score differently.

## Recommendations from this single-task baseline

1. **Phase 4 gap-analysis should include domain-coverage check.** When researching "the most commonly used X databases", at least one search should target *region-specific* and *specialty* X databases, not just the globally popular ones. Generic web search systematically over-weights popular sources.
2. **Phase 5b should require resolving cited URLs to canonical product pages.** Several DRB2 rubrics distinguish parent-domain vs specific-product URL. The current URL-liveness check accepts any 2xx; consider adding a "canonical landing page" check for documentation/database citations.
3. **Algorithm classification matters.** When the user's prompt enumerates a categorization (here: exploration / model / optimization), the skill should anchor on the user's framing rather than on whichever literature convention is most popular for each algorithm.

## To extend this baseline

Files left ready for additional task runs:
- `research/drb2-baseline/tasks/` — ready to receive more `taskN.json` extracts
- `research/drb2-baseline/runs/` — agent reports, one per task
- `research/drb2-baseline/scoring/` — rubric-by-rubric scoring tables
- `research/drb2-baseline/findings/` — this aggregated file

To add another task: download `tasks_and_rubrics.jsonl` from
github.com/imlrz/DeepResearch-Bench-II, extract the chosen task into
`tasks/`, launch a sonnet sub-agent with the task's prompt + this run's
prompt template, then score by re-reading the report against the
`content.rubric` arrays.
