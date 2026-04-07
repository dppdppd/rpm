---
description: "Quick staleness dashboard — read-only, no fixes"
argument-hint: ""
allowed-tools: ["Read", "Bash(wc:*)", "Bash(grep:*)", "Bash(ls:*)", "Bash(find:*)", "Glob", "Grep"]
---

# Audit Light

Quick staleness dashboard. Read-only — no fixes, no agents.

For each doc in the project: verify path exists, check last-modified
date, scan for broken references. Also check:
- CLAUDE.md line count (warn >120, critical >150)
- Task tracker exists and has recent updates
- Any `NOT_IMPLEMENTED` stubs

Produce a table ordered by priority. If issues warrant deeper
investigation, suggest `/pm:audit` or `/pm:audit-heavy`.
