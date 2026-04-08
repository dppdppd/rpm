---
name: deep-research
description: "Exhaustive multi-agent research on any topic. Parallel search, URL fetching, gap analysis, adversarial validation, citation check. Use when any task requires external knowledge before proceeding, or when the user asks for deep research on a topic."
argument-hint: "<research question or topic>"
allowed-tools: ["Read", "Write", "Bash(curl:*)", "Bash(mkdir:*)", "Agent", "WebSearch", "Glob", "Grep"]
---

# deep-research — Full Deep Research Protocol

Exhaustive multi-agent research on any topic. Invoked as a skill
(auto-triggered via description match), not a slash command.

**Research escalation rule:** During ANY /pm subcommand, if you encounter
a question requiring external knowledge, pause and offer to invoke the
`deep-research` skill before continuing.

## Design Principles

1. **Disk artifacts are source of truth.** Every phase writes to disk.
2. **Start simple, scale up.** Single-agent for narrow; multi-agent for broad. Max 4 concurrent.
3. **Search thoroughly but verify.** Every claim traces to a source.
4. **Agents NEVER fetch URLs.** Main session uses `curl -sL -m 60 "URL" | head -c 100000`.
5. **Agents NEVER create files.** Main session writes everything.
6. **Always `model: "sonnet"` for search agents.**
7. **Write the report once.** Revision causes 16-27% regression.

## Directory Structure

```
research/<topic-slug>/
├── progress.md
├── websearch/          # One file per dimension
├── fetched/            # Extracted URL content
├── gaps/               # Follow-up results
├── validation/         # Adversarial + citation audit
└── findings/report.md
```

## Phase 0: Setup

- Verify WebSearch + Bash permissions
- Live fetch test: `curl -sL -m 60 "https://addyosmani.com/blog/" | head -c 1000`
- Scan existing research for matches
- Clarify scope (1-3 questions if ambiguous)

## Phase 1: Scope & Decompose

- SIMPLE (1-3 dims): searches in main session
- COMPLEX (4+ dims): parallel sonnet agents, max 4 concurrent
- Present dimensions, wait for confirmation

## Phase 2: Parallel Discovery

**Agent prompt template:**
```
You are a research-only agent. ONLY use WebSearch.
FORBIDDEN: Write, Edit, Bash, Glob, Grep, Read, WebFetch, Agent.
Return your complete report as plain text.

QUESTION: {specific sub-question}

Run queries in two rounds:
ROUND 1: 5-6 broad queries with varied terminology
PAUSE: Review gaps, contradictions, new terms
ROUND 2: 4-6 targeted follow-ups

PRIORITIZE: official docs > papers > expert blogs > repos > news
Note CONTRADICTIONS — don't pick sides

Output: KEY FINDINGS (URL + Confidence H/M/L), CONTRADICTIONS,
ALL SOURCES, TOP 5 URLs TO FETCH, QUERIES USED, FOLLOW-UP suggestions
```

## Phase 3: URL Fetching

Minimums per dimension: Quick 1-2, Focused 2-3, Deep 3-5.
Fetch with curl. Replace failures from priority list. Post-fetch: check
for better URLs in fetched content.

## Phase 4: Gap Analysis & Validation

Must produce: `$TOPIC/gaps/` file + `$TOPIC/validation/adversarial.md`.
- Gap analysis: LOW-confidence findings, contradictions, thin dims
- Adversarial: 3+ searches seeking counter-evidence
- Recency check: findings >18mo still current?
- Citation pre-audit: source URLs exist and match?

## Phase 5: Synthesis & Report

Write `$TOPIC/findings/report.md`. Tag findings: HIGH/MEDIUM/LOW.
Launch citation audit agent (foreground sonnet). Fix mismatches.
Present summary with confidence levels and link to report.

## Scaling Rules

| Type | Dims | Searches/Dim | URLs/Dim | Agents |
|------|------|-------------|----------|--------|
| Quick | 1-2 | 3-5 | 1-2 | None |
| Focused | 2-4 | 5-8 | 2-3 | 1/dim sonnet |
| Deep | 4+ | 8-12 | 3-5 | 1/dim sonnet, max 4 |
