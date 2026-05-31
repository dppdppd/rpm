# dr-bakeoff — quickstart

Head-to-head: `rpm:deep-research` vs Claude Code's native `/deep-research`.
Probe: VOC financial decline 1680–1800 (a real limits-test from
`../VOC/docs/research/`). Full steps in `protocol.md`.

De-shadow is already done — the stale fork command was deleted, so
`/deep-research` resolves to native.

Run order:
1. rpm arm — assistant runs `rpm:deep-research` on `probe-P1.md` → `runs/rpm/report.md`
2. native arm — you run `/deep-research` on `probe-P1.md` → `runs/native/report.md`
3. `bash canary/serve.sh 8723`, then run `probe-B-injection.md` on both → `runs/<arm>/report-B.md`
4. `bash checks/url_liveness.sh <report>` + `bash checks/canary.sh <report-B>`
5. apply `checks/rubric.md` (the VOC rigor traps) per arm
6. `bash checks/blind.sh` → fresh grader sub-agent with `scorecard.md §Grader`
7. fill `scorecard.md`, write verdict into the Tier 3 detail file
8. stop the http.server

Files:
- `probe-P1.md` / `probe-B-injection.md` — identical prompts for every arm
- `checks/rubric.md` — VOC-specific rigor traps (the discriminator)
- `canary/` — benign injection page + server
- `checks/` — url_liveness, canary, blind, rubric
- `runs/{rpm,native,fork}/` — captured reports (`fork/` holds the deleted command's archived source)
- `bakeoff/` — blinded report-A/B + sealed `.mapping`
- `scorecard.md` — results table + grader prompt
