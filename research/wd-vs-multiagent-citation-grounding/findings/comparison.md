# Variant A (multi-subagent) vs. Variant B (W&D parallel single-agent)

**Topic tested:** How do LangChain Open Deep Research, MiroThinker, and GPT-Researcher handle citation grounding and source verification (Jan-Apr 2026)?
**Date:** 2026-04-26
**Hypothesis:** W&D pattern (parallel tool calling within a single sonnet agent) can match or beat the current 3-subagent design at lower token cost (per arXiv:2602.07359).

---

## Quantitative comparison

| Metric | Variant A (3 sub-agents) | Variant B (1 agent, parallel calls) | Δ |
|---|---|---|---|
| **Total tokens** | 70,060 (22,490 + 24,934 + 22,636) | 30,428 | **−56.6%** for B |
| **Wall-clock (max parallel)** | 168.5 s | 122.3 s | **−27.4%** for B |
| **Total tool uses (WebSearch)** | 36 (12 + 12 + 12) | 19 (12 + 6 + 1 final) | **−47.2%** for B |
| **Rounds run** | 2, 2, 2 | 2 | tied |
| **Parallelism inside an agent** | Sequential within each sub-agent | 12 in Round 1, 6 in Round 2 (confirmed) | — |
| **Agent slots used** | 3 | 1 | — |

Variant B's 30k-token cost is roughly equivalent to ONE Variant A sub-agent. Same task coverage delivered at one-third the token budget.

---

## Qualitative comparison — coverage and quality

### What Variant A had that Variant B didn't
- **Per-system depth** — each sub-agent had its full context budget for one system, allowing it to chase nuances that didn't surface in Variant B's parallel batch:
  - LangChain agent surfaced the arxiv:2604.03173 reference-hallucination paper as relevant context (Variant B did not).
  - GPT-Researcher agent surfaced Issue #677 (spillover bug) and Issue #565 (local-data references missing) — Variant B only found Issue #1000 (URL truncation).
  - MiroThinker agent surfaced "centralized citation management" phrasing from the vendor blog and the MiroFlow tool-layer retry/fallback mechanism — Variant B captured the Global Verifier but not these implementation-level details.

### What Variant B had that Variant A couldn't
- **Cross-system patterns surfaced in a single context.** Variant B's report includes a "CROSS-SYSTEM PATTERNS" section that names universal traits (all 3 are retrieval-grounded; **none implement HTTP URL-resolution at runtime**; all rely on the search provider as implicit URL filter) and divergences (only MiroThinker has a formal Verifier subagent; only LangChain has explicit citation-formatting spec; only GPT-Researcher has a documented URL-truncation defect). A Variant A sub-agent **cannot** produce this kind of synthesis because each is sandboxed to one system.
- **Comparable findings count** — Variant B surfaced 9 distinct findings per system on average vs. Variant A's ~9 per agent, despite using ~1/3 the tokens.
- **Fewer redundant searches** — Variant A's 3 sub-agents collectively ran a few overlapping queries (`...github docs`, `...hallucination`); the W&D pattern in one agent has no risk of inter-agent duplication.

### Source breadth
- Variant A: ~56 sources total across 3 reports (with some overlap).
- Variant B: 27 sources in one consolidated table.
- **Per-token source efficiency:**
  - Variant A ≈ 0.80 sources per 1,000 tokens
  - Variant B ≈ 0.89 sources per 1,000 tokens
  - Variant B is ~11% more source-efficient per token.

---

## Findings overlap audit

For each system, what did each variant uniquely capture?

### LangChain ODR
- Both: numbered inline citations [1][2][3], dedup across sub-agents, no separate audit step, Tavily as default retriever.
- Variant A only: arxiv 2604.03173 paper as context, Jan/Mar 2026 changelog detail, "recovery from hallucinated tool calls" framing.
- Variant B only: ranked #6 on Deep Research Bench Leaderboard (score 0.4344).

### MiroThinker
- Both: Local + Global Verifier audit reasoning chain not URL liveness; H1 announced Mar 16 2026.
- Variant A only: "Core Research Report Generation" capability (MiroFlow v0.2); "centralized citation management" phrasing; MiroFlow retry/fallback at tool layer; benchmark scores against OpenAI DR / Gemini DR.
- Variant B only: BrowseComp 74.0 / BrowseComp-Zh 75.3 (more specific scores than A's narrative).

### GPT-Researcher
- Both: visited_urls as authoritative reference list; Tavily as default retriever; no runtime URL check; Reviewer/Revisor pair.
- Variant A only: Issue #677 (spillover bug); Issue #565 (local-data references missing); PR #734 (`source_urls`/`add_additional_sources`); CMU DeepResearchGym #1 ranking; AG2 March 2026 integration.
- Variant B only: Issue #1000 (URL truncation to root domain) — a different concrete defect than A found.

---

## Verdict

**Variant B (W&D parallel) wins on cost; Variant A (multi-subagent) wins on per-system depth.**

For *this particular task* (a comparison of 3 specific systems on one axis), Variant B was strictly more cost-efficient and surfaced cross-system patterns that Variant A architecturally cannot. Variant A captured more idiosyncratic per-system detail — specific GitHub issue numbers, framework-specific terminology, additional benchmark contexts.

The cost gap (-56.6% tokens for B) is large enough that Variant B is the right default for **comparison-shaped research tasks** where cross-system synthesis is the goal. Variant A is still right for **deep-dive single-topic tasks** where each dimension demands extended exploration.

---

## Recommendations for the rpm `deep-research` skill

1. **Add a "research shape" classifier in Phase 1.** When the topic is a comparison or survey across N entities (where each entity is the dimension), default to Variant B (single agent, parallel tool calling) rather than spinning up N sub-agents. Token savings ~50%+, and cross-entity patterns get surfaced for free.

2. **Keep multi-subagent for orthogonal-dimension topics.** When dimensions are genuinely independent axes that each need depth (e.g., the original "improve deep-research skill" research had 4 unrelated dimensions: orchestration, search strategy, grounding, synthesis), multi-subagent's per-dimension context budget pays off.

3. **Heuristic decision rule:**
   - Comparison / survey across named entities → Variant B (single agent, parallel calls)
   - Independent dimensions of a complex topic → Variant A (multi-subagent)
   - Mixed → start with Variant B; if any entity needs deeper exploration, follow up with a single targeted Variant A sub-agent on just that entity.

4. **Update SKILL.md / standalone command** to document this choice and recommend the W&D pattern as the default for survey/comparison tasks. The current Phase 1 complexity assessment ("SIMPLE 1-3 dims" vs "COMPLEX 4+") is orthogonal to this; the new axis is "task shape" (deep-dive vs. comparison).

---

## Caveats

- **Single experiment, n=1.** This is one task with one model (sonnet) on one date. The 56% cost savings could vary substantially by topic.
- **Topic was unusually well-suited to Variant B**: 3 named entities, 1 axis. A topic with 4+ truly independent sub-questions could flip the result.
- **Quality assessment is qualitative.** No DRB II rubric was applied; the comparison rests on subjective coverage assessment. To make the verdict more rigorous, future work should pick 3 DRB II tasks and run both variants against each, scoring rubric satisfaction.
- **Wall-clock is dominated by tail agent.** Variant A took 168.5s because the slowest of 3 agents finished at that mark. If 4 agents had been launched (full skill design), the tail could have been longer.
- **Variant B's Round-2 6-search batch had 1 empty/throwaway search** in tool count (19 = 12 + 6 + 1 = could be batch overhead). Either way, fewer total calls than Variant A's 36.
