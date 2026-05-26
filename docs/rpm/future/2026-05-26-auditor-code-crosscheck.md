# Auditor: cross-check doc claims against live code before reporting

## Gap
The `rpm:auditor` agent surfaces "stale doc" findings by reading
status.md/CLAUDE.md/tasks.org and comparing them to each other — but it
doesn't verify those claims against the actual code/filesystem state, so
it confidently reports drift against documentation that itself is wrong.

## Evidence
- reddit-reports `reddit1.jsonl:L1307→L1311`: auditor reported **13
  findings** about VPS deployment, rsync wrappers, "CLAUDE.md deploy
  section is wrong host" — all anchored to stale Contabo docs. Real state:
  no VPS, no Contabo, runs on Synology in York. User had to interrupt:
  *"We need to slow down. the documents have drifted a lot so we need to
  look at the code for source of truth."*
- Auditor cost: ~6 minutes of agent time wasted producing wrong findings.

## Platform
**Both** (auditor agent is identical content in both runtimes).

## Proposed fix
Add a Phase 0 to `plugin/agents/auditor.md`:

1. For each high-impact noun extracted from CLAUDE.md/status.md (hostnames,
   IPs, technology names, file paths, ports, vendor names):
   - `grep -rli "<noun>"` against the project tree (excluding docs/).
   - If 0 code matches, flag the noun as "doc-only — code may have moved".

2. Tag each subsequent finding with one of:
   - `doc-stale` — doc lags code that exists.
   - `doc-orphan` — doc references entities that aren't in code anywhere.
   - `code-undocumented` — code exists, no doc reference.

3. For `doc-orphan` findings (the bulk of the reddit incident),
   recommendation should be "Remove or rewrite — entity not found in
   code", NOT "Update X to match Y".

## Validation
- Re-run auditor against reddit-reports current state, expect Contabo/VPS
  findings tagged `doc-orphan` with delete recommendation rather than
  rewrite.
- bats: fixture with a CLAUDE.md mentioning a fake hostname; assert auditor
  flags it as `doc-orphan`.
