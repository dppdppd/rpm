# Variant B — Single Agent, W&D-style Parallel Tool Calling

**Agent:** Variant B (sonnet, single)
**Tokens:** 30,428
**Duration:** 122.3s
**Tool uses:** 19 (12 in Round 1 batch + 6 in Round 2 batch + final report)
**Parallelism confirmed:** Round 1 = 12 parallel WebSearches in one message; Round 2 = 6 parallel WebSearches in one message. No sequential fallback.
**Rounds run:** 2

---

## KEY FINDINGS PER SYSTEM

### LangChain Open Deep Research

- **Inline numbered citations [1][2][3]** — each unique URL gets exactly one number. Sources section at end. **Confidence: H** (DeepWiki/3.4-agent-prompts-and-instructions)
- **Tavily fetch-first**: full webpage content retrieved, not snippets. No HTTP-resolution check. **Confidence: M**
- **No URL-validation guard**: bad URLs from search backends pass through. Issue #947 reports tool-call error handling problems. **Confidence: M**
- **No separate citation-audit subagent.** Writer dedupes citations as a formatting step only. **Confidence: H**
- **Ranked #6 on Deep Research Bench Leaderboard** (score 0.4344, 100 PhD-level tasks). **Confidence: M**

### MiroThinker

- Surfaces both reasoning chain and external sources. v1.7 highest Report Quality score (76.5) on DeepResearchEval. Exact inline citation format underspecified publicly. **Confidence: M**
- **Reasoning-level verification, not URL-level.** Trained to penalize high-confidence outputs lacking source support. "Scientist mode" (1.5) zero-tolerance for low-evidence reasoning. **Confidence: M**
- **Global Verifier (MiroThinker-H1, Mar 16 2026)**: distinct post-reasoning audit checking answer coherence and evidence support. "Think → verify locally → verify globally → answer." **arxiv:2603.15726**. **Confidence: H**
- BrowseComp 74.0 / BrowseComp-Zh 75.3. **Confidence: H**

### GPT-Researcher

- Each scraped resource summarized with source tracking. Citations inserted as live source links at report-writing time. 20+ sources per task. Reviewer + Revisor subagent pair. **Confidence: H**
- Tavily as default retriever filters low-quality sources. Statistical/aggregation strategy for hallucination reduction. No runtime HTTP check. **Confidence: H**
- **Issue #1000: URL truncation bug** — citations link to root domain (e.g., forbes.com) rather than specific page. Confirms citations derive from search metadata, not deep-link validation. **Confidence: H**
- Reviewer/Revisor = content quality check, NOT URL-resolution audit. **Confidence: H**

## CROSS-SYSTEM PATTERNS

**Universal across all 3 (Variant B's distinct contribution — no Variant A agent had this view):**
- All retrieval-grounded — citations from search/fetch, not model memory.
- **None implement an HTTP URL-resolution check at runtime.** Universal gap.
- All rely on the search provider as the implicit URL-validity filter.

**Divergences:**
- Only MiroThinker has a formally specified verification subagent (Global Verifier).
- LangChain has the most explicit citation-formatting spec.
- GPT-Researcher has a documented URL-truncation defect (#1000).
- MiroThinker addresses hallucination at TRAINING level (penalize low-evidence); LangChain/GPT-R address only at pipeline level.

**Unaddressed by all 3:** Catching AI-generated source titles paired with real-looking but non-existent URLs.

## TOP 3 URLs TO FETCH PER SYSTEM

LangChain ODR:
1. https://deepwiki.com/langchain-ai/open_deep_research/3.4-agent-prompts-and-instructions
2. https://github.com/langchain-ai/open_deep_research
3. https://blog.langchain.com/evaluating-deep-agents-our-learnings/

MiroThinker:
1. https://arxiv.org/pdf/2603.15726 (Global Verifier paper)
2. https://www.miromind.ai/blog/mirothinker-1.7-h1-towards-heavy-duty-research-agents-via-verification
3. https://github.com/MiroMindAI/MiroThinker/blob/main/README.md

GPT-Researcher:
1. https://deepwiki.com/assafelovic/gpt-researcher
2. https://github.com/assafelovic/gpt-researcher/issues/1000 (URL truncation bug)
3. https://docs.gptr.dev/blog

## ALL SOURCES

27 sources across all 3 systems — see agent transcript for full table.
