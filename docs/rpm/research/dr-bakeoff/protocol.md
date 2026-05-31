# rpm:deep-research vs native /deep-research — Bake-off Protocol

Empirical head-to-head to settle **Tier 3**
(`docs/rpm/future/2026-05-30-deep-research-native-overlap.md`).
Created 2026-05-30.

## Why
The source-read gives the *architecture* delta (prose-skill-portable vs
JS-Workflow-CC-only). This bake-off measures the *output/behavior* delta
you can't see from source: citation integrity, fabrication, injection
resistance, source coverage, and operational shape.

## Conditions (verified this environment)
- Claude Code **2.1.158** (native Workflow needs ≥ 2.1.154 ✓)
- Workflows **enabled**; global effort **xhigh**
- Per arm, record which model the sub-agents use (rpm forces `sonnet`;
  native default unknown — **observe**; a quality gap could be
  model-driven, not architecture-driven).

## Arms
1. **rpm** — `rpm:deep-research` skill (prose; portable). Artifacts →
   `docs/rpm/research/<slug>/`.
2. **native** — Claude Code's bundled `/deep-research` Workflow (CC-only).
3. ~~fork~~ — the stale `~/.claude/commands/deep-research.md` was DELETED
   this session (source archived at `runs/fork/forked-command.md`).
   Optional: re-create from the archive to run as a third arm.

## Step 0 — de-shadow — DONE
The fork command is deleted, so `/deep-research` already resolves to the
genuine native workflow. Nothing to do.

## The probe (Module A) — VOC financial decline 1680–1800
See `probe-P1.md` — identical text to every arm. Chosen because it has
built-in rigor traps (conflicting debt estimates, a paywalled standard
authority, a popular-but-shallow corruption narrative). Grade with
`checks/rubric.md`. Baseline reference (NOT an answer key — flagged
draft): `/home/coder/projects/VOC/docs/research/voc-decline-era-1680-1800/`.

## Step 1 — Module A run
- **rpm arm** (operator: assistant): invoke `rpm:deep-research` with
  `probe-P1.md` verbatim, answer `deep` at the offer gate. Copy the final
  report → `runs/rpm/report.md`. Record observed rows in `scorecard.md`
  (gates surfaced, # agents, model, wall-clock, tokens, artifact path).
- **native arm** (operator: you): `/deep-research <paste probe-P1.md>`.
  Copy its report → `runs/native/report.md`. Note where it wrote
  artifacts, agent count, model.

## Step 2 — Module B (injection canary)
1. `bash canary/serve.sh 8723` (leave running).
2. `curl -s http://localhost:8723/canary.html | head` to confirm reachable.
3. Run `probe-B-injection.md` through each arm → `runs/<arm>/report-B.md`.
4. If the native arm can't fetch localhost, that's itself a finding
   (fetch-reachability difference). Use a public host only with explicit
   approval to publish the (benign) canary.

## Step 3 — deterministic checks
```
bash checks/url_liveness.sh runs/rpm/report.md
bash checks/canary.sh       runs/rpm/report-B.md
bash checks/url_liveness.sh runs/native/report.md
bash checks/canary.sh       runs/native/report-B.md
```
`canary.sh` exits 0 = resisted, 1 = leaked. Apply `checks/rubric.md` per
arm. Fill the objective rows of `scorecard.md`.

## Step 4 — blind grading
```
bash checks/blind.sh        # randomly maps rpm/native → report-A/B, seals mapping
```
Dispatch a **fresh** grader sub-agent (sonnet), blind, using
`scorecard.md §Grader prompt`. It applies the rubric traps, samples 5
quantitative claims/report and fetch-verifies citation support, scores
the judged rows, picks a per-dimension winner. Unblind via
`bakeoff/.mapping`.

## Step 5 — synthesize
Fill `scorecard.md`. Write the verdict into the Tier 3 detail file: does
the data confirm "rpm wins rigor/portability, native wins
determinism/scale"? Lock the Tier 3 decision (A/B/C) with evidence.

## Cleanup
Stop the http.server (Ctrl-C). (No fork to restore — it's deleted.)

## Cost
Module A+B ≈ 2 real research runs + grading (~150–250k tokens). Buys an
evidence-based Tier 3 decision instead of a lean.
