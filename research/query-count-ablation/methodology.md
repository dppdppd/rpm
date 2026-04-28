# Query-count ablation — methodology + status

**Date:** 2026-04-28
**Status:** **scaffolded, not run.** The reflection-driven Grader check (v2.8.0) side-steps the question this ablation was originally meant to answer. Documentation only — no experiment executed.

---

## The original question

From `research/llm-deep-research-best-practices/gaps/01-query-count-ablation.md`:

> Is there a rigorous ablation showing how many search queries per dimension yields diminishing returns?

The deep-research literature (SoK Agentic RAG arXiv:2603.07379; LangChain ODR; Perplexity production) does not publish such an ablation as of April 2026. The original "5–6 broad + 4–6 targeted per dimension" heuristic in the rpm skill was practitioner default, not data-driven.

## Why the ablation is now lower-priority

The v2.8.0 update wired a **reflection-driven Grader check** between Round 1 and Round 2 in every agent prompt template:

> PAUSE — GRADER CHECK: Are all sub-questions covered with primary-source evidence already? If yes, halt early — skip Round 2 and emit your report. If no, list the specific gaps Round 2 must close.

This makes the absolute query count adaptive per task. The ablation question — "what is the optimal fixed N?" — assumes a fixed-budget model the skill no longer uses. The empirically-derived saturation point will vary by task complexity, source density, and dimension specificity; the Grader check finds it dynamically each run.

The W&D experiment (v2.9.0) gives circumstantial evidence the adaptive approach works: Variant A (3 sub-agents × ~5 queries each = 15 total) and Variant B (12 parallel + 6 follow-up = 18 total) both halted with comparable findings counts. Neither bottomed out at a fixed budget; both stopped when the Grader said "covered."

## When to actually run the ablation

Re-prioritize only if any of these signals:
1. Multiple full-protocol DRB2 runs show consistent under-coverage on info_recall — suggests the Grader is halting too early.
2. Token cost per task creeps up over time — suggests the Grader isn't halting *enough*.
3. Users report the skill produces thin reports on certain task shapes.

## If we do run it: methodology

**Setup.** Pick 5 DRB2 tasks of varied shape (2 SURVEY, 3 DEEP-DIVE) and varied difficulty.

**Treatment.** For each task, run the skill 5 times with overridden Grader behavior:
- Run-N1: Round 1 only (no Grader, no Round 2)
- Run-N2: Round 1 + 2 forced (no early-halt)
- Run-N3: Round 1 + 2 + 3 forced
- Run-N4: Adaptive (current behavior — Grader decides)
- Run-N5: Round 1 with 2× the queries (12 instead of 5–6) and no Round 2

**Measurement.**
- Token cost per run (sum of `total_tokens` across all sub-agents).
- Wall-clock per run.
- DRB2 rubric satisfaction rate (strict scoring).
- Source breadth (count of unique URLs cited).
- Source quality (% primary vs secondary).

**Hypothesis.** Adaptive (N4) is Pareto-optimal on (cost, rubric satisfaction). N1 saves cost at the price of coverage; N3 spends cost without proportional gain. N5 may match N4 at lower latency.

**Cost estimate.** 5 tasks × 5 runs × ~50k tokens = ~1.25M tokens per ablation pass. Roughly $20–40 worth of agent time. Two ablation passes (one for sonnet, one for haiku as cheap-comparison) = ~$50–80.

**Decision criterion.** If N4 wins on rubric satisfaction by ≥5% over N2 at <70% cost, the Grader check stays as-is. If N5 matches N4 at lower cost, swap the default to wider-Round-1 + no-Round-2.

## Why we're stopping here

This is a designed-but-deferred experiment. Running it costs real money and the marginal information (does adaptive beat fixed-budget?) is unlikely to overturn current practice given the W&D circumstantial evidence. Filed to revisit if any of the three signals above appear.

The methodology is documented so any future run can pick it up without re-deriving.
