# Anthropic Managed Agents — should the rpm deep-research skill migrate?

**Date:** 2026-04-28
**Decision:** **No migration.** Stay on Claude Code Agent tool. Selectively borrow 1–2 ideas.
**Status:** scoped (no implementation work).

---

## What Managed Agents is

Anthropic launched **Claude Managed Agents** in public beta on **Apr 8, 2026**. It separates agent logic from runtime concerns (orchestration, sandboxing, state, credentials) via a meta-harness, supports long-running multi-step workflows with external tools, error recovery, and session continuity.

Sources:
- https://www.anthropic.com/engineering/managed-agents
- https://www.infoq.com/news/2026/04/anthropic-managed-agents/
- gaps/03-anthropic-claude-research-2026.md (this project)

## Why migration doesn't fit rpm

1. **Wrong runtime target.** The rpm plugin's deep-research skill is a Claude Code skill. Users invoke `/deep-research` inside Claude Code, where the harness already provides Agent-tool spawning, file I/O, hook lifecycle, and session continuity tied to the user's terminal session. Managed Agents is a separate, Anthropic-hosted runtime billed independently — it doesn't run *inside* Claude Code, it runs *alongside* it.
2. **No durability gap to fill.** A typical full deep-research run is 5–15 min wall-clock and well within a single Claude Code session's working window. We already write artifacts to disk on every phase, so resumption-after-crash works without a managed runtime.
3. **rpm's value prop is local-first.** Research artifacts live under `research/<slug>/` in the user's project repo. They're meant to be readable, grep-able, committable, and reviewable. A managed runtime that holds state server-side conflicts with that.
4. **Universal SKILL.md format works elsewhere.** The skill is also published to opencode and (planned) Codex CLI. Tying the protocol to a Claude-only managed runtime would break that portability story.

## What's worth borrowing

- **Long-running workflow checkpointing.** rpm already does this via `progress.md` rebuilt-on-resume. The Managed Agents pattern formalizes it; nothing to change here.
- **Error recovery / retry logic.** Managed Agents bakes this in. We have a partial version in Phase 3 (single retry on curl failure, swap to next URL on exhaustion). Could harden — e.g., exponential backoff for HTTP 429, stronger fallback when a whole batch fails. Worth filing as a small backlog item if observed in practice.

## What we will NOT do

- Don't make the skill depend on Managed Agents.
- Don't expose a "use Managed Agents" toggle. It would split the skill's behavior between two runtimes for no user-facing benefit.
- Don't rewrite progress.md tracking to mimic the meta-harness state model. The plain-markdown rebuild-on-resume approach is fine.

## Revisit conditions

Migrate (or partially adopt) only if all three become true:
1. Anthropic publishes Managed Agents primitives that are reachable from a Claude Code skill (i.e., a skill can launch a Managed Agent runtime job and Read its outputs).
2. A typical deep-research run begins to exceed Claude Code's working session window (e.g., the protocol grows beyond ~15 min wall-clock).
3. Users are running rpm primarily on Claude desktop/web rather than Claude Code, and lose continuity in those harnesses.

None of these hold today.
