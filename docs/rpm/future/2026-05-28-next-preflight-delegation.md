# /next preflight delegation

## Request (2026-05-28)
> rpm next should run as many of its next phases by agents in background
> as possible. we don't need any of that in the context.

## Problem
A direct `/next` turn does its token-heavy preflight inline in the main
orchestrator context:
- **Mechanical drift** runs `scan.sh`, whose raw output is huge (the
  `not_implemented` sample alone dumps ~20 multi-line matches incl. the
  full `status.md` paragraph).
- **Guidance contradictions** dispatches `guidance-aligner` foreground,
  but the agent returns verbose reasoning (~60k tokens observed) into
  the orchestrator context.
- **Worker review** reads detail files + `git diff` inline.

All of this pollutes the main session context with material the
orchestrator only needs in summarized form. Reinforces
[[feedback_aggressive_delegation]].

## Constraint
`/next` is a single orchestrator turn that must decide
dispatch/block/idle from preflight results. True fire-and-forget
background preflight breaks that (orchestrator would idle every turn
waiting). So delegation here means: a subagent does the heavy lifting
and returns a *terse structured report*; raw scan/diff/reasoning output
never enters main context. Foreground-from-orchestrator, but
context-isolated.

## Design options (pending user pick)
- **A — single preflight agent**: one subagent runs scan + mechanical
  fixes + contradiction check + review-ready + pending-result review,
  returns a compact report (drift-fixes applied, contradictions top-3,
  pending reviews + verdicts, candidate next task). Orchestrator acts on
  the report.
- **B — scan/fix only**: delegate just the mechanical-drift scan+fixes
  (the biggest offender); keep contradiction check (already terse via
  cache) and review judgment in the orchestrator.
- **C — per-phase agents**: separate agents for drift, contradictions,
  review; orchestrator fans out and collects summaries.

## Outcome (shipped v2.20.0, 2026-05-29)
Picked **option A** (single foreground-summary preflight agent). New
`plugin/agents/preflight.md` runs scan+fixes, contradiction check, and
worker review, logs its own `drift-fix`/`review-result` entries, and
returns only a compact ~6-field report. `/next` SKILL collapsed
preflight steps 2–4 into one delegated step (step 1 stays inline). Codex
mirror wired via `AGENT_TO_SKILL` (`preflight.md:next`). 7 new bats,
206/206 green, shellcheck clean.

## Touch points
- `plugin/skills/next/SKILL.md` (orchestrator flow + worker contract)
- possibly a new `plugin/agents/*.md` (preflight agent, needs write
  access — `rpm:auditor` is read-only)
- codex mirror via `translate-skill-codex.py` (must stay byte-identical)
- `plugin/tests/` bats coverage
