# Port rpm to Codex CLI

## Why

OpenAI Codex CLI (`github.com/openai/codex`, npm: `@openai/codex`,
docs: `developers.openai.com/codex`) is a local coding agent with a
plugin system that shares many design decisions with Claude Code.
Skills port 1:1; the hook layer is more limited.

## What ports as-is

- **Skills** (all six) — same markdown + YAML-frontmatter format.
  Codex reads `skills/<name>/SKILL.md` in the plugin root.
- **Plugin manifest** — `.codex-plugin/plugin.json` with similar
  JSON schema (`name`, `version`, `description`, `skills` pointer).
- **SessionStart hook** — `SessionStart` event exists with
  `startup|resume` matcher and stdin JSON payload (same shape:
  `session_id`, `transcript_path`, `cwd`, `model`).

## What needs translation

- **Agents** — Codex uses TOML (`agents/*.toml`) not markdown.
  Fields: `name`, `description`, `developer_instructions`,
  optional model/sandbox overrides. `auditor.md` content moves
  into a `developer_instructions` string.
- **PostToolUse hooks** — event exists but currently only fires
  for the `Bash` tool (not Write/Edit/Grep/Glob). The
  context-monitor hook won't trigger on non-Bash tool calls.
- **Stop hook** — `Stop` event exists; payload differs from
  Claude Code's (no `last_assistant_message` — need to read
  from `transcript_path` instead).
- **Built-in tool names** — Codex has file tools but names differ
  from Claude Code's `Read`/`Edit`/`Write`/`Grep`/`Glob`. Skills
  referencing tool names in `allowed-tools` need updating.

## What has no equivalent (blocked)

- **SessionEnd** — no event. Can't detect "user exited without
  /session-end". The session-end.sh daily-log stub functionality
  is lost.
- **PreCompact / PostCompact** — no compaction lifecycle hooks.
  The checkpoint/recovery flow (`pre-compact.sh` → save state →
  `post-compact.sh` → re-inject) has no port path.
- **TaskCreated / TaskCompleted** — no events and no native task
  UI. The task-capture.sh hook and candidate-scoring pipeline
  are entirely blocked.
- **User-defined slash commands** — Codex has built-in commands
  only. Skills surface via `$skill` invocation, not `/rpm:skill`.

## Hook system details

Codex hooks are **experimental** (behind `features.codex_hooks = true`
in `config.toml`). Available events:

| Event             | Matcher             | Notes                    |
|-------------------|---------------------|--------------------------|
| `SessionStart`    | `startup\|resume`   | Direct match to CC       |
| `Stop`            | none                | No `last_assistant_message` |
| `PreToolUse`      | tool name (Bash)    | Only fires for Bash      |
| `PostToolUse`     | tool name (Bash)    | Only fires for Bash      |
| `UserPromptSubmit`| none                | CC doesn't have this     |

Output contract: JSON on stdout with `systemMessage` (→ LLM context),
`continue` (boolean), `stopReason`. Plain-text stdout is added as
developer context only for `SessionStart`.

## Proposed repo layout

Same pattern as the opencode port — add `codex/` as a sibling to
`plugin/` and `opencode/`:

```
rpm/
├── plugin/          # Claude Code — unchanged
├── opencode/        # opencode port
├── codex/           # Codex CLI port (NEW)
│   ├── .codex-plugin/
│   │   └── plugin.json
│   ├── skills/      # mirror of plugin/skills
│   ├── agents/      # TOML translations of plugin/agents
│   ├── hooks/       # bash scripts (subset that have events)
│   ├── config.toml  # sample config with hooks enabled
│   └── README.md
├── scripts/
│   └── sync-ports.sh   # rsyncs skills across plugin/ opencode/ codex/
└── docs/
```

## Scope estimate

Smaller than the opencode port since fewer hooks can port:
- Skills: zero effort (sync script)
- Plugin manifest: ~30 min
- SessionStart hook: direct port
- Stop hook: light translation (read transcript for last message)
- Agents: TOML translation (~1hr)
- Everything else: blocked until Codex adds more lifecycle events

## Open questions

1. How stable is the hooks experimental flag? Could it be removed
   or redesigned before we invest?
2. Will Codex add SessionEnd / compaction events? Worth tracking
   their roadmap / GitHub issues.
3. Should the sync script (`sync-ports.sh`) handle all three
   platforms (Claude Code → opencode + codex), or separate scripts?
4. Are tool name differences between Codex and Claude Code purely
   cosmetic, or do they have different argument shapes?

## Sources

- https://github.com/openai/codex — canonical repo
- https://developers.openai.com/codex/hooks — events, payloads
- https://developers.openai.com/codex/skills — SKILL.md format
- https://developers.openai.com/codex/plugins — plugin build guide
