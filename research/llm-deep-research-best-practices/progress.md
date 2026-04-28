# Deep Research Progress Tracker

**Topic:** How to best utilize LLMs for deep research (improve the deep-research skill)
**Slug:** llm-deep-research-best-practices
**Started:** 2026-04-26
**Strategy:** COMPLEX (4 dimensions, parallel sonnet agents)
**Status:** COMPLETE — report at findings/report.md, audit at validation/citation-audit.md
**Recency window:** last 3 months (Feb–Apr 2026)
**Source mix:** engineering write-ups + academic, equally weighted

## Dimensions
| # | Dimension | Status | Artifact | Notes |
|---|-----------|--------|----------|-------|
| 1 | Multi-agent orchestration | DONE | websearch/01-multi-agent-orchestration.md | role design, parallelism, coordination, single vs multi |
| 2 | Search strategy & query design | DONE | websearch/02-search-strategy.md | round-based, diversification, recency, rewriting |
| 3 | Grounding, citation & hallucination control | DONE | websearch/03-grounding-citation.md | verification, audit, source authority |
| 4 | Synthesis, evaluation & production lessons | DONE | websearch/04-synthesis-evals.md | report writing, evals, OpenAI/Gemini/Perplexity DR lessons |

## URL Fetch Status
| URL | Status | Artifact | Source Dimension |
|-----|--------|----------|-----------------|
| arxiv 2602.07359 (W&D) | DONE | fetched/01-wnd.html | D1+D4 |
| arxiv 2604.02460 (Stanford SAS vs MAS) | DONE | fetched/02-stanford-single-vs-multi.html | D1 |
| arxiv 2603.29632 (Empirical Multi-Agent) | DONE | fetched/03-empirical-multi-agent.html | D1 |
| arxiv 2603.04384 (AgentIR) | DONE | fetched/04-agentir.html | D2 |
| arxiv 2602.17518 (Picture of Agentic Search) | DONE | fetched/05-agentic-search-picture.html | D2 |
| arxiv 2603.07379 (SoK Agentic RAG) | DONE | fetched/06-sok-agentic-rag.html | D2 |
| arxiv 2604.03173 (Reference Hallucinations) | DONE | fetched/07-reference-hallucinations.html | D3 |
| arxiv 2602.23452 (CiteAudit) | DONE | fetched/08-citeaudit.html | D3 |
| arxiv 2601.22984 (PIES) | DONE | fetched/09-pies-why-dr-fails.html | D3+D4 |
| arxiv 2601.08536 (DRB II) | DONE | fetched/10-drb2.html | D4 |
| arxiv 2604.05952 (Progressive Confidence) | DONE | fetched/11-progressive-confidence.html | D4 |
| arxiv 2601.17879 (Self-Manager) | DONE | fetched/12-self-manager.html | D4 |
| Summary | DONE | fetched/abstracts-summary.md | all |

## Phase Completion
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
- [x] Phase 4
- [x] Phase 5
