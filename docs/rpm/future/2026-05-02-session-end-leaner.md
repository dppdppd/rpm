# Make session-end leaner

## Why
Long session-end ceremony discourages small sessions. We want
the opposite — short focused sessions should have a near-trivial
wrap-up so users aren't psychologically taxed for ending early.

## Problem
Current `plugin/skills/session-end/SKILL.md` is 530 lines and four
phases. Fast-path exists but only fires when:
- git status empty after tracker commit
- no drift findings
- no learnings worth promoting
- no in_progress/pending natives
- no Phase 3b mismatch signal

In practice most sessions have *some* uncommitted changes (that's
the point of a working session), so the bar is rarely cleared and
the user gets the full 4-phase ceremony even for trivial wrap-ups.

## Direction
Make the default path lean. Escalate to phases ONLY when there's
genuine multi-decision complexity. Concretely:

- Single-commit sessions (one logical change, no drift, no
  learnings, no native dedup) → one message: tracker writes +
  draft commit + handoff.
- Sessions with one or two surfaces (e.g. just a learnings menu,
  or just a drift fix) → inline those, skip phase headers, no
  ceremony.
- Only escalate to numbered Phase headers when there are
  genuinely 3+ interactive decision points OR a mismatch
  reconciliation that needs the user.

## Acceptance signals
- Skill body shrinks substantially (target: under ~250 lines).
- Most real sessions wrap up in 1–2 messages, not 4.
- Phase ceremony only triggers when warranted.
