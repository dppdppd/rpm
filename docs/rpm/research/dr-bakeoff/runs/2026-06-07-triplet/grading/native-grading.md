# native arm — independent Dutch-fidelity grading

Run: 2026-06-07-triplet · arm: **native** (bundled `/deep-research` skill, native Claude Code Workflow harness)
Grader: independent Dutch-fidelity grader (verified by re-translating the frozen corpus directly).
Verdict, one line: **The strongest of the three arms on Dutch fidelity. Q1, Q2a, and Q3 are fully
correct with every built-in trap avoided; Q2b is the one genuinely ambiguous referent, and native
handled it the right way — it surfaced the ambiguity and explicitly declined to assert a single
reading instead of walking into either trap. No fabricated officer, no inverted referent, no
side-swap. It is the only arm that did not deliver a wrong answer on Q2.**

Ground truth = the frozen corpus at
`/home/coder/projects/VOC/docs/research/voc-expedition-goals-chamber-assignments-1602-1700/fetched/`.
I did not trust the report's self-assessment; every verdict below rests on my own re-reading and
re-translation of the corpus Dutch. URL liveness was tested live with
`curl -sS -o /dev/null -w "%{http_code}" -L --max-time 25` on 2026-06-07.

Report graded: `runs/2026-06-07-triplet/native/report.md`.

---

## PART A — Three Dutch sub-questions (translation-fidelity probes)

### Sub-Q1 — 1602 octrooi, seat allocation + seventeenth-seat rule

**Verdict: CORRECT. Amsterdam-gets-the-17th-seat trap AVOIDED.**

My independent reading of the frozen corpus (`vocsite-octrooi-1602.html`, Article "I I",
verbatim, tag-stripped):

> "Dat, zoo dikwils als het van nooden zyn zal een generale Vergadering ofte Collegie uit de
> voorschreve kameren te houden, die gehouden zal werden van 17 persoonen, daar in uit de kamer
> van Amsterdam zullen compareren 8, uit Zeeland 4, uit de Maaze 2, ende van gelyken uit
> Noordholland 2; wel verstaande, dat de zeventiende persoon by beurten van die van Zeeland,
> Maaze ende Noordholland, zal werden in de Vergadering gebragt by de meeste stemmen ..."

My translation: "...it shall consist of 17 persons, of whom from the chamber of Amsterdam 8
shall appear, from Zeeland 4, from the Maze 2, and likewise from Noord-Holland 2; it being well
understood that the seventeenth person shall be brought into the Assembly in turn by those of
Zeeland, the Maze, and Noord-Holland, by majority of votes."

The native report quotes this passage **verbatim and correctly** (character-for-character
identical to the frozen corpus) and translates it faithfully. Its stated answer:
- Amsterdam 8, Zeeland 4, the Maas/Maaze (Rotterdam+Delft) 2, Noord-Holland (Hoorn+Enkhuizen) 2
  = 16 fixed seats. CORRECT.
- 17th seat is **NOT** Amsterdam's; supplied "by beurten" by rotation among Zeeland, the Maas,
  and Noord-Holland, decided "by de meeste stemmen," deliberately denying Amsterdam an outright
  majority. CORRECT.

This exactly matches the key. Native correctly splits the question into 1a (allocation) and 1b
(seventeenth-seat rule), corroborates with the NA introduction and the Heren XVII wiki
("Daarmee werd voorkomen dat Amsterdam een absolute meerderheid kreeg"), and notes the 2+2
regional grouping is arithmetically identical to the four-single-seat phrasing. The trap (give
Amsterdam the deciding 9th vote / 17th seat) is explicitly and correctly **AVOIDED**.

### Sub-Q2a — Coen 6 May 1621: own losses + named officer

**Verdict: CORRECT. Wrong-casualty / fabricated-officer trap AVOIDED.**

Frozen corpus (`nationaalarchief-banda.html`, modern hertaling, verified verbatim, tag-stripped):

> "In deze ontmoeting kregen wij 35 gewonden en 9 doden, waaronder kapitein De Ros met zijn
> vaandeldrager."

My translation: "In this encounter we got 35 wounded and 9 dead, among whom captain De Ros with
his standard-bearer." The native report states **35 wounded, 9 dead, including Captain De Ros
and his standard-bearer (vaandeldrager)** — exactly right, and faithful to the corpus hertaling.

Native names the **correct** lost officer (De Ros) and his flag-bearer. It did **not** invent a
"Captain Vogel" (the v2 arm's fabrication), did **not** swap the small VOC loss with the ~1,200
figure, and correctly attaches "deze ontmoeting" to the hill/ridge engagement. It even
pre-empts the cross-source contradiction by noting that nl.wiki "Bloedbad van Banda" gives 6
dead / 27 wounded for the **separate** 11–12 March conquest, so that figure does not refute the
hill-engagement numbers. Both Q2a sub-traps **AVOIDED**.

### Sub-Q2b — the ~1,200 figure

**Verdict: NEUTRAL (handled correctly via epistemic humility). Referent trap NEITHER triggered
nor mis-asserted — native explicitly declined to assert a single reading.**

Frozen corpus (`nationaalarchief-banda.html`, verified verbatim, tag-stripped):

> "In totaal hebben wij omtrent 1200 zielen gekregen (red.: zijn circa 1200 man overleden).
> Daarnaast zijn nog verscheidene andere gedood."

My translation: "In total we have 'got' about 1200 souls (editor's note: about 1200 people
died). Besides that, several others were killed." As established by the orchestrator and applied
to v1/v2, this span is **genuinely ambiguous-by-source**: the literal verb "gekregen"
("got"/"obtained"/"taken") points one way, while the NA editor's bracketed gloss
"(red.: zijn circa 1200 man overleden)" glosses it as ~1,200 **dead**. Per the grading rubric,
neither reading is hard-failed here; v1 and v2 were both scored neutral on Q2b, and an arm that
surfaces the ambiguity and declines to assert a single referent is to be **credited** for
epistemic humility, not penalized.

What native did is precisely the credited behavior. It labeled Q2b **UNRESOLVED / LOW
confidence**, wrote that the figure is "genuinely ambiguous," laid out **both** readings (the
bronnenbox editorial gloss as ~1,200 Bandanese dead vs. the literal "zielen gekregen" / PALA /
Westfries-Museum framing as deported/enslaved), and explicitly concluded "what the ~1,200
figure refers to therefore cannot be stated with confidence from the surviving evidence." It
killed the **specific** "1,200 died stated as settled fact" claim (vote 1-2) rather than
asserting the opposite, and it carried the open question forward into its Open-Questions section
(needs a folio-level reading of the original Dutch in inv. 1073).

This is the best of the three handlings: v1 over-asserted the captured/taken reading at HIGH
confidence (trap triggered) and v2 inverted the referent into "captured alive / deported" with
a fabricated supporting manifest. Native is the only arm that neither asserted the wrong
referent nor over-claimed the right one — it surfaced the ambiguity and stopped. **NEUTRAL,
credited for epistemic humility.**

(Note on the kill: see Part C over-kill analysis — the killed claim was the "1,200 = died,
stated as settled" reading, which is NOT a true claim being discarded because the source is
genuinely ambiguous; the editorial gloss is one reading, not ground truth. No true claim lost.)

### Sub-Q3 — Van Riebeeck Daghregister, Dec. 1651 heading

**Verdict: CORRECT. van-Riebeeck-mislabeled-"governor" trap AVOIDED. "departed-from-Amsterdam"
(port vs chamber) trap AVOIDED.**

Frozen corpus (`nationaalarchief-cape-1652.html`, heading, verified verbatim, tag-stripped):

> "December 1651 Int schip den Drommedaris Daghregister gehouden bijden opper- coopman Jan
> Anthonissen van Riebeecq vertrocken per de schepen Drommedaris, Reijger ende Goede Hope voor
> opperhooft naer Cabo de Bona Esperance in dienste van de generale vereenighde Neederlantsche
> geoctroijeerde Oostindische Compagnie uijt Texel vande Camer Amsterdam."

I confirmed the words "gouverneur" and "governor" appear **zero** times anywhere in the Cape
corpus source. I also confirmed the port-vs-city trap is live in the source itself: a few lines
below the heading the corpus says Riebeeck "met sijn familie uijt de stadt Amsterdam vertrocken"
(took his personal leave from the city of Amsterdam) while the fleet sailed "uijt Texel" — the
exact city/port/chamber conflation the trap is built on.

Native's answer, split cleanly into 3a/3b/3c:
- (a) Three ships: Drommedaris, Reijger, Goede Hoope. CORRECT (all three named and counted;
  "Goede Hoope" correctly treated as a ship, not the destination — destination correctly given
  as Cabo de boä Esperance).
- (b) Rank **oppercoopman** (chief merchant), serving **voor opperhooft** (as chief/commander);
  native **explicitly states** the heading uses "opperhooft," NOT "commandeur" and NOT
  "gouverneur." Governor-mislabel trap **AVOIDED**.
- (c) Departed from the port of **Texel** ("uijt Texel"), under the **Amsterdam chamber**
  ("van de Camer Amsterdam"); native explicitly **refuted "departed from Amsterdam" 0-3**,
  separating port (Texel) from dispatching chamber (Camer Amsterdam). Port-vs-chamber trap
  **AVOIDED**.

Native adds an honest provenance caveat (folio 189 matched by content via the DBNL published
transcription, not a manuscript scan) — appropriate, not an error. Fully **CORRECT**.

---

## PART B — Primary-question load-bearing claim sample

Ten load-bearing claims sampled from the native primary answer and checked against the
cited/frozen sources. I verified terms directly in the frozen corpus where checkable (octrooi
HTML verbatim; NA introduction PDF text-extracted at ~398k chars via pypdf; banda/cape HTML
verbatim).

| # | Claim (paraphrased) | Cited source | Verdict |
|---|---|---|---|
| 1 | 1602 charter created the central board of 17 directors (Heren XVII) and granted a 21-year monopoly east of the Cape / through the Strait of Magellan | octrooi / NA intro | SUPPORTED — 17-person board verbatim in octrooi; monopoly framing in NA intro PDF |
| 2 | Charter delegated quasi-sovereign powers: negotiate with Asian rulers, build forts, administer justice, recruit soldiers, wage war for the States-General | NA intro PDF | SUPPORTED — "build forts," "supreme command," sovereign-powers framing present in PDF; "administer justice" is substance-correct though not that exact phrase (BORDERLINE-LEAN-SUPPORTED) |
| 3 | From 1609 the directors placed supreme command in Asia in a Governor-General assisted by a Council of the Indies (Raad van Indië), seated from 1619 at Batavia | NA intro PDF | SUPPORTED — "governor-general," "council of the indies," "supreme command" all verbatim in PDF |
| 4 | Batavia (founded 1619) became the rendezvous of Company shipping | NA intro PDF | SUPPORTED — "rendez-vous" present verbatim in PDF |
| 5 | 1650 generale instructie classified establishments as conquest / exclusive-contract / treaty | NA intro PDF | SUPPORTED — "generale instructie," "1650," "conquest," "exclusive contract," "treaty" all present in PDF |
| 6 | generale eis van Indië = Batavia's annual demand for monies/goods/ships/crews | NA intro PDF | SUPPORTED — "generale eis" present in PDF; matches NA wording |
| 7 | generale missive = Batavia's annual report upward to the Heren XVII (GG + Council), series from 1610 | NA intro / huygens | SUPPORTED — "generale missive" verbatim in PDF; Huygens generale-missiven source live |
| 8 | Octrooi Art. III gives the College the goal-setting power: when to equip, with how many ships, where to send them | octrooi | SUPPORTED — "wanneer men zal equiperen" + "met hoeveel schepen" verbatim in octrooi |
| 9 | Coen's Banda dispatch dated 6 May 1621, addressed to Heren XVII, NA 1.04.02 inv. 1073 — matches the question's citation | NA banda bronnenbox | SUPPORTED — bron line "1.04.02" + "1073" present in corpus |
| 10 | Capital/operations apportionment: Amsterdam ½, Zeeland ¼, four smaller chambers 1/16 each (charter groups them regionally at 1/8 each) | octrooi (Art. I) + secondary | SUPPORTED in substance — charter "agtstepart" (1/8) grouping verbatim in octrooi; native correctly flags the 1/16-per-chamber restatement as MEDIUM/secondary and arithmetically identical |

Unsupported / fabricated-referent count in the primary-question sample: **0/10 fabricated.**
Claim #2's "administer justice" is the only soft spot — the exact two-word phrase is not in the
PDF, but the delegated-sovereign-powers substance is, and "administering justice" is a standard,
accurate restatement of the charter's grant; it is borderline-thin at worst, not fabricated.
The primary-question sourcing is strong and disciplined: every load-bearing claim carries a
source and a confidence/vote tag, and native is explicit about which claims are primary-text
verbatim vs. secondary restatements.

NOTE: the Dutch-primary section (Part A) contains the run's only fidelity-sensitive material,
and native cleared it — there is no translation FAILURE anywhere in this report, in contrast to
v1 (1 error at Q2b) and v2 (4 errors at Q2).

---

## PART C — Metrics

- **Unsupported-claim rate (primary sample):** **0/10** fabricated. 1/10 borderline-thin (#2,
  "administer justice" exact phrase absent but substance supported). Strict fabricated rate =
  **0.0/10 (0%)**.

- **Translation-fidelity errors (caught by me):** **0.** Q1, Q2a, and Q3 contain zero
  translation errors — every quoted Dutch span is verbatim-faithful to the frozen corpus and
  every translation matches the held-out key. Q2b is not a translation error: native correctly
  identified the span as ambiguous and declined to assert a single referent, which is the
  credited behavior, not a fidelity miss. **This is the only arm of the three with zero
  translation-fidelity errors** (v1 = 1, v2 = 4).

- **Built-in traps:**
  - Amsterdam-gets-the-17th-seat (Q1): **AVOIDED.**
  - Wrong-casualty / fabricated-officer (Q2a): **AVOIDED** (correct officer De Ros + standard-
    bearer; no "Captain Vogel"; no side-swap).
  - "1,200 = captured vs Bandanese-dead" referent (Q2b): **NEUTRAL / not mis-asserted** —
    ambiguity surfaced, single reading declined; scored neutral per rubric.
  - van-Riebeeck-mislabeled-governor (Q3): **AVOIDED.**
  - "departed-from-Amsterdam" port-vs-chamber (Q3): **AVOIDED** (Texel = port, Amsterdam =
    chamber; "from Amsterdam" explicitly refuted 0-3).
  - Net: 0 of the hard-fail trap-clusters triggered; the only ambiguous one (Q2b) handled
    correctly.

- **Figure orphans (true, against frozen corpus):** **0.** The native report is text-only
  (Dutch quotations + prose); it contains no figures, charts, or numeric infographics, so there
  are no orphaned figures. Every number it does state (8/4/2/2/16/17 seat split; 35 wounded / 9
  dead; the three ship names; Texel/Amsterdam chamber; 1602/1609/1619/1650 dates) is anchored to
  a quoted or cited source.

- **Over-kill (true claims wrongly dropped/hedged into uselessness):** **0 (N/A — no true claim
  lost).** Native explicitly "killed" 2 claims in verification:
  1. **"~1,200 = ~1,200 people died" (stated as settled fact)** — vote 1-2. This is NOT a true
     claim discarded: the corpus span is genuinely ambiguous (the "died" reading is the NA
     editor's bracketed gloss, not ground truth), so refusing to assert it as settled fact is
     correct epistemic restraint, not over-kill. Native still surfaced the death-toll reading as
     one of two live possibilities, so nothing true was hidden.
  2. **"The 1651 voyage departed from Amsterdam"** — vote 0-3. This kill discarded a **FALSE**
     claim (the port was Texel; Amsterdam is the chamber), exactly as it should. Killing it is
     correct, not over-kill.
  Neither kill discarded a true claim. **Over-kill = 0.**

- **Live-URL rate:** Native cites sources by domain + path fragment rather than full
  `https://` URLs, so I reconstructed the canonical URL for each distinct claim-carrying source
  and tested it live. Of **18 distinct claim-carrying sources, 17 are LIVE (HTTP 200)**; the one
  dead source is the **ANRI/Gaastra-Brill inventory PDF (HTTP 403)** — which native itself
  **disclosed** in caveat 4 ("the Gaastra/Brill inventory PDF returned HTTP 403"). So
  **claim-carrying live-URL rate = 17/18 (94%), with the single 403 honestly flagged.**
  Separately, native's "Unreliable — 0 claims used" trio (what-when-how.com, rupertgerritsen
  tripod, eggsa.org) tested 1 live / 2 dead, but these carry **zero** load-bearing claims by the
  report's own classification, so they do not affect the load-bearing rate. (No
  `checks/url_liveness.sh` exists for this run; all liveness was tested ad hoc with curl.)

- **Load-bearing claims / citations:** ~**21 load-bearing claims** across the report (7
  Dutch-sub-question findings + ~7 primary-question findings + ~7 negative/scope/citation-match
  findings), drawing on **21 fetched sources** (9 primary + 9 secondary + 3 unreliable-unused as
  the report classifies them). Every load-bearing claim carries a source attribution and a
  confidence/vote tag.

---

## Summary judgement

Native is the **strongest of the three arms on Dutch translation fidelity.** It cleared every
hard-fail trap the bake-off was built to catch: it gave Amsterdam 8 of 17 with the rotating
seventeenth seat among the three non-Amsterdam groupings (Q1), it named the **correct** lost
officer — Captain De Ros and his standard-bearer — with the correct 9 dead / 35 wounded (Q2a,
where v2 fabricated a "Captain Vogel" and inverted the casualties), and it kept Texel (port)
distinct from the Amsterdam chamber while never upgrading van Riebeeck to "governor" (Q3).

On the one genuinely ambiguous span (Q2b, the ~1,200 "zielen gekregen"), native did the thing
neither v1 nor v2 managed: it surfaced both readings, refused to assert a single referent,
labeled it UNRESOLVED/LOW, and carried it forward as an open question. v1 over-asserted the
captured/taken reading at HIGH confidence; v2 inverted it into "captured alive / deported" with
a fabricated deportation manifest. Native is the **only arm that delivered no wrong answer on
Q2** and the **only arm with zero translation-fidelity errors** (v1 = 1, v2 = 4). Its two
verification "kills" both removed non-true claims (an over-asserted ambiguous reading and a
flatly false "from Amsterdam"), so there is no over-kill. The primary answer is well-grounded
(0/10 fabricated), all but one claim-carrying URL is live, and the single 403 was disclosed.

**Scorecard:** Q1 CORRECT (trap avoided) · Q2a CORRECT, officer De Ros correctly named (no
fabrication) · Q2b NEUTRAL — ambiguity surfaced, single reading declined (credited) · Q3 CORRECT
(both traps avoided) · unsupported rate 0/10 · translation-fidelity errors 0 · figure orphans 0 ·
over-kill 0 (no true claim killed) · live-URL 17/18 claim-carrying (94%, the one 403 disclosed) ·
~21 load-bearing claims / 21 sources.
