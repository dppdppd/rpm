# Codex SessionStart strategy: stdout is invisible

## Gap
Codex doesn't capture SessionStart hook **stdout** into the conversation
context — only **stderr** surfaces (as a brief banner). The rpm
`session-start-auto.sh` emits 5–15KB of context block (rpm header, git
state, status.md, tasks.org, backlog menu, drift, instructions) and 0% of
it reaches the Codex agent.

Combined with Codex's structural lack of SessionEnd/PreCompact/PostCompact/
TaskCreated hooks, this means **most of rpm's session-context discipline is
absent in Codex**. Agents read only AGENTS.md plus skill descriptions.

## Evidence
- 0/63 sampled Codex sessions have the `rpm: session active` banner
  visible in conversation.
- 47 occurrences of `version=unknown` because `${CLAUDE_PLUGIN_ROOT}` is
  unset — the env-var chain works for hooks.json execution but not for
  scan.sh's lookups (see related: scan-version-and-excludes).
- 118 `compacted` events in 63 sessions, 0 rpm response.
- Marker `task: (unassigned)` stuck for 27 days in volta — Codex sessions
  read AGENTS.md but never the marker, so the stale state survives.

## Platform
**Codex-only — structural**.

## Proposed fix — DECISION NEEDED
This needs a design call before implementation. Options:

**(A) Accept and rely on AGENTS.md**:
- Move the dynamic context (top backlog, marker task, drift count) into a
  block that AGENTS.md transcludes via `# include: docs/rpm/...`.
- Pro: no upstream Codex change needed.
- Con: AGENTS.md re-reads every turn, so static-only; dynamic git diff /
  recent commits become harder to surface.

**(B) Port to a Codex-friendly mechanism**:
- `session-start-auto.sh` writes a transient `docs/rpm/~rpm-context.md`
  file before exit; AGENTS.md `# include`s it; auto-cleaned at session-end.
- Pro: dynamic, no upstream change.
- Con: writes to filesystem per session-start (~0.1s overhead).

**(C) Push upstream to Codex**:
- File issue against Codex to capture SessionStart stdout the way Claude
  does.
- Pro: parity restored.
- Con: out-of-band timeline; can't predict acceptance.

Recommend **(B)** as default — it's runtime-neutral, doesn't require
upstream cooperation, and matches Codex's existing AGENTS.md pattern.

## Decision (2026-05-26)

**Chosen: (B) Transient `~rpm-context.md` + AGENTS.md include.**

Implementation surface when a worker picks this up:
- `codex/.codex/hooks/session-start-auto.sh` (and plugin/ mirror) writes
  `docs/rpm/~rpm-context.md` with the same content currently emitted to
  stdout (rpm header, git state, status.md, tasks.org, backlog menu,
  drift, instructions).
- `init-rpm` SKILL.md emits an `AGENTS.md` template that includes
  `# include: docs/rpm/~rpm-context.md` at the top.
- session-end (and a Stop hook fallback) deletes `~rpm-context.md` so
  it doesn't propagate stale state into the next run.
- Add to `.gitignore`: `docs/rpm/~rpm-context.md` (it's transient).
- bats test: invoke session-start-auto.sh in fixture, assert the
  context file gets written; invoke session-end, assert it's removed.

## Validation
- After implementation, sampled Codex sessions should show the rpm header
  + backlog snapshot in early agent context.
- `task: (unassigned)` propagation count drops in next month of mining.

## Worker Result

### Summary
Implemented option B end-to-end. The SessionStart hook now mirrors all
stdout that reaches the model into `docs/rpm/~rpm-context.md` via a
`tee` + EXIT-trap pattern. AGENTS.md gets a top-of-file
`# include: docs/rpm/~rpm-context.md` directive from `/init-rpm` so the
content reaches Codex agents. The file is cleaned up by `/session-end`'s
handoff block, the `session-end.sh` Stop hook (Claude unclean-exit
path), and a defensive cleanup in `stop-learn-capture.sh` (the only
Stop-like signal Codex exposes, gated on `~rpm-session-end` so it only
fires after `/session-end` has already run).

### Files changed
- `plugin/hooks/session-start-auto.sh` (+22 lines, mirror setup + trap)
- `codex/.codex/hooks/session-start-auto.sh` (byte-identical mirror)
- `plugin/hooks/stop-learn-capture.sh` (+13 lines defensive cleanup, gated)
- `codex/.codex/hooks/stop-learn-capture.sh` (byte-identical mirror)
- `plugin/hooks/session-end.sh` (+5 lines defensive cleanup, Claude-only)
- `plugin/hooks/handoff-validator.sh` (added `~rpm-context.md` to the
  list of session-state files that should be cleared post-handoff)
- `codex/.codex/hooks/handoff-validator.sh` (mirror)
- `plugin/skills/session-end/SKILL.md` (extended Handoff Cleanup `rm`
  list to include `~rpm-context.md`)
- `codex/.codex/skills/session-end/SKILL.md` (mirror)
- `plugin/skills/init-rpm/SKILL.md` (added `# include:` line to the
  AGENTS.md template plus migration guidance for existing projects)
- `codex/.codex/skills/init-rpm/SKILL.md` (mirror)
- `.gitignore` (added `docs/rpm/~rpm-context.md`)
- `plugin/tests/session-start.bats` (+5 tests: mirror content, resume
  path, no-init guard, compact source skipped, overwrite vs append)
- `plugin/tests/stop-learn-capture.bats` (+3 tests: defensive cleanup
  fires post-handoff, preserves during normal conversation, no-op
  when file absent)
- `plugin/tests/session-end-hook.bats` (+3 tests: removes context.md
  alongside daily-log backfill, silent when absent, skipped when
  marker missing)

### Verification
- `bash plugin/tests/run.sh` — 171/171 pass (11 new tests added).
- `shellcheck -x` (run from each hooks directory so `_directives.sh`
  resolves) exits 0 for every modified hook in both `plugin/hooks/`
  and `codex/.codex/hooks/`.
- All three modified hook pairs (`session-start-auto.sh`,
  `stop-learn-capture.sh`, `handoff-validator.sh`) are byte-identical
  between `plugin/` and `codex/.codex/` — verified via `diff`.
- Performance: measured 10 runs of the hook over a minimal sandbox
  (`time` aggregate). Pre-change avg 0.181s, post-change avg 0.185s —
  ~4ms (~2%) overhead, well under the predicted ~100ms ceiling. The
  `tee` + `wait` round trip is cheap because all stdout fits in a
  single ~5KB buffer.

### Implementation notes
- The mirror uses `exec 3>&1; exec > >(tee "$tmp" >&3); TEE_PID=$!`
  with an EXIT trap that closes fd 1, waits on the tee subprocess
  (so all bytes are flushed), and atomically `mv`s the tmp file into
  `~rpm-context.md`. Empty tmp files (e.g. resume path that bailed
  early) are discarded.
- The mirror sits AFTER the no-init and `source=compact` early exits,
  so it never tries to write into a non-existent `docs/rpm/` directory
  and doesn't create a file on a compaction event.
- Stale fallback for `# include:`: the task brief asked specifically
  for the defensive cleanup to live in `stop-learn-capture.sh`. Naive
  removal there would delete the context file every assistant turn,
  which would defeat the include feature. The cleanup is therefore
  gated on `~rpm-session-end` (only present after `/session-end`'s
  handoff write), giving a true safety net without breaking the
  in-conversation include path.
- `init-rpm` SKILL.md flags the migration explicitly: pre-existing
  rpm-initialized Codex projects whose AGENTS.md predates this change
  will not pick up the include automatically. Users need to add the
  `# include: docs/rpm/~rpm-context.md` line at the top of their
  existing AGENTS.md manually for the feature to activate. The
  augmentation guidance in init-rpm's "Agent instructions file"
  section calls this out.

### Remaining risks
- ~0.1s overhead claim: measured at ~4ms in this codebase. Could rise
  on slower filesystems (NFS, network mounts) or very large `tasks.org`
  / status snippets, but still well under the 100ms target.
- AGENTS.md `# include:` semantics are project convention, not a
  documented Codex preprocessor directive. The line works because the
  LLM reading AGENTS.md sees it and is instructed (by the rpm context
  block itself, when included) to honor it; if a Codex update later
  introduces an actual preprocessor with different syntax, the
  template may need updating. Worst case: the line sits as inert text
  and the model still has `docs/rpm/~rpm-context.md` listed as a path
  in AGENTS.md, so it can read it on demand.
- The Stop-hook defensive cleanup fires only after `~rpm-session-end`
  exists. If a user kills Codex without `/session-end` (e.g. SIGKILL),
  the context file persists until the next SessionStart overwrites it.
  This is not a true "leak" — the file is bounded by SessionStart
  rewrites and `.gitignore` keeps it out of version control — but it's
  worth noting that the safety net is not a hard guarantee.
- Migration step required for pre-existing rpm-initialized Codex
  projects: users must manually add `# include: docs/rpm/~rpm-context.md`
  at the top of their AGENTS.md. Without this line, the file we write
  is invisible. `/init-rpm`'s repeat-run verification mode does not
  currently auto-patch existing AGENTS.md (the skill avoids
  destructive edits to user-authored agent guidance); a follow-up
  could add an opt-in offer.
