# Port rpm to opencode

## Why

opencode (`anomalyco/opencode`, canonical npm: `opencode-ai`,
docs: https://opencode.ai/docs/) is a Claude-Code-adjacent coding CLI
with its own extension system. It reads `.claude/skills/<name>/SKILL.md`
natively, so most of rpm's authored surface is already compatible;
the main blocker is the hook layer, which opencode implements in
TypeScript instead of bash.

## What ports as-is

- **Skills** (all six: `session-end`, `tasks`, `audit`, `init-rpm`,
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

- **Hooks** (8 scripts in `plugin/hooks/`). opencode's `Hooks` interface
  has **no dedicated session-lifecycle hooks** — lifecycle events arrive
  via a single generic `event` hook that receives a discriminated-union
  `Event` object from `@opencode-ai/sdk`. Dispatch is a switch on
  `event.type`. Corrected mapping (verified against `sst/opencode@dev`
  `packages/plugin/src/index.ts` + `packages/sdk/js/src/gen/types.gen.ts`
  on 2026-04-18):

  | Claude Code             | opencode route                                      |
  |-------------------------|-----------------------------------------------------|
  | `SessionStart`          | `event` hook on `event.type === "session.created"`  |
  | `SessionEnd`            | `event` hook on `event.type === "session.deleted"`  |
  | `Stop`                  | `event` hook on `event.type === "session.idle"`     |
  | `PostCompact`           | `event` hook on `event.type === "session.compacted"`|
  | `PreCompact`            | dedicated `experimental.session.compacting` hook    |
  | `PostToolUse`           | dedicated `tool.execute.after` hook                 |
  | `TaskCreated`/`TaskCompleted` | `event` hook on `event.type === "todo.updated"` |

  Stdin-JSON → stdout/stderr contract becomes a wrapper that shells out
  to the existing bash scripts via `$` (BunShell). The existing bash
  bodies can be reused unchanged; only the thin wrappers are new.

## Prototype findings (2026-04-18)

A working prototype lives at `opencode/.opencode/plugins/rpm.ts`.
Smoke tested against `opencode 1.14.17` via `opencode serve` headless +
`POST /session` / `DELETE /session/<id>`.

- ✅ TypeScript plugin loads without any deps installed — `import type`
  is stripped by opencode's bundled Bun runtime, so no package.json
  dance needed for the prototype.
- ✅ Auto-discovery works: dropping the file in
  `.opencode/plugins/` is sufficient, no entry in `opencode.json`.
- ✅ The `event` hook fires on `session.deleted` and the bash hook
  (`session-end.sh`) ran cleanly with `CLAUDE_PROJECT_DIR` +
  `CLAUDE_PLUGIN_ROOT` piped in via `$.env({...})`.
- ⚠️ `session.created` is **not seen by the very first session** —
  plugins load lazily on the first `POST /session`, and that session's
  `session.created` publishes before the `event` subscription is
  registered. Subsequent sessions fire normally. Workaround options:
  run startup side-effects inside the plugin's init function itself
  (called once per project bootstrap), or treat `session.updated` as a
  fallback trigger.
- ✅ Hook path resolution via `realpathSync(fileURLToPath(import.meta.url))`
  works through symlinks — dev installs can symlink the plugin into a
  test project's `.opencode/plugins/` and hooks still resolve to the
  real monorepo path. Without `realpathSync`, `fileURLToPath` preserves
  the symlink and the relative climb lands in the wrong place.
- ✅ SessionStart bootstrap moved inside the Plugin init function.
  First session's `session.created` is missed (publishes before the
  event hook registers), but init runs unconditionally on first POST,
  so the marker gets written and `docs/rpm/` state is consistent from
  session 1.
- ✅ **End-to-end proof (2026-04-18, /tmp/rpm-oc-test):** init wrote
  `~rpm-session-start` with correct frontmatter; delete-session
  triggered `session-end.sh` which appended a well-formed daily-log
  stub (`**Session:** plugin-init`, `**Reason:** other`) to
  `past/2026-04-18.md`. Every layer of the bridge confirmed.
- ✅ **Skills mirror works.** `scripts/sync-opencode.sh` cp-mirrors
  `plugin/skills/` into `opencode/.opencode/skills/`. `opencode debug
  skill` then lists all six: `audit`, `backlog`, `deep-research`,
  `init-rpm`, `rpm`, `session-end`. SKILL.md format is 1:1 compatible.
- ✅ **Agent translation working.** `scripts/translate-agent.py`
  rewrites Claude Code agent frontmatter for opencode: drops `name:`
  (opencode derives from filename), drops `model:` (Claude Code
  shortnames like `sonnet` don't map to opencode's
  `anthropic/claude-sonnet-4-20250514` format — let opencode default),
  inserts `mode: subagent` when absent, and converts
  `tools: [Read, Grep, ...]` (array) →
  `tools: {read: true, grep: true}` (record, lowercased —
  opencode's tool names are lowercase: `read`, `grep`, `glob`, `bash`,
  `edit`, `write`, `apply_patch`, `lsp`). Verified with
  `opencode debug agent auditor`.

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
   git-subtree-split plugin-only branch like Claude Code? (npm is the
   shipped path docs recommend, but local-file drop-in also works.)
2. ~~Does opencode's `session.idle` fire reliably enough to replace
   SessionEnd's "user exited without /session-end" detection?~~
   Superseded: `session.deleted` is the true SessionEnd analog;
   `session.idle` maps to `Stop`. Still TBD whether `session.deleted`
   fires on `/exit` / terminal close / kill vs only on explicit session
   teardown.
3. Should we write a CI job to validate skill/agent sync between
   `plugin/` and `opencode/`?
4. How to solve the first-session `session.created` miss — run
   startup logic inside the Plugin init function, or rely on
   `session.updated` as a secondary trigger? Needs a test with a
   real interactive session (not just a POST).

## Sources

- https://opencode.ai/docs/plugins (event list + `PluginInput` shape)
- https://opencode.ai/docs/skills (SKILL.md discovery incl. `.claude/skills/`)
- https://opencode.ai/docs/agents, /commands, /custom-tools, /mcp-servers, /config, /tools
- `packages/plugin/src/index.ts` on `anomalyco/opencode@dev` —
  authoritative `Hooks` interface
