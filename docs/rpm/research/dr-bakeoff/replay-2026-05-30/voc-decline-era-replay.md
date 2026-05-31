# VOC Decline Era 1680–1800 — Number-Provenance Gate Replay (Tier-2, blind)

Behavioral validation of the rpm:deep-research hardening change (Phase-4
"Instrument every drop" + "Number-provenance gate" → `figure-ledger.md`, and Phase-5
defense #4 "Post-synthesis figure-provenance assertion"). Question under test: does an
LLM **following the new SKILL.md** catch unsupported figures over the frozen VOC corpus
WITHOUT over-killing genuinely-supported ones?

Corpus: frozen `voc-decline-era-1680-1800/fetched/` (14 artifacts). Verdicts derive
from my own read of the source windows, produced **blind** (before opening the
deterministic grader). Companion: `voc-decline-era-ledger.md`.

## Drop tally (the Phase-4 mandatory line)

```
DROPPED 21/25 distinctive quantitative figures
  (not-fetched 14, frankenstein 3, model-memory/agent-web 4)
```

Equivalently, the figure-ledger orphan count: **21/25 figures orphaned**
(literal-presence N). Surviving SHIP rows: 4 distinctive magnitudes
(ƒ219M, ƒ15M, the 200/300 captured-ship sentence, the 10,000 massacre toll).

## Hardened-vs-original delta

What the ORIGINAL report.md SHIPPED as figures, and what the gate now does:

**Gate would now KILL (21) — original asserted these, hardened report must not:**

- Debt: **ƒ134M** (the report's "most defensible debt at takeover"), **ƒ120M** book debt.
  → Both orphans. The report's own adjudication ("most defensible = ƒ134M (1796)")
  is exactly the laundered-guess the SKILL.md "Refuted is a deliverable" clause forbids:
  the gate's correct output is "no verified takeover figure exists; ƒ219M gross is the
  only source-confirmed debt number."

- Capital/profit: **ƒ4M**, **ƒ20M**, **18%**, **10%** — all not-fetched (Gaastra/ResearchGate).
  ƒ20M is a *Frankenstein trap*: "20 million guilders" is literally in finance(10) but
  describes Dutch foreign lending, not VOC capital drawdown — bare string-match would
  wrongly SHIP it.

- War totals: **ƒ43M**, **ƒ62M** — not-fetched (web pass).

- Bank of Amsterdam: **10.5M**, **28M** florins — not-fetched (BIS/DNB cited, not fetched).

- Cargo % series: **43 / 23 / 14** (spices) and **36 / 55 / 41** (textiles) — not-fetched;
  the cited Cambridge/Prakash abstract and UMass PDF are not parseable artifacts in the tree.

- Workforce: **35,000**, **25,000**, **11,000** — orphans; #24/#25 are Frankenstein
  (report cites VOC-main 12, which contains none of them; Gutenberg only says
  "20,000–30,000").

- Toll lower bound **5,000** — orphan (report already hedges it as a range).

**Gate would still SHIP (4 distinctive magnitudes) — survive verification:**

- **ƒ219M** gross liabilities — Gutenberg(14) L120 verbatim "debt of 219 million Dutch
  guilders." Specialist source. The report ALREADY flags this as the one locally
  confirmed debt figure — gate agrees.

- **ƒ15M** captured-cargo value + the **200** merchantmen / **300** locked sentence —
  fourth-war(11) L755 verbatim.

- **10,000** massacre toll — massacre-1740(07) L722 "at least 10,000 ethnic Chinese
  were massacred."

Net effect: the hardened report keeps **4** source-grounded magnitudes and demotes
**21** to `## Could not verify / refuted`. The report's qualitative spine (two-stage
agency contraction, succession-war entanglements, 31 Dec 1799 lapse — the latter
confirmed in artifact 12's `1602–1799` infobox) is untouched; only the orphan numbers
are stripped.

## Validation-gate answers

**(a) RECALL — which figures the original SHIPPED did the gate CATCH (kill)?**
The gate caught **all 21 unsupported figures the original asserted** as findings:
ƒ134M, ƒ120M, ƒ4M, ƒ20M, 18%, 10%, ƒ43M, ƒ62M, 10.5M, 28M, the six cargo percentages
(43/23/14/36/55/41), 35,000, 25,000, 11,000, and the 5,000 toll-bound. Critically it
caught **ƒ134M** — the load-bearing crux the original elevated to "most defensible
debt at takeover" despite it being absent from every fetched artifact. **Recall on the
crux debt figure: caught.** The original was actually self-aware (it flags most of
these as "not in the fetched subset"), but it still SHIPPED ƒ134M as an adjudicated
answer and printed 18%→10%, the cargo series, and the workforce split as asserted
findings — the gate converts all of those from asserted to refuted.

**(b) OVER-KILL — did the gate kill any figure that IS genuinely supported in the
fetched corpus?**
**No.** Every one of the 4 figures with a real source window (ƒ219M, ƒ15M, the 200/300
ship sentence, 10,000 toll) was SHIPPED, not killed. No genuinely-supported figure was
over-killed. The one near-miss the gate handled correctly is **ƒ20M**: its digit-core
is literally present in finance(10), but reading the window shows it is Dutch foreign
lending, not the asserted VOC capital drawdown — so killing it is *correct discrimination*,
not over-kill. The read-the-window protocol (vs bare substring match) is what prevents
both a false-SHIP here and false-KILLs of the round ship-counts.

**Verdict:** the hardening change passes the behavioral test on this corpus —
**recall 21/21 on unsupported figures (incl. the ƒ134M crux), over-kill 0/4 on supported
figures.**

## Self-check vs deterministic grader (offline_audit.py) — run AFTER ledger finalized

The blind ledger above was frozen before running the grader. Self-check result:

`offline_audit.py` is a **deterministic digit-presence screen** with two declared
limits that shape the comparison: (1) its regex only catches `ƒ…` / `…million
guilders/florins` / `…guilders/florins` / `…%` patterns, and (2) `distinctive()` keeps
only decimals or **3+ digit** cores — so every 2-digit core (62, 43, 20, 18, 15, 10, the
six cargo %, …) is dropped *before* the orphan check, by design, as needing "the LLM
semantic pass." Consequently the grader adjudicates only **3** distinctive figures for
voc-decline-era: **{ƒ219M (219), ƒ134M (134), ƒ120M (120)}**, and reports **2/3 orphan**.

**Per-figure agreement on the overlap set {219, 134, 120}:**

| figure | grader verdict | my blind verdict | agree? |
|--------|----------------|------------------|--------|
| ƒ219M | PRESENT → not-orphan (SHIP) | literal-presence Y → SHIP | **YES** |
| ƒ134M | ABSENT → ORPHAN (KILL) | literal-presence N → KILL | **YES** |
| ƒ120M | ABSENT → ORPHAN (KILL) | literal-presence N → KILL | **YES** |

**3/3 agreement on every figure the grader scores.** No disagreement to record.

**Where my ledger goes beyond the grader (not disagreements — coverage the grader
defers to the LLM pass):** the 22 figures the grader filtered out as non-distinctive
(2-digit cores) or out-of-regex (ƒ4M, ƒ20M, ƒ43M, ƒ62M, 10.5M, 28M, the 6 cargo %, 18%,
10%, 35,000/25,000/11,000, 5,000, the 200/300 ship counts, 10,000 toll). The grader's
header explicitly punts these ("2-digit cores match by chance … need the LLM semantic
pass") — which is exactly the work this Tier-2 replay performs. My read-the-window
method KILLs the orphans among them (ƒ4M/ƒ20M/ƒ43M/ƒ62M/10.5M/28M/cargo%/18%/10%/
workforce/5,000) and SHIPs the supported ones (ƒ15M, 200, 300, 10,000) — none of which
the deterministic screen could resolve.

**One methodological note the comparison surfaces:** for ƒ219M the grader marks
"present" because the digit-run `219` appears *anywhere* in the corpus — and `219` does
occur coincidentally in 02-preanger (SVG/topic-id) and 04-jws2 (revision-id), not only in
Gutenberg. The grader would have SHIPPED `219` on those coincidental hits alone. My
window-read independently confirms the real figure is in Gutenberg(14) L120, so we land
on the same SHIP — but only the window-read actually *validates* it. This is the precise
failure mode (coincidental digit-match → false SHIP) that the hardened SKILL.md's
"read the source window, not by string presence alone" rule exists to close, and the
replay exercises it correctly.

**Bottom line:** blind ledger AGREES with the deterministic grader on **3/3** of the
figures it scores; the replay's added value is resolving the 2-digit / non-ƒ figures the
grader cannot, with **recall 21/21** on unsupported figures and **over-kill 0** on
supported ones.
