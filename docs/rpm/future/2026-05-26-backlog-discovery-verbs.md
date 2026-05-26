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
