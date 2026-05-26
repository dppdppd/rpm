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
