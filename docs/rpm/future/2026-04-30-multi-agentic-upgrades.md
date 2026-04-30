# Multi-agentic upgrades — port from volta

Seven items derived from a 2026-04-30 inventory of volta's
multi-agentic infrastructure (`/home/coder/projects/volta/.claude/`,
`tools/scripts/orch-*.sh`, `tests/parity/.orchestrator-{jobs,log}.*`).

## High value — port

### 1. `/next` orchestrator command

Single-step "pick one action per loop tick from a priority list"
wrapped by `/loop /next`. Action priority for rpm:

1. **blocked-on-user** — open question, awaiting reply (no-op turn,
   surface what we're waiting on)
2. **drift-fix** — scan.sh-flagged drift exists (run the fix, log)
3. **actionable-backlog** — top unblocked TODO in tasks.org → dispatch
   investigation/plan subagent
4. **idle** — no actionable work; emit summary + start counting
   toward the 3-idle terminal

Conventions copied from volta's `/next`:
- One action per turn, never loops internally
- Emits a 3-line summary: `action: <kind> / in-flight: <N> / next: <hint>`
- Terminal `loop-exhausted` after 3 consecutive `idle` iterations →
  do NOT call `ScheduleWakeup`; hand back to user
- Logs every decision via append-only JSONL (see item 7)

### 2. `/audit documents` → background by default

Today the auditor subagent runs foreground; the user blocks for ~3
min while it scans. Switch the dispatch to `run_in_background: true`,
return immediately, surface results when the `<task-notification>`
arrives. The new "delegate aggressively" directive already says do
this — today's audit was the prompt.

### 3. PostToolUse `REMINDER:` hooks tied to past audit findings

Volta's pattern: a PostToolUse hook emits `REMINDER: <rule>` to
stdout (model-visible next turn) when a commit/write touches a path
with a known invariant. Document the audit history reference in the
hook comment so the rationale is clear.

rpm candidates:

- Edit to `docs/rpm/future/tasks.org` without subsequent ordering
  check (`/backlog list` not invoked or no reorder happened)
- Commit touching `plugin/skills/**` or `plugin/hooks/**` without
  a corresponding `plugin/.claude-plugin/plugin.json` version bump
  (user-facing changes shipping unversioned)
- Edit to a `plugin/skills/<name>/SKILL.md` without a subsequent
  `sync-codex.sh` run (codex copy stale)

### 4. Loop-exhausted terminal pattern

For any future rpm command designed to run in `/loop`: after 3
consecutive idle ticks, output `action: loop-exhausted / next: USER
ATTENTION …` and explicitly do NOT call `ScheduleWakeup` on that
terminal turn. Prevents runaway dynamic-mode loops.

## Medium — adapt before porting

### 5. Worker-brief + RESULT_SCHEMA for dispatched subagents

Currently `rpm:auditor` returns prose; Phase 2 scoring is
LLM-rendered. Define a JSON schema for findings:

```json
{ "summary": "…",
  "findings": [
    { "id":"F1", "severity":"high|medium|low",
      "evidence":["…"], "fix":"…", "score": 85 }
  ],
  "session_drift": [ { "session_id":"…", "classification":"justified|unjustified", "note":"…" } ]
}
```

Have the auditor emit JSON; let the audit skill parse + sort + render.
Mechanical instead of LLM-rendered.

### 6. Tag-prefix state on backlog items

Volta uses `[task:][analyzed:][fix-attempted:]` prefixes on a single
text field as a race-safe state machine. rpm analog: mark
`** TODO [investigated:DATE]` when a research subagent has gone
deep on a backlog item, `[planned:DATE]` when a plan file exists.
Richer than the current TODO/IN-PROGRESS/BLOCKED set; lives in a
single text field; idempotent; no schema change.

### 7. Append-only orchestrator activity log

rpm already has `~rpm-learnings.jsonl`. Add
`~rpm-orchestrator-log.jsonl` capturing one line per `/next`
decision: `{ts, kind, target, rationale}`. Cheap visibility into
what the loop is doing across sessions.

## Skip — volta-specific or too heavy

- Atomic-claim REST API + lease reaper — needs a server; rpm is
  pure-markdown
- Lock-aware append helper — no parallel writers in rpm
- Triage → analyze → fix pipeline — volta's bugs are mechanical
  units; rpm's backlog is creative work the user owns
- Worktree-domain workers — rpm is single-tree
- Worker self-verification with daemon trace — domain-specific to
  parity rendering

## Suggested execution order

**First slice (smallest cohesive landing):** items 1 + 2 ship
together. `/next` gives users a working loop story (`/loop /next`);
`/audit documents` flipped to background demonstrates the
background-dispatch pattern. After that lands, items 3–7 follow as
separate increments once the orchestrator shape is proven.
