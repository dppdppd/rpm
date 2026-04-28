# Variant A — GPT-Researcher (citation grounding)

**Agent:** Variant A sub-agent 3 (sonnet)
**Tokens:** 22,636
**Duration:** 91.6s
**Tool uses:** 12
**Rounds run:** 2

---

## KEY FINDINGS

- **Citations tracked via `visited_urls` through RAG pipeline.** System scrapes 20+ URLs, summarizes each tagging source URL, then feeds tagged summaries to report-writing LLM. Report cites only URLs actually visited. **Confidence: H** (github issue #565)

- **No active URL validation / link-resolution check.** No HTTP HEAD/GET to verify URL resolves before inclusion. Citations are structural anchors back to scraped source. **Confidence: H** (issue #677)

- **Known "spillover" bug**: citations from previous research run can appear in subsequent runs if `GPTResearcher` object is reused — `visited_urls` not fully reset. Real URLs but wrong for current question. **Confidence: H** (issue #677)

- **References not generated for local-data (non-web) modes.** When local docs used, `visited_urls` is empty → no references appended. **Confidence: H** (issue #565)

- **RAG + parallel source aggregation = primary hallucination mitigation.** "Law of large numbers" claim: crawling 20+ sources reduces fabrication probability. Self-reported "50% reduction" — no methodology, marketing figure. **Confidence: M**

- **No standalone citation-audit/verifier in core library.** No "verify citations" stage. Verification is implicit in RAG architecture. **Confidence: M** (DeepWiki)

- **AG2 multi-agent integration (Mar 2026) adds Reviewer agent** scoring research quality 1-10 + identifying gaps. NOT a citation URL auditor — checks completeness/coverage, doesn't resolve URLs. **Confidence: H** (docs.ag2.ai/latest/docs/blog/2026/03/03/GPT-Researcher-AG2/)

- **CMU DeepResearchGym (May 2025) ranked GPT-Researcher #1 on citation quality** vs Perplexity, OpenAI DR, OpenDeepSearch, HuggingFace on 1,000 complex queries. **Confidence: M** (secondary source; CMU paper not directly retrieved)

- **`source_urls` parameter allows pre-validated URLs** to bypass search. `add_additional_sources` augments with web search. Closest to controlled citation grounding. **Confidence: H** (PR #734)

- **Tavily search API performs source relevance scoring** before URLs reach the agent. **Confidence: H**

## GAPS / CONTRADICTIONS

- "Visited URLs only" architecture vs spillover bug: real URLs but wrong context.
- No documented handling for 404/changed pages after scraping.
- "50% hallucination reduction" undocumented marketing.
- No enforcement that inline citations actually point to the correct scraped passage.

## TOP 3 URLs TO FETCH

1. https://docs.gptr.dev/docs/gpt-researcher/getting-started/introduction
2. https://docs.ag2.ai/latest/docs/blog/2026/03/03/GPT-Researcher-AG2/
3. https://deepwiki.com/assafelovic/gpt-researcher/4.3-deep-research-mode

## ALL SOURCES

20 sources captured (gpt-researcher repo + issues + PRs, gptr.dev docs, AG2 docs, Tavily, CMU benchmark via secondary, Nieman Lab, SERanking, PyPI).
