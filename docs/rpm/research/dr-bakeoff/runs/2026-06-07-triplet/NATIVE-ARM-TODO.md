# TODO (fresh session) — native arm of the v1│v2│native VOC bake-off

**Status:** v1 + v2 are DONE and graded (see `scorecard.md` in this dir). Only the **native arm**
remains. Run it in a FRESH session (this one ran out of context budget for a ~2.7M-token native
run). Do these two steps, then finalize.

## Step 1 — run the REAL native arm
Invoke the **bundled `/deep-research` skill** (the native Claude Code Workflow — NOT rpm's
`research` skill, NOT a hand-rolled subagent). Give it EXACTLY the question below and nothing else.

**Fairness (critical):** before/while running native, do **NOT** open `sub-questions.md` (it holds
the private answer key), and do **NOT** read anything under `/home/coder/projects/VOC/`. Native
must research live from scratch, exactly as v1/v2 did.

Question to hand native (verbatim):
> PRIMARY: What goals did the chambers / Heren XVII / Batavia / officers assign to VOC (Dutch East
> India Company) expeditions, 1602–1700, and through which issuing documents?
>
> Dutch-primary sub-questions (each answerable only by locating and translating a specific
> Early-Modern-Dutch source — find the actual text, translate it):
> 1. In the 1602 VOC charter (octrooi), the article setting up the central board of seventeen
>    directors specifies how many of the seventeen come from each chamber, and a special rule for
>    who supplies the seventeenth man. Translating that article, state the per-chamber allocation
>    of the seventeen seats and the exact rule that determines the seventeenth seat.
> 2. In Jan Pieterszoon Coen's dispatch to the Heren XVII on the Banda events, dated 6 May 1621
>    (Nationaal Archief 1.04.02, inv. 1073), Coen gives running figures for his own force's losses
>    in the hill engagement and a total figure for the Bandanese. From the Dutch, state (a) his own
>    killed/wounded in that engagement and any named officer lost, and (b) what the roughly
>    1,200-figure he reports actually refers to.
> 3. In Jan van Riebeeck's Daghregister of the December 1651 outbound voyage to the Cape (Nationaal
>    Archief 1.04.02, inv. 1188, folio 189), the opening register heading names the author, his
>    shipboard rank/role, the ships, and the place + chamber he departed under. From the Dutch,
>    name (a) the three ships, (b) his rank/role, and (c) the port and chamber he sailed under.

Persist native's cited report to `runs/2026-06-07-triplet/native/report.md` (relocate from
native's own output tree if needed). Record cost/#agents/wall-clock for the scorecard.

## Step 2 — grade native (same protocol as v1/v2)
Dispatch a Dutch-fidelity grader (general-purpose subagent) with the SAME contract used for v1/v2
(`grading/v1-grading.md`, `grading/v2-grading.md` show the format). It reads `native/report.md`,
the PRIVATE key in `sub-questions.md`, and the frozen corpus
`/home/coder/projects/VOC/docs/research/voc-expedition-goals-chamber-assignments-1602-1700/fetched/`.
Classify each sub-Q (CORRECT / MISTRANSLATION-FRANKENSTEIN / UNSUPPORTED / PARTIAL), compute
unsupported-claim rate, translation-fidelity errors, figure orphans, over-kill, live-URL; write
`grading/native-grading.md`; fill the **native column** in `scorecard.md`.

### Orchestrator-verified ground truth (anchor the grader; from `nationaalarchief-banda.html`)
- Casualties: *"35 gewonden en 9 doden, waaronder kapitein De Ros met zijn vaandeldrager"* →
  9 dead / 35 wounded / Capt. **De Ros** + standard-bearer. (Beware fabricated officers, e.g.
  v2 invented "Captain Vogel".)
- The 1,200: *"omtrent 1200 zielen gekregen (red.: zijn circa 1200 man overleden)"* → literal
  "obtained ~1,200 souls" (taken); "died" is an editorial gloss. Do NOT hard-fail either reading —
  v1/v2 were both scored neutral on Q2b.

## Step 3 — finalize
Write the 3-column verdict into `scorecard.md`, append a `## Worker Result` to the bake-off detail
file `docs/rpm/future/2026-05-31-dr-v1-v2-native-bakeoff.md`, mark that backlog item DONE, and
update `status.md` / today's `past/` log. The primary v1-vs-v2 finding (hardening showed no Dutch-
fidelity gain + one false-confidence regression on Sub-Q2a) is already written in `scorecard.md`.
