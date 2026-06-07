# Plan — v1/v2/native deep-research bake-off on a Dutch-primary-source VOC topic

**Status: DONE (2026-06-07).** All three arms run and graded; 3-column
scorecard finalized. See `## Worker Result` at the bottom. This was the rigorous
(controlled) version; the cheap reuse-v1 variant was rejected for prompt asymmetry.

Source: 2026-05-31 session. Closes the one real loose end in
`2026-05-30-deep-research-improvement-plan.md` — the v1→v2 hardening was only
ever validated by **offline Tier-2 replay over a frozen corpus**, never by a
fresh end-to-end head-to-head against native on a NEW topic.

## Goal
Measure whether the v1→v2 citation/translation hardening **changes behavior**
on a topic that *requires reading/translating Early-Modern-Dutch primary
sources* — the surface most likely to produce mistranslation-as-fabrication
(the qualitative-claim analogue of the ƒ20M wrong-referent trap) — and where
native lands on the same probe.

## Why rigorous, not cheap
The 2026-05-30 bake-off was criticized **in its own scorecard** for prompt
asymmetry (rpm specimen vs native ran different prompts → "do not read
cell-by-cell"). Fix: all three arms answer ONE identical question. Cost: v1
must run fresh too — 3 live runs, no free on-disk v1.

## Arms
- **v1** = deep-research SKILL.md *before* the 2026-05-30 citation hardening —
  checkout the **old path** `plugin/skills/deep-research/SKILL.md` at the parent
  of `2ba5fcc` (first hardening commit). No figure-ledger / kill-list /
  lens-panel; Principle-8 `<<<UNTRUSTED>>>` wrapping still present. (Resolve
  exact hash at run: `git log --oneline -- plugin/skills/deep-research/SKILL.md`.)
- **v2** = current hardened SKILL.md at HEAD (post-rename path).
- **native** = bundled `/deep-research` Workflow (CC-only, ~2.7M tok/run).

## Candidate / grading corpus
`/home/coder/projects/VOC/docs/research/voc-expedition-goals-chamber-assignments-1602-1700`
— most Dutch-primary-dense tree in the 28-tree VOC corpus (1,734 Dutch-prose
tokens / 17 of 21 fetched files; cites Nationaal Archief `1.04.02` invnrs
13862/23/323/360/7015, the Generale Missiven, GLOBALISE). Its on-disk
`findings/report.md` (created 2026-05-24, pre-hardening) is the v1-era reference
specimen; its `fetched/` is the frozen grading corpus.

**Caveat that shapes the design:** that report's HIGH-confidence claims lean on
**English secondary** sources (vocwarfare.net, Warwick DB, the NA introduction
PDF) that *describe* the archives; the Dutch primaries are cited more as
provenance than as translated, claim-supporting text. So to actually stress
translation, **add 2–3 Dutch-primary-only sub-questions** answerable *only* by
translating a specific Generale Missiven passage or a named invnr.

## Shared question (game-design tail stripped so native isn't handicapped)
"What goals did the chambers / Heren XVII / Batavia / officers assign to VOC
expeditions, 1602–1700, and through which issuing documents?" + 2–3
Dutch-primary-only sub-questions (pin to a specific Generale Missiven entry / an
invnr at run time).

## Grading
- Per load-bearing claim citing a Dutch primary: a clean-context Dutch-capable
  sub-agent translates the cited source window, confirms support, **KILLs**
  mistranslations / Frankensteins. Orchestrator cross-checks a sample by reading
  the Dutch window directly (same protocol that hardened the Tier-2 replay:
  ƒ219M verbatim-confirmed, ƒ20M referent-killed).
- Metrics: unsupported-claim rate, translation-fidelity errors caught, figure
  orphans (few — this tree is figure-light), over-kill (true-claim survival),
  plus the observed cost / #agents / wall-clock / artifacts row from the
  original scorecard.
- Reuse `dr-bakeoff/checks/{url_liveness,offline_audit}` + a new
  translation-fidelity check.

## Output
`docs/rpm/research/dr-bakeoff/runs/{v1,v2,native}/` + scorecard updated with a
v1│v2│native column triplet. Verdict: does v2 beat v1 on Dutch-source fidelity,
and how does it compare to native.

## Cost gate
2–3 live runs, ~3.5–4M tokens, ~30–60 min wall-clock. The "spend real tokens"
step — unlike all the offline Tier-1/2 work. Run only when greenlit.

## Progress (2026-06-07) — v1 + v2 DONE, native pending

Greenlit and run. **v1 and v2 are complete and graded**; the **native arm**
is handed off to a fresh session (this session ran out of context budget for
the ~2.7M-token native Workflow run).

- Sub-questions pinned (3 Dutch-primary-only probes, each with a built-in
  mistranslation trap) → `runs/2026-06-07-triplet/sub-questions.md` (public +
  private key).
- v1 (`24d8ab0` pre-hardening) and v2 (HEAD hardened) ran as background
  subagents on the identical question, graded blind against the held-out key +
  frozen corpus → `runs/2026-06-07-triplet/{v1,v2}/report.md`,
  `grading/{v1,v2}-grading.md`, `scorecard.md`.
- **Primary finding:** on this Dutch-primary probe the v1→v2 hardening showed
  **no fidelity gain and one false-confidence regression** — on Sub-Q2 v2
  mis-extracted the Banda casualties from the same primary and fabricated an
  officer ("Captain Vogel"), which its figure-ledger/kill-list certified as
  HIGH-confidence/zero-orphan; v1 got them right. Caveat n=1. Full table +
  caveats in `scorecard.md`.
- **Native arm DONE (fresh session):** ran the real bundled `/deep-research`
  Workflow on the identical question, graded it the same blind way, filled the
  3rd scorecard column. See `## Worker Result` below.

## Worker Result (2026-06-07 — native arm + finalize)

Ran the **native** arm: the bundled `/deep-research` skill (a native Claude Code
Workflow — Scope → Search → Verify → Synthesize, 3-vote adversarial verification),
given ONLY the verbatim question (no key, no corpus, no bake-off framing). It
researched live from the open web and independently re-found the authoritative
Nationaal Archief / DBNL / Wikisource primaries. Persisted to
`runs/2026-06-07-triplet/native/report.md`; graded blind against the held-out key +
frozen corpus by an independent Dutch-fidelity subagent →
`grading/native-grading.md`; native column filled in `scorecard.md`.

**Native scale/cost:** 103 agents · ~2.32M subagent tokens · 757 tool-uses · ~27 min.

**Native fidelity (grader):** Sub-Q1 CORRECT, Sub-Q2a CORRECT (De Ros +
standard-bearer named — *no fabrication*, vs v2's invented "Captain Vogel"),
Sub-Q2b left UNRESOLVED by design (surfaced both the "captured" and "died" readings,
refused to assert), Sub-Q3 CORRECT (both traps avoided; "from Amsterdam" refuted
0-3). Translation-fidelity errors **0**; unsupported **0/10**; figure orphans 0;
over-kill 0 (its verifier *killed* the two wrong claims); live-URL 17/18 (one ANRI
403, self-disclosed); ~21 load-bearing claims / 21 citations.

**3-column verdict:** On Dutch-source fidelity, **native is the strongest arm — but
at ~20× the token cost** (~2.32M vs v1 ~98k / v2 ~115k). It is the only arm that
delivered no wrong answer on Sub-Q2. The bake-off's actual question — did the v1→v2
hardening help? — answers **no**: the kill-list/figure-ledger neither beat v1 nor
caught the Sub-Q2 wrong-referent trap (it certified v2's fabrication as
HIGH-confidence/zero-orphan). The mechanism that *did* catch the traps is native's
**independent adversarial multi-vote verification**, not literal-presence
self-certification. Lesson: reserve adversarial verification for high-stakes
primary-source claims; it is expensive. n=1 probe, one topic — directional.
