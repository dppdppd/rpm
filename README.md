# rpm — Relentless Project Manager

Prevents documentation drift and keeps you on task across LLM-assisted
development sessions. Available for Claude Code, opencode, and Codex.

## Getting started — Claude Code

**1. Install** (once per machine):

```
/plugins marketplace add https://github.com/dppdppd/rpm
/plugins install rpm@dppdppd-plugins
```

**2. Run `/init-rpm`** inside the project you want to track. It
scaffolds `docs/rpm/` and activates the hooks immediately — no
restart needed.

See [plugin/README.md](plugin/README.md) for full documentation.

## Getting started — opencode

From inside the project you want to track:

```
curl -fsSL https://raw.githubusercontent.com/dppdppd/rpm/opencode/install.sh | bash
```

Installs the opencode config (plugin, hooks, skills, commands,
agents) into your project's opencode config directory. Then run
`/init-rpm` to scaffold `docs/rpm/`.

See [opencode/README.md](opencode/README.md) for the port status and
publish flow.

## Getting started — Codex

Install from a shell:

```bash
codex plugin marketplace add dppdppd/rpm@codex --enable hooks
```

Then enable the plugin in `~/.codex/config.toml`:

```toml
[plugins."rpm@dppdppd-rpm"]
enabled = true
```

Codex hooks also require this feature flag in `~/.codex/config.toml`
if it is not already enabled:

```toml
[features]
hooks = true
```

Run `$init-rpm` inside the project you want to track. Codex skills use
`$skill-name` invocation rather than slash commands.

See [codex/README.md](codex/README.md) for the port status and publish
flow.

## License

MIT
