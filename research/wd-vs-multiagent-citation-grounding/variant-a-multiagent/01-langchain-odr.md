# Variant A — LangChain Open Deep Research (citation grounding)

**Agent:** Variant A sub-agent 1 (sonnet)
**Tokens:** 22,490
**Duration:** 94.7s
**Tool uses:** 12
**Rounds run:** 2 (Grader Check identified gaps after Round 1)

---

## KEY FINDINGS

- **Citation generation: LLM-instructed inline numbering [1][2][3], not post-hoc linking.** Sub-agents cite inline as they retrieve. Supervisor consolidates and deduplicates (each unique URL → one number). `write_report` produces the markdown report in a single LLM call ending in `### Sources`. **Confidence: H** (docs.langchain.com/oss/python/deepagents/deep-research; blog.langchain.com/open-deep-research/)

- **Source URLs come from search tool results (Tavily), not LLM URL generation.** Tavily returns real, resolved URLs from its search index. Agent fetches webpage content from those URLs. Primary hallucination-reduction mechanism = grounding citations in search-tool output rather than letting the model freely generate URLs. **Confidence: H** (GitHub, official docs, DeepWiki)

- **No dedicated URL-validity verifier or citation-audit step in stock ODR.** Stock workflow (scoping → supervisor → sub-agents → write_report) does not HTTP-check, re-fetch, or validate cited URLs. Relies on search tool's upstream validity as only filter. No "citation auditor" node in the LangGraph graph. **Confidence: H**

- **Fabricated/non-resolving URLs: no specific handling documented.** If a sub-agent generates a URL not returned by the search tool (parametric memory leak), the pipeline does not detect it. `write_report` LLM receives raw text from sub-agents; no schema validation or URL-resolution check. Only structural guard = sub-agents instructed to use `task()` tool, but prompt-level not code-level. **Confidence: M**

- **Independent study (arxiv 2604.03173, Apr 2026): deep research agents hallucinate URLs at higher rates than simpler search-augmented LLMs.** 3-13% URL hallucination, 5-18% non-resolving on DRBench (53,090 URLs). Released `urlhealth` (83-line Python tool) as remedy. **Confidence: H**

- **deepagents 0.2 / 0.5 (Jan-Mar 2026): no citation-verification additions.** Jan 2026 added "recovery from hallucinated tool calls" — but this is structured tool-call schema recovery, NOT citation-URL hallucination. Mar 2026 v0.5.0 alpha added async subagents, multimodal, prompt caching — no citation auditor. **Confidence: M**

## GAPS / CONTRADICTIONS

- No primary-source LangChain doc explicitly addresses non-resolving cited URLs.
- arxiv 2604.03173 names "deep research agents" as a class; whether ODR was specifically tested isn't confirmed at search-snippet level.
- DeepWiki may contain code-level write_report prompt detail not surfaced by search.

## TOP 3 URLs TO FETCH

1. https://arxiv.org/html/2604.03173 — full text of reference-hallucination paper
2. https://docs.langchain.com/oss/python/deepagents/deep-research — exact sub-agent + writer prompt instructions
3. https://deepwiki.com/langchain-ai/open_deep_research — code-derived node-level detail

## ALL SOURCES

19 sources captured (LangChain official, DeepWiki, practitioner blogs, arxiv, news, PyPI, X) — see agent transcript for full list.
