# Plan — Improve rpm:deep-research (token-cheap evaluation via the existing research corpus)

Source: 2026-05-30 rpm-vs-native bake-off + process-gap analysis.
Companion: `2026-05-30-deep-research-native-overlap.md` (Tier 3 verdict).

## Why

The bake-off showed native `/deep-research` matched/edged rpm on rigor through a
tight verification core, and — more uncomfortably — that **rpm's prose claimed
discipline it did not always execute** (the specimen shipped ƒ134M/ƒ219M figures
whose cited sources don't contain them). We've already hardened the skill (kill-list,
refuted section, source-tiering, active-refutation verify). Two things remain:

1. **Verify the fix actually changes behavior** (prose ≠ behavior — that's the whole lesson).
2. **Find more gaps** — in rpm *and* native — without burning tokens re-running
   2.7M-token research arms.

**Governing principle:** a gap is not real until a test exercises it and the
pipeline fails. Grade rpm exactly as hard as native. Trust nothing prose merely claims.

## The asset: a pre-paid evaluation corpus

`/home/coder/projects/*/docs/research/` holds **57 completed research trees**
(VOC ×28, draftyard ×26, + tricks/reddit/volta), **~51 of which still retain their
`fetched/` sources** — **740 cached artifacts** total (457 html, 191 md, 63 pdf, 28 txt).

Each tree is a *labeled example of deep-research output paired with its source
corpus*: `findings/report.md` + `fetched/<sources>` + `validation/` + `gaps/`. That
pairing is what makes offline evaluation possible — we can check every claim in a
report against the very sources it was built from, with **zero new research tokens.**
Domain spread (history / software-UX / game-design / social) gives failure-mode
breadth for free.

## Evaluation methodology — cheapest first

### Tier 1 — Offline citation audit (0 research tokens) ← do this first
For each of the ~51 trees with `fetched/`:
1. Extract every **quantitative** claim from `report.md` + its cited URL/source.
2. Resolve the citation to a local `fetched/` artifact; check the figure actually
   **appears** there — deterministic string/grep match first; a light LLM
   semantic-match pass *only* on the misses.
3. Tag each figure: `supported` / `frankenstein` (cited source lacks it) /
   `tertiary-only` / `uncited`.

**Output:** per-report and aggregate **unsupported-figure rate** — the real,
many-run baseline the fix must beat (replaces our n=1 read). Tooling: extend
`docs/rpm/research/dr-bakeoff/checks/` with an `offline_audit.sh` + small LLM matcher.

### Tier 2 — Replay the hardened phases over cached sources (cheap; no search/fetch)
Take a tree's `fetched/` as a *frozen* input and run ONLY the new verify (kill-list +
active-refutation, against cached artifacts + minimal web) and synthesize discipline.
Diff the "hardened report" against the original.

**Measures:** would the fix have *caught* the figures the original shipped? does it
*over-kill* true claims? Skips the token-heavy search+fetch entirely — the expensive
part of deep-research — so a full re-evaluation costs a fraction of a real run.

### Tier 3 — Live failure-mode probes (reserved; only what offline can't reach)
A few modes need a live run: **injection** (Module B canary), **scope-decomposition**,
**recency**. Run these sparingly, on topics we already hold baselines for (VOC), so
grading stays cheap. Everything else (fabrication-bait, coverage/truncation,
contradiction-handling, empty-set, citation-support) is measurable offline via Tier 1/2.

### Cross-tree consistency (0 tokens)
Adjacent trees share figures (the VOC cluster especially). Disagreement across trees
on the same fact flags instability/error for free.

## Improvement backlog (each gated by the offline metric)

| # | Change | Status | Eval that proves it |
|---|--------|--------|---------------------|
| 1 | Citation discipline + kill-list + refuted section + source-tiering + active-refutation verify | **DONE** (skill, 2026-05-30) | Tier 1 baseline vs Tier 2 replay |
| 2 | Instrument silent drops — log dropped/unverified claims (don't inherit native's silent 47/72 truncation) | TODO | Tier 2: dropped-claim count surfaced |
| 3 | Number-provenance gate — confirm each figure literally appears in the fetched artifact (promote the Tier-1 check into a skill phase) | TODO | Tier 1 rate ↓ |
| 4 | Perspective-diverse verification — distinct lenses per verifier, not identical skeptics (native's correlated-voter weakness) | TODO | Tier 2: over-kill rate ↓ |
| 5 | Post-synthesis citation audit — synthesis cannot introduce unverified figures | TODO (partial in Phase 5) | Tier 2: synth-introduced figures = 0 |
| 6 | CC-workflow handoff — optional codified enforcement on CC (Tier 3/4 of ultracode eval) | TODO | live A/B on one probe |
| 7 | Module B injection test — validate rpm Principle 8 AND probe native (no fetch-sanitization) | TODO | Tier 3 live, canary token |

## Validation gate

Promote/release a change only when it **lowers the offline unsupported-figure rate**
on the corpus **without raising over-kill** (true-claim survival must hold). Re-grade
offline after every skill edit; the corpus is rpm:deep-research's permanent regression suite.

## Token budget

- Tier 1 + Tier 2 + cross-tree: **~0 research tokens** (cached sources; light LLM only
  on audit-misses and replay-synthesis).
- Tier 3: a handful of live runs, reserved for inherently-live modes, on pre-baselined topics.

## Risks / limits

- **~6 trees have no `fetched/`** → not citation-auditable (can still grade
  report-internal honesty).
- Offline audit tests *what the pipeline did with sources*, **not search/fetch
  quality** (what it FOUND) — search-quality gaps need live or metamorphic runs.
- Corpus skews to the user's domains (VOC/draftyard); the Tier-3 battery adds breadth.
- Replay (Tier 2) re-grades synthesis/verification but assumes the *cached* sources
  are representative — it cannot surface a source the original run never fetched.

## First step

Build `offline_audit.sh` (Tier 1) and run it across the ~51 trees → establish the
pre-fix baseline unsupported-figure rate. Everything else sequences off that number.

## Baseline result (2026-05-30) — Tier-1 deterministic screen

- Tool: `dr-bakeoff/checks/offline_audit.py`; raw output `checks/baseline-2026-05-30.txt`.
- **Validated against the blind grader:** on `voc-decline-era` it flagged **ƒ134M orphan**
  (the grader's "agent-sourced" figure) and **spared ƒ219M** (which *is* in the Gutenberg
  source) — the ~0-token screen independently agrees with the expensive grader.
- **Baseline:** figure-dense searchable subset = **7 trees, 16 distinctive (≥3-digit/decimal)
  figures → 9 orphan = 56%** absent from their own cached sources (voc-decline 2/3 = 67%).
  Deterministic **lower bound**. Zero research tokens.
- **Limits found empirically:** reliable only for ≥3-digit/decimal figures — 2-digit cores
  (43, 62) match coincidentally in a large corpus and falsely read as "present" (broadening
  to 2-digit wrongly dropped voc-decline to 13%). Most non-history trees have few money
  figures or thin/PDF-only corpora, so the metric bites mainly on quantitative-history reports
  — which is exactly where the failure lives.
- **Next Tier-1 increment:** a light LLM semantic pass over the orphans + 2-digit figures
  (confirm true-unsupported + in-context support), cached-source-only.
- **Implication:** the citation-discipline failure is **pervasive (≥56% on figure-dense
  reports), not n=1** — this is the number the hardened skill must beat, measured via Tier-2 replay.
