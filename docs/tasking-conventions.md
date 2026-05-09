# tasks.org conventions for `/next` dispatch

These are the conventions every project's `tasks.org` should follow
so `/next` can survey, score, and dispatch reliably. Established
through observation of failure modes — see "Why these exist" at the
bottom for the specific bugs each convention prevents.

## Hierarchy

```
* Parent (tier / theme)        — has Goal: body line
** Task                        — has :ID: drawer + [[file:detail]] link
*** Sub-grouping (optional)    — e.g. "Recently DONE" archive sub-section
```

## Parent headings (`*`)

Every `*` parent must open with a `Goal:` body line stating the
measurable success metric for that tier or theme. Format:

```
* Tier 2 — Volta-Rendered Parity                          :parity:render:
  :PROPERTIES:
  :ORDERED: t
  :END:
  Goal: <one-sentence north-star>. Success: <measurable metrics>.
  <Optional: "current headline tier" / "blocked on X" qualifier.>
```

The `Goal:` line is the dispatch-time scoring surface. Every task
under this parent is evaluated against it during `/next`'s task
selection step.

## Task headings (`**`)

Every actionable `** TODO` or `** IN-PROGRESS` heading must have:

1. **`[[file:YYYY-MM-DD-slug.md]]` link** to a readable detail file
   under `docs/rpm/future/`. The detail file holds spec, scope,
   verification gates, and (eventually) the worker result.
2. **`:PROPERTIES: / :ID: <slug> / :END:` drawer.** The `:ID:` is
   the stable handle for `log-decision.sh` and worker dispatch
   tracking.
3. **Body content ≤ 3 lines** plus the drawer. Longer bodies move
   to the detail file. (See per-project `feedback_tasks_org_three_
   line_rule` memory for rationale.)

Optional drawer fields:
- `:BLOCKED_BY: <other-id>` — declares a dep edge in the DAG.
  `/next` walks `:BLOCKED_BY:` to skip blocked tasks.
- `:NEVER_DONE: t` — recurring/maintenance tasks that should never
  be marked DONE (e.g. triage queues).
- `:POSTPONED: YYYY-MM-DD` — explicit deferral stamp from
  `/backlog postpone`.

Tasks lacking `:ID:` or a detail-file link are **invisible to
`/next`** even if they're at the top of the file. This is intentional
— the strict gate forces tasks to be scoped before dispatch.

## Floating detail files

A detail file under `docs/rpm/future/` that no `tasks.org` entry
links to is a gap. Either:
- Add a `tasks.org` entry that links it, or
- Move it to `docs/rpm/future/done.org`, or
- Delete it.

`/next`'s gap-analysis step surfaces these as candidates for
filing.

## Recurring tasks

Recurring tasks (triage queues, audits) are normal `** TODO` entries
with `:NEVER_DONE: t`. They still need `:ID:` so `/next` can
dispatch by ID. Their detail file describes the periodic process
rather than a one-shot deliverable.

## DONE entries

When a task ships, change `** TODO` → `** DONE` and append a
2-line CLOSED note in the body:

```
** DONE <heading> [[file:detail.md]] :tags:
   :PROPERTIES:
   :ID: <slug>
   :END:
   CLOSED: YYYY-MM-DD commit <sha>. <one-line outcome>.
```

`/session-end` archives DONE entries to `done.org` periodically;
they don't live long-term in `tasks.org`.

## Why these exist

Each convention prevents a specific failure mode:

- **`Goal:` line on every `*` parent** — without it, `/next` collapses
  to "drain the visible queue" (the recurring/triage queue typically)
  and idles when that queue is empty, even when other tier goals have
  unaddressed critical-path items. Observed: 40+ consecutive idle ticks
  while real tier1/tier3 work was unscoped.
- **`:ID:` drawer required** — without IDs, `log-decision.sh`
  pairings break (orchestrator-tracked agent_id ≠ worker self-tag),
  reviews go unpaired, and the dashboard accumulates phantom
  in-flight workers.
- **Detail file required** — without scope, workers guess. Observed:
  workers writing `## Plan` instead of `## Worker Result` because
  the task body was 3 sentences of context with no acceptance
  criteria.
- **Floating detail files surface as gaps** — because workflows
  often draft a scope doc before filing the backlog entry, and
  the entry then never gets filed. Observed: 5 floating tier3
  detail files referenced from a README but absent from
  `tasks.org`, blocking saturation for hours.
