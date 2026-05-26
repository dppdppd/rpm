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

## Validation
- After implementation, sampled Codex sessions should show the rpm header
  + backlog snapshot in early agent context.
- `task: (unassigned)` propagation count drops in next month of mining.
