# Phase 3 retry / fallback hardening

**Filed:** 2026-04-28
**Source:** `research/managed-agents-scoping/decision.md` — flagged as
"worth borrowing if observed in practice" while evaluating Anthropic
Managed Agents.

## Context

The deep-research skill's Phase 3 (URL fetching) currently has minimal
retry logic:

```
6. On failure, retry curl ONCE with a longer timeout (`-m 120`).
   For arxiv URLs specifically, try the `/abs/` URL if `/html/`
   fails, or vice versa. Also try `https://arxiv.org/pdf/ID`
   as a last resort.
   If ALL attempts fail, record in progress.md and **pick the
   next URL from the priority list as a replacement**
```

This handles single URL failure but degrades silently on
infrastructure-level failures (rate limits, regional blocking,
batch-wide timeouts). Anthropic Managed Agents bakes in stronger
retry/fallback as a meta-harness feature; we don't want to migrate
to that runtime, but the *patterns* are worth borrowing if a real
need surfaces.

## Trigger to actually do this

Re-prioritize only when a deep-research run hits one of:

1. **Rate-limit cascade** — multiple curls returning HTTP 429 in
   sequence, current single-retry doesn't recover.
2. **Cloudflare / bot-blocking on a domain** — every URL from one
   source (e.g., a specific journal site) returns 403/503; current
   priority-list replacement may exhaust before finding a working
   alternative.
3. **Batch-wide timeout** — most URLs in a parallel curl batch fail
   together (network blip), current logic treats each independently
   and burns retry budget on a transient cause.

## What the hardened version would add

- **Exponential backoff for HTTP 429**: detect status, sleep with
  jitter, retry up to 3 times before falling through.
- **Per-domain failure threshold**: if N consecutive URLs from a
  single domain fail, skip remaining URLs from that domain and add
  a domain-level note to `progress.md`. Avoids burning budget on a
  blocked source.
- **Batch-wide failure detection**: if more than half of a parallel
  curl batch fails, treat as a network event — pause 30 s before
  retrying the failed half, don't retry individually.
- **Optional**: surface a `/deep-research --resume-fetches` flow if
  partial-fetch state is the common reason runs are halted.

Not a hook — these are bash refinements inside the skill body's
fetch-and-sanitize section, plus a small awk/jq parser for response
codes.

## Why deferred

Hasn't been observed in practice as of 2026-04-28. The current
single-retry + priority-list-replacement is good enough for the
~12 URL fetches in a typical Deep run. Filing now so we don't
re-derive the design when it matters.
