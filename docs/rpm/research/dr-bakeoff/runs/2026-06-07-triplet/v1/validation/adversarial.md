# Validation — adversarial + citation audit

Run: 2026-06-07-triplet / v1. Date: 2026-06-07.

## URL liveness (HEAD, Phase 3)
All cited URLs returned HTTP 200 on 2026-06-07:
- https://www.vocsite.nl/geschiedenis/octrooi1602/ — 200
- https://www.dbnl.org/tekst/rieb001dagh01_01/rieb001dagh01_01_0004.php — 200
- https://www.dbnl.org/tekst/rieb001dagh01_01/rieb001dagh01_01_0005.php — 200
- https://archive.org/details/janpieterszcoenb01coen — 200
- https://www.nationaalarchief.nl/beleven/onderwijs/bronnenbox/hoe-ging-het-verder-op-banda — 200
- https://nl.wikipedia.org/wiki/Heren_XVII — 200
- https://resources.huygens.knaw.nl/vocgeneralemissiven — 200

## Adversarial check 1 — the "~1200" figure in Coen's 6 May 1621 letter

CONTRADICTION (resolved by reading the primary text):
- Nationaal Archief bronnenbox "Hertaling" glosses "omtrent 1200 zielen gekregen"
  with an editorial note "(red.: zijn circa 1200 man overleden)" — i.e. ~1200 *killed*.
- The original Early-Modern-Dutch text (Colenbrander, Bescheiden I, p. 639) reads:
  "In alles hebben ontrent 1200 zielen van haer becomen; daerenboven sijn noch
  verscheyde andere doot gebleven." The verb "becomen" = got / obtained / took
  (not "killed"). The dead are explicitly counted *in addition* ("daerenboven ...
  doot gebleven").
- Adversarial search corroborates "becomen" = "to obtain/gain": a separate Coen
  quote uses "verseeckerder staet te becomen" = "to gain a more secure position"
  (en.wikipedia.org/wiki/Dutch_conquest_of_the_Banda_Islands).
- CONCLUSION: literal primary reading = ~1,200 Bandanese souls *obtained/taken*
  (captured / brought into Dutch power), with further/other dead counted separately.
  The NA "killed" gloss is an editorial interpretation, not the literal text.
  Report states the literal reading and flags the NA gloss.

## Adversarial check 2 — Van Riebeeck rank ("oppercoopman" vs "commandeur")
- Daghregister heading: "gehouden bij den oppercoopman ... Jan Anthonisz. van
  Riebeeck ... voor opperhooft naer Cabo de boä Esperance."
- Editor's note (DBNL) explains: on 1647 dismissal he had reached "Koopman"; his
  appointment as Commander of the Cape post brought the rank "Koopman en
  Opperhoofd" with the salary of an "Opperkoopman." So the heading's "oppercoopman"
  (upper-merchant) is his pay-grade/rank and "opperhooft" (chief/commander) is his
  shipboard/command role. Both are reported. No contradiction; complementary.

## Adversarial check 3 — octrooi seat allocation
- vocsite.nl (Valentijn 1724 transcription) Art. II: Amsterdam 8, Zeeland 4,
  Maze 2, Noord-Holland 2 = 16; the 17th rotates among Zeeland, Maze, Noord-Holland.
- Independently corroborated by nl.wikipedia.org/wiki/Heren_XVII: "Het zeventiende
  lid werd bij toerbeurt afgevaardigd door Zeeland en een van de vier kleine
  kamers. Daarmee werd voorkomen dat Amsterdam een absolute meerderheid kreeg."
- Note: the small chambers (Delft, Rotterdam, Hoorn, Enkhuizen) are grouped in the
  octrooi as the "Maze" (Delft+Rotterdam) and "Noord-Holland / Westfriesland"
  (Hoorn+Enkhuizen) quarters; each quarter sends 2. No contradiction.

## Citation audit
Every load-bearing claim in report.md is tied to a fetched/ artifact. Each
Dutch-primary sub-answer quotes the verbatim Dutch and gives a from-scratch
English translation. No fabricated URLs. Confidence tags carry source URLs.
