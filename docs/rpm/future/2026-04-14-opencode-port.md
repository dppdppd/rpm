# Port rpm to opencode

## Why

opencode (`anomalyco/opencode`, canonical npm: `opencode-ai`,
docs: https://opencode.ai/docs/) is a Claude-Code-adjacent coding CLI
with its own extension system. It reads `.claude/skills/<name>/SKILL.md`
natively, so most of rpm's authored surface is already compatible;
the main blocker is the hook layer, which opencode implements in
TypeScript instead of bash.

## What ports as-is

- **Skills** (all six: `session-end`, `tasks`, `audit`, `bootstrap`,
  `rpm`, `deep-research`) — markdown + YAML frontmatter is identical.
- **Agents** — `agents/auditor.md` drops into `opencode/agents/`.
- **Slash commands** — markdown + `$ARGUMENTS`, `!bash`, `@file` refs
  are supported in both.
- **Built-in tools** — Read/Edit/Write/Grep/Glob/Bash are the same.
- **MCP** — supported via `opencode.json`.

## What needs translation

- **Plugin manifest** — `plugin.json` becomes `opencode.json` +
  directory layout.
- **Native task UI** — `TaskCreate`/`TaskList`/`TaskUpdate` become
  the `todowrite` built-in tool; `todo.updated` event for observation.

## What needs a full rewrite

- **Hooks** (8 scripts in `plugin/hooks/`). No bash-hook runtime in
  opencode; plugins are JS/TS modules subscribing to an event stream.
  Event mapping:

  | Claude Code           | opencode equivalent                    |
  |-----------------------|----------------------------------------|
  | `SessionStart`        | `session.created`                      |
  | `PostCompact`         | `session.compacted`                    |
  | `PreCompact`          | `experimental.session.compacting` hook |
  | `PostToolUse`         | `tool.execute.after`                   |
  | `Stop`                | `session.idle` (closest approximation) |
  | `TaskCreated`/`TaskCompleted` | `todo.updated`                  |
  | `SessionEnd`          | **no equivalent** — closest: `session.idle` / `session.deleted` |

  Stdin-JSON → stdout/stderr contract becomes `output.context.push(...)`
  / logging API calls. The existing bash bodies can be called from TS
  via `Bun.$`, so logic isn't lost — just the thin wrappers.

## Proposed repo layout

Keep `plugin/` unchanged — renaming breaks the existing
`git subtree split --prefix=plugin` publish flow and any marketplace
entries/user clones of the plugin-only branch. Add `opencode/` as a
sibling.

```
rpm/
├── plugin/                       # Claude Code plugin — UNCHANGED
├── opencode/                     # NEW
│   ├── package.json              # rpm-opencode npm package
│   ├── opencode.json
│   ├── src/
│   │   └── index.ts              # TS plugin — subscribes to opencode
│   │                             # events, shells out to ../plugin/hooks/*.sh
│   │                             # (or copies in hooks/) via Bun.$
│   ├── skills/                   # mirror of plugin/skills
│   ├── agents/                   # mirror of plugin/agents
│   ├── commands/
│   ├── hooks/                    # bash scripts (copied from plugin/hooks)
│   ├── tests/
│   └── README.md
├── scripts/
│   └── sync-opencode.sh          # rsyncs plugin/{skills,agents,hooks} → opencode/
├── docs/
└── CLAUDE.md
```

## Content-sharing strategy

Three options for keeping skills/agents/hooks in sync between
`plugin/` and `opencode/`:

1. **Duplicate + sync script** (recommended). `scripts/sync-opencode.sh`
   rsyncs on demand and in CI. Drift risk between runs, but simple.
2. **Symlinks.** Works on Linux/macOS, breaks on Windows and some git
   clients.
3. **TS plugin reaches across via relative paths.** Fine in the
   monorepo, doesn't work for a *shipped* opencode package.

## Publish flows

- Claude Code: `git subtree split --prefix=plugin -b plugin-only && git push origin plugin-only:master --force` (unchanged).
- opencode: either a second subtree split (`--prefix=opencode -b opencode-only` → separate remote or branch) or `npm publish` of `opencode/` as `rpm-opencode`.

## Scope estimate

~200–400 LOC of TypeScript for the plugin module. Skills and agents
are zero-effort copies (via sync script). Biggest unknown: mapping
`SessionEnd` correctly — `session.idle` isn't truly "ended", so the
SessionEnd hook's stale-detection and daily-log stub behaviors may
need redesign.

## Open questions

1. Is `rpm-opencode` as an npm package the right distribution, or a
   git-subtree-split plugin-only branch like Claude Code?
2. Does opencode's `session.idle` fire reliably enough to replace
   SessionEnd's "user exited without /session-end" detection? Research.
3. Should we write a CI job to validate skill/agent sync between
   `plugin/` and `opencode/`?

## Sources

- https://opencode.ai/docs/plugins (event list + `PluginInput` shape)
- https://opencode.ai/docs/skills (SKILL.md discovery incl. `.claude/skills/`)
- https://opencode.ai/docs/agents, /commands, /custom-tools, /mcp-servers, /config, /tools
- `packages/plugin/src/index.ts` on `anomalyco/opencode@dev` —
  authoritative `Hooks` interface
