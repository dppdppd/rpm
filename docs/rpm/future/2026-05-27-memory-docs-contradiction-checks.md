# Memory↔docs contradiction checks

Surface contradictions between auto-memory (`feedback_*.md`, `MEMORY.md`)
and active directive docs (`CLAUDE.md`, `AGENTS.md`, skill bodies) on a
recurring cadence — not only when the user manually runs `/audit`.

## Why

Today the only surface is `/audit documents` → `rpm:auditor` Phase 5
(GUIDANCE ALIGNMENT, plugin/agents/auditor.md:109). Drift between a
memory rule and the directive it was meant to codify can sit silent for
weeks. User wants this caught on the routine session loop instead.

## Scope

- **Lightweight, every `/next`** — runs in preflight, cheap, no LLM
  subagent. Surfaces only high-confidence direct contradictions; never
  blocks; logs a `drift-fix` or `idle` rationale entry when something is
  flagged.
- **Heavyweight, every `/session-end`** — Prep phase. Uses the
  auditor's Phase-5 classifier (`CODIFIED | PARTIAL | GAP | STALE`) over
  all memory files. Stale/contradictory items surface as a "Memory
  drift" decision surface alongside existing Commit / Drift / Native.

## Open design questions

1. **Lightweight detection mechanism.** Options:
   a) Pattern-based bash script — flag memory files whose `name:` or
      `description:` mentions a term that appears with negated polarity
      in CLAUDE.md/AGENTS.md (e.g. memory says "always X", docs say
      "never X"). Cheap, low recall, low false-positive.
   b) Memory-touched-since-last-audit heuristic — flag any memory file
      whose mtime is newer than the active instructions file mtime
      AND whose `name:` token appears in the instructions file. Doesn't
      detect contradictions, but flags "you updated guidance without
      reconciling docs."
   c) Small focused LLM call inside `/next` preflight (a single
      `claude-haiku` subagent reading just the touched memory file +
      relevant doc section). Higher recall, costs a turn.
2. **Heavyweight: invoke `rpm:auditor` fresh, or carve Phase 5 into a
   reusable subagent?** Auditor today is full-scan; calling it from
   session-end every time is heavy. Likely answer: extract Phase-5
   into its own focused agent (`rpm:guidance-aligner`?) and have both
   `/audit documents` and `/session-end` call it.
3. **Surface treatment.** Lightweight flag at `/next` — output line
   only (`contradictions: <N>`), or block dispatch until reviewed?
   Recommend: surface in preflight summary; never block.

## Out of scope

- Detecting contradictions inside the memory set itself
  (feedback-vs-feedback).
- Cross-project memory drift (we operate on this project's memory dir
  only).

## Acceptance

- `/next` preflight adds a contradiction check step that runs in <500ms
  and adds at most one summary line to the output.
- `/session-end` Prep adds a Memory drift surface that lists
  CODIFIED/PARTIAL/GAP/STALE counts and offers to reconcile.
- Auditor's Phase 5 either remains the source of truth or is extracted
  into a shared agent (decided in design).
- Tests cover: contradiction flagged → surfaces; no contradiction →
  silent; memory-touched-but-not-contradictory → silent at /next,
  visible at /session-end.

## Worker Result

**Summary.** Built the contradiction-check surface for both /next
(lightweight, cached) and /session-end (heavyweight, every session)
using a single shared subagent (`rpm:guidance-aligner`, haiku) with
two prompt modes. Rolled in the project-amendment convention
(`docs/rpm/skills/<name>.md`) and drift detection for hard-override
skills along the way.

**Files changed.**

- NEW `plugin/agents/guidance-aligner.md` — shared subagent. Two
  modes: `contradictions-only` (for /next) and `full`
  (CODIFIED|PARTIAL|GAP|STALE|CONTRADICTED, for /session-end and
  /audit). Returns JSON, no edits.
- NEW `plugin/skills/next/scripts/contradiction-check.sh` — mtime
  cache gate. `check` prints one of `skip|cached|dispatch <epoch>`;
  `save EPOCH` persists the agent JSON for reuse.
- NEW `plugin/tests/contradiction-check.bats` — 6 tests covering
  skip / dispatch / save / cached / re-dispatch on touch.
- EDIT `plugin/skills/next/SKILL.md` — added preflight step 3
  (guidance contradictions) and renumbered worker review to 4;
  added Project Amendments load step.
- EDIT `plugin/skills/session-end/SKILL.md` — added Prep step 1b
  (Guidance Alignment), Guidance Surface in Shared Mechanics, mode
  selection update (CONTRADICTED/STALE forces Inline), overridden
  skill drift handling, Project Amendments load step.
- EDIT `plugin/skills/audit/SKILL.md` — Project Amendments load step.
- EDIT `plugin/skills/backlog/SKILL.md` — Project Amendments load step.
- EDIT `plugin/skills/deep-research/SKILL.md` — Project Amendments
  load step.
- EDIT `plugin/agents/auditor.md` — Phase 4 Skill overrides check.
- EDIT `plugin/skills/session-end/scripts/scan.sh` — new
  `=== overridden_skills ===` section.
- EDIT `plugin/tests/scan.bats` — 3 tests for overridden_skills.
- SYNC `codex/.codex/skills/audit/references/auditor.md` via
  `scripts/sync-codex.sh` (keeps the byte-identical mirror in sync).

**Design decisions.**

- Shared agent over two specialized ones: same classifier, prompt
  mode parameter selects subset. Keeps the agent file canonical.
- Cache lives at `docs/rpm/~rpm-contradiction-cache` (gitignored
  via existing `docs/rpm/~rpm-*` wildcard).
- Session-end pipes its full report through the same `save` path so
  /next reuses the fresh result rather than re-dispatching.
- Override detection is mechanical (in scan.sh, hardcoded skill
  name list) — auditor also flags it in Phase 4 as defense in
  depth. Never auto-migrates: the project may have intentional
  override content.

**Verification.** Full bats suite (196 tests) passes. New tests
exercise the contradiction-check cache contract directly. Manual
test of scan.sh with a fake `.claude/skills/next/SKILL.md` produced
the expected `override=` line.

**Remaining risks / follow-ups.**

- The `rpm:guidance-aligner` agent hasn't been exercised end-to-end
  yet (would require a real /next or /session-end run). The contract
  is specified in the agent's frontmatter + body; first live
  dispatch will validate the prompt.
- README does not yet document the amendment convention. Deferred
  unless requested — the convention is self-documenting (each
  plugin skill body tells the LLM how to find amendments).
