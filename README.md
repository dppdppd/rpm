# rpm — Codex CLI port

Codex CLI port of the rpm plugin. Generated from `plugin/` via
`scripts/sync-codex.sh` (see top-level repo).

## What ports

| Surface | Status | Notes |
|---|---|---|
| Plugin manifest | Full | `.codex-plugin/plugin.json` is generated from the Claude plugin manifest and points at the Codex skills/hooks |
| Skills | Full | All six skills sync 1:1; Codex frontmatter is a strict subset of Claude Code's |
| `SessionStart` hook | Full | `session-start-auto.sh` — context injection, marker bookkeeping, backlog menu |
| `PostToolUse` hook | Full | `context-monitor.sh` — fires for all tools (per Codex schema) |
| Codex sync reminder | Full | `codex-sync-reminder.sh` — reminds rpm contributors to run `sync-codex.sh` after source edits |
| `Stop` hook | Full | `stop-learn-capture.sh` + `handoff-validator.sh` — Codex's Stop payload includes `last_assistant_message`, no transcript scraping needed |
| Auditor system prompt | Reference doc | Lives at `.codex/skills/audit/references/auditor.md`; the audit skill should Read it and hand it to a sub-agent (Codex has no separate "subagent definition" file format that fits) |

## What does NOT port

| Surface | Why blocked |
|---|---|
| `SessionEnd` hook | Codex has no SessionEnd event (only Stop). The session-end skill still works as a user-invocable wrap-up — no automatic detection of "user exited without /session-end" |
| `PreCompact` / `PostCompact` hooks | Codex has no compaction lifecycle hooks — the checkpoint/recovery flow that protects state across compaction is unavailable |
| `TaskCreated` / `TaskCompleted` hooks | Codex has no native task UI and no events. `task-capture.sh` is dropped |
| Pivot capture | Same root cause — depends on `TaskCreated` |

## Install

This port supports marketplace install only. From a shell:

```bash
codex plugin marketplace add dppdppd/rpm@codex --enable codex_hooks
```

Then enable the plugin in `~/.codex/config.toml`:

```toml
[plugins."rpm@dppdppd-rpm"]
enabled = true
```

The `codex plugin` CLI currently manages marketplaces only; it does
not provide a `codex plugin install` subcommand. Plugin activation is
the `[plugins."rpm@dppdppd-rpm"]` config entry above.

Then merge `.codex/config.toml.sample` into `~/.codex/config.toml` (or
`.codex/config.toml`):

```toml
[features]
codex_hooks = true
```

Without that flag, Codex parses `hooks.json` but skips dispatch
silently — SessionStart context injection won't fire.

## Maintenance

This port is generated. Don't hand-edit unless the file carries the
manual-sync sentinel near the top:

```html
<!-- codex-sync: manual -->
```

Files with that marker are preserved on the next `sync-codex.sh` run;
everything else is regenerated. Currently marked manual:

- `skills/deep-research/SKILL.md` — Codex-specific tool-name swaps
  (`web_search`, `shell`, sub-agent reframing) that don't pass cleanly
  through automated translation.

To regenerate from `plugin/`:

```bash
./scripts/sync-codex.sh
```
