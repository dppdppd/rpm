# rpm - Relentless Project Manager

rpm is an operational layer for LLM-assisted engineering work.

It does not make the model smarter. It makes the work more resumable,
auditable, and harder to lose between chat sessions, context compaction,
model changes, and agent runtimes.

If you know ML systems, the closest analogy is experiment tracking plus a
runbook plus a task queue for coding agents. The model is still the model;
rpm supplies durable state, lifecycle hooks, and verification pressure around
it.

## Why It Exists

LLM coding agents are good at local reasoning inside a context window. Software
projects are not local. They need continuity across days, commits, interrupted
sessions, tool restarts, and different model surfaces.

rpm keeps that continuity in the repository:

- what the project is
- what just changed
- what is currently in flight
- what should happen next
- what the agent learned
- where docs, plans, or handoffs drifted from reality

The result is less re-explaining, fewer lost handoffs, and a more inspectable
trail of agent work.

## What rpm Adds

### Durable Project State

rpm writes project memory into `docs/rpm/` instead of relying on chat history.
The important files are plain text and reviewable:

- `context.md` - stable project summary and key files
- `present/status.md` - current phase, version, completed work, known issues
- `future/tasks.org` - long-term backlog, separate from the model's native task UI
- `past/` - daily logs and session records
- `reviews/` and `research/` - audit and research artifacts when used

### Session Lifecycle

Session-start hooks inject the current task, git state, recent commits, backlog,
and handoff notes. Session-end writes a compact handoff for the next run. If a
session dies without wrapping up, rpm leaves enough state for the next agent to
recover.

This is the main value: an agent can resume the work as a workflow, not as a
guess from a transcript.

### Drift Control

rpm has cheap mechanical scans and deeper audit modes that look for stale docs,
broken references, unfinished handoffs, and contradictions between instructions
and code.

This is not meant to replace tests. It catches the failure class where the code,
docs, task list, and agent instructions stop describing the same project.

### Runtime Portability

The same repo state supports Claude Code, Codex, and opencode ports. The model
surface can change while the project memory remains local, textual, and under
version control.

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

Codex hooks also need hooks enabled:

```toml
[features]
hooks = true
```

Then run `$init-rpm` inside the project. Codex uses `$skill-name` invocation
rather than slash commands.

### opencode

From inside the project:

```bash
curl -fsSL https://raw.githubusercontent.com/dppdppd/rpm/opencode/install.sh | bash
```

Then run `/init-rpm`.

## Main Commands

- `/init-rpm` - scaffold `docs/rpm/` and project instructions
- `/session-end` - wrap up the current session and write the next handoff
- `/backlog` - add, list, review, postpone, or complete long-term tasks
- `/next` - run the next backlog item with rpm preflight checks
- `/audit quick` - deterministic drift scan, no LLM tokens
- `/audit documents` - deeper documentation and guidance review
- `/audit project` - full consultant-style review with research
- `/research` - structured research workflow with saved artifacts

## Published Surfaces

- Claude Code plugin: `plugin/`
- Codex port: `codex/`
- opencode port: `opencode/`

The detailed user-facing README for the plugin lives at
[plugin/README.md](plugin/README.md).

## License

MIT
