# Trim session-end — kill action menu, add fast path

## Description
Two cuts to `/session-end`:

1. **Remove the Phase 1 Actions menu.** Today, Phase 1 ends with
   `## Actions (pick any, multiple OK)` listing Commit / Record /
   Fix drift. Then Phase 2 asks per-section. The outer menu is
   redundant — each Phase 2 sub-section already prompts when its
   surface has content. Kill the outer menu entirely.

2. **Fast-path single-response mode.** When ALL decision surfaces
   are empty (drift empty, record-findings empty, no mismatch, no
   in-progress/pending natives, git clean after auto-apply),
   collapse Phases 1–4 into one compact `## Session end` message
   (Accomplished, Tracker updates, What's next, handoff text).
   No phase headers, same Phase 4 cleanup runs inline.

## Keep
- Full 4-phase flow whenever any surface is non-empty.
- Phase 2 sub-sections fire automatically based on content (already
  partial today; just document it as the explicit default).
- Phase 3 auto-demote sweep + mismatch check (silent by default).

## Files
- `plugin/skills/session-end/SKILL.md` — overview + Phase 1
  user-visible output + action-menu block.

## Tests
Bats coverage is on the hooks, not the skill body (skill is LLM
instructions). Verify manually via a session-end run; CI
shellcheck unaffected.

## Estimate
~20 minutes.
