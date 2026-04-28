# Fetched Abstracts — Verified Primary-Source Claims

Source: arXiv abstract pages, fetched 2026-04-26 via curl.
Each entry below is verbatim-grounded in the cited paper's official abstract.

---

## 1. W&D (arXiv:2602.07359) — D1 + D4
**Title:** W&D: Scaling Parallel Tool Calling for Efficient Deep Research Agents
**Date:** 2026-02-07
**Verified claims:**
- Width scaling = parallel tool calling within a single reasoning step.
- Position: "Unlike existing approaches that rely on complex multi-agent orchestration to parallelize workloads, our method leverages intrinsic parallel tool calling to facilitate effective coordination within a single reasoning step."
- **62.2% accuracy with GPT-5-Medium on BrowseComp, surpassing 54.9% reported by GPT-5-High**, "without context management or other tricks."
- Optimizing width × depth tradeoff is critical pathway.

## 2. Stanford SAS vs MAS (arXiv:2604.02460) — D1
**Title:** Single-Agent LLMs Outperform Multi-Agent Systems on Multi-Hop Reasoning Under Equal Thinking Token Budgets
**Date:** 2026-04-02
**Verified claims:**
- Information-theoretic argument from Data Processing Inequality: under fixed reasoning-token budget with perfect context utilization, single-agent is more information-efficient.
- Tested on Qwen3, DeepSeek-R1-Distill-Llama, Gemini 2.5.
- "SAS consistently match or outperform MAS on multi-hop reasoning tasks when reasoning tokens are held constant."
- Identifies API-based budget control artifacts (especially Gemini 2.5) and benchmark artifacts that inflate apparent MAS gains.
- Conclusion: many reported MAS advantages "better explained by unaccounted computation and context effects rather than inherent architectural benefits."

## 3. Empirical Multi-Agent (arXiv:2603.29632) — D1
**Title:** An Empirical Study of Multi-Agent Collaboration for Automated Research
**Date:** 2026-03-31
**Verified claims:**
- Three architectures benchmarked under fixed compute time: single-agent baseline, subagent (parallel exploration + post-hoc consolidation), agent team (experts + pre-execution handoffs).
- **Subagent mode**: "highly resilient, high-throughput search engine optimal for broad, shallow optimizations under strict time constraints."
- **Agent team**: "higher operational fragility due to multi-author code generation but achieves the deep theoretical alignment necessary for complex architectural refactoring given extended compute budgets."
- Recommendation: dynamically routed architectures that adapt to real-time task complexity.

## 4. AgentIR (arXiv:2603.04384) — D2
**Title:** AgentIR: Reasoning-Aware Retrieval for Deep Research Agents
**Date:** 2026-03-04
**Verified claims:**
- Two contributions: Reasoning-Aware Retrieval (jointly embeds reasoning trace + query); DR-Synth (data synthesis from QA datasets).
- AgentIR-4B on BrowseComp-Plus with Tongyi-DeepResearch: **68% accuracy**.
- Conventional embedding model 2x size: **50%** (D2 agent said 52% — minor mismatch, abstract says 50%).
- BM25: **37%**.

## 5. A Picture of Agentic Search (arXiv:2602.17518) — D2
**Title:** A Picture of Agentic Search
**Date:** 2026-02-19
**Verified claims:**
- IR is human-centred; agentic systems break assumptions on workload volume, predictability, querying.
- ASQ dataset: 3 diverse agents, 2 retrieval pipelines, queries on HotpotQA, Researchy Questions, MS MARCO.
- Includes reasoning-induced queries, retrieved documents, agent thoughts.
- Caching may lose effectiveness; query pre-processing may add overhead without improving results; standard metrics may mismeasure satisfaction in agentic context.

## 6. SoK Agentic RAG (arXiv:2603.07379) — D2
**Title:** SoK: Agentic Retrieval-Augmented Generation (RAG): Taxonomy, Architectures, Evaluation, and Research Directions
**Date:** 2026-03-07
**Verified claims:**
- Formalizes agentic retrieval-generation loops as **finite-horizon partially observable Markov decision processes**.
- Taxonomy across planning mechanisms, retrieval orchestration, memory paradigms, tool-invocation behaviors.
- Identified systemic risks: **compounding hallucination propagation, memory poisoning, retrieval misalignment, cascading tool-execution vulnerabilities**.
- Future directions: stable adaptive retrieval, cost-aware orchestration, formal trajectory evaluation, oversight mechanisms.

## 7. Reference Hallucinations (arXiv:2604.03173) — D3
**Title:** Detecting and Correcting Reference Hallucinations in Commercial LLMs and Deep Research Agents
**Date:** 2026-04-03
**Verified claims:**
- 10 models on DRBench (53,090 URLs); 3 models on ExpertQA (168,021 URLs across 32 academic fields).
- **3-13% of citation URLs are hallucinated** (no Wayback record, "likely never existed").
- **5-18% are non-resolving overall**.
- "Deep research agents generate substantially more citations per query than search-augmented LLMs but hallucinate URLs at higher rates."
- Domain effects: non-resolving rates from **5.4% (Business) to 11.4% (Theology)**.
- Some models fabricate every non-resolving URL; others show link-rot fractions indicating genuine retrieval.
- **urlhealth tool** (open-source) for liveness checking + stale-vs-hallucinated classification.
- Agentic self-correction: **6-79× reduction in non-resolving URLs to under 1%**, depending on model's tool-use competence.

## 8. CiteAudit (arXiv:2602.23452) — D3
**Title:** CiteAudit: You Cited It, But Did You Read It? A Benchmark for Verifying Scientific References in the LLM Era
**Date:** 2026-02-26
**Verified claims:**
- First comprehensive benchmark + detection framework for hallucinated citations.
- Multi-agent pipeline: **claim extraction → evidence retrieval → passage matching → reasoning → calibrated judgment**.
- Hallucinated citations "already observed in submissions and accepted papers at major machine learning venues."
- Significantly outperforms prior methods in accuracy and interpretability.

## 9. PIES / Why DR Fails (arXiv:2601.22984) — D3 + D4
**Title:** Why Your Deep Research Agent Fails? On Hallucination Evaluation in Full Research Trajectory
**Date:** 2026-01-30
**Verified claims:**
- Shift from outcome-based to **process-aware evaluation** by auditing full research trajectory.
- **PIES Taxonomy**: Planning vs Summarization × Explicit vs Implicit (4 categories).
- **DeepHalluBench**: 100 distinctively hallucination-prone tasks including adversarial.
- 6 SOTA Deep Research Agents tested: **"no system achieves robust reliability."**
- Failures trace to **hallucination propagation** and **cognitive biases**.
- Code: github.com/yuhao-zhan/DeepHalluBench

## 10. DRB II (arXiv:2601.08536) — D4
**Title:** DeepResearch Bench II: Diagnosing Deep Research Agents via Rubrics from Expert Report
**Date:** 2026-01-13
**Verified claims:**
- 132 grounded research tasks across 22 domains.
- **9,430 fine-grained binary rubrics** total.
- Three dimensions: information recall, analysis, presentation.
- Rubrics derived from expert-written investigative articles via 4-stage LLM+human pipeline.
- **400+ human-hours** of expert review.
- "Even the strongest models satisfy fewer than 50% of the rubrics, revealing a substantial gap between current DRSs and human experts."

## 11. Progressive Confidence (arXiv:2604.05952) — D4
**Title:** Towards Trustworthy Report Generation: A Deep Research Agent with Progressive Confidence Estimation and Calibration
**Date:** 2026-04-07
**Verified claims:**
- "Existing evaluation frameworks—typically based on subjective dimensions—fail to capture a critical aspect of report quality: trustworthiness."
- Deliberative search model with deep retrieval + multi-hop reasoning, grounding outputs in verifiable evidence.
- **Confidence scores assigned to individual claims** (per-claim, not per-section).
- Substantially improves interpretability + significantly increases user trust.

## 12. Self-Manager (arXiv:2601.17879) — D4
**Title:** Self-Manager: Parallel Agent Loop for Long-form Deep Research
**Date:** 2026-01-25
**Verified claims:**
- Existing agents constrained to "single context window and sequential execution paradigm" — mutual interference, blocking, restricted scalability.
- **Thread Control Blocks** for asynchronous, concurrent subthread execution.
- Each subthread has isolated context.
- "Consistently outperforms existing single-agent loop baselines across all metrics" on DeepResearch Bench.

---

## CITATION-AUDIT VERIFICATION — agent claims vs primary sources

| Agent claim | Primary source check | Status |
|---|---|---|
| W&D 62.2% GPT-5-Med vs 54.9% GPT-5-High on BrowseComp | Abstract confirms exactly | ✓ Verified |
| Stanford DPI argument, 3 model families | Abstract confirms exactly | ✓ Verified |
| AgentIR 68% / 52% / 37% (D2 claim) | Abstract: 68% / 50% / 37% | ⚠ Conventional baseline is 50%, not 52% |
| DRB II 9,430 rubrics, 132 tasks, 22 domains | Confirmed | ✓ Verified |
| DRB II <50% rubric satisfaction | Confirmed exactly | ✓ Verified |
| PIES taxonomy 4 categories | Confirmed | ✓ Verified |
| 6 SOTA DRAs on DeepHalluBench, "no system achieves robust reliability" | Confirmed | ✓ Verified |
| Reference hallucinations 3-13% / 5-18% / per-domain 5.4-11.4% | Confirmed | ✓ Verified |
| urlhealth: 6-79× reduction in non-resolving URLs | Confirmed | ✓ Verified |
| CiteAudit 5-stage pipeline (claim extraction → retrieval → matching → reasoning → judgment) | Confirmed | ✓ Verified |
| Self-Manager Thread Control Blocks, isolated context per subthread | Confirmed | ✓ Verified |
| Self-Manager "consistently outperforms single-agent loop baselines on DeepResearch Bench" | Confirmed | ✓ Verified |
| Empirical Multi-Agent: subagent mode optimal for broad/shallow under time constraint | Confirmed | ✓ Verified |
| Progressive Confidence: per-claim confidence | Confirmed | ✓ Verified |
| SoK Agentic RAG: POMDP formalization, identified compounding hallucination propagation as systemic risk | Confirmed | ✓ Verified |
| AgentIR uses Tongyi-DeepResearch agent (not just an embedding-only test) | Confirmed | ✓ Verified |

**Conclusion:** All cross-cutting D1-D4 claims used in the report are verifiable in primary-source abstracts. One minor numeric discrepancy (AgentIR conventional baseline) corrected.
