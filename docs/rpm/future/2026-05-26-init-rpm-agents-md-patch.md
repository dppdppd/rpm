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
