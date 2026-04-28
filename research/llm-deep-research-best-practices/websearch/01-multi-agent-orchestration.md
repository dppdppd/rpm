# D1: Multi-Agent Orchestration for LLM Deep Research

**Agent:** D1 (sonnet)
**Completed:** 2026-04-26

---

## 1. KEY FINDINGS

**FINDING 1 — Multi-agent genuinely wins on breadth-first parallelizable research; loses on sequential reasoning**
- Centralized multi-agent: +80.9% on parallelizable (financial reasoning) vs single agent; -39 to -70% on sequential multi-hop reasoning.
- Source: "Towards a Science of Scaling Agent Systems" (arXiv:2512.08296, Google/MIT, Dec 2025 / updated Feb 2026). https://arxiv.org/abs/2512.08296
- **Confidence: H** (260 configurations, 6 benchmarks, 5 architectures, 3 LLM families)

**FINDING 2 — Single-agent matches or outperforms multi-agent on multi-hop reasoning at equalized token budgets**
- Stanford (arXiv:2604.02460, Apr 2026): Data Processing Inequality argument — single agent is maximally information-efficient on a fixed reasoning-token budget. Multi-agent gains on multi-hop benchmarks largely explained by extra compute.
- Multi-agent becomes competitive only when single-agent context utilization degrades (very long contexts) or more compute is allocated.
- Source: https://arxiv.org/abs/2604.02460
- **Confidence: H** (Qwen3, DeepSeek-R1-Distill-Llama, Gemini 2.5)

**FINDING 3 — Parallel tool calling within a single agent (W&D) competes with multi-agent orchestration**
- W&D (arXiv:2602.07359, Salesforce, Feb 2026): on BrowseComp, GPT-5-Medium with W&D (62.2%) outperforms GPT-5-High single-agent (54.9%). Reduces coordination cost, token overhead, wall-clock time.
- Frames itself as alternative to "complex multi-agent orchestration."
- Source: https://arxiv.org/abs/2602.07359
- **Confidence: H** (BrowseComp, HLE, GAIA results)

**FINDING 4 — WideSeek-R1: RL-trained lead+subagent for broad info-seeking**
- WideSeek-R1 (arXiv:2602.04634, Feb 2026): lead agent + parallel subagents trained end-to-end via MARL. WideSeek-R1-4B matches DeepSeek-R1-671B item F1 on WideSearch.
- Performance gains *consistent* as subagent count increases — width scaling works for broad info-seeking, not reasoning-depth.
- Source: https://arxiv.org/abs/2602.04634
- **Confidence: H**

**FINDING 5 — Anthropic's own multi-agent research: lead Opus + worker Sonnet beats single Opus by 90.2%**
- Lead Claude plans and spawns parallel subagents, each given a specific aspect. Multi-agent (Opus 4 + Sonnet 4) outperformed single-agent Opus 4 by 90.2% on internal evals.
- **Key design lesson**: without detailed per-subagent task descriptions (objective, output format, tool/source guidance, task boundaries), agents duplicate or leave gaps.
- **Cost**: ~15x more tokens than standard chat; only justified when outcome value warrants.
- Source: https://www.anthropic.com/engineering/multi-agent-research-system
- **Confidence: H** (primary source, Anthropic engineering blog)

**FINDING 6 — Capability-saturation threshold: multi-agent yields diminishing/negative returns once single-agent baseline > ~45%**
- Coordination benefit has statistically significant negative relationship with single-agent baseline (β=-0.408, p<0.001).
- Source: arXiv:2512.08296
- **Confidence: H**

**FINDING 7 — Productive agent count: gains plateau; coordination overhead dominates beyond ~4–6 in most documented systems**
- Google/MIT scaling paper: saturation threshold; logarithmic plateau with message density.
- Practitioner consensus: 4 agents as practical ceiling for structured orchestration.
- Moonshot Kimi K2.6 (Apr 2026) scales to 300 sub-agents and 4,000 steps — but this is specialized coding/long-horizon work, not breadth research.
- Sources: arXiv:2512.08296; https://www.marktechpost.com/2026/04/20/moonshot-ai-releases-kimi-k2-6-with-long-horizon-coding-agent-swarm-scaling-to-300-sub-agents-and-4000-coordinated-steps/
- **Confidence: M**

**FINDING 8 — Sub-agent (parallel + post-hoc) vs agent-team (serial handoffs): different optimal regimes**
- "Empirical Study of Multi-Agent Collaboration for Automated Research" (arXiv:2603.29632, Mar 2026): subagent parallel mode is "highly resilient, high-throughput search engine optimal for broad, shallow optimization under strict time constraints." Agent-team has higher fragility but deeper alignment given extended budgets.
- The current design (parallel sub-agents + orchestrator-compiles) matches subagent mode → validated for time-constrained broad research.
- Source: https://arxiv.org/abs/2603.29632
- **Confidence: H**

**FINDING 9 — "Bag of agents" anti-pattern: 17.2x error amplification without coordination vs 4.4x with centralized**
- Independent agents amplify errors 17.2x; centralized orchestration containing all sub-agent outputs reduces to 4.4x.
- Current orchestrator-compiles design is the right mitigation.
- Source: arXiv:2512.08296
- **Confidence: H**

**FINDING 10 — Context pollution vs isolation: shared scratchpad tradeoffs**
- Passing only final messages (not internals) reduces token overhead but loses intermediate context. ~2% retention loss per step; below 60% accessible after 5 cycles in shared-context approaches.
- Dominant 2026 pattern: isolated context per sub-agent + structured final-output handoff to orchestrator.
- Source: https://arxiv.org/html/2602.15055v1
- **Confidence: M**

**FINDING 11 — A2A is the emerging cross-framework communication standard**
- Google A2A (Apr 2025, extended 2026); Anthropic Agent SDK (Claude 4.6) includes native A2A support.
- Five protocols: MCP, ACP, A2A, ANP, AG-UI.
- For single-framework (all-Claude) systems, A2A is less critical than for cross-vendor.
- **Confidence: M**

**FINDING 12 — "Rethinking Multi-Agent Workflow" (arXiv:2601.12307, Jan 2026): single-agent matches homogeneous multi-agent via KV cache reuse**
- For homogeneous (same base model) workflows, OneFlow auto-converts multi-agent → single-agent at lower cost.
- Caveat: cannot capture truly heterogeneous workflows (lead Opus + worker Sonnet). Heterogeneous remains advantageous when you want different capability/cost tiers per role.
- Source: https://arxiv.org/abs/2601.12307
- **Confidence: H**

**FINDING 13 — Multi-agent failure rates are high: 41–86.7% across 7 frameworks (MAST)**
- Coordination breakdowns = 36.9% of all multi-agent failures (1,642 traces).
- Causes: chaining without structure, tool bloat (30-50 vs <10 relevant), invisible state, over-coordination.
- Sources: https://atlan.com/know/agent-harness-failures-anti-patterns/; https://towardsdatascience.com/the-multi-agent-trap/
- **Confidence: M**

---

## 2. CONTRADICTIONS AND OPEN QUESTIONS

**Contradiction A — Multi-agent vs intra-agent parallel tool calling**
W&D (2602.07359) argues parallel tool calling within a single agent matches multi-agent breadth at lower overhead. WideSeek-R1 (2602.04634) reaches opposite conclusion: MARL-trained sub-agents with isolated contexts outperform single-agent parallel calls. Difference may hinge on whether you control model weights (WideSeek MARL) vs prompt-engineer fixed model (W&D GPT-5). For Claude Code users (no retraining), W&D may be more actionable.

**Contradiction B — Does multi-agent help research at all when compute is held equal?**
Stanford 2604.02460 (Apr 2026) argues multi-hop gains explained by extra compute. Anthropic's 90.2% claim does not hold compute equal (15x more tokens). Open question: compute-normalized study on breadth-first web research (not multi-hop reasoning)?

**Contradiction C — Optimal agent count**
Saturation-at-~4 appears in practitioner writing but not nailed by single clean experiment. WideSeek shows "consistent gains" with subagent count. May reflect different task structures (MARL-trained vs prompt-only) rather than universal number.

**Open Question 1**: Does sub-agent tool restriction (WebSearch only) change optimal agent count vs full-tool agents? Untested.

**Open Question 2**: At what research breadth does single-agent parallel tool calling break down?

**Open Question 3**: Handoff quality: how much does sub-agent output format structure affect orchestrator synthesis quality? Anthropic stresses task description detail; no quantitative ablation found.

---

## 3. ALL SOURCES

| Title | URL | Type | Date |
|---|---|---|---|
| Towards a Science of Scaling Agent Systems | https://arxiv.org/abs/2512.08296 | Academic | Dec 2025 / v3 Feb 2026 |
| W&D: Scaling Parallel Tool Calling | https://arxiv.org/abs/2602.07359 | Academic Salesforce | Feb 2026 |
| WideSeek-R1: Width Scaling via MARL | https://arxiv.org/abs/2602.04634 | Academic | Feb 2026 |
| Single-Agent vs Multi-Agent on Multi-Hop (Equal Tokens) | https://arxiv.org/abs/2604.02460 | Academic Stanford | Apr 2026 |
| Rethinking Multi-Agent Workflow: Strong Single Agent Baseline | https://arxiv.org/abs/2601.12307 | Academic | Jan 2026 |
| Empirical Study of Multi-Agent Collaboration for Automated Research | https://arxiv.org/abs/2603.29632 | Academic | Mar 2026 |
| Orchestration of Multi-Agent Systems | https://arxiv.org/html/2601.13671v1 | Academic | Jan 2026 |
| LLM-Enabled Multi-Agent Systems: Empirical Evaluation | https://arxiv.org/html/2601.03328v1 | Academic | Jan 2026 |
| Beyond Context Sharing: ACP for A2A Orchestration | https://arxiv.org/html/2602.15055v1 | Academic | Feb 2026 |
| AORCHESTRA: Automating Sub-Agent Creation | https://arxiv.org/abs/2602.03786 | Academic | Feb 2026 |
| Multi-Agent Collaboration via Evolving Orchestration | https://openreview.net/forum?id=L0xZPXT3le | OpenReview | 2025/2026 |
| How we built our multi-agent research system (Anthropic) | https://www.anthropic.com/engineering/multi-agent-research-system | Engineering Anthropic | Jun 2025 |
| Towards a science of scaling (Google blog) | https://research.google/blog/towards-a-science-of-scaling-agent-systems-when-and-why-agent-systems-work/ | Engineering Google | Feb 2026 |
| InfoQ: Google Scaling Principles | https://www.infoq.com/news/2026/02/google-agent-scaling-principles/ | News | Feb 2026 |
| Single-Agent vs Multi-Agent: When Coordination Helps, Hurts, Pays Off | https://medium.com/@mjgmario/single-agent-vs-multi-agent-systems-when-coordination-helps-hurts-and-pays-off-57735ee7916d | Practitioner | Apr 2026 |
| 17x Error Trap of "Bag of Agents" | https://towardsdatascience.com/why-your-multi-agent-system-is-failing-escaping-the-17x-error-trap-of-the-bag-of-agents/ | Practitioner | 2025/2026 |
| The Multi-Agent Trap | https://towardsdatascience.com/the-multi-agent-trap/ | Practitioner | 2025/2026 |
| Agent Harness Failures: 13 Anti-Patterns | https://atlan.com/know/agent-harness-failures-anti-patterns/ | Practitioner | 2026 |
| Moonshot Kimi K2.6: 300 sub-agents, 4000 steps | https://www.marktechpost.com/2026/04/20/moonshot-ai-releases-kimi-k2-6-with-long-horizon-coding-agent-swarm-scaling-to-300-sub-agents-and-4000-coordinated-steps/ | News | Apr 2026 |
| Spring AI Agentic Patterns: A2A Integration | https://spring.io/blog/2026/01/29/spring-ai-agentic-patterns-a2a-integration/ | Engineering | Jan 2026 |
| Orchestrator-Worker Agents Practical Comparison (Arize) | https://arize.com/blog/orchestrator-worker-agents-a-practical-comparison-of-common-agent-frameworks/ | Engineering | 2026 |
| W&D project page (Salesforce) | https://xqlin98.github.io/wide-deep-research-agent/ | Engineering | Feb 2026 |
| WideSeek-R1 project page | https://wideseek-r1.github.io/ | Engineering | Feb 2026 |

---

## 4. TOP 5 URLs TO FETCH

1. **https://arxiv.org/html/2602.07359** — W&D paper. Most directly relevant: parallel tool calling vs multi-agent for deep research. BrowseComp/HLE/GAIA numbers. Could change architecture decision.
2. **https://arxiv.org/html/2604.02460v1** — Stanford single-agent vs multi-agent token budget. DPI argument + 3 model families. Apr 2026.
3. **https://www.anthropic.com/engineering/multi-agent-research-system** — Anthropic's primary source. Task description guidance, duplication failure modes, 15x cost, 90.2% improvement.
4. **https://arxiv.org/html/2512.08296v3** — Google/MIT scaling science. 260 configs, predictive model R²=0.513, saturation threshold, error amplification numbers.
5. **https://arxiv.org/html/2603.29632** — Empirical study multi-agent for automated research. Validates parallel-subagent mode, agent-team comparison. Mar 2026.

---

## 5. SUGGESTED FOLLOW-UPS

1. Replication/critique of W&D's intra-agent parallelism claim on BrowseComp.
2. Sub-task description quality ablation (Anthropic mentions but no numbers).
3. Tool-restriction (WebSearch only) impact on optimal agent count.
4. Anthropic Agent SDK Claude 4.6 multi-agent research patterns (Apr 2026).
5. Context window degradation in multi-agent handoffs.
6. Compute-matched multi-agent on breadth-first (not multi-hop) research.
