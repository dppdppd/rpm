# v1 grading — 2026-06-07 triplet bake-off (Dutch-fidelity)

Grader: independent Dutch-fidelity grader (v1 arm). Date: 2026-06-07.
Report graded: `runs/2026-06-07-triplet/v1/report.md`.
Method: I read the v1 report, then independently re-translated each named Dutch
source window from the FROZEN corpus
(`/home/coder/projects/VOC/.../fetched/`) and from the report's own fetched
artifacts, and compared against the held-out grading key. I did not trust the
report's self-assessment. Deterministic URL-liveness and offline-audit checks
were run.

---

## PART A — Three Dutch sub-questions (translation-fidelity probes)

### Sub-Q1 — 1602 octrooi, seat allocation + seventeenth-seat rule

**Verdict: CORRECT. Amsterdam-17th-seat trap AVOIDED.**

My independent reading of the frozen corpus (`vocsite-octrooi-1602.html`,
Article "I I", verbatim):

> "Dat, zoo dikwils als het van nooden zyn zal een generale Vergadering ofte
> Collegie uit de voorschreve kameren te houden, die gehouden zal werden van 17
> persoonen, daar in uit de kamer van Amsterdam zullen compareren 8, uit Zeeland
> 4, uit de Maaze 2, ende van gelyken uit Noordholland 2; wel verstaande, dat de
> zeventiende persoon by beurten van die van Zeeland, Maaze ende Noordholland,
> zal werden in de Vergadering gebragt by de meeste stemmen ..."

My translation: "...it shall consist of 17 persons, of whom from the chamber of
Amsterdam 8 shall appear, from Zeeland 4, from the Maze 2, and likewise from
Noord-Holland 2; it being well understood that the seventeenth person shall be
brought into the Assembly in turn by those of Zeeland, the Maze, and
Noord-Holland, by majority of votes..."

The v1 report quotes this Dutch passage **verbatim and correctly** (character-for-
character identical to the frozen corpus), and translates it faithfully. Its
stated answer:
- Amsterdam 8, Zeeland 4, the Maze 2, North Holland 2 = 16 fixed seats. ✓
- 17th seat is NOT Amsterdam's; supplied "by beurten" by rotation among Zeeland,
  the Maze, and North Holland, by majority vote, deliberately denying Amsterdam an
  outright majority. ✓

This exactly matches the key. The report even adds correct corroboration from the
Heren XVII wiki ("Daarmee werd voorkomen dat Amsterdam een absolute meerderheid
kreeg" — verified present in the fetched artifact) and correctly flags the
Valentijn-1724 provenance. The trap (give Amsterdam the deciding 9th vote / 17th
seat) is explicitly and correctly AVOIDED.

### Sub-Q2 — Coen 6 May 1621: own losses + the ~1,200 figure

**Verdict: PARTIAL — (a) CORRECT; (b) MISTRANSLATION / WRONG-REFERENT.
"1200 = captured-not-dead" trap TRIGGERED.**

**(a) Own losses — CORRECT.** Frozen corpus (`nationaalarchief-banda.html`,
modern hertaling):

> "In deze ontmoeting kregen wij 35 gewonden en 9 doden, waaronder kapitein De
> Ros met zijn vaandeldrager."

My translation: "In this encounter we got 35 wounded and 9 dead, among whom
captain De Ros with his standard-bearer." The v1 report states **35 wounded, 9
dead, Captain de Ros with his ensign/vendrich (vaandrig)** — correct, and faithful
to both the corpus hertaling and the original Coen OCR ("In dese rescontre hebben
35 gequesten ende 9 dooden gecregen, daeronder cappiteyn de Ros met sijn
vendrich"). Naming the lost officer and his flag-bearer is correct.

**(b) The ~1,200 figure — TRAP TRIGGERED.** This is the decisive failure.

The frozen corpus — the authoritative source the bake-off designates for this
sub-question (NA 1.04.02 inv.nr. 1073) — reads:

> "In totaal hebben wij omtrent 1200 zielen gekregen (red.: zijn circa 1200 man
> overleden). Daarnaast zijn nog verscheidene andere gedood."

My translation: "In total we have 'got' about 1200 souls (editor's note: about
1200 people died). Besides that, several others were killed." The NA editorial
team inserted "(red.: zijn circa 1200 man overleden)" precisely BECAUSE "gekregen
/ becomen" here is a euphemism, and they gloss it as ~1,200 **dead**. The grading
key's correct answer is therefore: 1,200 = **Bandanese dead** (a euphemistic body
count), NOT people captured / received / enslaved / reinforcements.

What the v1 report did:
- It went OUTSIDE the frozen corpus to a different edition (Colenbrander,
  *Bescheiden* I, archive.org OCR), where the original verb is "becomen": "In alles
  hebben ontrent 1200 zielen van haer becomen; daerenboven sijn noch verscheyde
  andere doot gebleven." (I verified this OCR is faithfully reproduced in the
  report's own artifact `06-coen-bescheiden-vol1-6mei1621.md`.)
- It read "becomen" **literally** as "obtained / took / brought into their power"
  and concluded: "**the ~1,200 figure refers to ~1,200 Bandanese 'souls' the Dutch
  obtained/took ... brought into their power (captured / taken)** ... kept separate
  from the dead." It rated this **HIGH** confidence.
- It then explicitly **rejected** the corpus's authoritative "killed" gloss,
  demoting it to "an editorial interpretation" and a mere "divergence," at MEDIUM
  confidence.

This is exactly the built-in trap described in the key: "Translating 'omtrent 1200
zielen gekregen' literally as 'we received/took ~1200 souls' and reporting it as
prisoners taken ... the inverted referent." The report's primary, HIGH-confidence
stated answer attaches the captured/taken referent to the 1,200. The fact that it
flagged the contradiction transparently is creditable process — but its delivered
answer to (b) is the wrong referent, and it actively argued the correct
(death-toll) reading down to MEDIUM. On the merits, the report's literal-verb
defense is weak: "daerenboven/daarnaast ... andere gedood" most naturally reads as
"besides these 1,200, yet more were killed," and the historiography of the 1621
Banda genocide treats the ~1,200 as a euphemistic elimination count, consistent
with the NA gloss. **Trap TRIGGERED.**

(Note: the trap of swapping the small VOC loss with the 1,200 — "Coen lost 1,200
men" — was NOT made; the report keeps the 35/9 distinct. So this is a
wrong-referent error on the Bandanese figure, not a side-swap.)

### Sub-Q3 — Van Riebeeck Daghregister, Dec. 1651 heading

**Verdict: CORRECT. Governor-mislabel trap AVOIDED. "From-Amsterdam" trap AVOIDED.**

Frozen corpus (`nationaalarchief-cape-1652.html`, heading):

> "Daghregister gehouden bijden opper-coopman Jan Anthonissen van Riebeecq
> vertrocken per de schepen Drommedaris, Reijger ende Goede Hope voor opperhooft
> naer Cabo de Bona Esperance ... uijt Texel vande Camer Amsterdam."

I confirmed the word "gouverneur/governor" appears **zero** times anywhere in the
corpus source. The v1 report's answer:
- (a) Three ships: Drommedaris, Reijger, Goede Hoope ✓
- (b) Rank **oppercoopman**, shipboard role **voor opperhooft (chief/commander)**,
  and it **explicitly states this is NOT "governor"** by quoting only the heading's
  titles ✓ — trap AVOIDED.
- (c) Sailed **from Texel**, under the **Chamber of Amsterdam** ✓ — it correctly
  separates the port (Texel) from the dispatching chamber (Camer Amsterdam) and does
  NOT say "departed from Amsterdam," so the city/port/chamber wrong-referent trap is
  AVOIDED.

The report adds an honest provenance caveat that folio 189 was matched by content,
not by a manuscript scan — appropriate and not an error. Ships are all named and
counted correctly; "Goede Hoope" is correctly treated as a ship, not the
destination. Fully CORRECT.

---

## PART B — Primary-question load-bearing claim sample

Ten load-bearing claims sampled and checked against the cited/fetched sources.

| # | Claim (paraphrased) | Cited source | Verdict |
|---|---|---|---|
| 1 | Octrooi Art. III gives Heren XVII the goal-setting power (when to equip, how many ships, where to send, other trade matters); chambers execute | vocsite octrooi 1602 | SUPPORTED — verbatim Art. III present in corpus + fetched md |
| 2 | Chamber directors "verantwoordelijk voor het uitvoeren van het beleid van de Heren XVII" | nl.wiki Heren XVII | SUPPORTED — exact phrase in fetched artifact |
| 3 | Heren XVII met 2–3×/yr in an 8-yr cycle, 6 yrs Amsterdam then 2 yrs Middelburg | nl.wiki Heren XVII | SUPPORTED — "eerst twee keer ... later drie keer"; "zes jaar in Amsterdam ... twee jaar in Middelburg" |
| 4 | Generale Missiven = annual letters, Gov-Gen + Raden → Heren XVII, 1610–1761 | huygens / Heren XVII | SUPPORTED — "jaarlijkse brieven ... Gouverneur-Generaal en Raden ... aan de Heren Zeventien"; "periode 1610-1761" |
| 5 | 1617 journaal + reisverslagen rule; 1643 octrooigebieden systematically described | nl.wiki Heren XVII | SUPPORTED — both rules verbatim in fetched artifact |
| 6 | Secret instructions / "secreete boeken" kept by the advocaat | nl.wiki Heren XVII | SUPPORTED — "secreete boeken" + advocaat present (report rated MEDIUM, appropriately) |
| 7 | Van Riebeeck sailed under a written Heren XVII instruction to build a fort/refreshment station at the Cape | NA banda / Cape heading | SUPPORTED in substance (refreshment-node goal); the specific "written instruction from Heren XVII" is reasonable but lightly sourced — borderline, accepted |
| 8 | Banda goal = subjugation/depopulation to secure nutmeg monopoly; "Om een eynd van den oorloch ... meester te blyven" | archive.org Coen | SUPPORTED — phrase verbatim in Coen OCR + corpus hertaling |
| 9 | Cape was explicitly NOT a colony, no enslaving of locals | NA / Daghregister | PARTIALLY SUPPORTED — plausible and standard, but not quoted from a Dutch passage in the report; mild UNSUPPORTED-leaning. Counted as borderline. |
| 10 | The 6 May 1621 letter = NA 1.04.02 inv.nr. 1073 | NA banda bronnenbox | SUPPORTED — bron line "Brief Coen: 1.04.02 inventarisnummer 1073" present in corpus |

Unsupported / fabricated-referent count in the primary-question sample: **0 clearly
fabricated**; **1 borderline-thin** (#9, Cape "not a colony / no enslaving" asserted
without a quoted Dutch passage). Claim #7's "written instruction from Heren XVII" is
lightly sourced but historically standard. Overall the primary-question sourcing is
strong; the report is unusually disciplined about attaching a URL and a confidence
tag to every load-bearing claim.

NOTE: the one true translation-fidelity FAILURE (Q2b, 1,200 = captured-not-dead)
sits in the Dutch-primary section, not the primary-question sample. It is the
single most important defect.

---

## PART C — Metrics

- **Unsupported-claim rate (primary sample):** 0/10 fabricated; 1/10 borderline-thin
  (#9). Strict rate = **0.0/10 (0%)** fabricated; lenient-including-borderline =
  **1/10 (10%)**.
- **Translation-fidelity errors caught (by me):** **1** — Sub-Q2(b): the ~1,200
  figure is reported as Bandanese **captured/taken** (HIGH confidence), contradicting
  the frozen corpus's editorial gloss "circa 1200 man overleden" (died). This is the
  built-in wrong-referent trap, TRIGGERED. (Q1, Q2a, Q3 contain zero translation
  errors.)
- **Built-in traps:**
  - Amsterdam-gets-17th-seat (Q1): **AVOIDED.**
  - "1200 zielen" captured-vs-Bandanese-dead (Q2): **TRIGGERED** (reported as
    captured/taken; corpus says died).
  - van Riebeeck mislabeled governor / from-Amsterdam (Q3): **AVOIDED** (both
    sub-traps).
  - Net: 1 of 3 trap-clusters triggered (the Q2 referent).
- **Figure orphans:** **0** — the report is text-only (Dutch quotations + prose); it
  contains no figures/charts/numeric infographics, so there are no orphaned figures.
  (The repo-wide `offline_audit.py` scan reports orphans for OTHER VOC research dirs,
  not this report.)
- **Over-kill (true claims wrongly dropped):** **N/A** for v1 — this is a
  build-it-up translation report, not a prune of a prior draft; no evidence of true
  claims being dropped. The opposite risk (over-asserting the captured reading)
  occurred at Q2b.
- **Live-URL rate:** **10 / 10 = 100%** (ran `checks/url_liveness.sh`; every cited
  URL returned HTTP 200 on 2026-06-07).

---

## Summary judgement

v1 is a high-discipline arm: every load-bearing claim is URL-cited and
confidence-tagged, all 10 URLs are live, Q1 and Q3 are fully correct with both their
traps cleanly avoided, and the small VOC losses in Q2(a) are exactly right. Its one
real failure is Q2(b): rather than report the frozen corpus's authoritative reading
that the ~1,200 "zielen" are Bandanese **dead**, it left the corpus, read the
original verb "becomen" literally, and reported the 1,200 as Bandanese
**captured/taken** at HIGH confidence — the exact wrong-referent trap the
sub-question was built to catch — while arguing the correct death-toll reading down
to MEDIUM. Transparent flagging of the contradiction softens but does not excuse the
delivered wrong referent.

**Scorecard:** Q1 CORRECT (trap avoided) · Q2 PARTIAL — (a) correct, (b)
mistranslation/trap TRIGGERED · Q3 CORRECT (traps avoided) · unsupported rate
0/10 (1 borderline) · translation-fidelity errors 1 · figure orphans 0 · over-kill
N/A · live-URL 10/10.
