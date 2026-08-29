# rpm - Relentless Project Manager

rpm is an operational layer for LLM-assisted development.

It gives coding agents durable project state, session lifecycle hooks, a
repo-local backlog, drift checks, and reviewable handoffs.

## What rpm Does

### Stores Durable Project Memory

rpm writes project memory into `docs/rpm/` as plain text files that can be
reviewed, diffed, and committed.

| File | Meaning |
|------|---------|
| `docs/rpm/context.md` | Project summary, key files, and review focus |
| `docs/rpm/present/status.md` | Current phase, version, completed work, and open issues |
| `docs/rpm/future/tasks.org` | Durable project backlog |
| `docs/rpm/past/` | Daily logs and session history |
| `docs/rpm/reviews/` | Audit findings and plans |
| `docs/rpm/research/` | Research artifacts |

### Starts Sessions With Context

Session-start hooks load the state an agent needs:

- current git state
- recent commits
- active task or prior handoff
- open backlog items
- project status
- recent logs and learnings
- project-specific instructions

When rpm has an active marker, it resumes the marked task. When rpm has a
committed handoff from the previous session, it starts from that handoff. When
task selection is open, it shows the durable backlog menu.

### Runs A Session Lifecycle

rpm gives each session a lifecycle:

- start with context
- work from a durable task
- capture high-signal learnings
- checkpoint before compaction
- restore after compaction
- reconcile native task events
- wrap up with `/session-end`
- write the next handoff

### Controls Drift

rpm checks the project surfaces that drift during agent work:

- README, CLAUDE.md, AGENTS.md, and skill instructions
- backlogged tasks and task dependencies
- session handoffs
- project status
- documentation references
- contradictions between docs and implementation

`/audit quick` runs deterministic checks. `/audit documents` runs a semantic
documentation review. `/audit project` runs a broader project review and saves
a plan.

### Writes An Audit Trail

rpm turns agent work into repo artifacts:

- selected task
- completed work
- learnings
- open risks
- verification results
- next step

The trail lives in plain text under `docs/rpm/`.

### Works Across Runtimes

rpm ships for Claude Code, Codex, and opencode. Each port uses the hooks and
task surfaces that runtime exposes, while the project state stays in the repo.

## Install

### Claude Code

Install once per machine:

```text
/plugins marketplace add https://github.com/dppdppd/rpm
/plugins install rpm@dppdppd-plugins
```

For local development against a checkout:

```bash
claude --plugin-dir /path/to/rpm
```

Initialize once inside the project:

```text
/init-rpm
```

`/init-rpm` scans the codebase, asks setup questions, scaffolds `docs/rpm/`,
and creates or updates project instructions. Hooks activate immediately.

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

From inside the project directory:

```bash
curl -fsSL https://raw.githubusercontent.com/dppdppd/rpm/opencode/install.sh | bash
```

Then run:

```text
/init-rpm
```

## Daily Workflow

### First Run

Run `/init-rpm`. rpm creates the project state under `docs/rpm/` and wires the
session hooks.

### Start A Session

Start the agent normally. rpm injects current project state, current task,
recent commits, backlog items, and handoff instructions.

### Work Mid-Session

Use `/backlog` for durable project tasks. Use `Key finding:` for learnings that
should be captured. rpm checkpoints state around compaction and records native
task events for reconciliation.

### End A Session

Run:

```text
/session-end
```

rpm updates the daily log, present state, backlog, native-task reconciliation,
and next handoff.

## Commands

### `/init-rpm`

Scans the project, creates `docs/rpm/`, and patches the project instruction
file so future sessions can find rpm state.

### `/session-end`

Wraps up the current session. Updates past, present, and future trackers;
records learnings; reconciles native tasks; and writes the next handoff.

### `/backlog`

Manages the durable rpm backlog in `docs/rpm/future/tasks.org`. Add, list,
review, postpone, or mark entries done.

### `/next`

Runs rpm's task-selection loop. It performs preflight checks, reviews completed
worker results, then starts the next actionable backlog item. It also supports
bounded sequences such as `/next 3`, `/next all`, and `/next <group>`.

### `/audit quick`

Fast deterministic scan. Uses zero LLM tokens. Checks common mechanical drift:
git state, tracker gaps, broken references, task dependency issues, and
bookkeeping.

### `/audit documents`

LLM-assisted documentation audit. Looks for stale docs, contradictions, missing
updates, and instruction drift.

### `/audit project`

Full project review. Reads the codebase and docs, uses external research when
needed, and writes a review plus plan file.

### `/research`

Structured research workflow for external facts, comparison, source gathering,
and adversarial validation. Saves artifacts under `docs/rpm/research/`.

### `/rpm ?`

Quick command reference.

## Example Session Start

Backlog selection:

```text
rpm: session active (rpm 2.31.0)

=== git ===
modified=1 untracked=0 staged=0 stashes=0

=== backlog_menu ===
Your rpm backlog:

Active
   1. Add API rate-limit middleware
      detail: future/2026-07-13-rate-limit.md
   2. Fix stale deployment docs

S: something else
R: review tasks

Pick #, #? for details, S, or R.
```

Active-task resume:

```text
rpm: resuming - add API rate-limit middleware (rpm 2.31.0)

An rpm session marker is present - unfinished work on this task.
Treat that task as already selected.
```

## Hooks

| Hook | What it does |
|------|-------------|
| `SessionStart` | Loads project state, git state, backlog, handoffs, and current task |
| `SessionEnd` | Detects sessions that exited before `/session-end` and stubs recovery state |
| `Stop` | Captures learning signals and validates handoff completeness |
| `PostToolUse` | Watches transcript token pressure and review-ready worker results |
| `PreCompact` | Checkpoints state before compaction |
| `PostCompact` | Re-injects state after compaction |
| `TaskCreated` | Persists native task creation events |
| `TaskCompleted` | Persists native task completion events for backlog reconciliation |

Claude Code exposes the full lifecycle. Codex and opencode use each runtime's
supported subset.

## Configuration

Set the context window size used by the PostToolUse monitor. The default is a
1M-token window; override it for smaller model contexts:

```bash
export RPM_CONTEXT_TOKENS=200000
```

## Repository Layout

| Path | Meaning |
|------|---------|
| `plugin/` | Claude Code plugin source |
| `codex/` | Codex port generated from `plugin/` plus overlays |
| `opencode/` | opencode port and installer |
| `docs/rpm/` | This repo's own rpm state |
| `scripts/sync-codex.sh` | Regenerates the Codex port |
| `scripts/sync-opencode.sh` | Regenerates opencode mirrors |
| `scripts/publish-all.sh` | Publishes Claude, Codex, opencode, and version tag |

## License

MIT
