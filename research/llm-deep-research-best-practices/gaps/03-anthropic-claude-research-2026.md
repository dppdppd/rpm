# Gap 3: Anthropic's Own 2026 Architecture (Managed Agents, Skills)

**Question:** What has Anthropic shipped recently for multi-agent research that the rpm deep-research skill should align with?

**Answer (after targeted search 2026-04-26):**

## Managed Agents (Apr 8, 2026)
- Anthropic launched Claude Managed Agents in **public beta on April 8, 2026**.
- Architecture: separates agent logic from runtime concerns (orchestration, sandboxing, state management, credentials).
- Supports long-running multi-step workflows with external tools, error recovery, session continuity via a "meta-harness."
- Source: https://www.anthropic.com/engineering/managed-agents, https://www.infoq.com/news/2026/04/anthropic-managed-agents/

## Multi-agent research lesson confirmed in 2026
- Anthropic's June 2025 lesson holds: lead Opus + parallel Sonnet workers outperformed single Opus by 90.2% on internal research evals.
- **NEW finding**: "Token usage by itself explains 80% of the variance in performance evaluation." This aligns directly with the Stanford April 2026 paper (arXiv:2604.02460) — multi-agent gains are largely a compute story.

## Universal SKILL.md ecosystem
- As of March 2026, Claude Code skills work across **Claude Code, Cursor, Gemini CLI, Codex CLI, Antigravity IDE** with the same SKILL.md format.
- The rpm plugin's deep-research skill therefore has portability value beyond Claude Code.

## Implication for rpm deep-research skill
1. **Architecture is correct**: lead orchestrator + parallel worker subagents is what Anthropic itself uses. Don't change the basic shape.
2. **Token cost is real**: Anthropic's own number is ~15x for multi-agent research. Document this for users.
3. **Migration path**: if Managed Agents stabilizes, the skill could eventually delegate orchestration to that runtime instead of the current prompt-only orchestration. Not urgent.
4. **Portability**: keep the skill's command surface aligned with the universal SKILL.md format so it works in non-Claude-Code harnesses too.

## Sources
- https://www.anthropic.com/engineering/managed-agents
- https://www.anthropic.com/engineering/multi-agent-research-system (June 2025, still canonical)
- https://www.infoq.com/news/2026/04/anthropic-managed-agents/
- https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview
