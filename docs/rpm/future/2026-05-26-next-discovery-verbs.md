# `/next` discovery: trigger on "next?" / "next..."

## Gap
The `/next` skill description doesn't claim the terse forms users actually
type — `next?`, `next.`, `next ...` — so the model handles them inline
(picking from SessionStart preview) instead of running the orchestrator.

## Evidence
- reddit-reports Claude:
  - `reddit1.jsonl:9`: user typed `next?` — assistant replied inline ("Top
    of the backlog has two R6 items...") instead of invoking the skill.
  - `reddit2.jsonl:9, 18, 217`: three more `next` / `next?` user prompts,
    none triggered the skill.

This duplicates the issue that commit `c99ca4b` ("codex: use directive
wording for next") addressed on the Codex side — Claude side has the same
problem with terser forms.

## Platform
**Both** (Codex got partial fix in c99ca4b; CC and the terse-`?` form on
both still leak).

## Proposed fix
Update `plugin/skills/next/SKILL.md` description to include:
- "next?" / "next" / "what's next" as trigger phrases
- "next task" / "do next" as alternate triggers
- Make the description claim "use whenever the user asks for the next
  thing to work on or pings with bare 'next' / 'next?'"

## Validation
- Test prompts: `next?`, `next`, `what's next`, `next task` should each
  trigger `/next` skill (verify via skill activation in fresh sessions).
- Reduce inline-next-handling rate in next month of sampling.

## Worker Result

**Status:** needs-review (resolved inline by orchestrator)

**Summary:** Tightened `/next` SKILL.md description on both runtimes
with a `TRIGGER on terse forward-motion prompts — phrasings like
"next", "next?", "next.", "next task", "what's next", "do next", "go
next", "keep going", "continue" (when the prior turn was rpm work) all
qualify and must route through this skill instead of being answered
inline from the SessionStart preview.` block. Preserved the
runtime-specific wording divergence (`/loop /next` on Claude vs Codex
directives `do rpm:next until blocked`) from commit c99ca4b.

**Files changed:**
- `plugin/skills/next/SKILL.md` — added TRIGGER block + directive that
  bare-`next` prompts must route through the skill.
- `codex/.codex/skills/next/SKILL.md` — same TRIGGER block; runtime
  wording deliberately kept divergent.

**Verification:**
- `bash plugin/tests/run.sh` → 136/136 green.
- Manual inspection: both descriptions now lead the natural-language
  trigger phrases before "Use when..." like `/deep-research` does.

**Remaining risks:**
- Effectiveness is observational. Real-session sampling required to
  confirm the inline-next-handling rate drops; the four reddit-reports
  cases cited (reddit1.jsonl:9, reddit2.jsonl:9/18/217) are the
  baseline to compare against after this ships.
