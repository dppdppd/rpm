# Progress — VOC expedition goals 1602–1700 (v2 arm)

Run date: 2026-06-07
Protocol: v2 (hardened research protocol, this run's protocol.md)

## Task shape
HYBRID:
- SURVEY/DEEP-DIVE component: VOC expedition goals 1602–1700 + issuing documents
  (chambers / Heren XVII / Batavia / officers; instructiën, octrooi, commissiebrieven,
  artikelbrief, generale missiven).
- 3 Dutch-primary sub-questions requiring located + self-translated Early-Modern-Dutch text:
  1. 1602 octrooi article on the Heren XVII board — per-chamber seat allocation + 17th-seat rule.
  2. Coen dispatch to Heren XVII, 6 May 1621 (NA 1.04.02 inv. 1073), Banda — own losses + ~1,200 referent.
  3. Van Riebeeck Daghregister Dec 1651 outbound (NA 1.04.02 inv. 1188, fol. 189) — 3 ships, rank, port + chamber.

## Dimensions
D1. Issuing bodies + document types (octrooi, instructiën, commissie, artikelbrief, generale missiven, Heren XVII resolutions).
D2. Categories of assigned goals (trade/monopoly, fortification, diplomacy, exploration, conquest, freight).
D3. Sub-Q1 — 1602 octrooi text, article on the XVII board.
D4. Sub-Q2 — Coen 1621 Banda dispatch text.
D5. Sub-Q3 — Van Riebeeck 1651 Daghregister heading text.

## Strategy
Main session runs all fetches (protocol: agents never fetch URLs). Dutch-primary
sub-questions are fetch-and-translate, done in main session directly. Survey
dimensions D1/D2 via WebSearch + targeted fetches.

## Status
- [x] Phase 0 setup + live fetch test
- [x] Phase 1/2 discovery (WebSearch batches; all 3 Dutch primaries located)
- [x] Phase 3 fetch + persist (9 artifacts + 3 extracted sidecars + 1 PDF-extract under fetched/)
- [x] Phase 4 validation: figure-ledger (0/7 orphans), refuted (0/13 dropped), adversarial panel (5 lenses)
- [x] Phase 5 report.md written once; citation audit 8/8; synth-introduced figures 0/6

## Result
- 3 Dutch primaries fetched + self-translated:
  Q1 = 1602 octrooi Art. II (vocsite); Q2 = Coen 6 May 1621 letter (Colenbrander djvu, archive.org);
  Q3 = Van Riebeeck Daghregister heading (DBNL).
- 0 unsourced load-bearing claims. 1 qualitative claim flagged-but-kept (van der Hagen, tertiary).
