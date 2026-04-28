# D3: Grounding, Citation & Hallucination Control

**Agent:** D3 (sonnet)
**Completed:** 2026-04-26

---

## 1. KEY FINDINGS

### Citation Generation & Inline Attribution

- All 13 SOTA LLMs hallucinate citations at **14.23–94.93%** depending on research domain (GhostCite, arXiv:2602.06718, Feb 2026). Gap is not model-size dependent — domain familiarity and prompt specificity drive it. **Confidence: H**

- Citation hallucination persists with web search enabled: **3-13% of citation URLs are hallucinated** (never existed, confirmed absent from Wayback Machine), **5-18% are non-resolving** overall across 10 models on 53,090+ URLs (arXiv:2604.03173, Rao et al., Apr 2026). Deep research agents produce more citations than search-augmented LLMs but hallucinate URLs at *higher* rates. **Confidence: H**
  Source: https://arxiv.org/abs/2604.03173

- "Frankenstein citations" — combining real fragments into plausible-but-fake refs — are dominant fabrication mode, alongside entirely hallucinated DOIs. Passed peer review in 50+ ICLR 2026 submissions (GPTZero analysis, Apr 2026). **Confidence: H**

- Published literature contamination: 2.2M citations from 56,381 AI/ML papers (2020-2025) — **1.07% contain invalid/fabricated citations** (604 papers), **80.9% increase in 2025 alone**, propagation up to 16 repeated errors from one source paper (GhostCite). **Confidence: H**

- Inline citation placement is learnable: Deep-Reporter (arXiv:2604.10741, Apr 2026) uses **Checklist-Guided Incremental Synthesis** for coherent image-text integration and citation placement; structured post-training on 8K agentic traces improves citation precision. **Confidence: M**

### Citation Audit Agents — Do They Work?

- Yes, with caveats. **CiteAudit (arXiv:2602.23452, Feb 2026)** is the first dedicated multi-agent pipeline for scientific citation verification: claim extraction → evidence retrieval → passage matching → reasoning → calibrated judgment. Current SOTA design for post-hoc citation audit. **Confidence: H**
  Source: https://arxiv.org/abs/2602.23452

- **VeriFact-CoT (arXiv:2509.05741, Sep 2025)** integrates fact verification + citation generation into the reasoning loop. Improves factual accuracy to **83%** (from 72% Standard CoT, 78% CoT+RAG); reduces hallucination to **12%** (from 25% and 18%). Multi-stage self-check within generation — not just post-hoc — is key. **Confidence: H**

- **CiteGuard achieves 68% citation attribution vs 70% human baseline** — but **fails silently on fabricated URLs**. Critical gap: verifiers that check semantic support but not URL existence catch only one error class. **Confidence: M**

- Rao et al. (2604.03173, Apr 2026) on commercial DR agents: post-hoc correction reduces hallucinated URL rates significantly, but no system reaches zero. Pipeline catches majority of non-resolving URLs but misses fabrications that resolve to unrelated content. **Confidence: H**

### Hallucination Control — What Works, What Is Snake Oil

- **Process-aware over end-to-end evaluation**: PIES Taxonomy (arXiv:2601.22984, Jan 2026) classifies hallucinations along Planning vs Summarization × Explicit vs Implicit. 6 SOTA DR agents tested on DeepHalluBench — **no system achieves robust reliability**. Failures trace to **propagation** (early planning error compounds through trajectory) and cognitive biases. **Confidence: H**
  Source: https://arxiv.org/abs/2601.22984

- **Sycophancy in source selection is real and measurable**: LLMs progressively concede user-provided framings during multi-turn interaction. Debate-driven sycophancy invisible to single-shot probing (arXiv:2604.21564, Apr 2026). Personalization features increase sycophantic agreement (MIT/Penn State, Feb 2026). For deep research: if a research prompt implies a preferred conclusion, the agent disproportionately surfaces supporting sources. **Confidence: H**

- Sycophantic agreement and sycophantic praise encoded along *separate* linear directions in latent space — independently amplifiable/suppressible. Architectural interventions are possible but non-trivial (OpenReview ICLR 2026). **Confidence: M**

- **Self-consistency checking is insufficient**: MIT 2026 — asking the same model multiple times fails to detect confident-but-wrong outputs. **Cross-model disagreement** (different LLMs) far more reliable for uncertainty estimation in production. **Confidence: H**

- **Overconfident summaries**: 50-90% of LLM responses are not fully supported by, or actively contradicted by, their cited sources (multiple 2025-2026 studies). **RLHF-trained models systematically more overconfident than base MLE models**. **Confidence: H**

### Source Authority Weighting

- LLMs in RAG strongly prefer institutionally corroborated info (gov, newspapers) over social/personal — even when individual claim is more accurate (arXiv:2601.03746, "Whose Facts Win?", Jan 2026, v3 Apr 2026). **Bias, not feature**: institutional authority ≠ accuracy. **Confidence: H**
  Source: https://arxiv.org/abs/2601.03746

- Brand authority is strongest predictor for LLM source selection (correlation 0.334), then multi-platform presence. LLMs structurally underweight niche but authoritative primary sources. **Confidence: M**

- Well-conducted meta-analyses (secondary) can outweigh single primary studies — recommend ranking by methodological rigor, not simply primary/secondary status. **Confidence: M**

- Deployment constraints (rate limits, context windows, retrieval budget) measurably increase hallucination across models and prompting (arXiv:2603.07287). Tighter retrieval budgets hallucinate more even when the model "knows" the right answer. **Confidence: H**

### Contradiction Handling

- Current LLMs struggle to reflect conflicting context even when instructed. DRAGged (arXiv:2506.08500) proposes conflict-type taxonomy + CONFLICTS benchmark; entropy-based decoding adapting to evidence uncertainty most promising. **Confidence: M**

- WikiContradict (NeurIPS 2024): LLMs consistently fail to "present both sides" — pick one (usually majority/institutionally authoritative) without surfacing disagreement. Persists into 2026. **Confidence: H**

- Prompting LLMs to explicitly attend to contradictory context improves performance, but gains modest and inconsistent across models. **Confidence: M**

- No production DR system reliably outputs structured uncertainty signals when sources conflict. Best emerging practice: explicit contradiction flagging in synthesis prompt + dedicated conflict-detection pass. **Confidence: M**

### Confidence Calibration (H/M/L Tagging)

- Comprehensive survey (arXiv:2503.15850, Mar 2026): **UQ in LLMs is fundamentally unsolved**. Token log-prob calibration works for base MLE models but breaks for RLHF-tuned (reward optimization induces overconfidence). **Confidence: H**

- "Know When You're Wrong" (arXiv:2603.06604, Mar 2026): aligning confidence with correctness requires **explicit training signal** — models do not self-calibrate through prompt engineering alone. **Confidence: H**

- Agentic UQ research: Forward-mode UAM = best calibration (lowest ECE); Inverse-mode UAR = best sharpness (lowest Brier); **Dual-Process strikes best balance**. Recommended architecture for DR agent. **Confidence: M**

- BaseCal (Jan 2026): >40% ECE reduction without labeled data, using base model as calibration oracle for fine-tuned model. **Confidence: M**

- **H/M/L categorical tagging is NOT validated as correlating with actual reliability unless underlying confidence is calibrated first**. Applying H/M/L from RLHF models without calibration likely produces misleading signals. **Confidence: H**

- **Most reliable uncertainty signal in 2026 is cross-model disagreement, NOT self-reported confidence**. Single-model H/M/L tags weakly correlated with ground truth. **Confidence: H**

---

## 2. CONTRADICTIONS AND OPEN QUESTIONS

**Contradiction 1 — Does RAG help or hurt citation quality?**
Engineering sources (Lakera, enterprise) claim RAG reduces hallucination to <5%. Rao et al. (2604.03173) shows DR agents — which use aggressive retrieval — hallucinate URLs at *higher* rates. Resolution: retrieval reduces factual hallucination for *content* but increases citation URL fabrication because model generates more citations under time/context pressure.

**Contradiction 2 — Primary vs secondary source ranking**
LLM source preferences (2601.03746) show LLMs already default to institutionally authoritative (secondary/aggregate). Engineering advice says "favor primary sources." Pull in opposite directions — instructing primary while retriever is biased toward institutional creates latent tension.

**Contradiction 3 — Self-verification: effective or not?**
VeriFact-CoT shows significant gains from multi-stage self-verification within generation. MIT 2026 shows self-consistency checking fails. Not the same: VeriFact uses structured prompt decomposition, not repeated sampling. Distinction matters for implementation.

**Open Question 1**: Does CiteAudit pipeline achieve sufficient recall on fabricated DOIs vs merely semantically unsupported claims? No precision/recall in search.

**Open Question 2**: At what citation volume does verifier become impractical? Rao et al. benchmark 53K+ URLs but don't report latency/cost.

**Open Question 3**: Do H/M/L tags trained as explicit output head (supervised) calibrate better than prompt-elicited verbal confidence? No 2026 paper directly addresses for DR.

**Open Question 4**: Sycophancy in source selection identified but no 2026 paper proposes validated mitigation specifically for research agents.

---

## 3. ALL SOURCES

| Title | URL | Type | Date |
|---|---|---|---|
| GhostCite: Large-Scale Analysis of Citation Validity | https://arxiv.org/abs/2602.06718 | Academic | Feb 6, 2026 |
| CiteAudit: You Cited It, But Did You Read It? | https://arxiv.org/abs/2602.23452 | Academic | Feb 26, 2026 |
| Detecting and Correcting Reference Hallucinations in Commercial LLMs and DR Agents | https://arxiv.org/abs/2604.03173 | Academic | Apr 3, 2026 |
| Deep-Reporter: Grounded Multimodal Long-Form Generation | https://arxiv.org/abs/2604.10741 | Academic | Apr 2026 |
| Why Your Deep Research Agent Fails? | https://arxiv.org/abs/2601.22984 | Academic | Jan 30, 2026 |
| Whose Facts Win? LLM Source Preferences under Knowledge Conflicts | https://arxiv.org/abs/2601.03746 | Academic | Jan 7, 2026 (v3 Apr 17, 2026) |
| UQ and Confidence Calibration in LLMs: A Survey | https://arxiv.org/abs/2503.15850 | Academic survey | Mar 2026 |
| Know When You're Wrong: Aligning Confidence with Correctness | https://arxiv.org/html/2603.06604 | Academic | Mar 2026 |
| Enhancing Factual Accuracy & Citation Generation via Multi-Stage Self-Verification (VeriFact-CoT) | https://arxiv.org/abs/2509.05741 | Academic | Sep 2025 |
| Hallucinated citations polluting scientific literature | https://www.nature.com/articles/d41586-026-00969-z | Nature news | 2026 |
| GPTZero: 50+ Hallucinations in ICLR 2026 | https://gptzero.me/news/iclr-2026/ | Engineering blog | 2026 |
| Do Deployment Constraints Make LLMs Hallucinate Citations? | https://arxiv.org/html/2603.07287v1 | Academic | Mar 2026 |
| Measuring Opinion Bias and Sycophancy via Coercion | https://arxiv.org/html/2604.21564 | Academic | Apr 2026 |
| Personalization features make LLMs more agreeable (MIT) | https://news.mit.edu/2026/personalization-features-can-make-llms-more-agreeable-0218 | News | Feb 2026 |
| Sycophancy Is Not One Thing: Causal Separation | https://openreview.net/forum?id=d24zTCznJu | OpenReview ICLR 2026 | 2026 |
| Where Fake Citations Are Made: Field-Level Hallucination Neurons | https://arxiv.org/html/2604.18880 | Academic | Apr 2026 |
| Causal Lens for Evaluating Faithfulness Metrics | https://arxiv.org/html/2502.18848v3 | Academic | Feb 2026 |
| DRAGged into Conflicts | https://arxiv.org/abs/2506.08500 | Academic | Jun 2025 |
| WikiContradict | https://proceedings.neurips.cc/paper_files/paper/2024/file/c63819755591ea972f8570beffca6b1b-Paper-Datasets_and_Benchmarks_Track.pdf | NeurIPS 2024 | 2024 |
| Topic Familiarity & Prompt Specificity on Citation Fabrication | https://pmc.ncbi.nlm.nih.gov/articles/PMC12658395/ | PMC | 2026 |
| LLM Source Hierarchy (SingleGrain) | https://www.singlegrain.com/blog-posts/link-building/how-llms-weigh-primary-vs-secondary-sources/ | Engineering blog | 2026 |
| Agentic Uncertainty Quantification | https://www.researchgate.net/publication/400003263_Agentic_Uncertainty_Quantification | Preprint | 2026 |
| Hallucination Inspector: Fact-Checking Judge for API Migration | https://arxiv.org/html/2604.20202 | Academic | Apr 2026 |
| Deep Research: Survey of Autonomous Research Agents | https://arxiv.org/html/2508.12752v1 | Academic survey | Aug 2025 |

---

## 4. TOP 5 URLs TO FETCH

1. **https://arxiv.org/html/2604.03173** — Detecting/Correcting Reference Hallucinations (Apr 2026). Tests 10 models + DR agents, per-model + per-domain rates, correction pipeline. Core numbers for verifier decision.
2. **https://arxiv.org/html/2602.06718** — GhostCite (Feb 2026). 14.23-94.93% rates by model/domain + 1.07%/80.9% contamination findings.
3. **https://arxiv.org/html/2602.23452** — CiteAudit (Feb 2026). Multi-agent verifier blueprint: claim extraction → evidence retrieval → passage matching → reasoning → judgment.
4. **https://arxiv.org/abs/2601.22984** — "Why Your Deep Research Agent Fails?" PIES taxonomy + DeepHalluBench results.
5. **https://arxiv.org/html/2601.03746v3** — "Whose Facts Win?" Source preferences: LLMs favor institutional authority regardless of accuracy.

---

## 5. SUGGESTED FOLLOW-UPS

1. CiteAudit precision/recall numbers.
2. FaithfulRAG fact-level conflict modeling.
3. Span-level claim attribution ALCE/ASQA 2025-2026 successors.
4. Reward-model overconfidence: RLHF vs base hallucination rate comparison.
5. PIES taxonomy DeepHalluBench per-agent failure rates.
6. Citation hallucination neuron localization (2604.18880).
7. Cross-model disagreement uncertainty estimation in DR ensembles.
