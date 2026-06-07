# Native arm — VOC expedition goals / issuing documents 1602–1700 (+ 3 Dutch-primary sub-questions)

**Arm:** native (bundled `/deep-research` skill — the native Claude Code Workflow harness).
**Run date:** 2026-06-07. **Run ID:** `wf_291b4c7c-e54`.
**Protocol:** Scope (decompose into 5 search angles) → Search (5 parallel WebSearch agents)
→ Fetch (URL-dedup, fetch top sources, extract falsifiable claims) → Verify (3-vote
adversarial verification per claim; 2/3 refutes kills) → Synthesize (merge dupes, rank by
confidence, cite). Ran live from the open web; given ONLY the verbatim question (no answer
key, no corpus, no hint it was a bake-off).

## Run cost / scale (for the scorecard)
- **Agents:** 103
- **Subagent tokens:** ~2,323,533 (~2.32M)
- **Tool uses:** 757
- **Wall-clock:** 1,634,639 ms ≈ **27.2 min**
- **Pipeline:** 5 angles → 21 sources fetched → 82 claims extracted → 25 verified → 23
  confirmed / 2 killed → 14 findings after synthesis (3 URL dupes, 5 budget-dropped).

---

## Executive summary

VOC expeditions and operations, 1602–1700, were directed through a layered set of issuing
documents whose authority traced back to the 1602 charter (octrooi) granted by the
States-General. The charter created the central board of seventeen directors (Heren XVII) and
fixed both who governed and how: it granted a 21-year monopoly east of the Cape of Good Hope
and through the Strait of Magellan, and delegated quasi-sovereign powers (negotiating with
Asian rulers, building forts, administering justice, recruiting soldiers, waging war on behalf
of the States-General). From 1609 the directors placed supreme command in Asia in a
Governor-General assisted by a Council of the Indies (Raad van Indië), seated from 1619 at
Batavia, which became the rendezvous of Company shipping. Goals reached expeditions through
specific document types: the directors' *generale instructie* (general orders, e.g. the 1650
set classifying establishments as conquest / exclusive-contract / treaty), voting instructions
to chamber delegates before each Heren XVII meeting, and in wartime secret routes and signals
compiled by a *secrete commissie*; while Batavia's High Government reported and steered
decisions upward through the annual *generale missive* and the *generale eis van Indië*.

On the three Dutch-source sub-questions the primary texts give clean answers: (1) the charter
seats 8 from Amsterdam, 4 from Zeeland, 2 from the Maas (Rotterdam+Delft), 2 from
Noord-Holland (Hoorn+Enkhuizen) = 16, with the seventeenth seat rotating "by beurten" among
Zeeland, the Maas, and Noord-Holland by majority vote, deliberately denying Amsterdam an
outright majority; (2) in the Banda hill engagement Coen reported his own losses as 35 wounded
and 9 dead, including Captain De Ros and his standard-bearer (vaandeldrager); the ~1,200 figure
is left **unresolved** (see below); and (3) Van Riebeeck's December 1651 register heading names
three ships (Drommedaris, Reijger, Goede Hoope), his rank/role as *oppercoopman* serving as
*opperhooft*, sailing from Texel under the *Camer Amsterdam*.

---

## Dutch sub-questions

### Sub-Q1a — octrooi seat allocation — confidence HIGH, vote 3-0
The 1602 VOC charter seats the Heren XVII as Amsterdam 8, Zeeland 4, the Maas/Maaze
(Rotterdam+Delft combined) 2, and Noord-Holland (Hoorn+Enkhuizen combined) 2, totaling 16
fixed seats. Equivalently stated in scholarship as the four smaller chambers (Delft,
Rotterdam, Hoorn, Enkhuizen) holding one seat each.

> Primary charter text (Wikisource octrooi, Article II), verbatim: *"die gehouden zal werden
> van 17 persoonen, daar in uit de kamer van Amsterdam zullen compareren 8, uit Zeeland 4, uit
> de Maaze 2, ende van gelyken uit Noordholland 2"* (8+4+2+2 = 16 fixed seats), confirmed
> word-for-word at vocsite.nl. The Nationaal Archief introduction and the Gaastra/Brill
> inventory restate the same allocation. The 2+2 regional grouping (Maas = Rotterdam+Delft;
> Noord-Holland = Hoorn+Enkhuizen) and the four-single-seat phrasing are arithmetically
> identical.

Sources: nl.wikisource.org/wiki/Octrooi_van_de_VOC ·
nationaalarchief.nl NL-HaNA_1.04.02_introduction-VOC.pdf · sejarah-nusantara.anri.go.id
brillvocinventaris_gaastraen.pdf

### Sub-Q1b — the seventeenth-seat rule — confidence HIGH, vote 3-0
The seventeenth seat is NOT supplied by Amsterdam (which already holds 8); it rotates by turns
("by beurten") among the chambers of Zeeland, the Maas, and Noord-Holland, decided by majority
vote ("by de meeste stemmen"). The deliberate purpose, attested in Dutch, was to prevent
Amsterdam from holding an outright majority.

> *"wel verstaande, dat de zeventiende persoon by beurten van die van Zeeland, Maaze ende
> Noordholland, zal worden in de Vergadering gebragt by de meeste stemmen"* — 17th seat rotates
> among Zeeland, Maas, and Noord-Holland (explicitly excluding Amsterdam) by majority vote. NA
> introduction: "the seventeenth member would be appointed in turn by one of the chambers other
> than Amsterdam." Dutch Wikipedia (Heren XVII): *"Daarmee werd voorkomen dat Amsterdam een
> absolute meerderheid kreeg."*

Sources: nl.wikisource.org/wiki/Octrooi_van_de_VOC · NA introduction PDF ·
Gaastra/Brill inventory.

### Sub-Q2a — Banda hill-engagement losses + officer — confidence HIGH, vote 3-0
In the Banda hill engagement, Coen's 6 May 1621 dispatch reports his own (VOC) force suffered
**35 wounded and 9 dead, including Captain De Ros and his standard-bearer (vaandeldrager).**

> Nationaal Archief bronnenbox (modernized-Dutch rendering of Coen's dispatch, NA 1.04.02 inv.
> 1073), exact sentence: *"In deze ontmoeting kregen wij 35 gewonden en 9 doden, waaronder
> kapitein De Ros met zijn vaandeldrager."* The surrounding paragraph confirms "deze
> ontmoeting" is the hill/ridge engagement. An apparent contradiction (Dutch Wikipedia
> "Bloedbad van Banda" gives 6 dead/27 wounded) is tied to the separate 11–12 March conquest,
> a different event, so it does not refute the hill-engagement figures.

Source: nationaalarchief.nl bronnenbox "hoe-ging-het-verder-op-banda".

### Sub-Q2b — the ~1,200 figure — confidence LOW, **UNRESOLVED** (the "died" reading refuted 1-2)
The roughly 1,200 figure Coen reports (*"omtrent 1200 zielen gekregen"*) is **genuinely
ambiguous**: the bronnenbox editorial gloss reads it as ~1,200 Bandanese DEAD, but other
sources (PALA / Westfries Museum) frame ~1,200 as people DEPORTED/enslaved ("taken away"), and
"zielen gekregen" literally reads as souls captured/taken. The specific "died" interpretation
failed verification (vote 1-2); the ambiguity itself is well-attested.

> The verifier noted real ambiguity: the bronnenbox glosses *"omtrent 1200 zielen gekregen"* as
> ~1,200 dead, but PALA/Westfries Museum frames ~1,200 as deported, and the literal Dutch
> *"zielen gekregen"* = souls captured/taken (favoring captured/enslaved over killed). What the
> ~1,200 figure refers to therefore cannot be stated with confidence from the surviving
> evidence — this part of sub-question 2 remains open.

Source: nationaalarchief.nl bronnenbox "hoe-ging-het-verder-op-banda".

### Sub-Q3a — the three ships — confidence HIGH, vote 3-0
The December 1651 outbound Cape voyage register heading names three ships: the **Drommedaris**,
the **Reijger**, and the **Goede Hoope**.

> DBNL primary transcription (NA 1.04.02 inv. 1188 fol. 189): *"Daghregister, gehouden bij den
> oppercoopman Jan Anthonisz. van Riebeeck, vertrocken per de schepen Drommedaris, Reijger ende
> Goede Hoope..."* Correctly scoped to the three ships in the register heading; the broader
> fleet of five (adding Walvis/Oliphant, which arrived late) does not refute it.

Sources: dbnl.org rieb001dagh01_01 (…_0001 / …_0004 / colofon).

### Sub-Q3b — rank/role — confidence HIGH, vote 3-0
Van Riebeeck's shipboard rank/role in the register heading is **oppercoopman** (chief
merchant), serving **voor opperhooft** (as chief/commander) of the expedition. The heading uses
"opperhooft", NOT "commandeur" (his formal administrative title elsewhere) and NOT "gouverneur".

> DBNL heading: *"...gehouden bij den oppercoopman Jan Anthonisz. van Riebeeck ... voor
> opperhooft naer Cabo de boä Esperance."* Verifiers confirmed the heading does NOT use
> "commandeur", so the claim is not a misread.

Sources: dbnl.org rieb001dagh01_01 (…_0001 / …_0004 / colofon).

### Sub-Q3c — port + chamber — confidence HIGH, vote 3-0
Van Riebeeck departed from the port of **Texel** ("uijt Texel") and sailed under the
**Amsterdam chamber** ("van de Camer Amsterdam").

> DBNL heading: *"...in dienst van de Generale Vereenighde Nederlantsche G'octroyeerde
> Oostindische Comp. uijt Texel, van de Camer Amsterdam."* The competing claim that he departed
> "from Amsterdam" was **REFUTED 0-3** — the port was Texel, Amsterdam being the chamber.

Sources: dbnl.org rieb001dagh01_01 (…_0001 / …_0004).

---

## Primary-question findings

- **Issuing documents (HIGH, 3-0):** Goals/orders reached expeditions through the directors'
  *generale instructie* (1650 set classifying establishments into conquest / exclusive-contract
  / treaty); voting instructions to chamber delegates before each Heren XVII meeting; in
  wartime, secret routes and signals compiled by a *secrete commissie*; the *generale eis van
  Indië* (Batavia's annual demand for monies/goods/ships/crews, a guideline in Heren XVII
  sessions); and the *generale missive* (Batavia's annual report upward).
- **Generale Missiven (HIGH, 3-0):** annual general letters in which the Governor-General and
  Council reported to the Heren XVII on operations in Asia and South Africa; mandatory (signed
  by all, dissent not permissible), published series from 1610.
- **1602 charter framework (HIGH, 3-0):** 21-year monopoly east of the Cape / through the
  Strait of Magellan; quasi-sovereign powers on behalf of the States-General (negotiate, build
  forts, administer justice, recruit soldiers, marry colonists, wage war).
- **Command structure (HIGH, 3-0):** pre-1609 the outbound fleet admiral held supreme command
  in Asia; 1609 directors created the Governor-General + Raad van Indië; Batavia (founded 1619)
  became seat of the High Government and the mandatory shipping rendezvous.
- **Capital/operations apportionment (MEDIUM, 2-1):** Amsterdam ½, Zeeland ¼, four smaller
  chambers 1/16 each — same anti-Amsterdam-majority logic (charter groups the smaller chambers
  regionally at 1/8 each, arithmetically identical).
- **Citation match (HIGH, 3-0):** Coen's Banda dispatch is dated 6 May 1621, addressed to the
  Heren XVII, NA 1.04.02 inv. 1073 — matching the question's citation exactly.
- **Negative/scope (HIGH, 3-0):** the NA educational bronnenbox summary for the 1602 charter
  does NOT reproduce the Heren XVII article or per-chamber allocation; Sub-Q1 must be answered
  from the charter text itself.

---

## Refuted claims (killed in verification)
1. **"~1,200 = ~1,200 people died"** (the editorial-gloss reading stated as fact) — vote 1-2.
   Source: NA bronnenbox. (Ambiguity surfaced; "died" not asserted as settled.)
2. **"The 1651 voyage departed from Amsterdam"** — vote 0-3. Port was Texel; Amsterdam = chamber.
   Source: dbnl.org colofon.

---

## Caveats (self-reported by native)
1. Sub-Q2b is NOT resolved — the ~1,200 referent is genuinely ambiguous (killed vs
   deported/enslaved); the "died" reading was refuted 1-2 and should not be stated as settled.
2. The Banda casualty figures (35 wnd / 9 dead / De Ros) come from the bronnenbox's
   MODERNIZED-Dutch rendering, not a folio-level transcription of the original manuscript; the
   competing 6 dead / 27 wounded belongs to the separate 11–12 March conquest.
3. The 1/16-per-chamber apportionment (medium, 2-1) is a secondary-source restatement; the
   charter literally groups the smaller chambers regionally (1/8 each), arithmetically identical.
4. The NA VOC-introduction PDF could not be byte-verified in one pass (WebFetch returned
   binary; a cached extraction resolved to a different Gaastra course PDF) and the Gaastra/Brill
   inventory PDF returned HTTP 403 — content confirmed via search + Encyclopedia.com's verbatim
   Gaastra text.
5. The issuing-document inventory slightly conflates mission/route orders (generale instructie,
   secret routes) with upward governance-reporting documents (generale missive, generale eis).
6. Scope note: sourcing centers on the 1602 charter and three specific 1621/1651 documents; the
   report does not systematically cover the full 1602–1700 expedition-by-expedition range.

---

## Open questions
- What does Coen's ~1,200 ("omtrent 1200 zielen gekregen") actually denote — Bandanese killed,
  or deported/enslaved? Needs a folio-level reading of the original Dutch in NA 1.04.02 inv.
  1073 (+ comparison with Coen's 16 Nov 1621 follow-up).
- Beyond the generale instructie / eis / missive / voting instructions / wartime secret routes,
  what were the standard per-expedition documents (individual sailing orders, the artikelbrief,
  secrete resolutien) and their concrete goals across 1602–1700?
- Does the original manuscript heading of NA 1.04.02 inv. 1188 fol. 189 match the DBNL/published
  transcription exactly (spelling, rank wording), or did the edition normalize it?
- How did the 1650 conquest / exclusive-contract / treaty classification translate into
  differing concrete goals issued to expeditions bound for each category of establishment?

---

## Sources (21 fetched; quality as classified by native)
**Primary:** NA introduction PDF · Huygens generale-missiven (×2) · nl.wikisource octrooi · NA
bronnenbox octrooi-1602 · NA bronnenbox banda · dbnl rieb001dagh01_01 (_0001 / _0004 / colofon).
**Secondary:** Gaastra/Brill inventory · en.wikipedia VOC · vocwarfare.net communication ·
vocsite.nl octrooi1602 · encyclopedia.com Heeren XVII · vocsite.nl organisatie · nl.wikipedia
VOC · nl.wikipedia Bloedbad van Banda · nl.wikipedia VOC-verovering Banda.
**Unreliable (0 claims used):** what-when-how.com · rupertgerritsen.tripod.com VOC_Charter PDF ·
eggsa.org oldest-document.
