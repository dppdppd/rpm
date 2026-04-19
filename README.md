# rpm — Relentless Project Manager

Prevents documentation drift and keeps you on task across LLM-assisted
development sessions. Available as a plugin for both Claude Code and
opencode.

## Getting started — Claude Code

**1. Install** (once per machine):

```
/plugin marketplace add https://github.com/dppdppd/rpm
/plugin install rpm@dppdppd-plugins
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

## License

MIT
