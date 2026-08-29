# Handoff-doc feature for session-end

Researched 2026-08-28. Goal: session-end should leave behind a real
handoff *document* a cold agent can read, not only the three-line
`~rpm-last-session` pointer.

## Prior art surveyed

| Project | Shape | What it does well |
|---|---|---|
| [REMvisual/claude-handoff](https://github.com/REMvisual/claude-handoff) | skill + optional PreCompact hook | `plans/handoffs/HANDOFF_<task>_<date>.md`; sections: Goal / Where We Are / What We Tried / Key Decisions / Evidence & Data / User Feedback / Where We're Going / Quick Start. Auto-detects prior handoffs on the same work stream and chain-links with sequence numbers. Calls "What We Tried" the highest-value section — failed approaches are the most expensive thing to rediscover. |
| [thepushkarp/handoff](https://github.com/thepushkarp/handoff) | plugin, 3 hooks | PreCompact appends to `docs/handoff/HANDOFF.md`; SessionStart(compact) re-injects the latest entry; Stop hook blocks (up to 3 attempts) until the model fills `Model Summary` (8–12 bullets) and `Handoff Context` (pasteable resume prompt). Entry fields: Current Task State, Key Decisions, Modified Files, Blockers/Open Questions, Next Steps, Critical Context. |
| [who96/claude-code-context-handoff](https://github.com/who96/claude-code-context-handoff) | pure-hook, no LLM | PreCompact + SessionEnd(clear) capture last 15 user messages (deduped at 85%) and 10 assistant snippets plus file paths from tool inputs; SessionStart(compact\|clear) restores as `additionalContext`. Stored at `~/.claude/handoff/<session_id>.md` with a `latest-handoff` pointer guarded by cwd match and a 900s max age. |
| [softaworks/agent-toolkit session-handoff](https://github.com/softaworks/agent-toolkit/blob/main/skills/session-handoff/SKILL.md) | skill, CREATE + RESUME modes | `.claude/handoffs/YYYY-MM-DD-HHMMSS-<slug>.md`. Sections: Current State Summary, Important Context, Immediate Next Steps, Decisions Made (with rationale), Critical Files, Key Patterns Discovered, Potential Gotchas, Pending Work. Validates completeness and secrets with a quality score, threshold 70. RESUME mode checks staleness against recent commits and verifies the project still matches the document's assumptions. |
| [ykdojo/claude-code-tips handoff](https://github.com/ykdojo/claude-code-tips/blob/main/skills/handoff/SKILL.md) | minimal skill | Single `HANDOFF.md` at repo root, read-then-update. Goal / Current Progress / What Worked / What Didn't Work / Next Steps. |
| [Matt Pocock's /handoff](https://www.aihero.dev/skills-handoff) | skill | Framing: handoff is *portability*, not compression. Use it when work moves — different harness (Claude → Codex), different repo, another person, a forked parallel task. Same harness and directory, `/compact` is still better. The file references specs and diffs by path rather than copying them, suggests skills for the receiving agent, and redacts secrets. |

## What rpm already covers

- PreCompact checkpoint (`plugin/hooks/pre-compact.sh`) — git state, open
  tasks, learnings excerpts, daily-log entry.
- SessionStart injection of context, status, backlog and the previous
  session's `next:`.
- Learnings capture (`stop-learn-capture.sh`) and the "Key finding:" convention.
- A disciplined `What's next` resolution rule in session-end.
- `handoff-validator.sh` Stop hook — structural check after the session-end commit.

## The gap

`~rpm-last-session` carries `task` / `ended` / `next`. That is a pointer,
not a handoff. Nothing durable records what was tried and abandoned, why
decisions went the way they did, which files matter, or what will bite the
next agent. The daily log holds fragments of this, unstructured.

## Proposed shape (draft)

1. Session-end Phase 4 writes `docs/rpm/past/handoff/<YYYY-MM-DD-HHMM>-<slug>.md`.
2. Sections, ordered for a cold reader: Goal · Where We Are · What We Tried
   (and what failed) · Decisions & Rationale · Critical Files · Gotchas ·
   Where We're Going · Quick Start.
3. `~rpm-last-session` gains a `handoff:` line pointing at the file;
   SessionStart surfaces the path and injects the tried/failed and
   next-step sections.
4. Chain-link: if the previous handoff shares the work stream, record
   `continues-from:` and a sequence number.
5. Extend `handoff-validator.sh` to check the document exists and has no
   unfilled placeholders.
6. Keep it cheap for small sessions — Express mode should emit a short
   handoff or none at all, not the full document.

## Decisions (2026-08-28)

- **Separate file, not a fatter `past/<date>.md`.** The daily log is the
  append-only record of what happened; the handoff is a forward-looking
  document for the next agent. Keeping them apart means the handoff can be
  skipped outright when a session pivots away from what it started on, and
  a stale or irrelevant handoff can be ignored without losing the log.
- **The handoff is an offer, never a mandate.** Same principle applied to
  resume: see below.

## Related: resume was too aggressive (fixed 2026-08-28)

`session-start-auto.sh` told the model to state the handed-off step as a
fact and start working on it, with no allowance for the user opening the
session with a different request. It misfired live — a session started
with a research request and the hook still directed the model to announce
and begin a parked backlog item.

Both directive blocks (the active-marker resume path and the
`~rpm-last-session` handoff path) now say the same thing: the prior task
is the default plan, not a command, and the user's first message outranks
it. If the opening message asks for something else, drop the handoff
silently — no announcement, no "want to switch?", no "shall we return to
it later?" — and set the marker's `task:` field to the new work. Only when
the opening message carries no direction of its own does the old
no-confirmation resume behaviour apply, unchanged.

The handoff document must inherit this: session-end should not write one
when the session pivoted away from its starting task with nothing worth
carrying forward, and session start must not push one that the user's
opening message has already superseded.

## Scope (2026-08-28)

One forward-looking briefing per work stream, written at session-end, for
an agent starting cold. Seven sections:

1. **Goal** — what this work stream is trying to achieve.
2. **Where we are** — current state, one paragraph.
3. **What we tried that didn't work** — the one thing nothing else in rpm records.
4. **Decisions and why** — rationale, not just the outcome.
5. **Critical files** — paths, one clause each on why they matter.
6. **Gotchas** — what will bite the next agent.
7. **Next step** — the resolved `What's next` verbatim, plus a quick-start line.

Explicitly out of scope:

- Not a record of what happened — `past/<date>.md` keeps that, append-only.
- Not an exhaustive transcript reconstruction — that is what compaction does.
- No copied specs, plans, or diffs — reference them by path.
- Not written when the session pivoted away leaving nothing to carry.
- Not written for a trivial Express-mode session.
- No secrets.

### Length

**No line cap on the document.** Measured 2026-08-28: `future/` detail
files run 118–607 lines (median ~150) and daily logs 238–411. A cap in
that neighbourhood would be arbitrary, and a *total*-length cap forces the
wrong cut — the first thing trimmed would be the dead ends, the one thing
nothing else in rpm records.

rpm has exactly one document with a hard cap, `context.md` at 30 lines,
and it earns that cap by being injected verbatim at every session start.
The budget belongs on the **injected** part, not on the document. Session
start already emits ~155 lines; whatever it pulls from the handoff
competes with that, so keep it to a handful of lines — the path, the
next step, and the dead-end list.

Length is governed by per-section discipline instead of a total: goal in
one or two sentences, state in one paragraph, then one entry per dead end,
one per decision with its reasoning, one line per critical file, one line
per gotcha. That is self-limiting in the right direction — a small session
yields a short handoff because there were few dead ends, not because a cap
truncated it.

The acceptance test is not length: **could a cold agent start work from
this without opening the transcript?** If yes, it is the right size.

Signal, not rule: a handoff rivalling a daily log in size usually means
the work needed a spec. Link one rather than absorbing it.

Lifecycle: written in session-end Phase 4 (skippable) → stored at
`past/handoff/<YYYY-MM-DD-HHMM>-<slug>.md` → `~rpm-last-session` gains a
`handoff:` line → SessionStart injects the path plus the "didn't work" and
"next step" sections, full document read on demand → `continues-from:`
when the next session stays on the stream → dropped silently when the
user's opening message goes elsewhere.

## Can it use native compaction? (checked 2026-08-28)

**No, it cannot invoke it. Yes, it can harvest it.**

Verified facts:

- There is no compaction *skill*. `/compact` is a built-in command.
- Only the user can fire it (or auto-compact when context fills). No hook,
  skill, or tool can, and the model can only suggest it. So session-end
  cannot call compaction to produce the handoff.
- The *output* is durable and readable. It lands in the session transcript
  (`~/.claude/projects/<slug>/<session_id>.jsonl`) as a `user` entry with
  `isCompactSummary: true`, preceded by a `system` entry with
  `subtype: compact_boundary` carrying `trigger`, `preTokens`, `postTokens`.
  Measured on a real transcript: 12–14k characters per summary. Every hook
  receives `transcript_path`, so rpm can read it.

Three reasons the compaction summary must not simply *be* the handoff:

1. **Wrong shape.** It is backward-looking and exhaustive — its job is to
   let the *same* session continue. Template: Primary Request and Intent /
   Key Technical Concepts / Files and Code Sections / Errors and fixes. A
   handoff is forward-looking and selective.
2. **Not guaranteed to exist.** Short sessions never compact.
3. **Too big and unedited.** 12–14k characters, no redaction, full of tool
   noise and scratchpad paths.

Design: **harvest, don't delegate.** Session-end reads `transcript_path`,
extracts any `isCompactSummary` entries, and offers them to the model as
raw material for writing the handoff, alongside rpm's own learnings, git
state, and daily log. When a session compacted several times this is the
cheapest recovery of the early part of the session that has otherwise
fallen out of context. `pre-compact.sh` runs *before* compaction so it
never sees the summary — a small session-end script reads it after the fact.


## Goal restated (2026-08-28) — compete with compaction

The bar is not "a forward-looking briefing." It is: **after `/clear`, a
cold agent reading this handoff should be no worse off than one resuming
from a compaction summary.** That invalidates the Pocock split used
earlier in this document (compaction compresses, handoff carries forward)
— that framing licensed dropping things compaction keeps.

### What compaction actually preserves

Nine sections, read off a real summary:
Primary Request and Intent · Key Technical Concepts · Files and Code
Sections · Errors and fixes · Problem Solving · All user messages ·
Pending Tasks · Current Work · Optional Next Step.

The earlier seven-section scope covered about four of these. Missing: the
sequence of intent, in-session technical concepts, problem solving, the
verbatim user messages, and pending tasks.

### The measurement that decides the design

On a 3,159-line transcript spanning 400k+ tokens and two compactions, the
**48 real user messages total 2,975 characters.** The complete verbatim
record of what was asked fits in under 3KB and comes out with one `jq`
filter.

Compaction *paraphrases* intent. The handoff can *quote* it, losslessly,
for free — beating compaction on that section rather than matching it.

### Structure: split by who writes it

**Mechanical (a script, zero tokens):**
- every user message verbatim, in order
- files touched, with diff stats; commits made
- any `isCompactSummary` entries the session already produced
- rpm's captured learnings (`~rpm-learnings.jsonl`), native task deltas

**Model-written (judgment only):**
- what was tried and abandoned, and why
- decisions and reasoning
- domain facts established in-session that a cold agent would re-derive wrong
- gotchas
- exactly where things stand, work in flight
- next step (the already-resolved `What's next`)

### The asymmetry to design around

Compaction runs with the whole window in view and spends 100+ seconds on
it. Session-end's model works from a context that may already have lost
the early session. **Reading the transcript from disk is therefore
load-bearing, not optional** — without it session-end can only summarize
what it still remembers, which is strictly worse than compaction. With it,
the handoff has a better source than compaction had.

### Length, settled

Benchmark = the compaction summary, measured at 12–14k characters. That is
what the handoff must match to substitute for one. ~3k of it is free
(verbatim user messages). This supersedes the "no cap" reasoning above:
there is still no arbitrary cap, but there is now a real target.

## Cost: does this pay for the session twice? (measured 2026-08-28)

Only if written carelessly. "Read the transcript" must mean three narrow
slices, never the bulk. Measured on a 1.77M-token transcript:

| Slice | ~tokens | share |
|---|---|---|
| Full transcript | 1,766,000 | 100% |
| User turns, verbatim (46 msgs) | 730 | 0.04% |
| Compaction summaries already on disk | 6,680 | 0.38% |
| Unique file paths touched | 850 | 0.05% |
| **All three** | **8,260** | **0.47%** |

The 99.5% that *would* be double-payment is tool output. Never read it.

Caution on the filter: task notifications, `<output-file>` blocks and
local command stdout also arrive as `type=="user"` entries. Counting them
inflates "user speech" from 2,917 bytes to 75,638. Filter whole messages
whose content starts with `<`.

**The stronger argument:** the model writing the handoff still has the
session in context. It needs to re-read only what it *lost*.

- Never compacted → nothing lost. Pull only the verbatim user turns (730
  tokens), bought for exact quotes rather than paraphrase. Everything else
  is written from context, already paid for.
- Did compact → the lost stretch already has a summary on disk, already
  paid for once. Read that, not the raw material behind it.

Neither path summarizes anything twice.

**The real cost is output**, not input: ~3–4k output tokens to write a
12–14k character handoff. Unavoidable, and it is the price of the feature.
Compaction costs the same order and charges again every time context
fills; the handoff is paid once and survives `/clear`.

Two inputs are already free: `stop-learn-capture.sh` captures findings as
the session runs, and `pre-compact.sh` checkpoints git state.

## What the goal actually is (2026-08-28, corrects everything above)

**A compaction summary is useful because it reconstructs working memory,
not because it records events.** Re-reading a real one, the load-bearing
content was: "LOW card wins, lowest trump beats lowest led-suit"; "rank is
inverted-dual — actions *and* trick strength"; "seed-overlap footgun: game
*i* uses `base_seed + i`"; "`GameState.clone()` is hand-rolled, ~2x
faster"; "shadowing bug, pre-existing: local `board` overwrote the `board`
parameter." None of that is a record of what happened. It is what the
model came to *understand*.

**Goal, stated properly: the next agent should be able to make the next
correct decision without re-deriving what this session derived.** That is
a competence test, not a completeness test.

### Why both earlier section lists were wrong

The original seven and the "mirror compaction's nine" were both organised
around *events* — asked, tried, decided, changed. Compaction's headings
only look event-shaped from outside; the content inside them is
knowledge-shaped. "Files and Code Sections" is not a path list, it is what
each component now *is*. "Key Technical Concepts" has no event content at all.

### What belongs in it

1. What we now know about this problem that is **not recoverable from the
   code** — invariants, domain rules, why things are as they are.
2. What the code now does, as a **mental model**, not a diff.
3. What has been **ruled out**, and why — the eliminated search space.
4. What we **believe but have not verified**.
5. **Traps** — footguns, wrong-looking-but-correct code, pre-existing bugs found.
6. Where we are, and the next step.

### Consequence for the cost analysis above

Working knowledge lives only in the model's context. There is no `jq`
filter for it — which is exactly why compaction spends 100+ seconds and
real output tokens. **The extraction slices are garnish; the expensive
model-written part is the entire product.** This cannot be made cheap.
Trying to would produce a session diary.

User prompts fold in only where they carry standing intent recorded
nowhere else — a refusal, an imposed constraint, a stated preference. Real,
but small, and not the substance. The earlier enthusiasm for them was
driven by their extraction cost (730 tokens), not by their value.


## Outcome (2026-08-28): feature NOT built — three smaller fixes instead

The handoff document was designed in full and then dropped. Compaction
already produces a good knowledge-shaped summary; writing a second one
would duplicate a working capability at real output-token cost. Its only
genuine edge was surviving `/clear` — and that is fixable directly.

What shipped instead:

1. **`context-monitor.sh` stopped giving the wrong advice.** Below 10% of
   the window it used to say "consider /session-end". Low context means
   *make room*, not *stop*. It now names both tools and says which fits
   which situation.
2. **`session-end` gained a Closing Direction.** The ceremony still runs
   either way — its document auditing (tracker updates, drift, guidance
   alignment, backlog reconciliation) is valuable regardless. What changed
   is the ending: continuing → `/compact`, done → `/clear`, ordered by
   what the session actually indicates. It no longer assumes `/clear`.
3. **`post-compact.sh` files the summary where it survives a clear.** The
   hook already receives `compact_summary` on stdin. It now writes it to
   `docs/rpm/past/compact/YYYY-MM-DD-HHMM.md` and links it from the daily
   log — zero model tokens, since the text already exists.

Together these close the actual gap. A compacting user keeps the thread
and loses nothing. A clearing user gets the summary as a committed file
rather than something buried in a transcript.

The research above stays on record: the prior-art survey, the measured
cost table, the transcript-extraction mechanics, and the finding that a
compaction summary is a cache of understanding rather than a record of
events. If the handoff document is ever revisited, that is the starting
point — but it should have to justify itself against compaction, which it
did not this time.
