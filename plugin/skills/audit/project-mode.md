# /rpm:audit project — Consultant Review

Full consultant review with external research. You are NOT an expert
in this project's domain — investigate before judging.

**Five phases: Investigate → Inward Research → Outward Research →
Analyze → Refine.** Do not skip phases. Outward research is
**required**, not optional — without it you over-index on "does the
project match its own spec?" and miss whether the spec itself is
best-in-class.

## Phase 1: Investigate (gather evidence, don't opine yet)

**At the start of Phase 1, launch `rpm:auditor` in the background**
(`subagent_type: "rpm:auditor"`) so its structured scan runs in
parallel with the reads below. Without this, a Project audit can
silently miss broken file refs and tracker drift that a Documents
audit would catch.

**Hard gate:** Do NOT start Phase 4, present findings, or write
deliverables until the `rpm:auditor` scan has completed and its
findings have been merged into your evidence. Phases 2–3 may run
while the auditor is in flight, but the analysis and all output
must reflect the union of manual investigation AND the auditor
report. Presenting a partial list and appending auditor findings
later defeats the purpose of a single consolidated review.

Read project state in parallel:

- `git log --oneline -30` and `git diff --stat`
- CLAUDE.md, `present/PRESENT.md`, recent `past/` daily logs, debugging/parity logs
- Memory files (feedback type especially)
- `grep -rn NOT_IMPLEMENTED` across the project's source tree (tune path to layout)
- `docs/rpm/RPM.md` (project-specific PM context)
- Prior consultant reviews if they exist

Then **probe deeper**:

- **Code structure**: read 2-3 key source files. Most-changed files:
  `git log --format='%H' -30 | xargs -I{} git diff-tree --no-commit-id -r {} | awk '{print $6}' | sort | uniq -c | sort -rn | head -10`
- **Test coverage reality**: what test files exist vs source files?
- **Actual vs claimed architecture**: grep for cross-package imports
- **Build health**: `turbo build` (or project's build command)
- **Dependency freshness**: check package.json for outdated deps
- **Repetitive LLM work**: scan skills, commands, agent prompts,
  and hooks for deterministic operations that run on every
  invocation (file-existence checks, line counts, greps, simple
  diffs, status summaries, JSON parsing). These are candidates
  for bundling as bash scripts — each saves tokens on every call
  and is more reliable than LLM re-implementation.

## Phase 2: Inward Research (validate against authoritative sources)

Goal: confirm the project's current approach aligns with authoritative
references for its stack, frameworks, and domain.

For each dimension the project touches, identify what you DON'T know
*about how it's supposed to work*. Research against authoritative
docs (vendor docs, RFCs, spec repos). **Min 2 dimensions.**

Either:

- Use WebSearch / `curl --max-time 30 -sL` directly for narrow lookups, or
- Invoke the `deep-research` skill in parallel for complex,
  multi-angle topics. (`deep-research` is a skill in this plugin,
  not a slash command.)

Example inward questions:

- Is the plugin manifest schema current with vendor docs?
- Does our testing strategy match the framework's recommended approach?
- Are we using current API versions / avoiding deprecated patterns?
- Architecture best practices for this stack?

## Phase 3: Outward Research (competitive analysis — REQUIRED)

Goal: compare the project against real alternatives. This is where
you find out whether the spec *itself* is best-in-class, not just
whether the project matches its own spec. Skipping this phase is the
single biggest failure mode of Project mode.

**Discover 3–5 direct competitors or comparable tools.** For at least
**2**, actually fetch their docs or README (via `curl --max-time 30 -sL`) — do not rely on
search-result titles or summaries.

For each competitor, note:

- **What they do** — one-sentence summary of their approach
- **What they do better** — specific features/patterns worth stealing
- **What we do better** — things they lack that we should preserve
- **Verdict** — adopt, reject, or flag as complementary (with rationale)

Example outward queries (adapt to project):

- "What other tools in {this domain} exist as of {year}?"
- "How does {competitor A} handle {our core concern}?"
- "What do best-in-class {category} tools do that we don't?"

If a competitor has a feature worth adopting, emit it as a **gap
finding** in Phase 4. Gap findings carry equal weight to
spec-conformance findings.

## Phase 4: Analyze (now you can judge)

Evaluate across these dimensions. Every finding must cite Phase 1
evidence AND either Phase 2 or Phase 3 research — ideally both.
**Mechanical findings from the `rpm:auditor` scan (Phase 1) count as
Phase 1 evidence** — promote anything material into the dimension
list below (VALIDITY → LLM Workflow; tracker drift → Session
Discipline). Trivial hygiene drops out.

1. **Process Health** — workflow followed? measure→change→measure?
2. **Architecture & Code Health** — boundaries clean? complexity proportional?
3. **LLM Workflow** — hooks/skills/memory effective? CLAUDE.md right
   size? **Any deterministic work (grep, wc, file-existence checks,
   simple diffs, status summaries) done repeatedly by LLM workflows
   that should be bundled as bash scripts?** Each bundled script
   saves tokens on every invocation and is more reliable than
   per-call LLM re-implementation. Example pattern: ccpm's 14-script
   bundle for standup/status/next/blocked ops.
4. **Risk & Compliance** — untested paths? boundary violations?
5. **Strategic Direction** — time on highest-value work? critical path?
6. **Session Discipline** — tracker maintained? sessions scoped?
7. **Competitive Gaps** — features/patterns from Phase 3 the project
   should adopt or explicitly reject (with rationale).

If `docs/rpm/RPM.md` defines project-specific focus areas, evaluate those too.

## Phase 5: Ask questions and refine

If aspects require developer input, ask now — before writing the plan.
Don't defer questions to the plan file.

## Deliverables

### 1. Executive summary (displayed to user)

```
## PM Review — YYYY-MM-DD

### Health
[1-2 sentences]

### Research Conducted
- **Inward — [Topic]** — [what you asked, learned, how it changed assessment]
- **Outward — [Competitor]** — [what they do, what you learned]

### Findings
- **[Title] (Severity)** — [2-3 sentences: what, why, research context]

### Plan
**Plan saved to** `docs/rpm/reviews/YYYY-MM-DD-plan.md`
[1-line per task: title + effort]
```

### 2. Log the run

Append one line to `docs/rpm/past/RPM-LOG.md` Audit History:

```
- YYYY-MM-DD — audit project — N findings, plan saved to reviews/YYYY-MM-DD-plan.md
```

### 3. Plan file (saved to disk)

`docs/rpm/reviews/YYYY-MM-DD-plan.md`:

```markdown
# PM Plan — YYYY-MM-DD

## Context
[what was reviewed, what inward + outward research was conducted]

## Tasks
### Task 1: [title]
- **Severity:** Critical | High | Medium | Low
- **Dimension:** Process | Architecture | LLM Workflow | Risk | Strategy | Session Discipline | Competitive
- **What's wrong:** [evidence]
- **Why it matters:** [impact]
- **Research says:** [inward docs + outward competitors, both if relevant]
- **Fix:** [concrete steps]
- **Effort:** Small | Medium | Large

## What's Working (don't break these)
```

Ordered by severity then effort. Also save full report to
`docs/rpm/reviews/YYYY-MM-DD.md`.
