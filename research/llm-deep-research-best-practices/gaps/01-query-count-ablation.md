# Gap 1: Query Count Ablation / Saturation Point

**Question:** Is there a rigorous ablation showing how many search queries per dimension yields diminishing returns?

**Answer (after targeted search 2026-04-26):** No. Multiple sources confirm this is a genuine gap in published literature as of April 2026.

**What does exist:**
- Production system numbers (Google Deep Research Max: up to 160 searches, 900k input tokens, 60-min budget) — operational ceilings, not saturation curves.
- Reflection-driven termination (SoK Agentic RAG, arXiv:2603.07379) formalizes the "Grader" trigger — re-search when retrieved-doc relevance falls below threshold. This is the field's *answer to the budget question*: don't budget; let a relevance grader decide.
- LangChain Open Deep Research uses the same approach: pause-and-assess between rounds, narrower searches if gaps remain.
- General "diminishing returns" literature (MIT FutureTech) covers compute/algorithmic scaling, not per-query saturation in agentic search.

**Implication for the rpm deep-research skill:**
The current fixed-count heuristic (5–6 broad + 4–6 targeted per dimension) is a reasonable practitioner default in the *absence* of an ablation, but the SOTA direction is reflection-driven: have the agent (or the orchestrator after the agent returns) check whether the dimension's findings are saturated, and only then run more queries. A practical compromise: keep the fixed minimum, but allow the agent to halt early if Round 1 already produced strong primary sources for every sub-question.

**Sources:**
- https://docs.langchain.com/oss/python/deepagents/deep-research
- https://arxiv.org/abs/2603.07379 (SoK Agentic RAG)
- https://blog.google/innovation-and-ai/models-and-research/gemini-models/next-generation-gemini-deep-research/
