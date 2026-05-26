# `/init-rpm`: auto-patch existing AGENTS.md with `# include` line

## Gap
The 2026-05-26 codex-sessionstart-strategy fix added a
`# include: docs/rpm/~rpm-context.md` line to the AGENTS.md template
emitted by `/init-rpm` for FRESH bootstraps. But for projects already
initialized with rpm before that change (most existing Codex deployments),
AGENTS.md was authored without the `# include:` line — the context file
that session-start-auto.sh now writes is invisible to the LLM unless
the user manually edits AGENTS.md.

`/init-rpm` has a repeat-run verification mode that re-checks the rpm
scaffolding, but it deliberately avoids destructive edits to
user-authored agent guidance (CLAUDE.md / AGENTS.md). Adding the include
line is non-destructive — but the user hasn't opted in.

## Evidence
- Documented in the codex-sessionstart-strategy detail file's "Remaining
  risks" section by the worker that implemented option B.
- Implicit: every Codex project currently running rpm < `<release that
  ships this fix>` will pick up the new hook write but won't see the
  content because their AGENTS.md predates the template change.

## Platform
**Codex-only effective issue** — the `# include:` line is convention,
not a Codex preprocessor directive; the LLM reading AGENTS.md needs to
see the line to load the file. Claude already gets the context via
stdout, so its AGENTS.md doesn't need the line.

## Proposed fix
Extend `/init-rpm`'s repeat-run verification mode with an opt-in offer:

1. Detect: AGENTS.md exists AND `docs/rpm/` exists (project IS
   rpm-initialized) AND `AGENTS.md` does NOT contain
   `^# include: docs/rpm/~rpm-context.md` near the top.
2. Surface a one-line offer: "AGENTS.md missing rpm context include —
   add it? [y/N]" (or run silently with `--patch-agents-md` flag for
   automation).
3. On accept: prepend the line at the top of AGENTS.md (after any
   existing frontmatter / title block, before the first non-trivial
   content). Preserve existing AGENTS.md content verbatim otherwise.
4. On decline: skip silently this run; offer again on next repeat-run.

Mirror the same offer in the Codex copy of init-rpm SKILL.md.

## Validation
- bats fixture: AGENTS.md missing the line + `docs/rpm/` present →
  assert the offer surfaces (simulate "y" → assert line is prepended;
  simulate "N" → assert AGENTS.md unchanged).
- bats fixture: AGENTS.md already has the line → assert no offer.
- bats fixture: no AGENTS.md → assert the existing fresh-bootstrap path
  fires (template includes the line by default).

## Worker Result

Resolved together with `init-rpm-gitignore-wildcard` as a single
repair-mode addition (one shared `repair.sh` helper covers both gaps).

### Summary
- Added `plugin/skills/init-rpm/scripts/repair.sh` — an idempotent
  shell helper that detects and (optionally) fixes the two stale-config
  gaps (`.gitignore` wildcard, `AGENTS.md` include directive).
- Documented invocation + report interpretation in
  `plugin/skills/init-rpm/SKILL.md` under a new
  **Phase 4a: Repair stale configs** section.
- Wired the new phase into the **Repeat-run verification mode** step
  list (now step 4 of 8) so existing rpm projects pick up the
  migrations on the next `/init-rpm` re-run.
- Mirrored both the helper script and the SKILL.md changes into
  `codex/.codex/skills/init-rpm/` via `scripts/sync-codex.sh`.

### AGENTS.md behavior
- Helper detects missing `# include: docs/rpm/~rpm-context.md` in the
  first 20 lines of `AGENTS.md`.
- Surfaces a one-line offer (the SKILL body owns the prompt; the
  helper emits `action=offer_prepend` in `--check` / default mode and
  only writes when invoked with `--auto-yes`).
- Preserves all existing content verbatim. If `AGENTS.md` opens with
  YAML frontmatter (`---` ... `---`), the include line is placed
  immediately after the closing `---` with surrounding blank lines.
  Otherwise it's prepended at line 1.
- When `AGENTS.md` is absent, the helper emits `agents_md=absent` and
  surfaces no offer — the fresh-bootstrap path in Phase 4 already
  scaffolds a template that includes the directive.

### Files changed
- `plugin/skills/init-rpm/scripts/repair.sh` (new, shellcheck-clean)
- `plugin/skills/init-rpm/SKILL.md` (new Phase 4a section + step 4
  in Repeat-run verification mode + summary key in step 8)
- `codex/.codex/skills/init-rpm/scripts/repair.sh` (synced)
- `codex/.codex/skills/init-rpm/SKILL.md` (synced — runtime path for
  `repair.sh` rewritten to the Codex marketplace path by
  `translate-skill-codex.py`)
- `plugin/tests/init-rpm-repair.bats` (new — 12 cases covering both
  gaps + the scope flags + `--check` read-only mode)

### Verification
- `bash plugin/tests/run.sh` — 187/187 green (includes the 12 new
  `init-rpm-repair` cases plus the previous 175).
- `shellcheck plugin/skills/init-rpm/scripts/repair.sh
  codex/.codex/skills/init-rpm/scripts/repair.sh` — clean.
- Manual sanity check: `RPM_PROJECT_DIR=$(pwd) bash
  plugin/skills/init-rpm/scripts/repair.sh --check` against the rpm
  repo itself correctly reports `wildcard=absent / explicit_count=10
  / agents_md=absent` — the live state the gap brief described.

### Remaining risks
- The repair helper is non-destructive by default but invokes opt-in
  destructive operations (collapse explicit gitignore lines, prepend
  AGENTS.md include) only with `--auto-yes`. A SKILL body running
  this verbatim should always show the offer and wait for user
  confirmation; a worker subagent or non-interactive runtime should
  treat the default as "no" and surface the offers under
  `Needs attention` in the verification summary.
- The include line is convention, not a Codex preprocessor
  directive — Codex still loads it via the include mechanism in
  AGENTS.md. If Codex changes its include semantics, the helper's
  search pattern would need to be revisited.
