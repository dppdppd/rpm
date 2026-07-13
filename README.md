# rpm - Relentless Project Manager

rpm is an operational layer for LLM-assisted development.

It gives coding agents durable project state, session lifecycle hooks, a
repo-local backlog, drift checks, and reviewable handoffs.

## What rpm Does

rpm stores project memory in `docs/rpm/`:

- `context.md` records the project summary, key files, and review focus
- `present/status.md` records current phase, version, completed work, and open issues
- `future/tasks.org` records the durable project backlog
- `past/` records daily logs and session history
- `reviews/` stores audit findings and plans
- `research/` stores research artifacts

rpm starts each session with the state an agent needs:

- current git state
- recent commits
- active task or prior handoff
- open backlog items
- recent logs and learnings
- project-specific instructions

rpm also provides control loops:

- resumes active tasks from `~rpm-session-start`
- carries committed handoffs from the previous session
- checkpoints state before context compaction
- restores state after compaction
- captures high-signal learnings
- scans for documentation and instruction drift
- writes session-end handoffs for the next run

## Install

### Claude Code

Install once per machine:

```text
/plugins marketplace add https://github.com/dppdppd/rpm
/plugins install rpm@dppdppd-plugins
```

Initialize once per project:

```text
/init-rpm
```

### Codex

Install from a shell:

```bash
codex plugin marketplace add dppdppd/rpm@codex --enable hooks
```

Enable the plugin in `~/.codex/config.toml`:

```toml
[plugins."rpm@dppdppd-rpm"]
enabled = true
```

Enable hooks:

```toml
[features]
hooks = true
```

Run `$init-rpm` inside the project. Codex skills use `$skill-name`
invocation.

### opencode

From inside the project:

```bash
curl -fsSL https://raw.githubusercontent.com/dppdppd/rpm/opencode/install.sh | bash
```

Then run `/init-rpm`.

## Commands

- `/init-rpm` - scaffold `docs/rpm/` and project instructions
- `/session-end` - wrap up the current session and write the next handoff
- `/backlog` - add, list, review, postpone, or complete durable backlog tasks
- `/next` - run the next backlog item with rpm preflight checks
- `/audit quick` - deterministic drift scan, zero LLM tokens
- `/audit documents` - documentation and guidance review
- `/audit project` - full project review with research
- `/research` - structured research workflow with saved artifacts
- `/rpm ?` - command reference

## Published Surfaces

- Claude Code plugin: `plugin/`
- Codex port: `codex/`
- opencode port: `opencode/`

The detailed plugin README lives at [plugin/README.md](plugin/README.md).

## License

MIT
