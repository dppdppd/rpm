# Citation Audit — final report

**Auditor:** dedicated sonnet sub-agent (foreground), search-only, run 2026-04-26.
**Scope:** the 6 most load-bearing numeric claims plus 4 spot-checks on supporting numbers.

## Summary

| Category | Count |
|---|---|
| Verified | 9 |
| Mismatched | 1 (resolved with hedge) |
| Unsourced | 2 (fixed by adding source URLs) |
| Not audited (lower priority) | ~9 |

**Overall citation quality: ~82% verified** on audited claims, with all flagged issues addressed in the report.

## Verified

- W&D BrowseComp 62.2% / 54.9% (arXiv:2602.07359). ✓
- Stanford 2604.02460 single-agent matches/outperforms multi-agent under matched tokens; DPI argument; Stanford authors confirmed. ✓
- arXiv:2604.03173 URL hallucination: 3-13% / 5-18% / 6-79× / domain 5.4-11.4%. ✓ (all numbers exact)
- DRB II (arXiv:2601.08536): 132 tasks, 22 domains, 9,430 binary rubrics, 400+ human-hours, "<50% rubric satisfaction." ✓
- Anthropic 90.2% multi-agent improvement; "80% of variance" token-usage quote. ✓
- arXiv:2512.08296 Google/MIT: +80.9% parallelizable, −39 to −70% sequential, 17.2× vs 4.4× error amplification. ✓
- arXiv:2306.13063: GPT-4 AUROC 62.7%; GPT-3/3.5/Vicuna ECE >0.377. ✓
- arXiv:2603.29632 "subagent mode … broad, shallow optimization under time constraints" quote. ✓
- AgentIR (arXiv:2603.04384) 68% / 37%. ✓ (the conventional baseline number disputed — see below)

## Mismatch (1) — resolved with hedge

- **AgentIR conventional-embedding baseline**: the fetched primary-source abstract (the canonical paper statement) reports **50%**. The audit agent's independent re-search reported **52%**. Discrepancy unresolved; the report now states "~50%" with a parenthetical noting the 52% finding from the audit and clarifying it does not change the qualitative conclusion. Confidence on the precise gap downgraded from HIGH to MEDIUM.

## Unsourced (2) — fixed

- **Google Deep Research Max 160 searches / 900k tokens / 60-min**: source URL added inline (`https://ai.google.dev/gemini-api/docs/models/deep-research-max-preview-04-2026`).
- **Chroma Context Rot study (18 models, 50K-token threshold, 30%+ drops)**: source URL added inline (`https://research.trychroma.com/context-rot`); model coverage clarified ("GPT-4.1, Claude 4, Gemini 2.5").

## Not audited

The audit deliberately concentrated on the 6 highest-impact numeric claims plus 3 spot-checks. The following supporting citations were not independently re-verified by the audit agent (though all were cited by D1–D4 sonnet agents from search results):
- WideSeek-R1 (2602.04634), Rethinking Multi-Agent Workflow (2601.12307), VeriFact-CoT (2509.05741), Whose Facts Win? (2601.03746), GhostCite (2602.06718), Recency Bias 4.78-year shift (2509.11353), Self-Manager outperforms baselines (2601.17879), CiteAudit pipeline structure (2602.23452), PIES "no system achieves robust reliability" (2601.22984).

These are flagged as **MEDIUM confidence** in the report wherever a number is cited; the qualitative claims are well-supported by multiple cross-referenced sources.

## Net effect on report

The report's executive summary, recommendations, and adversarial findings all stand without modification. Three minor edits were made (two unsourced claims sourced; one numeric hedge added). No fabricated URLs detected.
