# Tier 1 — Make the "Delegate aggressively" directive ultracode/Workflow-aware

Source: 2026-05-30 rpm-vs-ultracode-mode evaluation.

## Context
Ultracode (`/effort ultracode`, shipped ~2026-05-27 with Opus 4.8) pairs
`xhigh` reasoning with automatic Workflow orchestration — Claude decides
per task whether to spawn a `Workflow`. rpm's "Delegate aggressively"
directive in `plugin/hooks/_directives.sh` predates the `Workflow`
primitive and only knows about `run_in_background: true` single-subagent
dispatch.

Official "who holds the plan" frame:
- **subagent** — Claude holds the plan, agent does one slice, returns terse report
- **skill** — Claude holds the plan, prose guides
- **workflow** — the *script* holds the plan; codified, rerunnable, scales agents

## Goal
Teach the consuming project's main session the three-tier model and when
to reach for a codified Workflow vs a one-off subagent.

## Action steps
1. Edit the "Delegate aggressively" paragraph in `plugin/hooks/_directives.sh`.
2. Name the three tiers by "who holds the plan."
3. Add: when ultracode/Workflow is available, prefer a codified Workflow +
   adversarial verification for *structured, rerunnable* multi-agent work;
   single `Agent` dispatch stays correct for one-off token-heavy slices.
4. Keep lifecycle bookkeeping (session-end, hooks, backlog) lean —
   ultracode exempts conversational/mechanical turns.
5. Phrase Workflow use as "when available" — it is CC-only, research-preview,
   version-gated (CC ≥ v2.1.154), paid, and disableable
   (`CLAUDE_CODE_DISABLE_WORKFLOWS=1`). Must degrade gracefully on
   opencode/codex.

## Constraints
- Portable prose only. Do NOT make rpm depend on `Workflow`.
- ~10–15 lines added to the existing directive.

## Verification
- `shellcheck plugin/hooks/_directives.sh`
- Confirm session-start still emits cleanly (directive flows through the
  heredoc in `session-start-auto.sh`).
- `bash plugin/tests/run.sh`

## Related
- `plugin/hooks/_directives.sh`, `plugin/hooks/session-start-auto.sh`

Estimate: ~20 min.
