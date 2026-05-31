# Tier 2 — "respect this cap even under ultracode" guardrails

Source: 2026-05-30 rpm-vs-ultracode-mode evaluation.

## Context
Ultracode's default is "more agents, token cost no object," and
auto-orchestration decides per task whether to fan out. That directly
threatens rpm's two **evidence-based caps**:

- `/next`: **one worker at a time**. 2026-05-04 audit found saturating to
  4 gave an 8.4% hit rate (107 dispatches → 9 shipped fixes) from
  daemon-queue contention + non-FF push conflicts.
- `deep-research`: **max 4 concurrent** and **"write the report once —
  revision causes 16–27% regression."**

Without explicit guardrails, an ultracode session may "optimize" past
these hard-won limits.

## Action steps
1. `plugin/skills/next/SKILL.md` — at the "Concurrency — one worker at a
   time" section, add one line: this single-worker rule is a deliberate
   override of ultracode/auto-orchestration; do NOT fan out workers even
   when ultracode is on.
2. `plugin/skills/deep-research/SKILL.md` — near Design Principles 2 (max 4)
   and 7 (write once), add: these caps are evidence-based and override
   ultracode's "maximize" default; do not raise concurrency or re-revise
   the report under ultracode.

## Constraints
- Prose-only, two short insertions. Preserve existing wording/evidence.

## Verification
- Re-read both sections for coherence.
- `bash plugin/tests/run.sh`

## Related
- `plugin/skills/next/SKILL.md`, `plugin/skills/deep-research/SKILL.md`

Estimate: ~15 min.
