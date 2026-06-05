# Port the goal-seeking "file the PROOF step" discipline into rpm:next

**Filed:** 2026-06-05 · **Escalated from:** Volta (the fix is already shipped in
Volta's project amendment; this lifts it upstream so every rpm project benefits).

## Summary of the issue

`rpm:next`'s goal-seeking is weak. The orchestrator picks the topmost actionable
goal-aligned task and grinds gaps one by one, but never reasons **backward** from
a parent goal to *"what must be DEMONSTRATED to call this MET, and is that proof
step filed?"*. Result: it closes coded gaps, reports progress, and gets "lost in
the weeds" — it can complete **every** filed gap-task for a goal without ever
verifying (or even filing the verification for) the actual capability.

## Root cause

The only goal-level mechanism is Task-Selection step 4 "Goal-aligned dispatch,"
which (a) scores a candidate task against its parent `Goal:` line, and (b) files a
gap task **only when NO actionable task moves a goal**. So whenever gap-closing
tasks exist, the check passes and the orchestrator grinds them. There is no
requirement that the goal have a **demonstrable** definition-of-done, nor that the
task chain **terminate in a verify/sign-off**. "Close the gaps" is treated as
"achieve the goal" — necessary but not sufficient.

## Real example (Volta, 2026-06-05)

Tier-3 goal = "Volta is a playable game client." The orchestrator closed
playable-UI gaps one at a time (rotation, then turn-advance), reported "buildable
gaps closed," and only filed an end-to-end playability-verification chain **after**
the maintainer asked "are we confident games are playable start-to-finish?". Even
the orchestrator's own metric reconciliation framed `[NOT MET]` as a gap-**list**
("blocked by X, Y, Z") rather than "blocked until we **demonstrate** playability"
— reproducing the weakness in the very edit meant to fix the metric.

## Fix (reference implementation already in Volta's amendment)

Volta added "Step 1.0: Goal-seeking — file the PROOF step, don't just grind gaps"
to its `/next` amendment (`<volta>/docs/rpm/skills/next.md`, commit `db13f854`).
The **generalized** rule (strip Volta-specifics) to move into
`plugin/skills/next/SKILL.md`:

> Before choosing a dispatch toward any parent goal that is NOT MET, confirm:
> 1. the goal's definition-of-done is a **DEMONSTRATION** — a test/artifact that
>    PROVES it met (e.g. "N representative cases pass end-to-end vs reference",
>    "trace 38/38"), not a gap-checklist or a vague description ("launch ready");
> 2. a terminal **VERIFY / SIGN-OFF** task exists whose completion DEMONSTRATES
>    the goal met, with the gap-tasks as its `:BLOCKED_BY:` deps.
>
> If either is missing, **FILING it is the dispatch** — higher leverage than any
> gap-closer (a gap-closer nudges a NOT-MET goal; only the demonstration flips it
> to MET). Decompose backward: demonstrable DoD → verify/sign-off closer →
> the gap-tasks it depends on.

This is stronger than the current "Goal-aligned dispatch" (which only files a gap
task when *no* task moves a goal). Even when goal-moving gap-tasks exist, the
chain must terminate in a demonstrable proof; file that proof if it's absent.

**Backlog-hygiene corollary** (for `rpm:backlog`): every `* Parent` `Goal:`
`Success:` is a demonstrable test, and every `[NOT MET]` clause ends in a
verify/sign-off task — not merely a list of build gaps. A metric reconcile/split
must add the "prove it" terminus in the same edit.

## Proposed plugin changes

1. `plugin/skills/next/SKILL.md` — add the goal-seeking step to Task Selection,
   ahead of / strengthening "Goal-aligned dispatch." Generalized, no Volta
   specifics.
2. `plugin/skills/backlog/SKILL.md` — add the demonstrable-DoD + terminal-sign-off
   hygiene rule to **Review** (flag goals whose `Success:` is a gap-list or
   description), and to **Add** when a parent goal is involved.
3. Mirror to the `codex/` and `opencode/` ports if they carry these skills.

## Acceptance

- `rpm:next` (upstream, in a clean project) files the demonstrable DoD +
  verify/sign-off for a NOT-MET goal whose chain is all build-tasks, **without a
  maintainer prompt**.
- `rpm:backlog review` flags any `* Parent` goal whose `Success:` is a gap-list or
  vague description rather than a demonstrable test.
- Volta's amendment Step 1.0 can then be trimmed to only project-specific notes
  (the general rule lives upstream).

## Done (2026-06-05)

- `plugin/skills/next/SKILL.md` — strengthened Task Selection step 4 into
  "Goal-seeking — file the PROOF step, don't just grind gaps": before
  dispatching toward a NOT-MET goal, demand (1) a demonstrable definition-of-done
  and (2) a terminal verify/sign-off task; if either is missing, filing it IS the
  dispatch (decompose backward), then fall through to the existing goal-aligned
  dispatch. No renumber — Output Format's "step 4" reference stays valid.
- `plugin/skills/backlog/SKILL.md` — added a **Demonstrable goals** check to
  Review (flag any `* Parent` whose `Goal:`/`Success:` is a gap-list/vague
  description, or whose `[NOT MET]` chain has no terminal proof task; reconcile
  must add the "prove it" terminus in the same edit) and the same hygiene to Add
  when a parent goal is created/edited.
- Synced to the codex port via `scripts/sync-codex.sh` (next + backlog). Opencode
  carries only the `rpm` skill, so nothing to mirror there.
- Verified: `bash plugin/tests/run.sh` → 206/206 pass.
- Follow-up (external, not in this repo): trim Volta's amendment Step 1.0 to
  project-specifics now that the general rule lives upstream.
