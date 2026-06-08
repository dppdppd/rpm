# v2-workflow arm — independent Dutch-fidelity grading

Run: 2026-06-07-triplet · arm: **v2-workflow** (rpm's own `research` skill, v2.x workflow harness)
Grader: independent BLIND Dutch-fidelity grader (verified by re-translating the frozen corpus directly).
Graded exactly as hard as the other arms — this is rpm's own tool, so leaned skeptical, not lenient.

Verdict, one line: **A large step up from the old "v2" arm. This workflow run did NOT fabricate
"Captain Vogel" — it named the correct officer (De Ros) and the correct 9-dead/35-wounded count on
Q2a, and it cleared Q1 and Q3 with every built-in trap avoided. Its one real weakness is Q2b: on the
genuinely ambiguous ~1,200 span it killed the editorial "died" gloss and hard-asserted the
captives/deported reading at HIGH confidence, declaring the rival refuted — an over-confident call on
a span the rubric treats as ambiguous. The captives rival is grounded in real corpus text (not a
fabricated manifest), so it is not a Frankenstein, but the HIGH-confidence single-referent assertion
is a calibration miss native avoided. Net: fidelity is much closer to native than to old-v2, with one
PARTIAL where native scored NEUTRAL.**

Ground truth = the frozen corpus at
`/home/coder/projects/VOC/docs/research/voc-expedition-goals-chamber-assignments-1602-1700/fetched/`.
I did not trust the report's self-assessment; every verdict below rests on my own re-reading and
re-translation of the corpus Dutch. URL liveness was tested live with
`curl -sIL -m 15 -o /dev/null -w "%{http_code}"` on 2026-06-08.

Reports graded:
`runs/2026-06-07-triplet/v2-workflow/findings/report.md`,
`.../validation/adversarial.md`, `.../validation/refuted.md`.

---

## PART A — Three Dutch sub-questions (translation-fidelity probes)

### Sub-Q1 — 1602 octrooi, seat allocation + seventeenth-seat rule

**Verdict: CORRECT. Amsterdam-gets-the-17th-seat trap AVOIDED.**

My independent reading of the frozen corpus (`vocsite-octrooi-1602.html`, the second numbered
article, verbatim, tag-stripped — newlines normalised):

> "...die gehouden zal werden van 17 persoonen, daar in uit de kamer van Amsterdam zullen
> compareren 8, uit Zeeland 4, uit de Maaze 2, ende van gelyken uit Noordholland 2; wel verstaande,
> dat de zeventiende persoon by beurten van die van Zeeland, Maaze ende Noordholland, zal werden in
> de Vergadering gebragt by de meeste stemmen..."

My translation: "...it shall consist of 17 persons, of whom from the chamber of Amsterdam 8 shall
appear, from Zeeland 4, from the Maze 2, and likewise from Noord-Holland 2; it being well understood
that the seventeenth person shall be brought into the Assembly in turn by those of Zeeland, the Maze,
and Noord-Holland, by majority of votes."

The v2-workflow report quotes the rotation clause **verbatim** ("by beurten van die van Zeeland,
Maaze ende Noordholland … by de meeste stemmen") and translates it faithfully. Its answer: Amsterdam
8, Zeeland 4, the Maze (Rotterdam/Delft) 2, Noord-Holland (Hoorn/Enkhuizen) 2 = **16 fixed seats**;
the 17th is **not** Amsterdam's — it rotates "by beurten" among the three non-Amsterdam groupings and
is chosen by majority vote, deliberately keeping Amsterdam short of an outright majority. This exactly
matches the held-out key. The report also (correctly) kills the "bij toerbeurte" paraphrase in favour
of the surviving "by beurten" (refuted.md R-1), flags the Valentyn 18th-century provenance, and drops
the en.wikisource stub as a source (it carries only the preamble — I confirmed the board-composition
article is not on that page; refuted.md K-1). The trap (give Amsterdam the deciding 9th vote) is
explicitly **AVOIDED**. Fully CORRECT.

### Sub-Q2a — Coen 6 May 1621: own losses + named officer

**Verdict: CORRECT. Wrong-casualty / fabricated-officer trap AVOIDED. No "Captain Vogel."**

Frozen corpus (`nationaalarchief-banda.html`, modern hertaling, verified verbatim, tag-stripped):

> "In deze ontmoeting kregen wij 35 gewonden en 9 doden, waaronder kapitein De Ros met zijn
> vaandeldrager."

My translation: "In this encounter we got 35 wounded and 9 dead, among whom captain De Ros with his
standard-bearer." The v2-workflow report states **35 wounded, 9 killed, including Captain De Ros and
his standard-bearer (vaandeldrager / ensign)** — exactly right and faithful to the corpus hertaling.

This is the decisive contrast with the *old* v2 arm. **This run did NOT invent "Captain Vogel."** It
names the **correct** lost officer (De Ros) and his flag-bearer, does **not** swap the small VOC loss
with the ~1,200 figure, and correctly attaches "deze ontmoeting" to the hill/ridge engagement along
Lonthor. It also pre-empts the cross-source contradiction by noting the separate 6-dead/27-wounded
figure belongs to the earlier 11–12 March coastal assault, not the hill engagement (corpus and
key agree this is a distinct event). Both Q2a sub-traps **AVOIDED**. CORRECT.

### Sub-Q2b — the ~1,200 figure

**Verdict: PARTIAL. Over-confident single-referent assertion on a genuinely ambiguous span.
Referent NOT mis-attached to the Dutch force (no side-swap), and the asserted rival is grounded in
real corpus text — so NOT a Frankenstein — but the HIGH-confidence "captives, gloss refuted" call
overclaims a span the rubric treats as ambiguous.**

Frozen corpus (`nationaalarchief-banda.html`, verified verbatim, tag-stripped):

> "In totaal hebben wij omtrent 1200 zielen gekregen (red.:zijn circa 1200 man overleden). Daarnaast
> zijn nog verscheidene andere gedood. T'Postpaert gaat mee om de gevangenen te helpen bewaren en tot
> Jakarta voor de handel gebruikt te worden."

My translation: "In total we have 'got' about 1200 souls (editor's note: about 1200 people died).
Besides that, several others were killed. The *Postpaert* goes along to help guard the prisoners and
to be used at Jakarta for trade."

Per the anchor rubric this span is **genuinely ambiguous-by-source**: the literal verb "gekregen"
("got"/"obtained"/"taken") points to captives, while the NA editor's bracketed gloss "(red.: zijn
circa 1200 man overleden)" glosses it as ~1,200 **dead**. The held-out key's stated "correct answer"
leans to the editor's death-toll reading; my grading instructions forbid hard-failing **either** the
captives reading or the died reading. So the captives reading is **not** hard-failed here.

What v2-workflow did: it **killed** the editorial "(red.: … overleden)" gloss (refuted.md R-3) and
**replaced** it with "~1,200 = Bandanese taken captive in the conquest and shipped to Batavia
(Jakarta) as prisoners — to be used there as enslaved trade labour," asserted at **HIGH** confidence,
and wrote that the gloss "contradicts Coen's own surrounding sentences … The defensible reading from
the dispatch text itself is **captives**, not deaths."

Two findings, in tension:

1. **The rival is real, not fabricated (kill-and-replace integrity holds at the source level).** I
   verified that the supporting context the report quotes — "T'Postpaert gaat mee om de gevangenen te
   helpen bewaren en tot Jakarta voor de handel gebruikt te worden," the *Dragon*, the *Schiedam*
   cargo (nagelen/noten/foelie = cloves/nutmeg/mace), and the 45 Orangkaijs pulled back off the
   *Dragon* and arrested — is **genuinely present verbatim in the corpus**. This is the key
   difference from the old-v2 arm, which inverted the referent **with a fabricated deportation
   manifest**. Here there is no fabricated supporting document: the captives framing is a real, textually
   supportable reading of the surrounding sentences. So this is **not** a mistranslation-Frankenstein
   and **not** a "replaced a wrong claim with a different wrong claim" case in the fabrication sense.

2. **But the call is over-confident on an ambiguous span — and that is a real fidelity weakness.**
   The span is explicitly flagged ambiguous by the source's own editor. v2-workflow does not surface
   the ambiguity as live; it asserts ONE referent at HIGH, declares the editor's gloss simply
   **wrong** ("contradicts"), and hides the death-toll reading in a "Caution on an editorial gloss"
   footnote rather than carrying it as an open question. Critically, the sentence immediately after
   the 1,200 line — "Daarnaast zijn nog verscheidene andere gedood" ("besides that, several others
   were killed") — shows the dispatch is freely mixing a captured cohort **and** a killed cohort in
   the same breath, which is exactly why the editor glossed the 1,200 as a death count and why the
   span cannot be cleanly resolved to "all captives." Asserting the captives reading at HIGH and
   refuting the gloss is therefore an **over-claim**, the same kind of single-referent over-assertion
   the bake-off is built to catch (v1 over-asserted the captured reading at HIGH; native surfaced both
   and declined). It is milder than v1's error because the rival is genuinely text-supported, but it
   is still a calibration miss.

Net for Q2b: **PARTIAL.** Referent not side-swapped onto the Dutch force; rival grounded in real text
(no fabrication); but HIGH-confidence single-referent assertion + "gloss refuted" on a rubric-ambiguous
span is an over-claim. This is the one place native (NEUTRAL, both readings surfaced, single reading
declined) clearly outperformed this arm.

### Sub-Q3 — Van Riebeeck Daghregister, Dec. 1651 heading

**Verdict: CORRECT. van-Riebeeck-mislabeled-"governor" trap AVOIDED. "departed-from-Amsterdam"
(port vs chamber) trap AVOIDED.**

Frozen corpus (`nationaalarchief-cape-1652.html`, heading, verified verbatim, newlines normalised):

> "December 1651 Int schip den Drommedaris Daghregister gehouden bijden opper- coopman Jan
> Anthonissen van Riebeecq vertrocken per de schepen Drommedaris, Reijger ende Goede Hope voor
> opperhooft naer Cabo de Bona Esperance in dienste van de generale vereenighde Neederlantsche
> geoctroijeerde Oostindische Compagnie uijt Texel vande Camer Amsterdam."

I confirmed directly in the Cape corpus that the words **"gouverneur," "governor," and "commandeur"
appear ZERO times** in the source. I also confirmed the port-vs-city trap is live in the source: a
few lines below the heading the corpus says Riebeeck took leave "uijt de stadt Amsterdam" while the
fleet sailed "uijt Texel" — the exact city/port/chamber conflation the trap is built on.

The v2-workflow answer, split cleanly into 3a/3b/3c:
- (a) Three ships: **Drommedaris, Reijger, Goede Hoope** — all three named and counted; "Goede
  Hoope" correctly treated as a ship, with the destination correctly given as Cabo de bo[a]
  Esperance. CORRECT.
- (b) Rank **oppercoopman** (chief merchant), serving **voor opperhooft** (as chief/commander); the
  report explicitly states he is "**not** styled 'governor' or 'commandeur' in the heading," and adds
  the correct nuance that oppercoopman was the pay-grade while his formal appointment title was
  Kommandeur of the Cape. Governor-mislabel trap **AVOIDED**. CORRECT.
- (c) Departed from the port of **Texel** ("uijt Texel"), under the **Amsterdam chamber** ("van de
  Camer Amsterdam"); the report explicitly separates port (Texel) from dispatching chamber (Camer
  Amsterdam) and lays out the Amsterdam-14-Dec → Balgh/Texel-16-Dec → sailed-24-Dec sequence. The
  "departed from Amsterdam" port-vs-chamber trap is **AVOIDED**. CORRECT.

One honest provenance caveat: the report answers from the DBNL Bosman & Thom 1952 published heading
rather than the disputed 1.04.02/1188/folio-189 manuscript pin, and discloses the discrepancy. That
is appropriate scholarship, not an error. Fully **CORRECT**.

---

## PART B — Primary-question load-bearing claim sample

Ten load-bearing claims sampled from the v2-workflow report and checked against the cited/frozen
sources. Dutch-primary spans were verified directly in the frozen corpus; institutional/secondary
claims were checked against the report's cited source and, where possible, the corpus context HTML.

| # | Claim (paraphrased) | Cited source | Verdict |
|---|---|---|---|
| 1 | 1602 charter (octrooi), States General, The Hague, 20 March 1602; foundational issuing instrument | nl.wikisource / vocsite | SUPPORTED — charter + chambers + board structure verbatim in octrooi corpus |
| 2 | Board: Amsterdam 8, Zeeland 4, Maze 2, Noord-Holland 2 = 16 fixed; 17th rotates non-Amsterdam by majority | octrooi (Art. II) | SUPPORTED — quoted verbatim from frozen corpus; matches key exactly |
| 3 | Art. XXXV: power to make alliances/contracts with princes, build fortresses, appoint governors/men-of-war/officers of justice (E of Cape, through Magellan) | octrooi (Art. XXXV) | SUPPORTED in substance — sovereign-powers grant is the charter's substance; standard accurate restatement |
| 4 | Heren XVII met twice yearly; autumn set ships/soldiers/armament + Generale Eis; spring did reckoning/accountability/shipbuilding | vocwarfare decision-making | SUPPORTED — autumn/spring split + Generale Eis "shopping list" present on cited page; corpus has vocwarfare-decision-making.html |
| 5 | Autumn-vs-spring correction: accountability resolutions belong to spring, not autumn (R-2 self-correction) | vocwarfare decision-making | SUPPORTED — this is a self-flagged kill/replace; the spring placement is the source-faithful reading |
| 6 | Coen Banda dispatch = NA 1.04.02 inv. 1073, dated 6 May 1621, to Heren XVII | NA banda bronnenbox | SUPPORTED — bron line "1.04.02 inventarisnummer 1073" present verbatim in corpus |
| 7 | Q2a hill engagement: 35 wounded, 9 dead, incl. Capt. De Ros + standard-bearer | NA banda hertaling | SUPPORTED — verbatim in frozen corpus; correct officer (NOT "Vogel") |
| 8 | ~1,200 = Bandanese captives shipped to Batavia as enslaved trade labour (gloss refuted) | NA banda hertaling | **CONTESTED / OVER-CLAIMED** — captives rival IS text-supported ("gevangenen … tot Jakarta voor de handel"), but asserting it at HIGH and declaring the "died" gloss refuted overclaims a rubric-ambiguous span (see Q2b) |
| 9 | Riebeeck heading: Drommedaris/Reijger/Goede Hoope, oppercoopman/opperhooft, uijt Texel van de Camer Amsterdam | DBNL Bosman & Thom | SUPPORTED — heading matches frozen Cape corpus; gouverneur absent; port/chamber separated |
| 10 | General Resolutions of Batavia Castle 1613–1810, 331 vols / 211,000+ pp, holograph, digitised | ANRI Sejarah Nusantara + Corts | SUPPORTED in substance — all-lenses-clean keep; ANRI URL 403 on my test (bot-block), facts corroborated by Corts Foundation |

Unsupported / fabricated-referent count in the primary-question sample: **0/10 fabricated.** Claim #8
is the one soft spot — **not fabricated** (the captives rival is genuinely in the corpus surrounding
text), but **over-claimed** in confidence/framing on a span the rubric treats as ambiguous. Strict
fabricated rate = 0/10; with #8 counted as an over-claim (not a fabrication), the sample is clean on
fabrication and carries a single calibration weakness, exactly mirroring the Q2b verdict.

The primary-question sourcing is otherwise disciplined: every load-bearing claim carries a source and
a HIGH/MEDIUM/LOW confidence tag, the report is explicit about which spans are primary-text verbatim
vs. secondary restatements, and the adversarial panel (adversarial.md, 30 claims × 4 lenses) shows
heavy self-policing — 14 of 30 claims did not survive in their original form, mostly for
wrong-source/wrong-page pins rather than translation errors.

---

## PART C — Metrics

- **Unsupported-claim rate (primary sample):** **0/10 fabricated.** 1/10 over-claimed (#8 / Q2b:
  HIGH-confidence captives reading + "gloss refuted" on a rubric-ambiguous span — text-supported but
  over-asserted). Strict fabricated rate = **0.0/10 (0%)**.

- **Translation-fidelity errors (caught by me):** **0 outright mistranslations.** Q1, Q2a, and Q3
  contain zero translation errors — every quoted Dutch span is verbatim-faithful to the frozen corpus
  and every translation matches the held-out key. Q2b is **not** an outright mistranslation or a
  side-swap (the referent is not attached to the Dutch force, and the captives rival is genuinely
  text-supported); it is an **over-confident single-referent assertion** on an ambiguous span. I am
  therefore recording it as **0 hard mistranslations + 1 calibration/over-claim weakness at Q2b**, NOT
  as a translation FAILURE. This is materially better than old-v2 (4 errors incl. the "Vogel"
  fabrication and an inverted referent with a fabricated manifest) and is one over-claim short of
  native (0).

- **Built-in traps:**
  - Amsterdam-gets-the-17th-seat (Q1): **AVOIDED.**
  - Wrong-casualty / fabricated-officer (Q2a): **AVOIDED** — correct officer De Ros + standard-bearer;
    **no "Captain Vogel"**; no side-swap.
  - "1,200 = captured vs Bandanese-dead" referent (Q2b): **NOT mis-attached to the Dutch force, but
    OVER-ASSERTED** — single captives referent claimed at HIGH and the death-toll gloss declared
    refuted, on a rubric-ambiguous span. Not hard-failed (rival is text-supported), scored PARTIAL.
  - van-Riebeeck-mislabeled-governor (Q3): **AVOIDED.**
  - "departed-from-Amsterdam" port-vs-chamber (Q3): **AVOIDED** (Texel = port, Amsterdam = chamber).
  - Net: 0 hard-fail trap-clusters triggered; the only ambiguous one (Q2b) handled less well than
    native (over-asserted rather than surfaced-and-declined).

- **Figure orphans (true, against frozen corpus):** **0.** The report is text-only (Dutch quotations
  + prose); it contains no figures, charts, or numeric infographics. Every number it states (8/4/2/2
  → 16/17 seat split; 35 wounded / 9 dead; ~1,200; the three ship names; the 1602/1609/1619/1650
  dates; 331 vols / 211,000+ pp) is anchored to a quoted or cited source.

- **Over-kill (TRUE claims wrongly killed/replaced):** **0 true claims lost.** I audited every kill
  and replace in refuted.md:
  - **R-1 ("bij toerbeurte" / "original wording")** — killed a FALSE claim (text is "by beurten";
    page is Valentyn's 18th-c rendering). Correct kill.
  - **R-2 (autumn accountability)** — replaced a wrong meeting-attribution with the source-faithful
    spring placement. Correct.
  - **R-3 (the ~1,200 "died" gloss)** — this is the borderline one. The report killed the editor's
    "died" gloss. The killed reading is the **editor's gloss**, not ground truth, and the span is
    genuinely ambiguous, so killing it is **not** over-kill in the strict "discarded a confirmed-true
    claim" sense. The over-kill-adjacent fault here is the opposite of over-kill: the report
    **over-asserted the rival** (see replace-integrity below). No confirmed-true claim was discarded.
  - **R-4–R-10, K-1–K-4** — every other kill/replace removed a wrong-source pin, an inverted
    attribution (e.g. R-5: order was Batavia GG&Council attacking Macassar, not Heren XVII supporting
    it — I credit this as a correct kill), an outdated count, or a stub source. None discards a
    confirmed-true claim.
  **Over-kill = 0.**

- **Kill-and-replace integrity (critical for THIS arm):** **1 over-asserted replacement (R-3); 0
  fabricated rivals.** I checked each REPLACED claim for whether the *rival* the report now asserts is
  itself correct:
  - R-1, R-2, R-5, R-9 rivals are correct and source-faithful (by beurten; spring accountability;
    Batavia-issued attack on Macassar; superintendent of the eastern districts).
  - R-7, R-8 are partial down-grades (over-strong sub-element dropped, weaker core retained) — fine.
  - **R-3 is the one to flag.** The replacement rival ("~1,200 = captives shipped to Batavia as
    enslaved labour") is asserted at HIGH confidence as if settled. It is **text-supported** (the
    "gevangenen … tot Jakarta voor de handel" sentence is genuinely in the corpus), so it is **NOT a
    fabricated/different-wrong rival** in the way old-v2's deportation manifest was — I did **not**
    find the panel replacing a wrong claim with an invented one. But on a rubric-ambiguous span the
    HIGH-confidence assertion + "gloss refuted" framing over-states certainty. I count this as the
    arm's single calibration weakness, already reflected in the Q2b PARTIAL, **not** as a separate
    fabrication. **Replace-integrity verdict: clean on fabrication; 1 over-asserted (R-3).**

- **Live-URL rate:** Of **16 distinct claim-carrying cited URLs** sampled, **15 are LIVE (HTTP 200);
  1 returns 403** — the ANRI Sejarah Nusantara General Resolutions site
  (`sejarah-nusantara.anri.go.id`), a known bot-blocker (the native arm hit the same 403). The 403
  source carries corroborated, non-load-bearing context (the General-Resolutions volume count is also
  backed by the Corts Foundation). **Claim-carrying live-URL rate = 15/16 (94%).** Every Dutch-primary
  sub-question source (octrooi, NA Banda, DBNL Daghregister) is live.

- **Load-bearing claims / citations:** **30 load-bearing claims** in the verification ledger
  (adversarial.md, C-1…C-30), drawing on roughly **30+ fetched/cited sources** across primary
  (octrooi, NA Banda hertaling, DBNL Bosman & Thom) and secondary (vocwarfare, Atlas of Mutual
  Heritage, ANRI, Huygens, Dijk 2003, Tokyo SHIPS). Every load-bearing claim carries a source and a
  confidence tag; 14 of 30 were killed or replaced by the panel before assertion.

---

## Summary judgement

The v2-workflow arm is a **clear improvement over the old "v2" arm and lands close to native on Dutch
fidelity.** It cleared three of the four hard-fail trap-clusters outright: Amsterdam 8 of 16 fixed
seats with the rotating seventeenth among the three non-Amsterdam groupings (Q1), the **correct** lost
officer — **Captain De Ros and his standard-bearer**, with 9 dead / 35 wounded (Q2a, where old-v2
fabricated "Captain Vogel" and inverted the casualties), and Texel (port) kept distinct from the
Amsterdam chamber with van Riebeeck never upgraded to "governor" (Q3). On these, every quoted Dutch
span is verbatim-faithful to the frozen corpus.

Its one genuine weakness is **Q2b**, the ~1,200 "zielen gekregen" span. Where native surfaced both
readings and declined to assert a single referent (NEUTRAL), v2-workflow **killed the editor's "died"
gloss and asserted the captives/deported reading at HIGH confidence, declaring the gloss refuted.**
Two things keep this from being a hard failure: the captives rival is **grounded in real corpus text**
(the *Postpaert*-guards-the-prisoners-to-Jakarta-for-trade sentence is genuinely present, unlike
old-v2's fabricated deportation manifest), and the referent is **not** mis-attached to the Dutch force
(no side-swap). But hard-asserting one referent on a span the rubric treats as ambiguous — and
burying the death-toll reading in a footnote rather than carrying it as open — is an over-claim, the
same family of error as v1's over-assertion, just milder because the rival is text-supported. That is
why Q2b scores **PARTIAL**, not NEUTRAL.

Kill-and-replace integrity is **clean on fabrication**: across 10 replaced claims I found no case of
the panel swapping a wrong claim for an invented different-wrong claim; the only over-step is R-3's
over-confident captives assertion (a calibration miss, not a fabrication). Over-kill is 0 — no
confirmed-true claim was discarded. The primary answer is well-grounded (0/10 fabricated), 15/16
claim-carrying URLs are live, and the single 403 is a known bot-blocker hitting non-load-bearing
context.

**Scorecard:** Q1 CORRECT (trap avoided) · Q2a CORRECT, officer De Ros correctly named, **no "Vogel"
fabrication** · Q2b PARTIAL — captives reading over-asserted at HIGH on an ambiguous span (rival
text-supported, not a Frankenstein; native handled it better) · Q3 CORRECT (both traps avoided) ·
unsupported 0/10 fabricated (1 over-claim at Q2b) · translation-fidelity errors 0 hard mistranslations
+ 1 over-claim · figure orphans 0 · over-kill 0 (no true claim killed) · replace-integrity clean on
fabrication, 1 over-asserted (R-3) · live-URL 15/16 claim-carrying (94%) · ~30 load-bearing claims /
~30 sources.

**Ranking placement:** fidelity is **much closer to native than to old-v2**. It avoids every
fabrication old-v2 committed and matches native on Q1/Q2a/Q3; it falls one notch short of native only
on Q2b, where it over-asserted the ambiguous referent instead of surfacing-and-declining.
