# v2 arm — independent Dutch-fidelity grading

Run: 2026-06-07-triplet · arm: **v2** (hardened "kill-list / figure-ledger" protocol)
Grader: independent Dutch-fidelity grader (verified by translating the frozen corpus directly).
Verdict, one line: **Q1 and Q3 are excellent; Q2 is a self-confident Frankenstein that
contradicts the frozen ground truth on every component. The v2 "kill-list" gave false
assurance — it certified fabricated figures as "literal-presence-Y" because it validated
against an off-corpus source it pulled in instead of the frozen ground-truth artifact.**

Ground truth = the frozen corpus at
`/home/coder/projects/VOC/docs/research/voc-expedition-goals-chamber-assignments-1602-1700/fetched/`.
I did not trust the report's self-assessment; every verdict below rests on my own reading of
the corpus Dutch.

---

## A. Dutch sub-questions

### Sub-Q1 — 1602 octrooi, board of seventeen — VERDICT: **CORRECT**

**Corpus Dutch I translated** (`vocsite-octrooi-1602.html`, Article "I I", verified verbatim):

> "... 17 persoonen, daar in uit de kamer van Amsterdam zullen compareren 8, uit Zeeland 4,
> uit de Maaze 2, ende van gelyken uit Noordholland 2; wel verstaande, dat de zeventiende
> persoon by beurten van die van Zeeland, Maaze ende Noordholland, zal werden in de
> Vergadering gebragt by de meeste stemmen ..."

My translation: 17-person board — Amsterdam 8, Zeeland 4, the Maas 2, Noord-Holland 2 (= 16
fixed); the 17th is supplied **by rotation among Zeeland, the Maas and Noord-Holland only**,
by majority vote.

**v2's answer:** Amsterdam 8 / Zeeland 4 / Maas 2 / Noord-Holland 2 = 16 fixed; 17th "NOT an
Amsterdam seat … by beurten among Zeeland, the Maas and North-Holland … brought in by the most
votes"; correctly explains the device keeps Amsterdam (8/17) short of a majority. v2's quoted
Dutch matches the corpus verbatim and its translation matches the held-out key.

**Traps:**
- "17 from Amsterdam" misread → **AVOIDED** (v2 states the 17 is the total board, Amsterdam 8).
- 17th seat given to Amsterdam / rotated among all chambers → **AVOIDED** (v2 explicitly
  excludes Amsterdam and lists only the three groupings).

Minor: v2 adds a defensible note mapping "de Maaze / Noordholland" to the later
Rotterdam+Delft / Hoorn+Enkhuizen chambers — consistent with the key, no error.

---

### Sub-Q2 — Coen's Banda dispatch, 6 May 1621 — VERDICT: **MISTRANSLATION / FRANKENSTEIN (both parts wrong)**

This is the decisive sub-question and the locus of the cross-arm conflict. I resolved it
directly from the frozen ground-truth artifact.

**Corpus Dutch I read** (`nationaalarchief-banda.html`, "Wat staat er precies in het verslag
van J.P. Coen?", Hertaling — verified verbatim in the file):

> "In deze ontmoeting kregen wij **35 gewonden en 9 doden, waaronder kapitein De Ros met zijn
> vaandeldrager.**"

> "In totaal hebben wij **omtrent 1200 zielen gekregen (red.: zijn circa 1200 man overleden).**
> Daarnaast zijn nog verscheidene andere gedood."

My translation:
> "In this encounter we got **35 wounded and 9 dead, among them captain De Ros with his
> standard-bearer.**"
> "In all we have **'got' about 1200 souls (editor's note: about 1200 people died).** Besides
> these, various others were killed."

**Ground-truth answer (matches the held-out key exactly):**
- (a) **9 killed, 35 wounded**, and a **named officer WAS lost — captain De Ros, with his
  standard-bearer (vaandeldrager).**
- (b) The ~1,200 = **Bandanese DEAD**; the corpus's own editorial gloss spells it out:
  "zijn circa 1200 man overleden" (~1,200 people died). It is a euphemistic body count, not
  captives.

**What v2 actually wrote:**
- (a) "**1 killed and 4–5 wounded** … **no named officer was lost** (the named captain, Vogel,
  led the charge and survived)"; campaign total "5 killed and about 20 wounded."
- (b) "The ~1,200 is **NOT a death toll** … the number of Bandanese **taken alive / captured
  ('becomen') and deported as prisoners**."

**Every component is wrong, and inverted in the diagnostic direction:**

| Component | Ground truth (corpus) | v2 | Status |
|---|---|---|---|
| Own dead in the engagement | 9 | 1 | WRONG |
| Own wounded in the engagement | 35 | 4–5 | WRONG |
| Named officer lost | **captain De Ros + vaandeldrager** | "none; Vogel survived" | **FABRICATED / SWAPPED** |
| ~1,200 referent | Bandanese **dead** (editor: "overleden") | "captured alive, deported" | **INVERTED REFERENT** |

**Trap scorecard:**
- "1200 zielen/becomen misread as taken/deported rather than deaths" → **TRIGGERED.** v2 takes
  the literal "received souls" reading and reports deportation — exactly the inverted referent
  the corpus editor's note exists to prevent. v2 even congratulates itself for catching this
  ("methodology/referent lens prevented a present-but-wrong reading of '1,200' as a death
  toll") — i.e. it confidently asserts the *opposite* of the truth.

**Fabrication analysis (why this is a Frankenstein, not an honest miss):**
v2 did not translate the frozen ground-truth artifact. It substituted an **off-corpus source**
— the Colenbrander *Bescheiden* edition on archive.org (`fetched/04-coen-bescheiden-v1-djvu.txt`)
— which is **not in the frozen corpus** (the corpus's designated Banda source is
`nationaalarchief-banda.html`; see `source-excerpts.md`). From that substitute it produced:
- a different casualty quote ("een van d'onse doot geschoten … 4 a 5 gequest"),
- a different campaign total ("5 mannen verlooren … 20 gequeste"),
- a **named captain "Vogel"** who replaces the actual lost officer De Ros,
- a "789 / 287 / 256 / 246" deportation manifest,
- a "van Slamma gelicht 1200 sielen" reading that recasts the dead as captives.

I could not confirm these strings exist verbatim in the archive.org text (the fetch returned
only front matter), so they are at best real-but-off-corpus and at worst invented. Either way,
**measured against the frozen ground truth they are fabricated referents**: a captain who is
not the one the source names, casualty numbers an order of magnitude off, and the 1,200
referent flipped from dead to deported. This is the canonical Frankenstein pattern: a fluent,
internally-consistent, heavily-cited answer that is wrong because it is built from the wrong
body. The dense citation scaffolding ("fetched/04, L31276-78", "L31790-91", confidence HIGH)
makes the error *more* dangerous, not less.

**Cross-arm conflict resolution (load-bearing):** The conflict was between
"~9 dead / 35 wounded, Captain de Ros + ensign lost" and "~1 killed / 4–5 wounded, no officer
lost, Capt. Vogel survived." **The frozen corpus settles it unambiguously: 9 dead / 35
wounded, captain De Ros + his standard-bearer lost is CORRECT.** v2 is the arm holding the
**wrong** side (1 killed / 4–5 wounded / Vogel survived), and "Captain Vogel" is a **fabricated
named officer** — there is no Vogel in the ground-truth casualty line; the lost officer is
De Ros. v2's "no officer lost" is also false.

---

### Sub-Q3 — Van Riebeeck Daghregister heading, Dec 1651 — VERDICT: **CORRECT**

**Corpus Dutch I read** (`nationaalarchief-cape-1652.html`, "Wat staat er precies in de brief
van Van Riebeeck?", verified verbatim):

> "December 1651 Int schip den Drommedaris / Daghregister gehouden bijden opper-coopman Jan
> Anthonissen van Riebeecq vertrocken per de schepen Drommedaris, Reijger ende Goede Hope voor
> opperhooft naer Cabo de Bona Esperance … uijt Texel vande Camer Amsterdam."

**Ground-truth answer:** (a) ships *Drommedaris, Reijger, Goede Hope*; (b) **oppercoopman**
sailing **voor opperhooft** (chief merchant as expedition head) — **NOT governor**; (c)
departed **uijt Texel**, under **de Camer Amsterdam**.

**v2's answer:** (a) Drommedaris, Reijger, Goede Hoope; (b) "rank **oppercoopman** … sailing
**voor opperhooft** — i.e. as the commander / chief of the voyage and intended head of the
post"; (c) "out of Texel … under the Chamber of Amsterdam." Quoted Dutch matches the corpus;
translation matches the key.

**Traps:**
- van Riebeeck mislabeled "governor" → **AVOIDED** (v2 gives oppercoopman/opperhooft and never
  upgrades the rank).
- "departed from Amsterdam" / chamber-as-port conflation → **AVOIDED** (v2 says out of Texel,
  chamber = Amsterdam). v2 sourced this to the DBNL critical edition rather than the
  bronnenbox, but the facts are identical to the frozen artifact, so no fidelity error.
- ship miscount / "Goede Hope" as destination → **AVOIDED** (all three named, destination
  correctly "Cabo de Bona Esperance").

---

## B. Primary-question load-bearing claims (sampled)

I sampled 10 load-bearing claims and checked each cited source against the frozen corpus
(NA introduction PDF text-extracted at 399 k chars; octrooi HTML verbatim).

| # | Claim (report) | Cited src | Verified in corpus? | Status |
|---|---|---|---|---|
| 1 | Charter "allowed the Company far reaching rights … build forts; employ soldiers; conclude treaties …; appoint judges" | NA intro fetched/05 | "far reaching rights overseas … build forts … employ soldiers; conclude treaties with Asian rulers; and appoint judges" — exact | SUPPORTED |
| 2 | Octrooi Art. III: College "zal te zamen komen, om te resolveren, wanneer men zal equiperen, met hoeveel schepen, waar men die zal zenden …" | vocsite octrooi fetched/01 | Present verbatim (Article III in HTML) | SUPPORTED |
| 3 | Admiral of outbound fleet held "supreme command in Asia and all the Company's employees were subject to him" | NA intro fetched/05 | Verbatim in PDF | SUPPORTED |
| 4 | Batavia became "rendez-vous for the Company's shipping traffic" | NA intro fetched/05 | "rendez-vous for the Company's shipping traffic" verbatim | SUPPORTED |
| 5 | generale missive = Gov-Gen & Council report to Heren XVII | NA intro fetched/05 | "generale missive … from the Governor-General and Council of the Indies" verbatim | SUPPORTED |
| 6 | generale eis van Indië = order of monies/goods/ships/crews | NA intro fetched/05 | "generale eis van Indië … amount of monies, goods, ships and crews" verbatim | SUPPORTED |
| 7 | "world monopoly on fine spices" frames the Asian effort | NA intro fetched/05 | "win the world monopoly on fine spices" verbatim | SUPPORTED |
| 8 | GG + Raad van Indië created 1609 as Asian coordination point | NA intro fetched/05 (+ corpus political-structure) | Resolution of 1 Sep 1609 in corpus excerpts; PDF describes GG/Council | SUPPORTED |
| 9 | van der Hagen's Dec-1603 **sealed** instructions ordered war on Iberians | en.wikipedia fetched/08 (tertiary) | NOT in frozen corpus; tertiary; report flags it as MEDIUM and qualitative only | WEAK-but-DISCLOSED (not counted unsupported: v2 labels it tertiary, load-bearing on no number) |
| 10 | NA intro dates Banda conquest to 1622 vs. report's 1621 | NA intro fetched/05 | PDF: "conquest of the Banda Archipelago in 1622" — report correctly flags the discrepancy | SUPPORTED + honestly disclosed |

**Primary-question unsupported count: 0/10** load-bearing claims unsupported (claim 9 is a
disclosed tertiary illustration carrying no figure; not scored as unsupported). The primary
answer is genuinely strong and well-sourced. The damage is concentrated entirely in Sub-Q2.

---

## C. Over-kill check (v2-specific)

v2's protocol advertises a "kill-list / figure-ledger" that drops unsupportable claims and a
"figure-provenance" pass. Reported result: **"DROPPED 0/13 quantitative claims," "Figure-ledger
orphans: 0/7," "synth-introduced figures: 0/6."**

- **Over-kill of true claims: 0.** No true, supportable claim was wrongly dropped or hedged into
  uselessness. Every primary-question figure I could verify (8/4/2/2/17 seat split; the three
  ship names; Texel/Amsterdam chamber) survived intact and correctly. So on the narrow brief
  ("did v2 kill anything true?") v2 scores clean — **0 over-kill.**

- **But the kill-list catastrophically UNDER-killed where it mattered.** The ledger certified
  the Sub-Q2 figures (1 dead, 4–5 wounded, 5 dead/20 wounded, ~1,200 captured, 789/287/256/246)
  as "literal-presence-Y in its cited primary artifact." That certification is *true of the
  off-corpus archive.org file v2 chose* and *false of the frozen ground truth*. The mechanism
  failed open: "present in the source I cited" was treated as equivalent to "correct," so a
  whole cluster of wrong/fabricated figures and a fabricated officer passed with **Confidence:
  HIGH** and a self-congratulatory "the one catch a provenance-only skeptic would have missed."
  The ledger's literal-presence test has **no defense against citing the wrong document** — and
  that is exactly the failure mode that occurred. The over-kill guard is working as designed;
  the **corpus-grounding guard is the missing control**, and its absence is what sank Sub-Q2.

**Net:** over-kill = 0 (nothing true was lost), but the figure-ledger's clean self-report is
**not trustworthy** — it green-lit the run's single largest fidelity failure.

---

## D. Metrics

```
ARM: v2
Sub-Q1 (octrooi seats):      CORRECT        — Amsterdam-17th trap AVOIDED
Sub-Q2 (Banda casualties):   FRANKENSTEIN   — 1200-as-deaths trap TRIGGERED; officer fabricated (Vogel ≠ De Ros)
Sub-Q3 (Cape heading):       CORRECT        — governor & from-Amsterdam traps AVOIDED

Translation-fidelity errors (count): 4
  - own dead 9 → reported 1
  - own wounded 35 → reported 4–5
  - named officer De Ros (+ standard-bearer) lost → reported "none lost, Vogel survived" (fabricated officer)
  - ~1,200 = Bandanese DEAD → reported "captured alive / deported" (inverted referent)

Unsupported-claim rate (primary sample): 0 / 10  (0%)
  — primary answer is solidly corpus-grounded
Unsupported / fabricated-referent rate (Sub-Q sample, the stress test): 4 / 4 components in Sub-Q2 wrong;
  across all sub-Qs: Q1 clean, Q3 clean, Q2 fully fabricated.
Fabricated named entity: 1 (Captain "Vogel" as the surviving vanguard officer; not in ground truth)
Figure orphans (true, against frozen corpus): Sub-Q2 figure cluster (1 / 4–5 / 5 / 20 / 1200-as-captured
  / 789-287-256-246) — all orphaned w.r.t. the frozen ground truth, sourced to an off-corpus artifact.
  v2's self-reported orphan tally (0/7) is FALSE.
Over-kill (true claims wrongly killed): 0
Live-URL rate: 12 / 12 (100%) — verified by url_liveness.sh; the off-corpus archive.org URLs are live,
  which is exactly why the bad citations looked authoritative.
```

**Single most important finding:** v2 answered Sub-Q2 by translating an **off-corpus**
Colenbrander/archive.org edition instead of the frozen ground-truth bronnenbox page, and from
it produced a fully **Frankenstein** answer: **1 dead / 4–5 wounded / "no officer lost, Captain
Vogel survived" / "~1,200 captured alive and deported."** The frozen corpus is unambiguous and
settles the cross-arm conflict the *other* way: **9 dead, 35 wounded, captain De Ros and his
standard-bearer killed, and ~1,200 = Bandanese DEAD (corpus editor's gloss: "circa 1200 man
overleden").** "Captain Vogel" is a fabricated officer. Worst of all, v2's own kill-list /
figure-ledger **certified these fabrications as HIGH-confidence, zero-orphan** and even claimed
its "referent lens" had *avoided* the 1,200 trap — when in fact it walked straight into it. The
hardened protocol's literal-presence check has no guard against citing the wrong source, so it
gave false assurance for the run's biggest error. Q1 and Q3 remain genuinely excellent and the
primary answer is well-grounded; the failure is isolated but severe and self-masked.
