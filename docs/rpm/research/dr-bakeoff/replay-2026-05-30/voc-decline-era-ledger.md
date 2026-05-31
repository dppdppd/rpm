# VOC Decline Era 1680–1800 — Number-Provenance Figure Ledger (Tier-2 replay)

Replay of the rpm:deep-research Phase-4 number-provenance gate against the
**frozen** corpus at `/home/coder/projects/VOC/docs/research/voc-decline-era-1680-1800/fetched/`
(14 cached artifacts). Source of figures: that tree's `findings/report.md` (211 lines).

**Method (per SKILL.md Phase 4 "Number-provenance gate"):** for every distinctive
figure (any decimal, or any integer with 3+ significant digits) I (1) identified the
artifact the report cites/implies, (2) grepped the digit-core across all 14 fetched
files separator-insensitively, then (3) **read the surrounding source window of each
hit** to judge whether the FIGURE ITSELF appears or whether the digit-core is a
coincidental substring (Wikipedia revision/oldid, SVG path coordinates, CSS widths,
infinite-scroll topic IDs, years, category counts). literal-presence Y requires the
asserted figure to be present in its cited artifact; verdict SHIP requires
literal-presence Y **and** a primary/specialist source. Orphans (literal-presence N),
tertiary-only, and model-memory figures are KILLED.

This was produced **blind** — before opening `checks/offline_audit.py` or
`checks/baseline-2026-05-30.txt`.

## Distinctiveness filtering

Excluded as non-distinctive / not source-claims: 4-digit years (1602–2026); URL &
DB-ID fragments that the report's own citation strings contain (`9533`, `7804`,
`119886`, `16801740`, `380175177`, `628`, `555`, `456`); internal game-design
grain numbers (`3.5`, `~10` yr/trick — iteration-16 design, not a VOC corpus claim).
2-digit cores (e.g. `200`, `300`) are flagged below but their verdict rests on a
read of the source window, never bare string-match.

## Ledger

| # | figure (as report asserts) | cited / implied artifact | literal-presence Y/N | source-tier | verdict | evidence note |
|---|----------------------------|--------------------------|----------------------|-------------|---------|----------------|
| 1 | **ƒ219M** gross liabilities / "debt of 219M guilders" | fetched/14-gutenberg-voc | **Y** | specialist (Reynders essay, Project Gutenberg AU) | **SHIP** | 14 L120: "went bankrupt leaving a debt of 219 million Dutch guilders." Sole non-coincidental hit in corpus. Other "219" hits (04,02) = revision-id / SVG coords / topic-id. |
| 2 | **ƒ134M** debt assumed at 1796 nationalization | (implied VOC-main 12 / finance 10) | **N** | model-memory / agent-web | **KILL** | No "134 million" anywhere. All "134" hits are oldids (`134596…`, `134548…`), SVG path data, category counts. Report itself: "agent-sourced; not in the fetched VOC article." Orphan. |
| 3 | **ƒ120M** ~1795 book debt | (none cited; "appears as") | **N** | model-memory | **KILL** | No "120 million" / "f120" anywhere in corpus. Orphan. |
| 4 | **ƒ4M** Asian capital drawdown 1730–80 | ResearchGate "Finances of the VOC" + Gaastra 2003 | **N** | not-fetched (no parseable artifact) | **KILL** | No VOC "4 million" drawdown figure in any fetched file. Report: "not in the fetched Wikipedia subset." Orphan. |
| 5 | **ƒ20M** European liquid-capital drawdown 1730–80 | ResearchGate + Gaastra 2003 | **N** | not-fetched | **KILL** | "20 million guilders" DOES occur in finance(10) L775 — but as *Dutch foreign sovereign lending* ("Foreign investment probably doubled to 20 million guilders annually"), a different referent. As the asserted VOC-capital figure: orphan. Frankenstein risk if credited by bare string. |
| 6 | **18%** profit (start of decline-in-margin) | ResearchGate + Gaastra 2003 | **N** | not-fetched | **KILL** | No VOC profit "18%" in corpus. The only `%` figures in finance(10) are Dutch-Republic tax shares (83%/66%/10%-penny/16%/9.6%/6.1%). Orphan. |
| 7 | **10%** profit (end of margin) | ResearchGate + Gaastra 2003 | **N** | not-fetched | **KILL** | Same as #6. "10 percent" in finance(10) L726 = Habsburg "Tenth Penny" tax, not VOC profit. Orphan. |
| 8 | **ƒ15M** cargo value of captured merchantmen | fetched/11-fourth-war | **Y** | primary-ish (Wikipedia, but verbatim source statement) | **SHIP** | 11 L755: "more than 200 Dutch merchantmen, with cargo to the amount of 15 million guilders, had been captured… and 300 more were locked up." |
| 9 | **200** Dutch merchantmen captured | fetched/11-fourth-war | **Y** (round, but figure present) | primary-ish | **SHIP** | 11 L755 "more than 200 Dutch merchantmen". 2-sig core, but the figure itself is in the cited window. |
| 10 | **300** more locked in port | fetched/11-fourth-war | **Y** (round, but figure present) | primary-ish | **SHIP** | 11 L755 "300 more were locked up in foreign ports". 2-sig core, confirmed in window. |
| 11 | **ƒ43M** total VOC war loss | Gaastra (web pass) | **N** | not-fetched | **KILL** | Zero "43 million" hits in corpus. Report: "Gaastra-sourced (web pass), not in the fetched subset." Orphan. |
| 12 | **ƒ62M** net assets (→~0) 1780 | Gaastra (web pass) | **N** | not-fetched | **KILL** | Zero "62 million" hits. Orphan. |
| 13 | **10.5M** florins backed by bullion (Bank of Amsterdam, 28 Jan 1790) | BIS/DNB working papers (cited, not fetched) | **N** | not-fetched | **KILL** | Zero "10.5 million" in corpus. Orphan. |
| 14 | **28M** florins total (Bank of Amsterdam) | BIS/DNB (cited, not fetched) | **N** | not-fetched | **KILL** | Zero "28 million" in corpus. Orphan. |
| 15 | **43%** pepper+spices import share (1668–70) | Cambridge/Prakash abstract + UMass PDF | **N** | not-fetched (neither source is a fetched artifact) | **KILL** | "43%" hits (06-giyanti) are coincidental CSS/unrelated; none in a pepper-spices import-share table. Report: "MEDIUM for the exact percentages." Orphan. |
| 16 | **23%** pepper+spices share (1698–1700) | Cambridge/Prakash + UMass | **N** | not-fetched | **KILL** | No "23%" near spice/import anywhere. Orphan. |
| 17 | **14%** pepper+spices share (1738–40) | Cambridge/Prakash + UMass | **N** | not-fetched | **KILL** | All "14%" hits = `width:14%` CSS / unrelated war-article text. Orphan. |
| 18 | **36%** textiles+raw-silk share (1668–70) | Cambridge/Prakash + UMass | **N** | not-fetched | **KILL** | No "36%" in any cargo context. Orphan. |
| 19 | **55%** textiles+raw-silk share (1698–1700) | Cambridge/Prakash + UMass | **N** | not-fetched | **KILL** | "55%" hits are coincidental (CSS / unrelated). Orphan. |
| 20 | **41%** textiles+raw-silk share (1738–40) | Cambridge/Prakash + UMass | **N** | not-fetched | **KILL** | "41%" hits are coincidental. Orphan. |
| 21 | **10,000** ethnic Chinese killed (1740 massacre) | fetched/07-massacre-1740 | **Y** | primary-ish (Wikipedia, verbatim) | **SHIP** | 07 L722 "at least 10,000 ethnic Chinese were massacred"; L718 ">10,000 killed". Borderline distinctiveness (2-sig core 10) but figure present in cited window. |
| 22 | **5,000** (lower bound of 5,000–10,000+ toll range) | (overview sources, flagged) | **N** | not-fetched as a figure | **KILL** | Report flags this as a range bound, not asserted firmly; "600 to 3,000 survived" is what 07 gives, not a "5,000" toll. No "5,000 killed" in cited artifact. Orphan (low-stakes; report already hedges). |
| 23 | **35,000** workforce by 1750 | (implied) | **N** | model-memory | **KILL** | No "35,000" anywhere. Gutenberg(14) says "between 20,000 and 30,000 employees"; report's 35,000 unsupported. Orphan. |
| 24 | **25,000** in Asia (workforce at height) | fetched/12-voc-main (report cites it) | **N** | Frankenstein (cited artifact lacks it) | **KILL** | Report attributes "25,000 in Asia + 11,000 en route" to VOC-main(12). Artifact 12 contains NO "25,000" / "11,000". Gutenberg(14) only "20,000–30,000". Frankenstein citation. |
| 25 | **11,000** en route (workforce) | fetched/12-voc-main (report cites it) | **N** | Frankenstein | **KILL** | Same as #24 — not in artifact 12 or anywhere in corpus. Orphan/Frankenstein. |

## Orphan tally

**Orphaned: 21/25 distinctive figures** (literal-presence N).
Surviving (SHIP, literal-presence Y): **4/25** → #1 ƒ219M, #8 ƒ15M, #21 10,000 toll,
plus the two round ship-counts #9 (200) / #10 (300) which are technically 2-sig but
confirmed-in-window. Counting the two round ship-counts as ships, the **distinctive-magnitude
survivors are 4** (ƒ219M, ƒ15M, 10,000, and the 200/300 ship pair as one cited sentence).

Reason-code breakdown of the 21 kills:
- **not-fetched (no parseable source artifact)**: 13 — #4 #5 #6 #7 #11 #12 #13 #14 #15 #16 #17 #18 #19 #20 *(14 lines; #5 doubles as frankenstein-risk)*
- **frankenstein (cited artifact lacks the number)**: 3 — #24 #25 (cited to VOC-main 12, absent) + #5 (ƒ20M present but wrong referent)
- **model-memory / agent-web (no citation that resolves)**: 4 — #2 ƒ134M, #3 ƒ120M, #22 5,000, #23 35,000

(Several figures fit two codes; primary code assigned above. Net distinct kills = 21.)

## Post-synthesis figure-provenance assertion (SKILL.md Phase 5 defense #4)

A hardened report may assert ONLY the surviving (literal-presence-Y) rows:
**{ƒ219M, ƒ15M, 200 merchantmen, 300 locked, 10,000 toll}**.
Re-extracting distinctive figures from such a hardened report and diffing against the
surviving ledger ⇒ **synth-introduced figures = 0/5** *by construction*, provided the
writer pulls only from these rows. The assertion's job here is to confirm the writer
introduces no NEW number (e.g. does not "round ƒ219M into ~ƒ220M", does not resurrect
ƒ134M as a hedge). Against the surviving set: **synth-introduced figures: 0**.

(The ORIGINAL report.md, by contrast, asserts 21 figures that are NOT surviving-ledger
rows — see the replay delta file. That original would FAIL this hard gate.)
