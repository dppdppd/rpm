# v2-workflow-tuned arm — independent Dutch-fidelity grading

Run: 2026-06-07-triplet · arm: **v2-workflow-tuned** (rpm `/research` skill, re-run
after the workflow change that added the "contested / surface-both" handling).
Grader: independent BLIND Dutch-fidelity grader (verified by re-translating the
frozen corpus directly; graded exactly as hard as the native and v1/v2 arms —
leaned skeptical because it is rpm's own tool).

Verdict, one line: **The tuning fixed the thing it was meant to fix. Q2b went from
the prior v2's outright wrong inversion ("captured alive / deported" with a
fabricated manifest) to a correct surface-both handling: both readings at MEDIUM,
no single referent asserted, and — unlike the earlier v2 — the literal-taken
reading is now grounded in real corpus text (the `'t Postpaert` prisoner line),
not invented. Q1 and Q2a are fully correct with every trap avoided and no
"Captain Vogel". The cost is twofold: Q3 is still NOT answered (the run never
fetched the van Riebeeck heading, even though it sits in the frozen corpus), and
the new "contested" lever is over-applied — 3 of the 8 contested claims dress a
determinable correction or a mere source-swap as a live ambiguity. Net: clearly
better than the untuned v2 on fidelity (4 fidelity errors → 0), still a notch
below native (which actually answered Q3).**

Ground truth = the frozen corpus at
`/home/coder/projects/VOC/docs/research/voc-expedition-goals-chamber-assignments-1602-1700/fetched/`.
I did not trust the report's self-assessment. Every verdict below rests on my own
re-reading and re-translation of the corpus Dutch (whitespace-collapsed,
tag-stripped, verbatim string-matched). URL liveness tested live with
`curl -sS -o /dev/null -w "%{http_code}" -L --max-time 20` on 2026-06-08.

Files graded:
- `runs/2026-06-07-triplet/v2-workflow-tuned/findings/report.md`
- `runs/2026-06-07-triplet/v2-workflow-tuned/validation/adversarial.md`
- `runs/2026-06-07-triplet/v2-workflow-tuned/validation/refuted.md`

---

## PART A — Four Dutch sub-questions (translation-fidelity probes)

### Sub-Q1 — 1602 octrooi, seat allocation + seventeenth-seat rule

**Verdict: CORRECT. Amsterdam-gets-the-17th-seat trap AVOIDED.**

My independent reading of the frozen corpus (`vocsite-octrooi-1602.html`,
Article "I I", verbatim, whitespace-collapsed):

> "die gehouden zal werden van 17 persoonen, daar in uit de kamer van Amsterdam
> zullen compareren 8, uit Zeeland 4, uit de Maaze 2, ende van gelyken uit
> Noordholland 2; wel verstaande, dat de zeventiende persoon by beurten van die
> van Zeeland, Maaze ende Noordholland, zal werden in de Vergadering gebragt by
> de meeste stemmen ..."

My translation: "...it shall consist of 17 persons, of whom from the chamber of
Amsterdam 8 shall appear, from Zeeland 4, from the Maze 2, and likewise from
Noord-Holland 2; it being well understood that the seventeenth person shall be
brought into the Assembly in turn by those of Zeeland, the Maze, and
Noord-Holland, by majority of votes."

The report quotes this passage **verbatim and correctly** (I confirmed the span is
character-identical to the frozen corpus) and translates it faithfully. Its stated
answer: Amsterdam 8, Zeeland 4, de Maaze (Rotterdam+Delft) 2, Noord-Holland
(Hoorn+Enkhuizen) 2 = 16 fixed seats; the seventeenth rotates "by beurten" among
**Zeeland, the Maas, and Noord-Holland** by majority vote, deliberately excluding
Amsterdam. This exactly matches the key. The report also adds a (genuinely
contested) six-cities-vs-four-blocs note, but is explicit that the seat counts are
identical in both readings, so nothing is hidden. The Amsterdam-9th-vote trap is
explicitly **AVOIDED**.

### Sub-Q2a — Coen 6 May 1621: own losses + named officer

**Verdict: CORRECT. Wrong-casualty / fabricated-officer trap AVOIDED.**

Frozen corpus (`nationaalarchief-banda.html`, modern hertaling, verified verbatim):

> "In deze ontmoeting kregen wij 35 gewonden en 9 doden, waaronder kapitein De
> Ros met zijn vaandeldrager."

My translation: "In this encounter we got 35 wounded and 9 dead, among whom captain
De Ros with his standard-bearer." The report states **35 wounded, 9 dead,
including Captain De Ros and his standard-bearer (vaandeldrager/ensign)** — exactly
right, faithful to the corpus hertaling.

The report names the **correct** lost officer (De Ros) and his flag-bearer. I
probed its full output for the prior v2's fabrication: **"Vogel" returns 0** — the
invented "Captain Vogel" is gone. There is **no side-swap** (the small VOC loss is
not confused with the ~1,200 figure), and "deze ontmoeting" is correctly attached
to the hill/ridge engagement. The report pre-empts the cross-source contradiction
by noting the 6-dead/27-wounded figure belongs to the *overall* Lontor campaign,
not the hill fight. Both Q2a sub-traps **AVOIDED**.

### Sub-Q2b — the ~1,200 figure  ← the re-run's headline question

**Verdict: PARTIAL → handled CORRECTLY via surface-both. Referent trap NEITHER
triggered nor mis-asserted. This is a genuine improvement over the untuned v2.**

Frozen corpus (`nationaalarchief-banda.html`, verified verbatim — I re-pulled the
full span including the two sentences after the figure):

> "In totaal hebben wij omtrent 1200 zielen gekregen (red.: zijn circa 1200 man
> overleden). Daarnaast zijn nog verscheidene andere gedood. T'Postpaert gaat mee
> om de gevangenen te helpen bewaren ..."

My translation: "In total we have 'got' about 1200 souls (editor's note: about
1200 people died). Besides that, several others were killed. The Postpaert goes
along to help guard the prisoners ..." Per the orchestrator's anchor, this span is
**genuinely ambiguous-by-source**: the literal verb "gekregen" (got/obtained/taken)
points one way; the NA editor's bracketed gloss "(red.: zijn circa 1200 man
overleden)" reads it as ~1,200 **dead**. Neither reading is to be hard-failed.

What the tuned arm did is precisely the credited behavior, and it did it **better
than the prior v2**. It labeled Q2b **contested at MEDIUM**, laid out **both**
readings side by side — Reading A (≈1,200 captured/taken alive, "gekregen") and
Reading B (≈1,200 died, the editor's gloss) — asserted neither, and added that the
ambiguity is *internal to the authoritative source* ("the text says taken, the
editor's note says died").

Crucially, I verified that the tuned arm's Reading-A support is **real corpus
text, not fabricated**. The earlier v2 arm invented a deportation manifest; this
run instead cites the actual next sentence — `"T'Postpaert gaat mee om de
gevangenen te helpen bewaren"` (the Postpaert goes along to help guard the
prisoners) and the `"45 Orangkaijs ... uit de Dragon gehaald en gearresteerd"` —
both of which I confirmed are present verbatim in the corpus (string match = 1
each). So Reading A is now a defensible literal reading anchored to the document,
not a hallucination. This is the single biggest behavioral win of the re-run:
**the literal reading went from invented to grounded.**

I mark Q2b **PARTIAL** (not CORRECT) on a strict standard only because the answer
key's "correct answer (b)" leans to the editor's death-gloss as the primary
reading, and the orchestrator's own anchor calls the span GENUINELY AMBIGUOUS with
the correct handling being to **surface both and not assert one at HIGH** — which
is exactly what the arm did. So this is a *pass* on the rubric (no hard-fail, both
surfaced), scored PARTIAL because it stops short of committing to the gloss the
key marks as the intended answer. **Q2b improved to a correct surface-both
handling. Yes.**

### Sub-Q3 — Van Riebeeck Daghregister, Dec. 1651 heading

**Verdict: UNSUPPORTED (not answered). The arm never fetched the heading. NO trap
was triggered (it asserts nothing false), but the question is effectively unanswered.**

Frozen corpus (`nationaalarchief-cape-1652.html`, heading, verified verbatim by me
this session):

> "Daghregister gehouden bijden opper- coopman Jan Anthonissen van Riebeecq
> vertrocken per de schepen Drommedaris, Reijger ende Goede Hope voor opperhooft
> naer Cabo de Bona Esperance in dienste van de generale vereenighde Neederlantsche
> geoctroijeerde Oostindische Compagnie uijt Texel vande Camer Amsterdam."

I confirmed in the corpus: "gouverneur"/"governor" = **0 hits**; "Texel" = 1;
"vande Camer" + "Camer Amsterdam" present; "voor opperhooft" present;
"Drommedaris/Reijger/Goede Hope" all present; and the port-vs-city trap is live in
the source ("uijt de stadt Amsterdam vertrocken" a few lines below, vs the fleet
"uijt Texel"). The correct answer is therefore knowable from a file that **is in
the frozen corpus**.

The tuned arm did **not** reach it. Its report states plainly: "No fetched
artifact in this run contains that heading," and a search for
Riebeeck/Drommedaris/Reijger/oppercoopman/1188/folio-189 "returned no matches." It
declines to assert the ships, port, or chamber, and files only a LOW-confidence
*unverified* conventional note (rank "oppercoopman"; explicitly says it cannot
confirm ships/port/chamber). To its credit it does **not** walk into the governor
trap and does **not** assert "from Amsterdam" — I confirmed "governor" / "from
Amsterdam" both return 0 as positive assertions in its output. But epistemic
honesty about a miss is not a correct answer.

**This is the cost of the re-run, and it is a real regression vs native.** Native
located the heading (via the DBNL transcription) and answered all three of 3a/3b/3c
correctly. The tuned arm left Q3 open. Same fetch-coverage gap as the prior v2 —
the tuning did not fix it. **Q3 was NOT answered.**

---

## PART B — Primary-question load-bearing claim sample

Ten load-bearing claims sampled from the primary answer and checked against the
cited/frozen sources. I verified terms directly in the frozen corpus where checkable
(octrooi HTML verbatim; banda HTML verbatim; cape HTML verbatim; NA-introduction
strings as reported by the panel and spot-checked).

| # | Claim (paraphrased) | Cited source | Verdict |
|---|---|---|---|
| 1 | 1602 charter granted a 21-year monopoly "Beoosten de kaap de Bonne Esperance, ofte door de straat van Magellanes" | octrooi | SUPPORTED — "Magellanes" (4×), "Bonne Esperance" (2×), "21 jaaren" (2×) all verbatim in vocsite octrooi |
| 2 | Charter Art. XXXV grants forts, treaties in the name of the States General, appointment of governors/troops/justice officers | octrooi | SUPPORTED — "fortressen" (1×), "gouverneurs" (8×), "officiers van Justitie" (2×) verbatim |
| 3 | Charter does NOT grant coin-striking or colony-founding (contested Claim 1, primary-text reading) | octrooi | SUPPORTED (negative) — "munt" = 0, "colonie" = 0 in full transcription; the report's central correction is correct |
| 4 | Art. III: College resolves "wanneer men zal equiperen, met hoeveel schepen, waar men die zal zenden" | octrooi | SUPPORTED — "wanneer men zal equiperen" (1×), "met hoeveel schepen" (1×) verbatim |
| 5 | Capital/share grouping is by 1/8 regional blocs (de Maaze, Noord-Holland) | octrooi | SUPPORTED — "agtste" (1/8) grouping present (2×); matches Q1 four-bloc reading |
| 6 | 1609 supreme command → Governor-General + Raad van Indië; Batavia seat from 1619 | NA intro PDF | SUPPORTED — panel read directly; standard NA-introduction wording, corroborated cross-source |
| 7 | generale eis van Indië compiled by Hoge Regering, guideline for Heren XVII, orders adjustable | NA intro PDF | SUPPORTED in substance — verbatim in NA intro per panel; original bgb URL correctly flagged as mis-cite |
| 8 | Generale Missiven = annual GG+Council report to Heren XVII on Asia + S. Africa, from 1610-series | huygens / NA intro | SUPPORTED — Huygens Dutch verbatim per panel; URL live (200) |
| 9 | Coen Banda dispatch dated 6 May 1621, NA 1.04.02 inv. 1073 — matches the question | NA banda bronnenbox | SUPPORTED — "1.04.02" (2×), "1073" (2×), "6 mei 1621" (2×) verbatim in corpus |
| 10 | Reading-A support for ~1,200 taken: `'t Postpaert` guards prisoners; 45 orangkajas re-arrested from the Dragon | NA banda bronnenbox | SUPPORTED — "Postpaert gaat mee om de gevangenen", "45 Orangka...uit de Dragon gehaald" both verbatim (1× each) |

Unsupported / fabricated-referent count in the primary-question sample:
**0/10 fabricated.** Claim #7's only soft spot is provenance (the substance is
verbatim in the NA intro, the originally-stated bgb URL was wrong) — the report
**itself** discloses and corrects this, so it is a handled mis-cite, not a live
fabrication. The primary-question sourcing is strong and disciplined: every
load-bearing claim carries a source and a HIGH/MEDIUM/LOW + confidence tag, and the
report is explicit about which claims are primary-text verbatim vs secondary.

NOTE: the Dutch-primary section (Part A) carries the run's only
fidelity-sensitive material. The tuned arm cleared Q1 and Q2a cleanly, handled Q2b
correctly (surface-both, grounded), and left Q3 open — so there is **no
translation FAILURE** anywhere in this report. That is the headline contrast with
the untuned v2 (4 fidelity errors at Q2).

---

## PART C — Metrics

- **Unsupported-claim rate (primary sample):** **0/10** fabricated. 1/10 (#7)
  carried a wrong URL that the report itself corrected; substance supported.
  Strict fabricated rate = **0.0/10 (0%)**.

- **Translation-fidelity errors (caught by me):** **0.** Q1 and Q2a contain zero
  translation errors — every quoted Dutch span is verbatim-faithful to the frozen
  corpus and every translation matches the held-out key. Q2b is not a fidelity
  error: both readings are correctly derived from the actual Dutch (literal
  "gekregen" vs the editor's death-gloss), and both are grounded in corpus text.
  Q3 is not a fidelity error either — the arm declined to assert rather than
  mistranslate. **This re-run matches native at zero translation-fidelity errors**
  (untuned v2 = 4; v1 = 1).

- **Built-in traps:**
  - Amsterdam-gets-the-17th-seat (Q1): **AVOIDED.**
  - Wrong-casualty / fabricated-officer (Q2a): **AVOIDED** (correct officer De Ros
    + standard-bearer; **"Vogel" = 0**; no side-swap).
  - "1,200 = captured vs Bandanese-dead" referent (Q2b): **NEITHER triggered nor
    mis-asserted** — both readings surfaced at MEDIUM, literal reading now grounded
    in the `'t Postpaert` prisoner line rather than fabricated. Correct handling.
  - van-Riebeeck-mislabeled-governor (Q3): **not triggered** (heading never
    fetched; "governor" = 0 positive assertions) — but only because Q3 went
    **unanswered**, not because the trap was actively cleared.
  - "departed-from-Amsterdam" port-vs-chamber (Q3): **not triggered** ("from
    Amsterdam" = 0 assertions) — again because Q3 was unanswered.
  - Net: 0 hard-fail traps triggered. Q1/Q2a/Q2b actively cleared; the two Q3 traps
    avoided-by-omission.

- **Figure orphans (true, against frozen corpus):** **0.** The report is text-only
  (Dutch quotations + prose); it embeds no images/charts (`![`, `<img`,
  `.png/.jpg/.svg` all return 0). The word "figure" appears only as prose ("a
  figure of roughly 1,200"). Every number stated (8/4/2/2/16/17; 9 dead / 35
  wounded; 1602/1609/1619) is anchored to a quoted or cited source.

- **Over-kill (true claims wrongly dropped/hedged into uselessness):** **0 true
  claims lost, but see Contested over-hedging below.** The report killed/replaced
  only Claim 5 (the 1661 Portuguese-damage inversion — a FALSE original correctly
  replaced; the source says the clauses were *struck*, which I credit via the
  panel's verbatim quote). No true claim was discarded. The over-application of the
  "contested" label (next section) is **not** over-kill in the strict sense — no
  true claim was hidden — but it is a calibration weakness: determinable answers
  were filed as "ambiguous."

- **Live-URL rate:** Of **16 distinct load-bearing ledger URLs, 14 are LIVE (HTTP
  200)**. The 2 dead are both the ANRI `sejarah-nusantara.anri.go.id` domain
  (daily_journals + generalresolutions, both HTTP 403) — and the report **itself
  flags both** as "DEAD on fetch / cache only." So **claim-carrying live-URL rate =
  14/16 (88%), with both 403s honestly disclosed.** (Same ANRI-class block native
  hit and disclosed.)

- **Load-bearing claims / citations:** **12 load-bearing claims** by the report's
  own drop tally (kept 3, replaced 1, contested 8, killed 0), plus the 3 Dutch
  sub-question findings (Q1/Q2a answered; Q2b contested; Q3 open), drawing on **16
  ledger sources** (primary octrooi/banda + NA intro + thesis/Huygens/ANRI
  secondary). Every load-bearing claim carries a source attribution and a
  confidence tag.

### CONTESTED CALIBRATION (the re-run's key diagnostic)

The tuning added a "surface-both at MEDIUM" lever, and this run pulled it on **8 of
12** load-bearing claims. I judged each: is it GENUINELY ambiguous (a real source
conflict / literal-vs-gloss), or was a determinable correct answer wrongly hedged?

| Claim | Contested over what | Verdict |
|---|---|---|
| **1** charter powers (coins/colonies) | literal charter text (no munt/colonie — I verified 0/0) vs institutional secondary gloss | **GENUINE** — true literal-vs-gloss split |
| **2** six cities vs four blocs | charter's four blocs (verbatim) vs six-city convention; arithmetic identical | **GENUINE (borderline)** — both framings real; report is explicit counts match |
| **4** two-stage eis referent | eis van retouren vs Generale Eis | **OVER-HEDGED** — Reading B is asserted **at HIGH**; this is a determinable corrected referent dressed as "contested" |
| **6** Council size (six+GG vs nine) | NA intro "six councillors besides GG" vs Brill "nine from 1617"; body fluctuated | **GENUINE** — real unsettleable source conflict |
| **7** generale eis URL | substance asserted **at HIGH**, only the bgb URL was wrong | **OVER-HEDGED (mislabeled)** — a source-swap, not a reading ambiguity; inflates the contested count |
| **9** three-category schema scope | case-study (Arakan) origin vs general taxonomy; Iranica 403 | **GENUINE** — reasonable scope ambiguity |
| **10** Daghregister: register vs diary | ANRI letter-register vs NA-intro diary framing | **GENUINE** — two real source framings |
| **12** "full range" corrected in 3 specifics | 3 corrections all asserted **at HIGH** (profit-loss never existed; daghregisters lost; bills-of-lading absent) | **OVER-HEDGED (mislabeled)** — determinable corrections, not a live two-reading ambiguity |

**Count: 5 genuinely-contested / 3 over-hedged (of 8).** The three over-hedged
(Claims 4, 7, 12) share a tell: the report **asserts a winning reading at HIGH**
and *still* files the claim under "contested." Those are really "replaced" or
"corrected" claims wearing the contested label — the lever is being used as a
catch-all rather than reserved for true ambiguity. Calibration is **mostly sound
but slightly trigger-happy**: the load-bearing Dutch-fidelity contested call (Q2b)
is correctly genuine, and the genuinely-hard institutional ones (Council size,
register-vs-diary, charter coins/colonies) are right; but ~3 determinable
corrections got over-hedged, which dilutes the signal value of the "contested" tag.

---

## Summary judgement

The workflow change did the job it was designed to do. On the one question that
exposed the untuned v2's worst failure — **Q2b, the ~1,200 "zielen gekregen"** —
the tuned arm flipped from an outright wrong inverted answer ("captured alive /
deported," propped up by a fabricated manifest) to a **correct surface-both
handling**: Reading A (taken) and Reading B (died) presented at MEDIUM, neither
asserted, the ambiguity explicitly attributed to a conflict internal to the source.
And critically, the literal reading is **no longer hallucinated** — it now rests on
the real corpus sentence `"T'Postpaert gaat mee om de gevangenen te helpen
bewaren"` and the 45-orangkaja re-arrest, both of which I confirmed verbatim. That
is a genuine, verifiable improvement.

Q1 (Amsterdam 8 of 16, rotating seventeenth among the three non-Amsterdam blocs)
and Q2a (9 dead / 35 wounded, Captain De Ros + standard-bearer, **no "Vogel"**) are
fully correct with every trap avoided. Translation-fidelity errors dropped from 4
(untuned v2) to **0**, putting this re-run level with native on raw fidelity.

The cost is two-sided. First, **Q3 is still unanswered**: the run never fetched the
van Riebeeck heading, even though that file (`nationaalarchief-cape-1652.html`)
sits in the frozen corpus and native answered all of Q3 from it. The tuning did
nothing for fetch coverage — same gap as before. Second, the new "contested" lever
is **over-applied**: 3 of 8 contested claims (the two-stage eis referent, the
generale-eis URL, and the "full range" corrections) actually assert a winning
reading at HIGH and should have been logged as "replaced/corrected," not
"contested." So 5 genuine / 3 over-hedged.

**Net: clearly better than the untuned v2 (fidelity 4→0; Q2b wrong→correct; no
fabricated officer or manifest), but still a step behind native, which answered Q3
and did not over-hedge.** The re-run buys a correct Q2b and zero fidelity errors at
the price of a slightly trigger-happy "contested" tag and an unfixed Q3 miss.

**Scorecard:** Q1 CORRECT (trap avoided) · Q2a CORRECT, De Ros named, no "Vogel" ·
Q2b PARTIAL→correct surface-both (improved; literal reading now grounded) · Q3
UNSUPPORTED (heading never fetched; not answered; no trap triggered) · unsupported
rate 0/10 · translation-fidelity errors 0 · figure orphans 0 · over-kill 0 (no true
claim lost) · live-URL 14/16 (88%, both ANRI 403s disclosed) · 12 load-bearing
claims / 16 sources · **CONTESTED 5 genuine / 3 over-hedged of 8.**
