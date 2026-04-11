# Project: rpm — Relentless Project Manager

Relentless product manager for LLM-assisted development. Tracks
what shipped, what's next, and what's drifting — via hooks,
slash commands, doc auditing, and deep research.

## Layout
- `skills/` — command surface (`rpm`, `bootstrap`, `audit`,
  `session-end`, `tasks`, `deep-research`);
  each is a directory with `SKILL.md` plus optional supporting files
- `agents/` — subagents (currently `auditor.md`, namespaced
  `rpm:auditor`)
- `hooks/` — `hooks.json` + lifecycle scripts
- `.claude-plugin/` — plugin manifest + marketplace.json

## Editing the plugin
- Primary surface is `skills/<name>/SKILL.md`. Frontmatter:
  `name`, `description`, optional `argument-hint`, `allowed-tools`,
  `disable-model-invocation`, `user-invocable`, `context`, etc.
- Bundle deterministic ops as bash scripts under
  `skills/<name>/scripts/` and invoke via `${CLAUDE_SKILL_DIR}`
  (see `skills/session-end/scripts/scan.sh` for the pattern).
- Auto-inject (`!…`) lines must use `bash "…"` wrapping:
  `!bash "${CLAUDE_SKILL_DIR}/scripts/foo.sh"`, not bare
  `!${CLAUDE_SKILL_DIR}/scripts/foo.sh`. The raw form expands
  to an absolute path that won't match `Bash(bash:*)` rules.
- After meaningful changes, bump `version` in
  `.claude-plugin/plugin.json`.
- No build, test, or lint toolchain. Verify changes by re-installing
  the plugin and running the skill in a real Claude Code session.
- Recent commit style: short conventional-ish prefixes (`chore:`,
  `audit:`, `rpm:`). One commit per deliverable.
- To publish to GitHub (pushes only `plugin/` contents):
  `git subtree split --prefix=plugin -b plugin-only && git push origin plugin-only:master --force`

## Workflow
- Plan → edit → verify → commit. No spec ceremony for skill-sized
  changes.
- Keep README, `skills/rpm/SKILL.md`, and individual skill bodies in
  sync when renaming or removing a slash command — they all describe
  the same surface.
- Update `docs/rpm/past/log.md` after audits or noteworthy sessions.
- Session context auto-loads via the SessionStart hook.

## Guardrails
- 3 attempts max to fix an issue, then STOP and report
- Same error twice → change strategy, do not retry blindly
- Ask before: renaming user-facing commands, changing command
  argument shape, restructuring directories, adding new top-level
  scaffolding to what `/bootstrap` generates
- Read command body + referenced subagents/skills end-to-end before
  proposing any rename or regrouping
- **No ADRs.** This project does not use Architecture Decision
  Records — do not propose ADR templates or directories.

## Post-compaction recovery
Read `docs/rpm/~rpm-compact-state` to recover the active task, git
state, and tracker snapshot. The PreCompact hook saves this automatically.