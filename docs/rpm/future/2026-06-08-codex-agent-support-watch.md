# WATCH — Codex native agent/subagent support

**Filed:** 2026-06-08. **Type:** periodic check (no action until the trigger lands).

**What to check.** Whether the Codex CLI has gained a first-class subagent / agent-dispatch
primitive — a managed "spawn N workers, collect their (ideally structured) results" tool, or a
Workflow-like orchestration. As of `codex-cli 0.137.0` (2026-06-08) there is none: only `codex exec`
(headless one-shot, backgroundable by hand) and `codex mcp-server` (Codex-as-MCP-tool). Re-check on
Codex CLI version bumps / release notes.

**Why it matters.** rpm's `research` skill runs its collapse-proof verification panel as a Claude
Code Workflow (genuinely independent fan-out). On Codex it self-gates to prose because Codex has no
Agent/Workflow tool. When Codex ships real agent dispatch, we can port the fan-out
(search-per-dimension + independent per-lens verify) to Codex and get much closer to the CC path —
without the fragility of a roll-your-own `codex exec` orchestration.

**When it lands — do this.**
1. Confirm the primitive supports parallel workers + collecting their outputs (structured if possible).
2. Add a Codex fan-out path to `research` (mirror `rpm-research.workflow.js`'s
   Scope→Search→Fetch→per-lens-Verify→Synthesize), gated to Codex, alongside the CC Workflow and the
   prose fallback.
3. Re-grade on the VOC probe to confirm the collapse-proof panel works on Codex.

**Interim fallback (only if needed before native support):** `codex exec` workers backgrounded via
Bash + stdout parsing — manual, no schema validation, token-heavy. A spike, not a default.
