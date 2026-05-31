# Tier 3 — Resolve rpm:deep-research vs native bundled /deep-research overlap

Source: 2026-05-30 rpm-vs-ultracode-mode evaluation.
**Needs user sign-off before execution.**

## Context
Web research (2026-05-30, CONFIRMED via code.claude.com/docs) found that
`/deep-research` is **the single bundled Workflow that ships with Claude
Code**. rpm's `rpm:deep-research` (217-line hand-rolled prose fan-out) now
duplicates it on CC.

rpm's version still earns its keep via:
- project **amendments** (`docs/rpm/skills/deep-research.md`)
- saved artifacts under `docs/rpm/research/`
- mandatory Key-Findings chat gate
- **portability** — opencode/codex have no native deep-research or Workflow

But continuing to *elaborate* the prose fan-out invests in a wheel
Anthropic now maintains.

## Decision (pick one)
- **A (lean):** keep rpm's as the portable baseline + differentiate
  (amendments/artifacts/chat-gate); stop growing the prose fan-out; on CC
  optionally hand off to native `/deep-research` / a Workflow when present.
- **B:** thin-wrap native on CC, prose only off-CC.
- **C:** accept duplication, status quo.

## Action steps (if A)
1. Add a note to `deep-research/SKILL.md` acknowledging native
   `/deep-research` and when to defer to it on CC.
2. Freeze prose-fan-out elaboration; make the differentiation explicit
   (amendments / artifacts / chat-gate / portability).
3. Optional: detection + handoff path when native is available.

## Constraints
- Preserve injection defenses, citation rigor, write-once, multi-runtime.
- Strategic — confirm direction before editing.

Estimate: 30–40 min once direction is chosen.

---

## Bake-off verdict (2026-05-30) — decision: **A, refined**

Ran a head-to-head (`docs/rpm/research/dr-bakeoff/`): the rpm:deep-research VOC
specimen vs a fresh native `/deep-research` Workflow (`wf_16c5ddc1-0e2`) on the
same VOC-decline probe class, graded **blind** against a 7-trap rigor rubric by
an independent agent that **fetched the cited sources** to check support.

**The finding that decides it:** native is at least as rigorous as rpm, and
under actual citation-fetch, *cleaner*. native = **7/7 PASS, ~0–1 fabrication**;
rpm = **4 PASS / 3 PARTIAL, 3–4 fabrication-exposures** (load-bearing financial
figures — ƒ4M/ƒ20M drawdown, ƒ62M, ƒ134M, the Bank-of-Amsterdam split — cited to
pages that don't contain them; honestly flagged but still presented as
adjudicated findings; the headline ƒ219M rests on an amateur self-published
source). So the original premise — *"rpm earns its keep on citation rigor /
output quality"* — **does not hold.** Native matched/edged it.

**Therefore differentiation cannot be rigor — it must be orchestration/fit**,
where the contrast is real and durable:
- **Portability** — native is CC-only; opencode/codex have no Workflow. rpm's
  prose fan-out is the only deep-research that runs everywhere. *Foundational —
  disqualifies native as a replacement.*
- **Durable artifacts** — rpm writes a navigable `docs/research/<slug>/` tree
  (fetched sources, adversarial.md, report.md); native's result is ephemeral
  JSON in a temp task file, no fetched tree.
- **Inline delivery** — native is a background workflow that *silently lost its
  report* on the first run (session ended before synthesis surfaced); rpm runs
  in-session.
- **Cost governance** — native spent **101 agents / ~2.74M tokens / 32 min** vs
  rpm's ~5 agents: exactly the "maximize" fan-out rpm's evidence-based caps exist
  to govern.

**New finding the bake-off earned (act on separately):** rpm:deep-research's
*citation discipline on hard-to-fetch figures is a real weak spot* — it presents
figures cited to pages that don't support them. native's pattern is the model:
**refuse to assert an unverifiable number, and actively refute uncited claims**
(it killed an uncited "74M deficit" 0-3). rpm's write-once + flag-don't-assert
convention should be tightened so flagged-unverifiable figures are demoted OUT of
findings/adjudications, not presented as "most defensible."

### Refined action steps (A)
1. `deep-research/SKILL.md`: acknowledge native `/deep-research`; on CC, hand off
   to native when max verification depth matters and cost/CC-lock-in are
   acceptable (the Tier 4 fast-path). Otherwise rpm — for portability + artifacts
   + inline + cost-control.
2. Freeze prose-fan-out elaboration; make the differentiation explicit
   (portability / durable artifacts / inline / cost-governance — **not** "more
   rigorous").
3. **Harden citation discipline** (new, backlog separately): demote unverifiable
   figures out of findings; adopt native's refute-uncited-claims behavior.

### Caveats on the evidence (n=1)
- One probe, with **prompt asymmetry**: native got the financially-framed probe-P1
  (played to structural/financial primary sources); the rpm specimen answered the
  user's *project-framed* question (Java-inclusive + a design-translation
  section), so rpm spent rigor budget on Java political entanglement (well-sourced,
  verbatim-verifiable) with finance as 1 of 4 dimensions.
- The rpm specimen is a *generous* 2-pass human-confirmed-scope run; its flagged
  financial figures are a documented draft limitation, not a hidden blind spot.
- **Module B (injection resistance) UNTESTED for both arms** — a remaining gap.

Artifacts: `docs/rpm/research/dr-bakeoff/` (scorecard.md, runs/{rpm,native}/,
checks/, bakeoff/).
