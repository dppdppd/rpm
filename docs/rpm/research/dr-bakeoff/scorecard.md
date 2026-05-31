# Bake-off Scorecard — rpm:dr vs native /deep-research

Probe A: VOC financial decline 1680–1800. Probe B: injection canary (NOT run — see note).
Date: 2026-05-30. Conditions: CC 2.1.158, effort xhigh, workflows enabled.

**Run provenance (asymmetric — read before trusting any single cell):**
- **rpm** = the completed VOC specimen (`runs/rpm/report.md`), session c16e7b11, a *2-pass human-confirmed-scope* upgrade run on the user's *project-framed* VOC question (4 user-chosen dimensions incl. Java military). Generous specimen.
- **native** = fresh Workflow `wf_16c5ddc1-0e2` (`runs/native/report.md`), run THIS session on **probe-P1 verbatim** (financially framed). Single-shot, auto-scoped.
- ⇒ Different prompts. The rubric's *general* VOC-rigor traps are the common yardstick; do not read cell-by-cell as a controlled head-to-head.

## Objective rows (deterministic + rubric)
| Metric | rpm | native | tool |
|---|---|---|---|
| Live-URL % (HEAD) | 14/18 (~17/18 real; 3 Wikipedia 429 = live) | 13/19 (~16/19 real; 3 Leiden 000 = GET-fetched, HEAD-hostile) | `url_liveness.sh` |
| Fabricated / 404 URLs | 0 (1 ResearchGate 403, flagged) | 0 (2 ResearchGate 403 flagged *unreliable*/0-claims; 1 IIAS 403 flagged *paywall*) | `url_liveness.sh` |
| Unsourced / unsupported quantitative claims | **3–4** (ƒ4M/ƒ20M drawdown & ƒ62M cited to a Wikipedia page lacking them; ƒ134M "agent-sourced"; ƒ219M rests on amateur self-pub Reynders) — honestly labeled but still presented as findings | **~0–1** (one soft flag: 12.2M-in-1766 not on cited web page; refuted the uncited 74M deficit 0-3) | rubric fabrication flag (grader **fetched** sources) |
| Rigor traps passed (/7) | **4 PASS / 3 PARTIAL** under citation-fetch (Gaastra-honesty, balance, dividend-forensics partial) | **7/7 PASS** | `rubric.md` (grader-confirmed) |
| Injection canary resisted (Y/N) | n/a | n/a | Module B not run either arm |

> **Module B note:** neither arm was given the injection probe (both runs were Module A only). Injection-resistance is UNTESTED for both — a remaining gap, not a result.

## Observed rows
| Metric | rpm | native |
|---|---|---|
| Sub-agent model | sonnet | workflow agents (mixed) |
| # agents | ~4–5 | **101** |
| Wall-clock | ~15–20 min | **~32 min** (1,938s) |
| Tokens (approx) | not captured | **~2.74M** subagent tokens |
| Artifacts written + where | **durable tree** `docs/research/<slug>/` (fetched/×14, gaps/, validation/adversarial.md, findings/report.md, progress.md) | **none on disk** — result is JSON in a temp task-output file; no fetched/ tree |
| Scope-confirmation gate? | yes (user confirmed "go" on 4 dims) | no (auto-decomposed 5 angles) |
| Offer (quick/deep) gate? | yes | no |
| Key-findings chat summary? | yes (in-session) | yes (result.summary) — but only reached the user because the session stayed alive; the *prior* native run's never did |
| Resumable / background? | no (inline main session) | yes (Workflow, resumable by runId) |

## Judged rows (independent blind grader — A/B unblinded: **A=native, B=rpm**)
Grader fetched a 5-claim citation sample per report. Scores 1–5 (precision + honest uncertainty, NOT length).

| Metric | native (A) | rpm (B) |
|---|---|---|
| Comprehensiveness | 5 | 5 |
| Accuracy (vs primary sources) | 5 | 3 |
| Source quality (primary/specialist vs popular) | 5 | 2 |
| Citation support (fetched N=5) | 5 — 4 yes / 1 partial / 0 fail | 3 — 3 yes / 1 partial / **1 no** |
| Confidence calibration | 5 | 4 |
| Debt-figure end-state handling | 4 | 4 |
| Structure / readability | 4 | 5 |
| **Overall** | **stronger** (accuracy, source tier, citation support, balance) | broader & more readable; weaker financial-citation discipline |

## Final read (grader-confirmed via citation-fetch)
- **NOT a wash.** native = 7/7 PASS, ~0–1 fab; rpm = 4 PASS / 3 PARTIAL, 3–4 fab-exposures. Under *actual* citation-fetch, native's load-bearing claims verified verbatim (incl. nested Gaastra footnotes) while several of rpm's financial figures trace to sources that don't contain them. Styles differ:
  - **native** is more *conservative + adversarial*: refuses to assert any debt end-state (calls ~200M tertiary-only, **refutes** an uncited 74M deficit), killed 5/25 claims, fetched-and-verified **primary** sources (de Vries EHR 2010, Nierstrasz Leiden PhD, Gelderblom–Jonker JEH) with 3-vote checks, exposes its vote tallies.
  - **rpm** is *broader + more actionable*: adjudicates the debt figures (ƒ134M/ƒ219M/ƒ120M, picks most-defensible, ƒ219M Gutenberg-confirmed), covers Java military entanglement richly, but its *fetched* set is 10/18 Wikipedia (specialist works cited-not-fetched).
- **Direct conflict found:** rpm asserts dividends-exceeded-earnings "nearly every decade after ~1690" (MED); native **refuted** that exact generalization (0-3) and kept only the specific facts. native's verify is more aggressive.
- **Implication for Tier 3:** native MATCHED rpm on output rigor (and edged it on primary-source verification). So "keep rpm because its output is more rigorous" is **NOT supported**. rpm's real differentiators are orchestration/portability (see Observed rows), not report quality.

## §Grader prompt — see the dispatched background agent (blind A/B, 7 traps + N=5 citation fetch per report).

## Verdict
Final Tier 3 recommendation written into `docs/rpm/future/2026-05-30-deep-research-native-overlap.md` once the grader lands.
