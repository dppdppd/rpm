# `/backlog` discovery: claim natural-language verbs

## Gap
The `/backlog` skill is bypassed at >99% across all runtimes and projects.
Users say "backlog X" / "add to backlog" / "backlog the following" and the
assistant edits `tasks.org` directly instead of invoking the skill.

## Evidence
- Claude transcripts:
  - rpm/VOC/draftyard (round 1): **75 direct `Edit(tasks.org)` vs 1
    `/backlog` skill call**.
  - volta (round 2): **447 direct edits vs 2 skill calls**.
  - reddit/tray/dock (round 3): 0 `/backlog` calls across 8 sessions.
- Codex: **103 raw "backlog ..." prompts in `~/.codex/history.jsonl`** —
  none routed through the skill.
- VOC Codex May 17-18 session: 33 `apply_patch` edits to tasks.org, 0
  backlog skill invocations.

## Platform
**Both**.

## Proposed fix
Two paths, not mutually exclusive:

1. **Tighten SKILL.md description**: the current line says "Manage the rpm
   backlog…". Add explicit trigger keywords: "backlog X", "add to backlog",
   "backlog the following", "postpone", "done X". Mirror the description
   shape that `/next` uses for its terse-verb claim.

2. **UserPromptSubmit hook** that detects literal `backlog ` prefix and
   re-emits an instruction to the model: "Route this through /backlog
   skill, not direct tasks.org edit." (Lower-effort but more invasive.)

If neither works, deprecate `/backlog` and document that natural-language
edits are the supported path.

## Validation
- Spawn 10 test prompts of the natural form ("backlog the duplicate
  cache install issue") and assert `/backlog` skill triggers.
- Reduce direct-edit-to-skill-invocation ratio to ≤ 5:1 in next month of
  sampling.

## Worker Result

**Status:** needs-review (resolved inline by orchestrator)

**Summary:** Implemented Proposed-fix path 1 — tightened the SKILL.md
`description:` line to lead with an explicit `TRIGGER on
natural-language backlog operations — phrasings like ...` block listing
the discoverable verbs (`backlog X`, `add to backlog`, `backlog the
following`, `what's on the backlog`, `show/list backlog`, `review
backlog`, `postpone N`, `done N`, `mark N done`, `defer X`) plus the
directive that these "must route through this skill instead of editing
tasks.org directly." Mirrors the `TRIGGER whenever the user asks for…`
shape that `/deep-research`'s description uses successfully.

Path 2 (UserPromptSubmit hook) deliberately deferred — more invasive,
not necessary if path 1 raises the trigger rate. Re-sample after the
release and reopen if the direct-edit-to-skill ratio doesn't move.

**Files changed:**
- `plugin/skills/backlog/SKILL.md` — description-line rewrite.
- `codex/.codex/skills/backlog/SKILL.md` — identical description line
  (parity verified by grep diff).

**Verification:**
- `diff <(grep ^description: plugin/.../SKILL.md) <(grep ^description:
  codex/.../SKILL.md)` → empty (lines identical).
- `bash plugin/tests/run.sh` → 136/136 green (description-only change,
  no behavior surface).

**Remaining risks:**
- Effectiveness is observational, not testable in-repo. Validation
  step "Spawn 10 test prompts → assert skill triggers" still pending —
  the only way to confirm path 1 worked is to sample real Claude/Codex
  sessions across a release cycle and compare the direct-edit-to-skill
  ratio to the baseline cited above. If it doesn't move, reopen and
  implement the UserPromptSubmit hook (path 2).
