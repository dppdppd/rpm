# Dutch-primary-only sub-questions — 2026-06-07 triplet bake-off

Purpose: stress translation fidelity. Each sub-question is answerable ONLY by
locating the named Dutch source in the frozen corpus and translating the actual
Early-Modern / archival Dutch passage. The wrong answer is a fabricated claim
that a careless agent reaches by mistranslating or attaching the wrong referent
("Frankenstein" risk).

Frozen corpus root:
`/home/coder/projects/VOC/docs/research/voc-expedition-goals-chamber-assignments-1602-1700/fetched/`

---

## PUBLIC sub-questions (given to all three arms)

1. In the 1602 VOC charter (octrooi), the article that sets up the central
   board of seventeen directors specifies how many of the seventeen come from
   each chamber, and gives a special rule for who supplies the seventeenth man.
   Translating that article's Dutch text, state the per-chamber allocation of
   the seventeen seats and the exact rule that determines the seventeenth seat.

2. In Jan Pieterszoon Coen's dispatch to the Heren XVII reporting the events on
   the Banda islands, dated 6 May 1621 (Nationaal Archief, archief 1.04.02,
   inventarisnummer 1073), Coen gives running figures for his own force's
   losses in the hill engagement and a total figure for the Bandanese. From the
   Dutch text, state (a) Coen's own killed and wounded in that engagement and
   any named officer lost, and (b) what the roughly 1,200-figure he reports
   actually refers to.

3. In Jan van Riebeeck's journal (Daghregister) of the December 1651 outbound
   voyage to the Cape of Good Hope (Nationaal Archief, archief 1.04.02,
   inventarisnummer 1188, folio 189), the opening register heading names the
   author, his shipboard rank/role, the ships he sailed with, and the place and
   chamber he departed under. From the Dutch text, name (a) the three ships,
   (b) van Riebeeck's stated rank/role on the voyage, and (c) the port he sailed
   from and the chamber he sailed under.

---

## PRIVATE grading key (NEVER shown to arms — graders only)

### Q1 — 1602 octrooi, Article II (Heren XVII composition)

Source file: `vocsite-octrooi-1602.html`, body, Article "I I" (the second
numbered article, immediately after the chamber-share Article I).

Verbatim Dutch (Valentijn's 1724 modernized rendering of the 1602 text):

> "Dat, zoo dikwils als het van nooden zyn zal een generale Vergadering ofte
> Collegie uit de voorschreve kameren te houden, die gehouden zal werden van 17
> persoonen, daar in uit de kamer van Amsterdam zullen compareren 8, uit Zeeland
> 4, uit de Maaze 2, ende van gelyken uit Noordholland 2; wel verstaande, dat de
> zeventiende persoon by beurten van die van Zeeland, Maaze ende Noordholland,
> zal werden in de Vergadering gebragt by de meeste stemmen; van welke persoonen
> alle zaaken, deze vereenigde Compagnien aangaande, zullen verhandelt worden."

Literal English translation:

> "That, as often as it shall be necessary to hold a general Assembly or College
> drawn from the aforesaid chambers, it shall consist of 17 persons, in which
> from the chamber of Amsterdam 8 shall appear, from Zeeland 4, from the Maze 2,
> and likewise from Noord-Holland 2; it being well understood that the
> seventeenth person shall be brought into the Assembly in turn by those of
> Zeeland, the Maze, and Noord-Holland, by majority of votes; by which persons
> all matters concerning these united Companies shall be transacted."

Correct answer:
- Amsterdam 8, Zeeland 4, the Maze (Rotterdam/Delft) 2, Noord-Holland
  (Hoorn/Enkhuizen) 2 — that is 16 fixed seats.
- The seventeenth (the "Heren Zeventien" namesake) is NOT a fixed Amsterdam
  seat: it is supplied **in rotation ("by beurten") by Zeeland, the Maze, and
  Noord-Holland** — deliberately excluding Amsterdam — and chosen by majority
  vote. This rotation kept Amsterdam from holding an outright majority (8 of 17).

Mistranslation traps:
- Reading "17 persoonen ... uit de kamer van Amsterdam zullen compareren" as
  "17 from Amsterdam" (the 17 is the total board; only 8 are Amsterdam's).
- Claiming the seventeenth seat is Amsterdam's, or rotates among ALL chambers
  including Amsterdam. "by beurten van die van Zeeland, Maaze ende Noordholland"
  explicitly lists only the three non-Amsterdam groupings. An agent that gives
  Amsterdam the deciding 9th vote has fabricated the charter's central
  power-balancing rule.

### Q2 — Banda, Coen's letter of 6 May 1621 (NA 1.04.02 inv.nr. 1073)

Source file: `nationaalarchief-banda.html`, body section "Wat staat er precies
in het verslag van J.P. Coen?", the long "Hertaling" paragraph. (The page gives
a modern-Dutch hertaling of the original letter; the bron line confirms
1.04.02 inventarisnummer 1073.)

Verbatim Dutch (key spans):

> "In deze ontmoeting kregen wij 35 gewonden en 9 doden, waaronder kapitein De
> Ros met zijn vaandeldrager."

> "In totaal hebben wij omtrent 1200 zielen gekregen (red.: zijn circa 1200 man
> overleden)."

Literal English translation:

> "In this encounter we got 35 wounded and 9 dead, among whom captain De Ros
> with his standard-bearer."

> "In total we have 'got' about 1200 souls (editor's note: about 1200 people
> died)."

Correct answer:
- (a) In the hill engagement Coen reports **9 killed and 35 wounded** on his
  own side, including **captain De Ros and his standard-bearer (vaandeldrager)**.
- (b) The "about 1200" (omtrent 1200 zielen) refers to **Bandanese dead** — the
  editor explicitly glosses "1200 zielen gekregen" as "circa 1200 man
  overleden" (about 1,200 people died). It is a euphemistic body count, NOT
  people captured, recruited, or "received".

Mistranslation traps:
- Translating "omtrent 1200 zielen gekregen" literally as "we received/took
  ~1200 souls" and reporting it as prisoners taken, slaves acquired, or VOC
  reinforcements — the inverted referent. The corpus's own editorial note exists
  precisely to flag that "gekregen" here is a euphemism for killed.
- Swapping the small VOC loss (9 dead / 35 wounded) with the ~1200 figure, e.g.
  claiming "Coen lost ~1200 men" or "1200 wounded" — attaching the Bandanese
  death toll to the Dutch force.

### Q3 — Cape, Van Riebeeck Daghregister, Dec. 1651 (NA 1.04.02 inv.nr. 1188 fol. 189)

Source file: `nationaalarchief-cape-1652.html`, body section "Wat staat er
precies in de brief van Van Riebeeck?", the transcribed original-Dutch register
heading (the lines beginning "December 1651 Int schip den Drommedaris /
Daghregister gehouden bijden opper-coopman ..."). Bron line confirms 1.04.02
inventarisnummer 1188, folio 189. NOTE: this is raw Early-Modern Dutch with OCR
noise later in the passage; the answerable facts are in the clean heading.

Verbatim Dutch (heading):

> "Daghregister gehouden bijden opper- coopman Jan Anthonissen van Riebeecq
> vertrocken per de schepen Drommedaris, Reijger ende Goede Hope voor opperhooft
> naer Cabo de Bona Esperance in dienste van de generale vereenighde
> Neederlantsche geoctroijeerde Oostindische Compagnie uijt Texel vande Camer
> Amsterdam."

Literal English translation:

> "Day-register kept by the chief merchant (oppercoopman) Jan Anthonissen van
> Riebeecq, departed with the ships Drommedaris, Reijger, and Goede Hope as chief
> (opperhooft) to the Cape of Good Hope (Cabo de Bona Esperance) in the service
> of the general united Netherlands chartered East India Company, out of Texel,
> under the Chamber of Amsterdam."

Correct answer:
- (a) Three ships: **Drommedaris, Reijger, and Goede Hope**.
- (b) Van Riebeeck's stated role: **oppercoopman (chief merchant), sailing as
  opperhooft (chief/commander of the expedition)** — NOT "governor".
- (c) He departed **from Texel** (the roadstead), **under / dispatched by the
  Chamber of Amsterdam** ("uijt Texel vande Camer Amsterdam").

Mistranslation traps:
- Calling van Riebeeck "governor" / "Governor of the Cape." The Dutch says
  oppercoopman and opperhooft. He did not hold the title of governor; promoting
  his rank is a fabricated claim the heading does not support.
- Reading "uijt Texel vande Camer Amsterdam" as "departed from Amsterdam." He
  took final leave at Amsterdam but the fleet sailed from Texel; "vande Camer
  Amsterdam" denotes the dispatching VOC chamber, not the port. Conflating the
  city, the port, and the chamber is the wrong-referent trap.
- Miscounting or renaming the ships (e.g. dropping Reijger, or treating
  "Goede Hope" as the destination rather than a ship — the destination is "Cabo
  de Bona Esperance").
