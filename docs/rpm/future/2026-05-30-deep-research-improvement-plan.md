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

## Worker Result (2026-05-30, dr-verification-hardening)

**Summary.** Landed the verification-chain hardening bundle (backlog items #2, #3, #5)
as three concrete, observable gates in `plugin/skills/deep-research/SKILL.md`, converting
prose discipline into surfaced behavior (a logged count, a kill action keyed to the
offline orphan definition, and a hard post-synthesis assertion):

- **#2 Instrument silent drops (Phase 4).** New "Instrument every drop — no silent
  truncation" block: every dropped/unverified claim is appended to `refuted.md` with a
  reason code, a one-line **drop tally** (`DROPPED N/M …`) is written at the top of
  `refuted.md`, and that tally is carried into the Phase-5 final summary. Explicitly
  cites the native 47/72-silent-drop failure as the thing the gate prevents. A run that
  drops claims but reports a zero/absent count fails the gate.
- **#3 Number-provenance gate (Phase 4).** New "Number-provenance gate →
  `validation/figure-ledger.md`" block promotes the Tier-1 offline-audit check into a
  skill phase: a ledger of every distinctive figure (decimal or ≥3-sig-digit integer;
  2-digit cores must be confirmed by reading the source window, matching the audit's own
  coincidence caveat) with `figure | cited artifact | literal-presence Y/N | verdict`.
  Orphans (literal-presence N) and tertiary/amateur/model-memory-only figures are KILLED;
  a figure ships only as a Y-row with a primary source. The block names
  `dr-bakeoff/checks/offline_audit.py` as the suite running the identical check, so the
  gate is defined in the exact terms the regression metric measures.
- **#5 Post-synthesis citation audit (Phase 5).** New defense step 4: re-extract figures
  from the *written* report, diff against surviving ledger rows, and **assert
  `synth-introduced figures = 0`**. Any report figure absent from the surviving ledger is
  a hard FAILURE — trace-and-add or strike-to-refuted; result recorded in
  `figure-ledger.md` and carried into the final summary. "The run is not done until this
  count is zero." Also added a mandatory **Verification ledger line** (drop tally + orphan
  count + `synth-introduced figures: 0`) to the chat final summary so a silent truncation
  cannot hide.
- Directory Structure updated to list `figure-ledger.md` under `validation/`.

**Files changed.**
- `plugin/skills/deep-research/SKILL.md` (+49/−1): Directory Structure + Phase 4 (two new
  mandatory blocks) + Phase 5 (new post-hoc defense #4 + final-summary ledger line).
- `docs/rpm/future/2026-05-30-deep-research-improvement-plan.md` (this section).

**Verification run.**
- Reproduced baseline: `python3 docs/rpm/research/dr-bakeoff/checks/offline_audit.py` →
  `AGGREGATE (searchable): 9/16 distinctive figures ORPHAN = 56%` (matches
  `baseline-2026-05-30.txt` exactly).
- Structural gate validation (zero research tokens): a Python harness that imports
  `offline_audit.py`'s own `load_corpus`/`extract_figures`/`distinctive`/`in_corpus` and
  simulates the new gate's kill action over the same searchable subset. Observed:
  PRE 9/16 orphan (56%) → gate KILLS exactly the 9 orphans, SPARES all 7
  literal-presence-Y figures → POST 0/7 shipped figures orphan (0%); **over-kill = 0**
  (figures killed that the audit calls supported = 0, because the gate's kill predicate
  *is* the audit's orphan predicate). This satisfies the validation gate (lowers the
  offline unsupported-figure rate without raising over-kill / true-claim survival holds).
- Confirmed only SKILL.md changed (`git diff --stat`) and no bats test references the
  `validation/` artifacts, so the suite is unaffected.

**Remaining risks / follow-ups.**
- The verification above is **structural/offline**: it proves the gate's *definition*
  matches the regression metric and would zero the orphan rate **if the pipeline obeys the
  instructions**. It is **not** a full **Tier-2 live replay** (re-running the hardened
  verify+synthesis over a tree's frozen `fetched/`), which is token-heavier and was **not
  run** here per the cached-only / zero-new-token budget. Tier-2 replay over ≥1 VOC tree
  (e.g. `voc-decline-era`) remains the promotion-grade confirmation that an LLM following
  these gates actually drops ƒ134M/ƒ120M and keeps ƒ219M — recommend it as the next step.
- The deterministic screen (and thus the gate's string-presence shortcut) is reliable only
  for ≥3-digit/decimal figures; 2-digit cores still need the source-window read the gate
  prose now mandates — correctness there depends on the model honoring that instruction,
  not on a deterministic check.
- Items #4 (perspective-diverse verification), #6 (CC-workflow handoff), #7 (Module B
  injection) are out of this task's scope and remain TODO in the backlog table.

## Tier-2 Replay Result (2026-05-30) — promotion gate PASSED

The structural check above proved the gate's *definition* matches the regression
metric; this replay proves an LLM *executes* it. Blind replay of the hardened
Phase-4/5 gates over the frozen `voc-decline-era` corpus — the subagent built the
figure-ledger from its own read of `fetched/` source windows, forbidden from opening
`offline_audit.py` until its ledger was finalized. Evidence:
`docs/rpm/research/dr-bakeoff/replay-2026-05-30/{voc-decline-era-ledger,voc-decline-era-replay}.md`.

- **Recall 21/21** on unsupported figures the original shipped — including the **ƒ134M**
  crux the original elevated to "most defensible debt at takeover", and **ƒ120M**.
- **Over-kill 0/4** — every genuinely-sourced figure was SHIPPED (**ƒ219M** Gutenberg-
  verbatim, ƒ15M, the 200/300 ship sentence, 10,000 toll). The **ƒ20M** Frankenstein
  trap (digits present in `finance.md` but referent = Dutch foreign lending, not VOC
  capital) was correctly KILLED by reading the window — discrimination, not over-kill.
- **3/3 agreement** with the deterministic `offline_audit.py` on the figures it scores
  (ƒ219M SHIP, ƒ134M/ƒ120M KILL); the replay additionally resolved the 22 figures the
  grader defers to the LLM pass.
- Orchestrator independently cross-checked: "debt of 219 million Dutch guilders" is
  verbatim in `14-gutenberg-voc.html.md:120`; "134 million"/"120 million" absent as
  figures (only coincidental bare-"134" digit-runs). Confirms the subagent, not just
  trusts it.

Validation gate (lower the unsupported-figure rate without raising over-kill) met
**behaviorally**, not just structurally. Items #2/#3/#5 promotion-grade — committed.
