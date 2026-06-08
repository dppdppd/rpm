# Adversarial validation — per-lens panel rows

Four lenses reviewed each load-bearing claim: **provenance** (does the stated
source actually contain it), **cross-source** (do independent sources agree),
**referent** (does the claim point at the right thing), and **alt-hypothesis**
(is there a better rival reading). Verdicts: keep / flag / kill. The final
decision column reflects the synthesis applied in the report.

Legend for "Decision": kept = asserted as-is; replaced = rival asserted, original
refuted; contested = both readings presented at MEDIUM-or-lower; killed = removed,
no rival.

---

## Claim 1 — 1602 octrooi: founding date, monopoly, and powers

| Lens | Verdict | Note |
|---|---|---|
| provenance | flag | Date/monopoly/forts/treaties/justice officers confirmed in nl.wikisource + vocsite; "striking coins" and "establishing colonies" appear nowhere in the 46-article text — secondary glosses, not the charter. |
| cross-source | flag | Article XXXV grants treaties/forts/governors/troops/justice in two transcriptions; no "munten slaan" or colony language; the powers list over-states the charter by two items. |
| referent | flag | Core verbatim in two transcriptions; "striking coins" not in the text, "establishing colonies" an editorial gloss on fort/garrison language — genuinely contested, not a clean kill. |
| alt-hypothesis | flag | Confirms date/issuer/monopoly/Art XXXV grants; coins+colonies absent from the 46 articles; VOC coin-striking began 1640s under separate authority. |

**Decision: contested.** Both readings presented; primary-text reading (no coins/colonies) at HIGH, secondary summary at MEDIUM.

Reviewer re-verification: `munt`, `colonie`, `coloni`, `volkplant`, `penningen/geld slaan` all return -1 in the full transcription; Articles XXXIV (monopoly) and XXXV (powers) read directly; dating clause "den 20den Maart des jaars 1602" confirmed.

---

## Claim 2 — Heren XVII: six chambers and seat allocation

| Lens | Verdict | Note |
|---|---|---|
| provenance | flag | Stated source and charter use regional groupings (Maas 2, Noord-Holland 2), not four named cities; 17th seat rotates among Zeeland/Maas/Noord-Holland, not "Zeeland or a smaller chamber." |
| cross-source | kill | Charter Article II: four blocs (Amsterdam 8, Zeeland 4, de Maaze 2, Noordholland 2); Delft+Rotterdam share Maas, Enkhuizen+Hoorn share Noord-Holland — claim misreads as one each. |
| referent | kill | Four voting bodies, not six; smaller chambers grouped; 17th rotates among the three minor blocs by majority vote. |
| alt-hypothesis | keep | Six-chamber delegate counts and rotating 17th confirmed by charter + Dutch Wikipedia + encyclopedia.com as consistent with stated source. |

**Decision: contested.** Seat arithmetic is identical across readings (four small-chamber seats); the dispute is six-cities labelling vs. four-blocs charter language. Charter-bloc reading at HIGH, city reading at MEDIUM.

Reviewer re-verification: Article II text identical in nl.wikisource and vocsite — "uit de kamer van Amsterdam ... 8, uit Zeeland 4, uit de Maaze 2, ende van gelyken uit Noordholland 2; ... de zeventiende persoon by beurten van die van Zeeland, Maaze ende Noordholland ... by de meeste stemmen."

---

## Claim 3 — Heren XVII autumn meeting: single supply agenda item

| Lens | Verdict | Note |
|---|---|---|
| provenance | keep | Autumn meeting, exact quoted agenda wording, and ship list with per-ship personnel all verbatim at vocwarfare.net/thesis/3/supplies. |
| cross-source | keep | All elements directly confirmed; author cites the VOC Resolutions of the Heren XVII as primary basis. |
| referent | keep | Exact agenda-item wording + "a list of all the ships ... and a specification of the amount of personnel each ... was to carry" word-for-word. |
| alt-hypothesis | keep | Every element reproduced verbatim. |

**Decision: kept (HIGH).**

Reviewer re-verification: passage read directly — autumn meeting, single agenda item, 22 Aug 1658 example (3,970 heads, 3/5 sailors 2/5 soldiers), ship list with personnel spec all present.

---

## Claim 4 — Two-stage eis + Generale Eis approval

| Lens | Verdict | Note |
|---|---|---|
| provenance | flag | Second half (Generale Eis "approved and would be fulfilled") verbatim in stated source; the two-stage provisional/definitieve eis framework is NOT on that page; the eis van retouren flows the opposite direction from what the claim asserts. |
| cross-source | keep | Both elements confirmed — Generale Eis half verbatim at supplies page; two-stage eis van retouren confirmed by the Brill/ANRI archives reference work. |
| referent | flag | Claim conflates eis van retouren (goods FROM Asia) with Generale Eis (goods TO Batavia) — opposite directions; two-stage process applies only to the eis van retouren. |
| alt-hypothesis | flag | Fuses two distinct instruments; attributes combined description to a page covering only the Generale Eis side. |

**Decision: contested.** Two-stage process is real (HIGH) but belongs to the eis van retouren, not the Generale Eis; corrected referent at HIGH, original conflation at MEDIUM.

Reviewer re-verification: supplies page confirms Generale Eis half verbatim and contains no two-stage framework; NA introduction confirms two-stage process applies to the eis van retouren ("a list of the products that the directors wished to receive with the next return fleet from Asia ... the definitive eis was only decided upon after the autumn auctions").

---

## Claim 5 — Heren XVII fleet instructions: Portuguese-damage clauses

| Lens | Verdict | Note |
|---|---|---|
| provenance | kill | Source says the autumn 1661 meeting STRUCK the Portuguese-damage clauses as peace prep; claim inverts it. No Cape orders — covert traffic ran to Batavia (Nieuwenhove) and Ceylon. |
| cross-source | kill | Source says the opposite; "secret orders to the Cape" absent entirely. |
| referent | kill | Meeting struck damage clauses in anticipation of peace; claim asserts the reverse; no Cape/incoming-fleet support. |
| alt-hypothesis | kill | 1661 redesign removed Portuguese-damage clauses; exact opposite of claim; no Cape secret orders. |

**Decision: replaced.** Unanimous kill of the original; rival reading (clauses struck out) is well-sourced and asserted in the report. Original goes to refuted.md.

Reviewer re-verification: communication page read directly — "designing new instructions for the outgoing fleets, striking all the clauses about inflicting as much damage as possible on the Portuguese"; secret resolutions discussed only as separate books surviving for the late 18th century, no Cape orders.

---

## Claim 6 — Hoge Regering: 1609 formation, nine members from 1617

| Lens | Verdict | Note |
|---|---|---|
| provenance | flag | Facts confirmed by Niemejer/ANRI-Brill scholarship; but the cited URL (1.04.17) is a bare finding aid with none of the narrative; substantive text lives in 1.04.02 introduction + Brill chapter. |
| cross-source | flag | NA introduction confirms 1609 / GG+Raad / Batavia seat / highest authority, but states the aim was "six councillors besides the Governor-General," conflicting with "nine regular members from 1617." |
| referent | keep | Brill/ANRI states "Council of the Indies of which there were (from 1617 onwards) nine members," matching the claim; 1.04.17 confirms instructies for scheepsgezagvoerders. |
| alt-hypothesis | kill | NA introduction (Gaastra) says six councillors besides the GG, not nine; "seated at Batavia" misleading pre-1619; nine-member figure a clear error vs. the authoritative introduction. |

**Decision: contested.** Membership number genuinely conflicts (six+GG in NA introduction vs. nine from 1617 in Brill/Niemejer) and the council size fluctuated; surrounding facts (1609, GG+Raad, Batavia seat from 1619, highest authority, instructions to commanders) confirmed at HIGH; the number left unsettled.

Reviewer re-verification: NA introduction read directly — "In 1609 the directors decided to place the supreme command in Asia in the hands of a Governor-General ... assisted by a Raad van Indië"; "Batavia was founded in 1619 ... This became the seat"; "eventually the aim was to have six councillors besides the Governor-General." The Brill "nine from 1617" source was not independently fetched in this run.

---

## Claim 7 — generale eis van Indië compiled by the Hoge Regering

| Lens | Verdict | Note |
|---|---|---|
| provenance | kill | Stated URL (bgb.huygens.knaw.nl/?page_id=40) contains no mention of generale eis / Hoge Regering; passage is in the NA VOC introduction, not the cited URL. |
| cross-source | keep | Confirmed verbatim by the Brill VOC archives publication; stated URL does not contain it. |
| referent | flag | bgb URL cannot support the claim; corroborators confirm the Hoge Regering compiled the generale eis; the adjustment detail (who adjusts which order) is contestable. |
| alt-hypothesis | flag | Substantive claim accurate per NA introduction; stated URL wrong (cargo database, no mention). |

**Decision: contested → asserted with corrected source.** The substance (Hoge Regering compiles the generale eis van Indië, guideline for Heren XVII, individual establishment orders included and adjustable) is confirmed VERBATIM in the NA introduction; only the stated URL was wrong. Asserted at HIGH in the report with the corrected source; the bgb URL is noted as mis-cited.

Reviewer re-verification: NA introduction read directly — "It was also the job of the Governor-General and Council to compile the generale eis van Indië ... in which the amount of monies, goods, ships and crews considered necessary for the business overseas was summed up. In the sessions of the Heren XVII it served as a guideline ... The orders from the various establishments were included in the generale eis; the Governor-General and Council were empowered either to reduce or increase each order."

---

## Claim 8 — Generale Missiven: annual report Batavia → Heren XVII

| Lens | Verdict | Note |
|---|---|---|
| provenance | keep | Stated source confirms all core facts: annual letters, GG+Council, to Heren XVII, on Asia + South Africa, summarising settlement reports for continuous information. |
| cross-source | keep | Huygens KNAW page confirms verbatim; vocwarfare independently calls them "the most important means of communication between patria and Batavia." |
| referent | keep | Core confirmed; "Hoge Regering" a standard synonym; "principal relay document" corroborated. |
| alt-hypothesis | keep | All core elements confirmed in Dutch verbatim. |

**Decision: kept (HIGH).**

Reviewer re-verification: Huygens page read directly — "De generale missiven zijn de jaarlijkse brieven waarin Gouverneur-Generaal en Raden ... aan de Heren Zeventien een algemeen verslag gaven van het bedrijf in Azië en Zuid-Afrika. Tevens vatten zij de berichten samen die ze uit de vestigingen ontvangen hadden ... doorlopende informatie over de VOC-vestigingsgebieden."

---

## Claim 9 — Three-category factory records (missiven / daghregisters / instructies)

| Lens | Verdict | Note |
|---|---|---|
| provenance | kill | Iranica source (stated) blocked by Cloudflare; the clean three-category formulation traces to Van Galen's Arakan paper, describing the Arakan factory only — not the VOC archive as a whole. |
| cross-source | flag | NA introduction frames record categories differently (five categories, two largely lost); instructies appear as outgoing, not a standard incoming category; three-category summary conflicts with how survival is characterised. |
| referent | flag | Exact three-category formulation is from the Arakan paper, not Iranica; NA introduction confirms the three types exist but uses a different top-level structure. |
| alt-hypothesis | keep | Three-category description confirmed verbatim from the Arakan source; NA introduction independently confirms dagregisters, outgoing missiven, instructions to functionaries. |

**Decision: contested.** Substance defensible (all three types existed at factory level), but the schema's origin is a single case study (Arakan), not a general taxonomy; case-specific reading at HIGH, general-taxonomy reading at MEDIUM. Stated Iranica source unverifiable (403).

Reviewer re-verification: NA introduction read directly — "There appear to have been five important categories, but two of these have been almost entirely lost ... the dagregisters (diaries) of the different establishments and the registers of the accountants"; instructie and memories van overgave terms present in the introduction.

---

## Claim 10 — Daghregister van Batavia: 1624–1806, letter register not chronicle

| Lens | Verdict | Note |
|---|---|---|
| provenance | flag | Stated URL returns 403 (verifiable only via cache); the "not a chronicle" framing is contradicted by the NA introduction, which translates dagregister as "diary" kept by the castle secretary. |
| cross-source | keep | All principal claims confirmed by ANRI Sejarah Nusantara (the stated source, authoritative): 1624–1806, register of political advisories/news, thousands of letters, not a chronicle, duty clerk selecting daily. |
| referent | keep | Major sub-claims confirmed by ANRI and corroborated: date range, purpose, letter-register character, duty clerks. |
| alt-hypothesis | keep | Sub-claims confirmed via ANRI cache; NA introduction corroborates the secretary/clerk role. |

**Decision: contested.** The "principally a letter register, not a chronicle" framing (ANRI) conflicts with the "diary kept by the castle secretary" framing (NA introduction); likely two document uses sharing the name. Both presented at MEDIUM; the 1624–1806 span and heavy letter-registration role hold either way. Stated URL DEAD on fetch.

Reviewer re-verification: ANRI URL is DEAD on fetch (confirmed not saved in run); NA introduction read directly and translates dagregister as "diary," and notes Batavia dagregisters survive in the Indonesian National Archives.

---

## Claim 11 — Resoluties of Batavia Castle: signed final decisions of the Hoge Regering

| Lens | Verdict | Note |
|---|---|---|
| provenance | keep | ANRI page describes authorised final decisions of the Supreme Government with holograph signatures; 211,000 pages (1613–1810); distinct from the Daghregister — confirmed by source + Niemejer/Brill. |
| cross-source | keep | Corts Foundation confirms all 330 volumes 1613–1810 digitised; ANRI "~47,500 entries / >211,000 folio pages / original signatures"; Cambridge guide + TANAP confirm Hoge Regering characterisation and distinction from the Daghregister. |
| referent | keep | ANRI (cache) confirms all major sub-claims; TANAP confirms resoluties are formal signed decisions distinct from notulen; 211,000 vs 232,000 is a units difference. |
| alt-hypothesis | keep | Every sub-claim confirmed by ANRI + Corts Foundation; the page/scan discrepancy reflects counting units, not error. |

**Decision: kept (HIGH).** Stated URL returns 403; content verified via Corts Foundation + cache + cross-source.

Reviewer re-verification: not independently re-fetched (URL 403); decision rests on unanimous panel keep across four lenses with the Corts Foundation corroboration cited.

---

## Claim 12 — VOC archive holds the "full range" of document types

| Lens | Verdict | Note |
|---|---|---|
| provenance | flag | Correct authoritative document; most types attested; but "bills of lading" absent, "price lists" not a discrete series, "profit-loss statements" overstates (source describes balance sheets/ledgers), memories van overgave only in a separate transferred archive. |
| cross-source | kill | Source states dagregisters "almost entirely lost" — refutes "full range incl. daghregisters"; "bills of lading" never named. |
| referent | kill | Chapter 3: "No profit and loss account was made up" — they cannot be in the archive; "bills of lading" never named; "full range" framing not supportable. |
| alt-hypothesis | kill | "No profit and loss account was made up"; bills of lading absent; dagregisters "almost entirely lost"; 9,500–10,000 volumes sold winter 1821/1822 — "full range" contradicted by documented gaps. |

**Decision: contested → corrected.** "Full range" framing is wrong in three specific ways (profit-loss never existed; daghregisters largely lost; bills of lading not a named series), all asserted at HIGH from the NA introduction. The genuinely-held types (missiven, resoluties, journals, instructies, eisen, treaties, Batavia–chamber correspondence) are confirmed.

Reviewer re-verification: NA introduction read directly — "No profit and loss account was made up"; "two of these have been almost entirely lost ... the dagregisters"; "9,500 to 10,000 volumes ... sold ... in the winter of 1821/1822"; `bills of lading` / `cognossement` return -1 in the full extract.
