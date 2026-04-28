# D2: Search Strategy & Query Design

**Agent:** D2 (sonnet)
**Completed:** 2026-04-26

---

## 1. KEY FINDINGS

**Query Generation — Round-Based and Decomposition-First**

- Self-ask / decomposition before search is the dominant 2026 paradigm. Top systems (OpenAI, Google, Perplexity) front-load planning to decompose top-level question into atomic sub-queries before any search. LangChain supervisor delegates each sub-topic; Google exposes plan to user before execution. **Confidence: H**
  Sources: https://docs.langchain.com/oss/python/deepagents/deep-research, https://blog.google/innovation-and-ai/models-and-research/gemini-models/next-generation-gemini-deep-research/

- Round-based search is standard: broad first to establish vocabulary + sub-topics, then targeted rounds. LangChain documented strategy: "broader searches first, pause to assess gaps, then narrower searches." Google Deep Research Max runs up to 160 searches and 900k input tokens in up to 60 minutes. **Confidence: H**
  Source: https://ai.google.dev/gemini-api/docs/models/deep-research-max-preview-04-2026

- ParallelSearch (Aug 2025) trains LLMs to recognize parallelizable query structures and fire multiple sub-queries simultaneously. RL reward for identifying independent components. Gains on multi-hop QA. Under-explored in off-the-shelf agents. **Confidence: M**
  Source: https://arxiv.org/abs/2508.09303

- **AgentIR (Mar 2026, Waterloo/CMU/UQ)**: most directly applicable academic result. Fine-tunes embedding model to jointly embed agent's *reasoning trace* alongside query (not query alone). On BrowseComp-Plus: 68% end-to-end vs 52% for conventional embedding model 2x size, 37% for BM25. **Key insight**: agentic queries arrive with rich CoT context — feed it to the retriever, don't discard. **Confidence: H**
  Source: https://arxiv.org/abs/2603.04384

**Query Rewriting**

- 2026 frontier: decouple rewriting from dense retriever. **LevelRAG (Feb 2026)**: high-level "searcher" decomposes into atomic queries independently of retriever, then passes to separate low-level searchers (sparse Lucene / web / dense). Hybrid retrieval without tight coupling. Validated on 5 single-hop and multi-hop QA datasets. **Confidence: H**
  Source: https://arxiv.org/abs/2502.18139

- SageRAG (2026): query rewriting + clarification for grounded research responses. **Confidence: M**

- LITHE (EDBT 2026): LLM-as-rewrite-advisor with database tools — most relevant for SQL but the agentic tool-loop pattern applies to web search. **Confidence: M**

**Iterative Search — When to Re-Search**

- EvolveSearch (May 2025): self-evolving SFT+RL framework. Avg 4.7% improvement across 7 multi-hop QA across iterations. Validates iterative loop. **Confidence: M**

- **SoK agentic RAG (Mar 2026, arXiv:2603.07379)** formalizes the loop as finite-horizon POMDP. Control policy includes a **"Grader"** that triggers query rewriting + another retrieval pass when retrieved docs score below threshold. Clearest formalization of "when to re-search" trigger: **document relevance grading, not fixed query count**. **Confidence: H**
  Source: https://arxiv.org/abs/2603.07379

- Perplexity production: dozens of searches across hundreds of sources per query, parallelized ingestion + hierarchical summarization, 2-4 minute reports. Trigger for additional searches = **gap detection during synthesis**, not predetermined count. **Confidence: M (practitioner claim, no ablation)**

**Diversification — Terminology, Perspective, Source-Type**

- **DRACO benchmark (Perplexity, Feb 2026, arXiv:2602.11685)** evaluates deep research on 100 tasks across 10 domains, 40 countries. 4 dimensions: factual accuracy, **breadth/depth (completeness)**, presentation quality (objectivity), citation quality. Diversity is a first-class evaluation criterion, not a nice-to-have. **Confidence: H**
  Source: https://arxiv.org/abs/2602.11685

- **"A Picture of Agentic Search" (arXiv:2602.17518, Feb 2026)**: agentic queries differ from human queries — high volume, unpredictable temporal patterns, **redundant near-duplicates**. ASQ dataset across 3 agents and 2 retrieval pipelines. Validates that diversification heuristics ("vary terminology") are empirically necessary because agents otherwise generate redundant queries. **Confidence: H**
  Source: https://arxiv.org/abs/2602.17518

- Google teaches its model to "consult a diverse array of sources and carefully weigh conflicting evidence." Source diversity production-validated. **Confidence: H**

- JMIR viewpoint (2026): without conscious diversification, agents perpetuate publication biases (practitioner vs academic, proponent vs critic imbalance). Validates explicit source-type variation as guardrail. **Confidence: M**

**Recency Tuning**

- **LLM rerankers have statistically significant recency bias**: across GPT-3.5, GPT-4o, GPT-4, LLaMA-3 8B/70B, Qwen-2.5 7B/72B, "fresh" passages systematically promoted, shifting Top-10 mean publication year forward by **up to 4.78 years**. Larger models attenuate but don't eliminate (arXiv:2509.11353, SIGIR AP 2025). **Implication**: if you want foundational sources, you must explicitly request them. **Confidence: H**
  Source: https://arxiv.org/abs/2509.11353

- Google Deep Research and OpenAI both allow explicit source-type filtering (trusted sites, MCP-connected private data, academic-only). Practitioner answer: **explicit constraint injection in system prompt or research plan**, not learned mechanism. **Confidence: H**

**Search Depth Budgeting**

- Google Deep Research Max: up to 160 searches, 900k input tokens, 60 minutes (only published hard numbers from a production system). No public ablation comparing 10 vs 30 vs 80 searches within these systems. **Confidence: H (numbers), L (no ablation)**

- "Agentic deep research" survey (arXiv:2508.05668): loop = search → generate → reflect → re-plan/re-search until satisfactory. **Diminishing-returns detection by model's reflection step**, not hardcoded count. No specific ablation numbers found. **Confidence: M**

- MIT EnCompass (Feb 2026): beam-search-like over query sequences, finds path where LLM finds best solution. **Confidence: M**

- **A-RAG (Feb 2026, arXiv:2602.03442)**: 3 hierarchical retrieval tools — keyword, semantic, chunk read. Agent decides which to call. **Granularity-budgeting by tool type, not by query count**. **Confidence: H**

**Search Engine vs Vector DB vs Site-Specific**

- A-RAG (Feb 2026): 3 tools — keyword (BM25), semantic (dense), chunk read. Agent adaptively selects. Clearest recent architecture for "when to use which retrieval type": let the agent decide. **Confidence: H**

- LevelRAG (Feb 2026): sparse + web + dense as parallel low-level searchers under high-level planner. Outperforms single-type retrieval on single-hop and multi-hop. Different query types benefit from different retrieval mechanisms → planning layer above retrieval is necessary. **Confidence: H**

- Google Deep Research API (Apr 2026) supports simultaneous Google Search + remote MCP servers + URL Context + Code Execution + File Search, or web disabled for private-data-only. Production confirmation of multi-source orchestration. **Confidence: H**

---

## 2. CONTRADICTIONS AND OPEN QUESTIONS

**Contradiction 1 — Fixed query budget vs reflection-driven termination.**
Current implementation uses fixed-count (5-6 broad + 4-6 targeted per dimension). 2026 consensus from SoK, Perplexity, LangChain favors **reflection-driven termination** (re-search when grader scores docs as insufficient). No public ablation comparing fixed vs reflection-driven on same benchmark. Reflection is theoretically superior but more expensive; fixed is more predictable.

**Contradiction 2 — Recency bias is both bug and feature.**
SIGIR AP 2025 documents recency bias as unwanted artifact. Yet including current year in queries deliberately exploits the same mechanism. Both defensible: question is whether you want recency-preference (fast-moving fields) or not (foundational theory).

**Contradiction 3 — Agentic query volume vs quality.**
"A Picture of Agentic Search" documents agents generate far more queries than humans, but also more near-duplicates. Diversification heuristics validated as necessary. Paper does not give saturation point.

**Open Question 1 — Ablation on query count per dimension.**
No paper provides rigorous ablation showing "N queries yields X% recall, N+K diminishes at Y%." Genuine gap in published literature as of April 2026.

**Open Question 2 — Reasoning-trace-to-query for off-the-shelf APIs.**
AgentIR shows large gains from embedding reasoning traces with queries — but requires fine-tuned retriever. For systems using Tavily/Google/Bing, equivalent workaround is unclear (prepend trace? separate context field?). No engineering blog has published ablations.

**Open Question 3 — Critic/adversarial source coverage.**
JMIR flags publication bias but no paper provides concrete mechanism for systematically sourcing critic perspectives (beyond "search for criticism of X" as separate query).

---

## 3. ALL SOURCES

| Title | URL | Type | Date |
|---|---|---|---|
| AgentIR: Reasoning-Aware Retrieval for Deep Research Agents | https://arxiv.org/abs/2603.04384 | Academic | Mar 2026 |
| A Picture of Agentic Search | https://arxiv.org/abs/2602.17518 | Academic | Feb 19, 2026 |
| DRACO: Cross-Domain Benchmark for Deep Research | https://arxiv.org/abs/2602.11685 | Academic / Perplexity | Feb 2026 |
| SoK: Agentic RAG Taxonomy, Architectures, Evaluation | https://arxiv.org/abs/2603.07379 | Academic | Mar 7, 2026 |
| A-RAG: Hierarchical Retrieval Interfaces | https://arxiv.org/abs/2602.03442 | Academic | Feb 4, 2026 |
| LevelRAG: Multi-hop Logic Planning over Rewriting Augmented Searchers | https://arxiv.org/abs/2502.18139 | Academic | Feb 2026 |
| Deep Research Max blog (Google) | https://blog.google/innovation-and-ai/models-and-research/gemini-models/next-generation-gemini-deep-research/ | Engineering Google | Apr 2026 |
| Deep Research Max API docs (Google) | https://ai.google.dev/gemini-api/docs/models/deep-research-max-preview-04-2026 | Official Docs | Apr 2026 |
| Gemini Deep Research API docs | https://ai.google.dev/gemini-api/docs/deep-research | Official Docs | Apr 2026 |
| OpenAI Deep Research System Card | https://openai.com/index/deep-research-system-card/ | Engineering OpenAI | Feb 2025 |
| OpenAI Cookbook deep research intro | https://cookbook.openai.com/examples/deep_research_api/introduction_to_deep_research_api | Official Docs | 2026 |
| LangChain deep research docs | https://docs.langchain.com/oss/python/deepagents/deep-research | Engineering Docs | 2026 |
| Open Deep Research (LangChain blog) | https://blog.langchain.com/open-deep-research/ | Engineering Blog | 2026 |
| Perplexity DRACO article | https://research.perplexity.ai/articles/evaluating-deep-research-performance-in-the-wild-with-the-draco-benchmark | Engineering Perplexity | Feb 2026 |
| EvolveSearch | https://arxiv.org/abs/2505.22501 | Academic | May 2025 |
| ParallelSearch | https://arxiv.org/abs/2508.09303 | Academic | Aug 2025 |
| Recency Bias in Reranking | https://arxiv.org/abs/2509.11353 | Academic SIGIR AP 2025 | Sep 2025 |
| Teaching LLMs to Ask: Self-Querying Category-Theoretic | https://arxiv.org/pdf/2601.20014 | Academic | Jan 2026 |
| Agentic RAG Survey | https://arxiv.org/abs/2501.09136 | Academic survey | Jan 2026 |
| MIT News: EnCompass | https://news.mit.edu/2026/helping-ai-agents-search-to-get-best-results-from-llms-0205 | News/Research | Feb 2026 |
| JMIR Deep Research Agents Viewpoint | https://www.jmir.org/2026/1/e88195/PDF | Academic commentary | 2026 |
| LITHE: Query Rewrite Advisor (EDBT 2026) | https://openproceedings.org/2026/conf/edbt/paper-93.pdf | Academic conference | 2026 |
| SageRAG: Query rewriting | https://www.sciencedirect.com/science/article/abs/pii/S0957417426000746 | Academic | 2026 |
| Elastic: Query Rewriting | https://www.elastic.co/search-labs/blog/query-rewriting-llm-search-improve | Engineering | 2025/2026 |

---

## 4. TOP 5 URLs TO FETCH

1. **https://arxiv.org/html/2603.04384v3** — AgentIR (Mar 2026). Most directly relevant: reasoning-trace-aware retrieval. Ablation numbers (68% vs 52% vs 37%).
2. **https://arxiv.org/html/2602.17518** — A Picture of Agentic Search (Feb 2026). Empirical agent vs human query patterns, redundancy, volume.
3. **https://arxiv.org/html/2603.07379v1** — SoK Agentic RAG (Mar 2026). Full taxonomy, POMDP formalization, when-to-re-search.
4. **https://arxiv.org/html/2602.03442v1** — A-RAG (Feb 2026). Hierarchical retrieval tools for engine vs vector vs site-specific.
5. **https://arxiv.org/html/2502.18139v1** — LevelRAG (Feb 2026). Decoupled query rewriting + Lucene+web+dense.

Honorable mention: https://ai.google.dev/gemini-api/docs/models/deep-research-max-preview-04-2026 — Google's Deep Research Max (160 searches, 900k tokens, 60 min budget).

---

## 5. SUGGESTED FOLLOW-UPS

- Ablation on query count per dimension (saturation point).
- Reasoning-trace-to-query mapping for off-the-shelf APIs.
- Adversarial / critic perspective sourcing mechanisms.
- Recency-foundational balance mechanism (not just bias correction).
- Live vector DB vs web search tradeoffs in production.
