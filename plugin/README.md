# rpm - Relentless Project Manager

rpm is an operational layer for LLM-assisted engineering work.

It does not make the model smarter. It makes the work more resumable,
auditable, and harder to lose between chat sessions, context compaction,
model changes, and agent runtimes.

For an engineer who already understands ML systems: rpm is experiment tracking
plus a runbook plus a task queue for coding agents. The model remains a
stateless predictor with a large context window. rpm supplies the durable state,
workflow boundaries, and verification pressure that software projects need
around that predictor.

## The Problem

LLM coding agents are good at local reasoning inside the context they can see.
Software projects are not local.

Real projects span:

- days or weeks of work
- interrupted sessions
- commits made outside the current chat
- documentation that can drift from implementation
- task queues that outlive a single model run
- multiple agent runtimes with different memory surfaces

Without an external state layer, every new session has to infer the work from a
partial transcript. That produces familiar failures: repeated orientation,
stale plans, "done" claims with no durable evidence, lost findings, and
handoffs that ask the user what to do even when the next step was already
known.

rpm exists to make agent work stateful at the project level.

## What rpm Provides

### Durable Project Memory

rpm writes project memory into the repository, under `docs/rpm/`, using plain
text files that can be reviewed, diffed, and committed.

Core files:

| File | Meaning |
|------|---------|
| `docs/rpm/context.md` | Stable project summary, key files, and review focus |
| `docs/rpm/present/status.md` | Current phase, version, completed work, known issues |
| `docs/rpm/future/tasks.org` | Long-term backlog, separate from native task UI |
| `docs/rpm/past/` | Daily logs and session records |
| `docs/rpm/reviews/` | Saved audit plans and findings |
| `docs/rpm/research/` | Saved research artifacts when the research skill is used |

The important distinction is that rpm's backlog is durable project state.
Claude's native task list, Codex task state, or another runtime's planning UI is
session state. rpm keeps those concepts separate.

### Session Lifecycle

rpm hooks give each session a lifecycle:

- Session start loads git state, recent commits, current task, backlog, and any
  handoff from the prior session.
- During the session, hooks capture high-signal learnings and watch for context
  pressure.
- Before compaction, rpm checkpoints the current task and open state.
- After compaction, rpm restores that state.
- Session end updates the daily log, status, backlog, and next handoff.
- If a session exits without `/session-end`, rpm leaves enough state for the
  next session to recover.

The goal is not ceremony. The goal is that an agent can resume work as an
engineering workflow instead of guessing from a chat transcript.

### Drift Control

rpm checks for the kind of drift that tests usually do not catch:

- README, CLAUDE.md, AGENTS.md, or skill instructions describing files that
  moved or commands that changed
- backlog items that no longer match the actual state of the repo
- session handoffs that failed to record what happened
- project status that lags behind commits
- documentation that contradicts implementation

There are fast deterministic checks and deeper LLM-assisted audit modes. The
deterministic checks are cheap and mechanical; the LLM-assisted modes are for
semantic review.

### Audit Trail

rpm turns agent work into repo artifacts:

- what task was selected
- what changed
- what was learned
- what was left open
- what got verified
- what should happen next

That makes agent output inspectable by another engineer without requiring them
to read the entire chat.

### Runtime Portability

rpm ships for Claude Code, Codex, and opencode. The ports differ because each
runtime exposes different hooks and task primitives, but the underlying project
state stays in the repository.

This matters because the model and runtime will change. The project memory
should not be trapped in one vendor's conversation state.

## Mental Model

rpm is not a better model and not a replacement for tests.

It is the missing control plane around LLM-assisted engineering:

- **External memory:** durable repo-local state instead of chat-only memory
- **Run lifecycle:** start, checkpoint, resume, compact, end
- **Task semantics:** long-term backlog separated from session-local tasks
- **Drift detection:** docs, instructions, status, and code kept aligned
- **Reviewability:** decisions and handoffs saved as text artifacts

One-line pitch:

> rpm makes LLM coding agents less like clever chat sessions and more like
> resumable, auditable engineering workers.

## Getting Started

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

Initialize once inside the project you want to track:

```text
/init-rpm
```

`/init-rpm` scans the codebase, asks a few clarifying questions, scaffolds
`docs/rpm/`, and creates or updates project instructions. Hooks activate
immediately.

Requirements: [Claude Code](https://docs.anthropic.com/en/docs/claude-code).
The plugin itself is markdown and bash.

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

Enable hooks if needed:

```toml
[features]
hooks = true
```

Then run `$init-rpm` inside the project. Codex skills use `$skill-name`
invocation rather than slash commands.

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

Start the agent normally. rpm injects context at session start:

- current git state
- recent commits
- current or previous task
- open backlog items
- project status
- recent session notes
- instructions for how to continue

If rpm already knows the in-flight task, it tells the agent to continue it. If
there is a committed handoff from the prior session, it treats that handoff as
selected. If there is no active task, it shows the backlog menu.

### Work Mid-Session

Use `/backlog` for durable project tasks. Native task UIs remain session-local.

When a high-signal learning appears, prefix it with `Key finding:` so rpm can
capture it. When context gets tight or compaction happens, rpm checkpoints and
restores the session state.

### End A Session

Run:

```text
/session-end
```

rpm updates the daily log, present state, backlog, native-task reconciliation,
and next handoff. Clean sessions get a short wrap-up. Messier sessions get
more structure.

## Commands

### `/init-rpm`

One-time project setup. Scans the project, creates `docs/rpm/`, and patches the
project instruction file so future sessions can find rpm state.

### `/session-end`

Wraps up the current session. Updates past, present, and future trackers;
records learnings; reconciles native tasks; and writes the next handoff.

### `/backlog`

Manages the durable rpm backlog in `docs/rpm/future/tasks.org`. Add, list,
review, postpone, or mark entries done. Use this for long-term project work,
not the model's session-local task list.

### `/next`

Runs rpm's "what should I do next?" loop. It performs preflight checks, reviews
completed worker results when present, then starts the next actionable backlog
item. It can also run bounded sequences such as `/next 3`, `/next all`, or
`/next <group>`.

### `/audit quick`

Fast deterministic scan. No LLM tokens. Checks common mechanical drift:
git state, tracker gaps, broken references, task dependency issues, and related
bookkeeping.

### `/audit documents`

LLM-assisted documentation audit. Looks for stale docs, contradictions, missing
updates, and instruction drift.

### `/audit project`

Full project review. Reads the codebase and docs, uses external research when
needed, and writes a review plus plan file.

### `/research`

Structured research workflow. Useful when a task depends on external facts,
comparison, source gathering, or adversarial validation. Saves artifacts under
`docs/rpm/research/`.

### `/rpm ?`

Quick command reference.

## Example Session Start

When there is no active committed handoff, rpm shows the durable backlog:

```text
rpm: session active (rpm 2.30.1)

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

When there is an active marker, rpm resumes instead of asking whether to
continue:

```text
rpm: resuming - add API rate-limit middleware (rpm 2.30.1)

An rpm session marker is present - unfinished work on this task.
Treat that task as already selected. Do NOT ask whether to continue it.
```

## Hooks

| Hook | What it does |
|------|-------------|
| `SessionStart` | Loads project state, git state, backlog, handoffs, and current task |
| `SessionEnd` | Detects sessions that exited without `/session-end` and stubs recovery state |
| `Stop` | Captures learning signals and validates handoff completeness |
| `PostToolUse` | Watches transcript token pressure and review-ready worker results |
| `PreCompact` | Checkpoints state before compaction |
| `PostCompact` | Re-injects state after compaction |
| `TaskCreated` | Persists native task creation events |
| `TaskCompleted` | Persists native task completion events for backlog reconciliation |

Runtime support varies. Claude Code exposes the full lifecycle. Codex and
opencode ports use the subset each runtime supports.

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
