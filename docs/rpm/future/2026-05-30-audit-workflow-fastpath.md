# Tier 4 — CC-only Workflow fast path for /audit project mode (spike)

Source: 2026-05-30 rpm-vs-ultracode-mode evaluation.
**Deferred — do after Tier 1–3 land.**

## Context
`/audit` project mode is multi-dimension and maps cleanly onto the
Workflow "review" pattern: fan-out dimensions → adversarially verify each
finding → synthesize → dedupe. It is lower-stakes than deep-research (no
untrusted-fetch injection surface; internal docs only). Today it uses a
single `rpm:auditor` agent — no fan-out.

## Action steps (spike)
1. Prototype a Workflow script: parallel dimension-scanners (schema'd
   findings) → adversarial verify each finding → synthesize → dedupe.
2. Gate behind CC + Workflow availability; the single-`auditor` prose path
   stays the portable fallback (opencode/codex).
3. Compare findings quality + token cost vs the current single-auditor run.

## Constraints
- CC-only fast path, never the foundation. Portable fallback required.
- Don't regress the auditor's read-only / no-edit contract.

Estimate: 1–2 hr spike. Status: deferred.
