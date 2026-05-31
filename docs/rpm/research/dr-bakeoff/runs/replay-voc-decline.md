# Tier-2 hardened replay — voc-decline (cached-only, ~0 research tokens)

Applied the hardened deep-research discipline (number-provenance gate + kill-list +
refuse-to-adjudicate) to the 11 load-bearing figures of the original `voc-decline-era`
report, checking each against that run's OWN cached `fetched/` corpus. No new search/fetch.

## Per-figure adjudication

| # | Figure | Found in cached corpus? | Tier | Verdict |
|---|--------|-------------------------|------|---------|
| 1 | **ƒ134M** debt @1796 ("most defensible") | ABSENT | none | **KILLED** |
| 2 | **ƒ219M** gross liabilities | gutenberg-voc:120 "debt of 219 million" | amateur self-pub (Reynders, gutenberg.net.au) | **TERTIARY-ONLY** |
| 3 | **ƒ120M** ~1795 book debt | ABSENT | none | **KILLED** |
| 4 | ƒ43M Fourth War loss | ABSENT | none | **KILLED** |
| 5 | ƒ62M net assets 1780 | ABSENT | none | **KILLED** |
| 6 | **ƒ15M** cargo / 200+ ships | fourth-war:755 verbatim | specialist secondary | **CONFIRMED** |
| 7 | ƒ4M/ƒ20M capital drawdown | ABSENT | none | **KILLED** |
| 8 | profit 18%→10% | ABSENT (all %-hits = CSS noise) | none | **KILLED** |
| 9 | cargo shares 43→23→14 / 36→55→41 | ABSENT as series | none | **KILLED** |
| 10 | **~10,000** killed 1740 | massacre-1740:718/722 verbatim | specialist secondary | **CONFIRMED** |
| 11 | Bank of Amsterdam 10.5M/28M, 28 Jan 1790 | ABSENT | none | **KILLED** |

**Tally: 2 CONFIRMED · 1 TERTIARY-ONLY · 8 KILLED.**

## Hardened debt-end-state stance (what the fixed skill writes)

> The dissolution debt total cannot be stated from this source set. Only ƒ219M appears
> in any fetched artifact, and its sole support is a self-published essay (Reynders,
> gutenberg.net.au) — barred as sole basis for a load-bearing number. ƒ134M ("debt at
> the 1796 nationalization") is absent from the corpus and cannot be asserted, ranked,
> or called "most defensible." ƒ120M is likewise absent. **No verified dissolution-debt
> figure exists in this corpus** — it is an open gap pending a specialist source (Gaastra
> 2003 / primary balance sheets) that was never fetched.

This is native `/deep-research`'s exact winning behavior — refuse to invent the total.

## Verdict

- **The fix catches both baseline orphans (ƒ134M, ƒ120M) and 6 more**; the original's
  headline "ƒ134M most defensible" adjudication is struck entirely.
- **Bonus / stricter than the grader:** ƒ219M's only support is the Reynders self-pub,
  so the hardened rule demotes it to tertiary-only — the grader had counted it "supported."
- **True unsupported rate ≈ 8–9 / 11 (~73–82%)** for voc-decline — *worse* than the 67%
  the deterministic digit-screen estimated, confirming the screen is a lower bound and the
  semantic pass catches far more.

## Caveat

This validates that the **rule** is correct and catches the orphans (the replay agent was
told to apply it). It does NOT yet prove the SKILL **prose** reliably *induces* this in a
live run — that is the prose-vs-behavior gap, and only a live re-run (deferred to save
tokens) closes it.
