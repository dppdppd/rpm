# D4: Synthesis, Evaluation & Production Lessons

**Agent:** D4 (sonnet)
**Completed:** 2026-04-26

---

## 1. KEY FINDINGS

### A. SYNTHESIS QUALITY

- **Parallel sub-agents for research, sequential single-pass for writing is now the dominant pattern.** Earlier systems that ran section-writing in parallel sub-agents produced disjoint, incoherent reports. The consensus from OpenAI's system card, the ByteBytego architecture analysis, and DeepResearch Bench II findings is: parallelize only the *retrieval/exploration* phase; funnel all gathered evidence into a single synthesis pass by one lead model.
  Sources: https://openai.com/index/deep-research-system-card/, https://blog.bytebytego.com/p/how-openai-gemini-and-claude-use
  **Confidence: H**

- **Self-Manager (arxiv 2601.17879, Jan 2026) introduces Thread Control Blocks** — each sub-thread has an isolated context window. The main thread manages them iteratively, preventing mutual interference. It consistently beats single-agent loop baselines on all DeepResearch Bench metrics. This is the most recent architectural alternative to a pure "gather then synthesize" pattern, and it preserves the single-context-for-writing benefit while enabling broader parallel retrieval than 4 fixed agents.
  Source: https://arxiv.org/abs/2601.17879
  **Confidence: H**

- **Context rot is a confirmed architectural hazard for synthesis.** Chroma's study (2025, 18 models including GPT-4.1, Claude 4, Gemini 2.5) shows every frontier model degrades continuously starting around 50K tokens — not at a cliff. The "lost-in-the-middle" effect causes 30%+ accuracy drops for content in the middle of long contexts. Directly relevant: if your final synthesis context (all artifacts concatenated) exceeds ~50K tokens, the first sections of the report will be written correctly and later sections will regress.
  Source: https://research.trychroma.com/context-rot
  **Confidence: H**

- **W&D (Salesforce, Feb 2026, arxiv 2602.07359): parallel tool calling within a single reasoning step** outperforms complex multi-agent orchestration in both quality and cost. "Width" scaling (parallel calls per turn) improves BrowseComp, HLE, and GAIA scores simultaneously while reducing turns, API cost, and wall-clock time. Your current "4 parallel Sonnet sub-agents" design is directionally correct but this paper suggests you can get similar or better gains by giving one agent more tool calls per turn rather than more agents.
  Source: https://arxiv.org/abs/2602.07359
  **Confidence: H**

- **Gemini Deep Research Max (2026) uses extended test-time compute to *iteratively reason, search, and refine* the report** — multiple passes of "research a gap, rewrite that section." This iterative refinement loop is more expensive than one-pass but targets completeness. Google's Deep Research Max outperforms single-pass Deep Research substantially on HLE (37.5% for Gemini 3 Pro Preview, compare to 61.9% on BrowseComp for standard vs 85.9% for Max).
  Source: https://blog.google/innovation-and-ai/models-and-research/gemini-models/next-generation-gemini-deep-research/, https://officechai.com/ai/google-releases-deep-research-max-tops-hle-browsecomp-deepsearchqa-benchmarks/
  **Confidence: M**

- **Conciseness vs. completeness tradeoff is unresolved.** DeepResearch Bench II rubrics show even the best models satisfy fewer than 50% of expert-derived criteria — the gap is mostly in *analysis depth* and *evidence coverage*, not formatting. This suggests current SOTA underperforms on completeness, not verbosity. Cutting for conciseness at current capability levels likely worsens scores.
  Source: https://arxiv.org/abs/2601.08536
  **Confidence: H**

---

### B. EVALUATION BENCHMARKS AND LEADERBOARDS

- **DeepResearch Bench II (DRB II, arxiv 2601.08536, Jan 30 2026)** is the most rigorous benchmark for synthesis quality as of April 2026. 9,430 fine-grained binary rubrics across 132 tasks (22 domains), derived from expert-written articles with 400+ human-hours of review. Three evaluation dimensions: *information recall*, *analysis*, and *presentation*. Top models score under 50%.
  Source: https://arxiv.org/abs/2601.08536, https://github.com/imlrz/DeepResearch-Bench-II
  **Confidence: H**

- **DeepResearch Bench I (arxiv 2506.11763)** uses RACE (reference-based adaptive criteria evaluation) for report quality, and FACT (factual abundance + citation trustworthiness). March 2026 leaderboard top: Cellcog Max 56.13.
  Source: https://deepresearch-bench.github.io/, https://arxiv.org/abs/2506.11763
  **Confidence: H**

- **BrowseComp (OpenAI)** current top scores: Google Deep Research Max 85.9%, standard Deep Research 61.9%, GPT-5 + Qwen3-Embedding-8B retriever 70.1%, MiroThinker-v1.5 69.8%.
  **Confidence: H**

- **BrowseComp-Plus (ACL 2026 Main, arxiv 2508.06600)** addresses fairness flaw in original BrowseComp (live web APIs make comparisons non-reproducible). Fixed curated corpus with human-verified supporting documents and hard negatives. Disentangles retriever from model contribution.
  Source: https://arxiv.org/abs/2508.06600
  **Confidence: H**

- **HLE (Humanity's Last Exam)** 2026 scores: Gemini 3 Pro Preview 37.5%, Claude Opus 4.6 Thinking Max 34.4%, GPT-5 Pro 31.6%. Human experts ~90%.
  **Confidence: M**

- **GAIA**: MiroThinker-v1.5 80.8% on GAIA-Val-165. W&D shows parallel tool calling improves GAIA scores.
  **Confidence: H**

- **DeepSearchQA (Google DeepMind, Dec 2025)**: targets "comprehensiveness gap." Google Deep Research Max tops it.
  **Confidence: M**

- **Towards Knowledgeable Deep Research (arxiv 2604.07720, Apr 2026)**: new framework + benchmark for knowledge integration. Very recent.
  **Confidence: L**

---

### C. PRODUCTION LESSONS FROM VENDORS

- **OpenAI Deep Research (o3-based)**: multi-agent writing caused disjoint reports, resolved by restricting agent parallelism to search/retrieval only. Browsing safety (resisting prompt injection from web content) required specific training on adversarial web pages.
  Source: https://openai.com/index/deep-research-system-card/
  **Confidence: H**

- **OpenAI's roadmap (MIT Tech Review, Mar 2026)**: o3 hallucinates 33% on public information summaries, o4-mini 48%. More capable reasoning models hallucinate *more*, not less.
  Source: https://www.technologyreview.com/2026/03/20/1134438/openai-is-throwing-everything-into-building-a-fully-automated-researcher/
  **Confidence: H**

- **Gemini Deep Research failure modes**:
  1. Orchestration layer state desynchronization across stages.
  2. Thought Signature limitations: not truly stateful across requests.
  3. Prompt vagueness amplification — extended reasoning amplifies assumptions.
  4. Rate limiting + site blocking (HTTP 429, bot blocking).
  Sources: https://dev.to/gys/a-gemini-deep-research-failure-mode-refusal-topic-drift-and-fabricated-charts-1dgd, https://www.iphalo.com/blog/gemini-3-deep-research-blocked/
  **Confidence: M**

- **Perplexity Deep Research (Feb 2026 upgrade)**: passed 7 of 9 real-world tests. Hallucination rate in citation attribution: 37% (best among tested; Grok-3 worst at 94%).
  Source: https://www.perplexity.ai/changelog/what-we-shipped---february-6th-2026
  **Confidence: M**

- **Gemini API Deep Research Preview (April 2026)**: deep-research-preview-04-2026 endpoint exposed.
  **Confidence: M**

---

### D. TOP 5 FAILURE MODES IN PRODUCTION DEEP RESEARCH

From "Why Your Deep Research Agent Fails?" (arxiv 2601.22984, Jan 2026):

1. **Citation fabrication / misquotation (Explicit Summarization hallucination)**: Model cites real URLs but attributes claims to them that those sources do not support. Rates: Perplexity 37%, Grok-3 94%. Citation-audit agents directly target this. **Confidence: H**

2. **Missing essential retrieved information (Implicit Summarization hallucination)**: Agent finds the right sources but synthesis drops key evidence — often material in the middle of long context windows (context rot). DRB II rubrics confirm this as the primary gap. **Confidence: H**

3. **Planning deviation / redundancy (Explicit Planning hallucination)**: Plan drifts from query or repeats sub-tasks with different phrasings. Gemini's "topic drift" is a production instance. **Confidence: H**

4. **Prompt injection from fetched web content**: Malicious instructions embedded in web pages. OpenAI required specific training. Curl-based URL fetching puts raw HTML/text directly into model context — under-addressed in open implementations. **Confidence: H**

5. **Infrastructure failure cascades (rate limits, blocked sites)**: HTTP 429, Cloudflare blocking, paywalls. Operational, not cognitive. Requires retry logic and fallback sources. **Confidence: H**

PIES Taxonomy formalizes the cognitive failures: Explicit Planning, Implicit Planning, Explicit Summarization, Implicit Summarization.

---

### E. CONFIDENCE TAGGING AND REPORT FORMAT

- **Progressive Confidence Estimation and Calibration (arxiv 2604.05952, Apr 7 2026)**: Most recent directly relevant paper. Confidence scores on *individual claims* (not just section-level), grounded in retrieved evidence via multi-hop reasoning. Validates per-claim confidence design.
  **Confidence: H**

- **Intent-aware writing**: Tag-based format with intent type + natural language rationale at paragraph and citation levels. User study: 4.47/5.0 agreement that intent tags help users decide whether to read in detail.
  **Confidence: M**

- **Optimal length unresolved but "more complete beats more concise" at current capability levels.** DRB II completeness gap is dominant; no current benchmark penalizes length.
  **Confidence: M**

- **FS-Researcher (arxiv 2602.01566)**: filesystem as external memory to avoid context window accumulation. Architecturally sound; matches the "write artifacts to findings/" pattern.
  **Confidence: M**

---

### F. CURRENT DESIGN vs. 2026 SOTA

| Design | Current | 2026 SOTA Assessment |
|---|---|---|
| Dimension-based decomposition | Yes | Aligned with all production systems |
| Parallel Sonnet sub-agents (max 4) | Yes | Correct for retrieval; keep parallel research, not parallel writing |
| Max 4 agents | Fixed | W&D suggests width (tool calls/turn) may beat more agents |
| URL fetching via curl | Yes | Sound; add prompt-injection sanitization |
| Confidence-tagged claims | Yes | Validated; push toward per-claim granularity |
| Dedicated citation-audit agent | Yes | Highest-impact mitigation per 2026 literature |
| Final report (one-pass synthesis) | Yes | Correct; iterative refinement (Gemini Max) improves completeness at cost |
| No iterative gap-filling loop | Implicit | Gap: no "identify what's missing, re-search" loop |

---

## 2. CONTRADICTIONS AND OPEN QUESTIONS

1. **Iterative refinement vs. one-pass cost tradeoff**: Gemini Max iterative loops vs. Self-Manager isolated threads vs. W&D parallel tool calls — not directly compared at same cost budget.
2. **More reasoning = more hallucination paradox**: o3 33%, o4-mini 48% (worse than o1's 16%).
3. **Retriever vs. model contribution**: BrowseComp-Plus shows 14pp swing between BM25 and Qwen3-Embedding-8B for same model.
4. **Optimal report length**: No benchmark penalizes verbosity; completeness incentivized.
5. **Context rot mitigation**: Whether chunked retrieval + selective loading actually solves synthesis regression is not confirmed by ablation.

---

## 3. ALL SOURCES

| Title | URL | Type | Date |
|---|---|---|---|
| DeepResearch Bench | https://deepresearch-bench.github.io/ | Academic / leaderboard | 2025 (updated Mar 2026) |
| DeepResearch Bench II | https://arxiv.org/abs/2601.08536 | Academic | Jan 30 2026 |
| BrowseComp | https://openai.com/index/browsecomp/ | Vendor | 2025 |
| BrowseComp-Plus | https://arxiv.org/abs/2508.06600 | Academic ACL 2026 | 2025/2026 |
| Deep Research System Card | https://openai.com/index/deep-research-system-card/ | Vendor | Feb 2025 |
| Deep Research System Card PDF | https://cdn.openai.com/deep-research-system-card.pdf | Vendor | Feb 2025 |
| OpenAI Deep Research API Guide | https://developers.openai.com/api/docs/guides/deep-research | Vendor docs | 2026 |
| Gemini Deep Research Max blog | https://blog.google/innovation-and-ai/models-and-research/gemini-models/next-generation-gemini-deep-research/ | Vendor | 2026 |
| Gemini API Deep Research Preview | https://ai.google.dev/gemini-api/docs/models/deep-research-preview-04-2026 | Vendor docs | Apr 2026 |
| Gemini DR failure modes | https://dev.to/gys/a-gemini-deep-research-failure-mode-refusal-topic-drift-and-fabricated-charts-1dgd | Practitioner | 2026 |
| Gemini 3.0 DR blocked | https://www.iphalo.com/blog/gemini-3-deep-research-blocked/ | Practitioner | 2026 |
| Perplexity changelog Feb 6 2026 | https://www.perplexity.ai/changelog/what-we-shipped---february-6th-2026 | Vendor | Feb 2026 |
| Perplexity DR Review | https://www.secondtalent.com/resources/perplexity-deep-research-review/ | Practitioner | 2026 |
| OpenAI automated researcher (MIT TR) | https://www.technologyreview.com/2026/03/20/1134438/openai-is-throwing-everything-into-building-a-fully-automated-researcher/ | Press | Mar 20 2026 |
| Self-Manager | https://arxiv.org/abs/2601.17879 | Academic | Jan 25 2026 |
| W&D Parallel Tool Calling | https://arxiv.org/abs/2602.07359 | Academic Salesforce | Feb 7 2026 |
| Why Your Deep Research Agent Fails? | https://arxiv.org/abs/2601.22984 | Academic | Jan 2026 |
| Progressive Confidence Estimation | https://arxiv.org/abs/2604.05952 | Academic | Apr 7 2026 |
| Detecting/Correcting Reference Hallucinations | https://arxiv.org/html/2604.03173v1 | Academic | Apr 2026 |
| Towards Knowledgeable Deep Research | https://arxiv.org/abs/2604.07720v1 | Academic | Apr 2026 |
| FS-Researcher | https://arxiv.org/html/2602.01566v1 | Academic | Feb 2026 |
| Self-Optimizing Multi-Agent Systems | https://arxiv.org/abs/2604.02988 | Academic | Apr 2026 |
| Inference-Time Scaling of Verification | https://arxiv.org/html/2601.15808v1 | Academic | Jan 2026 |
| Deep Research Agents Survey | https://arxiv.org/abs/2506.18096 | Academic | 2025 |
| Context Rot (Chroma) | https://research.trychroma.com/context-rot | Practitioner | 2025 |
| Context Discipline (arxiv 2601.11564) | https://arxiv.org/html/2601.11564v1 | Academic | Jan 2026 |
| DeepSearchQA | https://storage.googleapis.com/deepmind-media/DeepSearchQA/DeepSearchQA_benchmark_paper.pdf | Academic Google | Dec 2025 |
| GAIA Princeton HAL | https://hal.cs.princeton.edu/gaia | Leaderboard | Live |
| GAIA HuggingFace | https://huggingface.co/spaces/gaia-benchmark/leaderboard | Leaderboard | Live |
| Google Deep Research Max press | https://officechai.com/ai/google-releases-deep-research-max-tops-hle-browsecomp-deepsearchqa-benchmarks/ | Press | 2026 |
| MiroThinker | https://github.com/MiroMindAI/MiroThinker | Repo | 2026 |
| ByteBytego: How OpenAI/Gemini/Claude Use Agents | https://blog.bytebytego.com/p/how-openai-gemini-and-claude-use | Practitioner | 2026 |
| LangChain deep research agent | https://docs.langchain.com/oss/python/deepagents/deep-research | Vendor docs | 2026 |
| LangChain Open Deep Research | https://blog.langchain.com/open-deep-research/ | Vendor | 2025 |
| AI Hallucination Stats 2026 | https://suprmind.ai/hub/insights/ai-hallucination-statistics-research-report-2026/ | Synthesis | 2026 |
| Stanford AI Index 2026 hallucination | https://explore.n1n.ai/blog/stanford-ai-index-2026-hallucination-engineering-2026-04-21 | Analysis | Apr 2026 |
| Characterizing Deep Research | https://arxiv.org/html/2508.04183v1 | Academic | 2025 |
| ResearchRubrics | https://arxiv.org/html/2511.07685v1 | Academic | 2025 |
| AI Benchmarks 2026 | https://kili-technology.com/blog/ai-benchmarks-guide-the-top-evaluations-in-2026-and-why-theyre-not-enough | Analysis | 2026 |
| Anthropic context engineering | https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents | Vendor | 2026 |

---

## 4. TOP 5 URLs TO FETCH

1. **https://arxiv.org/html/2601.08536** — DRB II full paper. Rubric categories, failure mode distribution. Most actionable for evaluation. (Jan 2026)
2. **https://arxiv.org/html/2601.22984v1** — "Why Your Deep Research Agent Fails?" PIES taxonomy with quantitative rates. (Jan 2026)
3. **https://arxiv.org/html/2604.05952** — Progressive Confidence Estimation. Per-claim architecture. (Apr 2026)
4. **https://arxiv.org/html/2602.07359** — W&D parallel tool calling ablations. Width vs. depth tradeoffs. (Feb 2026)
5. **https://arxiv.org/html/2601.17879v1** — Self-Manager Thread Control Blocks. Direct relevance to 4-agent design. (Jan 2026)

---

## 5. SUGGESTED FOLLOW-UPS

1. Self-Optimizing Multi-Agent Systems 2604.02988 — self-improvement loop design.
2. Inference-Time Scaling of Verification 2601.15808 — citation audit self-correction.
3. FS-Researcher ablations 2602.01566.
4. Detecting/Correcting Reference Hallucinations 2604.03173.
5. Towards Knowledgeable Deep Research 2604.07720.
6. Anthropic Claude research mode architecture 2026.
7. Deep research prompt injection web content defense 2026.
