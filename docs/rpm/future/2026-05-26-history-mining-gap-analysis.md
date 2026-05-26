# Mine Claude + Codex conversation histories for rpm gaps

Survey conversation transcripts across Claude Code projects and Codex sessions
to surface concrete evidence of:

- **Usage gaps** — rpm available but not invoked when it would have helped
  (missed `/session-end`, missed pivot capture, missed backlog adds, missed
  `/audit`, drift markers ignored, etc.)
- **Implementation gaps** — rpm invoked but produced friction, wrong output,
  failed hook, confusing skill body, or had no hook fire when expected
- **Workflow gaps** — recurring patterns where rpm doesn't have a tool for
  what the user actually needed (and would have to either invent one or
  bolt on)

## Inputs
- `~/.claude/projects/-home-coder-projects-rpm/<uuid>/` — JSONL transcripts
  for this repo
- `~/.claude/projects/-home-coder-projects-*/` — transcripts in other projects
  that may carry rpm artifacts (docs/rpm/, plugin/, etc.)
- `~/.codex/history.jsonl` — Codex CLI prompt history
- `~/.codex/sessions/` — full Codex transcripts

## Output
- Categorized findings with concrete excerpts/citations
- Severity + frequency tags
- Recommendation per finding (skill body edit, hook tweak, new feature, etc.)

## Method
1. Inventory which projects carry rpm artifacts (broad usage surface)
2. Parallel mine: one agent per source bucket
3. Dedupe + categorize centrally
4. Present Key Findings before any implementation
