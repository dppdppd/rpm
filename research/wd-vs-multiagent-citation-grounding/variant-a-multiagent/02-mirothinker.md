# Variant A — MiroThinker (citation grounding)

**Agent:** Variant A sub-agent 2 (sonnet)
**Tokens:** 24,934
**Duration:** 168.5s
**Tool uses:** 12
**Rounds run:** 2

---

## KEY FINDINGS

- **Citations as byproduct of agentic search loop, not post-hoc formatter.** Web searches → reads pages → grounds claims in retrieved content. **Confidence: H** (arxiv 2511.11793)

- **MiroFlow v0.2 introduced "Core Research Report Generation"** with generation/preview/sharing. Markdown footnote/citation typesetting NOT explicitly documented. **Confidence: M**

- **MiroFlow framework includes "centralized citation management"** for reproducibility — "hybrid search, re-ranking, and centralized citation management to preserve reproducibility and traceability." Mentioned at framework level only, no implementation detail. **Confidence: M**

- **URL validation implicit via tool loop** — agent calls web search/browse tools in Linux sandbox, gets real HTTP responses. No dedicated URL-resolver / HTTP-200 verification pass before report output. **Confidence: M**

- **NO documented explicit citation-audit / URL-liveness step.** Local Verifier + Global Verifier audit reasoning chain + evidence coherence, NOT URL liveness or source authenticity. Training-time penalty for high-confidence-without-source, but not runtime URL resolver. **Confidence: H** (PR Newswire + paper)

- **Local Verifier + Global Verifier (H1)**: Local breaks probability bias at intermediate reasoning steps; Global audits complete evidence chain after trajectory, can trigger resampling. Neither checks source URL resolution. **Confidence: H** (arxiv 2603.15726)

- **Fabricated URLs: no explicit handling.** Implicit only — failed browsing tool returns error, agent trained to resample rather than fabricate. **Confidence: L**

- **MiroThinker-H1 ranks #1 on DeepResearchEval Report Quality (76.5)** vs OpenAI DR 76.4, Gemini-3.1-Pro DR 72.3. BrowseComp: H1 88.2, 1.7 74.0. **Confidence: H**

- **MiroFlow tool layer has automatic retry + fallback** — closest documented mechanism for non-resolving sources, but at tool-execution layer, not citation-audit layer. **Confidence: M**

## GAPS / CONTRADICTIONS

- Citation insertion mechanics not publicly documented (numbered? hyperlinked? appendix?).
- "Centralized citation management" coined but not specified.
- Training-time penalty ≠ runtime guarantee. No documented post-generation filter rejecting unverifiable citations.
- No third-party citation-accuracy audit of MiroThinker found.

## TOP 3 URLs TO FETCH

1. https://arxiv.org/pdf/2603.15726 (full H1 paper)
2. https://www.miromind.ai/blog/mirothinker-1.7-h1-towards-heavy-duty-research-agents-via-verification
3. https://github.com/MiroMindAI/MiroThinker/blob/main/apps/miroflow-agent/README.md

## ALL SOURCES

17 sources (arxiv 2511.11793, 2603.15726, 2602.22808; MiroMind blog; PR Newswire; GitHub; news outlets).
