# `/init-rpm`: write `docs/rpm/~rpm-*` wildcard to .gitignore

## Gap
rpm scatters transient session-state files under `docs/rpm/` with a
`~rpm-` prefix (`~rpm-session-start`, `~rpm-session-end`,
`~rpm-orchestrator-log.jsonl`, `~rpm-context.md`, `~rpm-learnings.jsonl`,
`~rpm-native-tasks.jsonl`, `~rpm-task-candidates.jsonl`,
`~rpm-last-session`, `~rpm-last-validated-commit`,
`~rpm-compact-state`). None of these should be checked in — they're
per-session ephemera that change every turn.

But `/init-rpm` doesn't touch `.gitignore`. The pattern this session
saw (and the codebase's existing pattern): every time a new transient
file is added, someone has to remember to add a matching explicit
`.gitignore` line. The repo's current `.gitignore` shows the
accumulated debt — 10 explicit entries, all matching the same shape.
The codex-sessionstart-strategy worker just added the 10th today.

## Evidence
```
$ grep -E 'rpm' .gitignore
docs/rpm/~rpm-session-start
docs/rpm/~rpm-session-end
docs/rpm/~rpm-compact-state
docs/rpm/~rpm-context.md
docs/rpm/~rpm-learnings.jsonl
docs/rpm/~rpm-native-tasks.jsonl
docs/rpm/~rpm-last-session
docs/rpm/~rpm-last-validated-commit
docs/rpm/~rpm-task-candidates.jsonl
docs/rpm/~rpm-orchestrator-log.jsonl
```

All 10 collapse to one wildcard.

## Platform
**Both** — `/init-rpm` ships to both runtimes.

## Proposed fix

### Fresh bootstrap
In both `init-rpm/SKILL.md` copies, add a `.gitignore` step:

1. If `.gitignore` does not exist, create it.
2. If it exists, check whether the line
   `docs/rpm/~rpm-*` (or an equivalent pattern that covers all
   transient files) is already present.
3. If absent, append it under a clearly-labeled section, e.g.:
   ```
   # rpm session-state (transient, regenerated every session)
   docs/rpm/~rpm-*
   ```

### Repeat-run verification mode
Already-initialized projects (everyone running rpm before this fix)
have the 10 explicit entries. The repeat-run mode should:

1. Detect: `.gitignore` is missing `docs/rpm/~rpm-*` wildcard.
2. Offer (non-destructive): "Replace the 10 explicit
   docs/rpm/~rpm-* lines with one wildcard? [y/N]" — or split into
   two offers if the user might want both for clarity.
3. On accept: remove the 10 explicit lines (only if exact matches),
   add the wildcard, preserve all other .gitignore content verbatim.

Stretch: same repeat-run mode could also offer to fix the AGENTS.md
`# include:` migration from `init-rpm-agents-md-patch.md`. Both are
"existing project has the new tooling but stale config" gaps.

## Validation
- bats fixture: fresh project (no `.gitignore`); run `/init-rpm`; assert
  `.gitignore` has the wildcard line.
- bats fixture: `.gitignore` exists without the wildcard; run init;
  assert wildcard appended, existing lines preserved.
- bats fixture: `.gitignore` already has the wildcard; run init;
  assert no duplicate written.
- Manual: `git check-ignore` on each `docs/rpm/~rpm-*` path should
  match the wildcard rule.

## Related
- `2026-05-26-init-rpm-agents-md-patch.md` — same shape (existing
  project missing new config); consider implementing both in one pass
  with a unified `init-rpm --repair` or `--verify` mode.

## Worker Result

Resolved together with `init-rpm-agents-md-patch` as a single
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

### .gitignore behavior
- Helper detects whether `docs/rpm/~rpm-*` is present on a line of
  its own.
- If absent, the wildcard (plus a `# rpm session-state ...` comment
  header) is appended to `.gitignore` automatically — this is treated
  as non-destructive: an existing project that just adds the wildcard
  is strictly better off, with no behavior loss.
- If `.gitignore` doesn't exist, the helper creates it with only the
  comment + wildcard line.
- If explicit `docs/rpm/~rpm-<name>` lines exist (the historical
  per-file pattern; the live rpm repo has 10 of them right now), the
  helper emits `action=offer_collapse count=N` and lists the exact
  lines via repeated `explicit_line=<line>` outputs. The SKILL body
  uses those to render a numbered offer to the user. Collapse only
  happens with explicit user consent (`--auto-yes` from the SKILL
  body after the user says `yes`).
- Idempotent: re-running on a fully-repaired project produces no
  diff and emits `wildcard=present / explicit_count=0`.

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
  / agents_md=absent` — the live state this gap brief described.
- bats fixture covers the live-repo shape: a 10-line explicit-entry
  fixture is collapsed to one wildcard with all other `.gitignore`
  content preserved (`init-rpm-repair.bats`, test
  "auto-yes collapses into wildcard").

### Remaining risks
- The repair helper is non-destructive by default but invokes the
  opt-in destructive operation (collapse explicit gitignore lines)
  only with `--auto-yes`. A SKILL body running this verbatim should
  always show the offer and wait for user confirmation.
- The live rpm repo still has the 10 explicit lines; the orchestrator
  will need to run `/init-rpm` against this repo once after this
  ticket lands to actually collapse them.
