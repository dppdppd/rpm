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

## Worker Result

### Summary
Added a Phase 0 noun cross-check section to the auditor agent (both the
Claude-native subagent and the Codex mirror reference). Phase 0 instructs
the agent to extract high-impact nouns from CLAUDE.md / status.md /
context.md, grep them against the code tree (excluding docs/, .git/,
node_modules/, .opencode/, .venv/), and tag every subsequent finding as
`doc-stale`, `doc-orphan`, or `code-undocumented` — surfacing orphans
first so the agent stops recommending rewrites against ghosts. Added a
bats structural guard so the section can't be silently stripped.

### Files changed
- `plugin/agents/auditor.md` — inserted Phase 0 section above the
  existing numbered phases (kept original 1-9 numbering, added a
  `## Phase 1+: doc scan` header before phase 1 for separation).
- `codex/.codex/skills/audit/references/auditor.md` — identical Phase 0
  insertion (verified byte-identical with `diff`).
- `plugin/tests/auditor-phase-0.bats` — 6 new structural tests:
  files exist, Phase 0 section present, each tag (`doc-stale`,
  `doc-orphan`, `code-undocumented`) appears exactly once per file,
  Claude + Codex mirrors are byte-identical.

### Verification
```
ok 1 auditor agent files exist (Claude + Codex mirror)
ok 2 auditor agent contains a Phase 0 section
ok 3 auditor agent mentions doc-stale exactly once
ok 4 auditor agent mentions doc-orphan exactly once
ok 5 auditor agent mentions code-undocumented exactly once
ok 6 auditor agent Claude + Codex mirrors are byte-identical
...
ok 151 version script reports plugin manifest version
```
Full suite green: 151/151.

### Remaining risks
- The bats test is a **structural guard only** — it asserts the Phase 0
  section and its three tags exist verbatim. It does NOT exercise the
  LLM agent's runtime behavior. Bats can't drive an LLM following a
  markdown prompt, so we can't assert "auditor flags a fake hostname
  as doc-orphan" in CI. (The detail file's original proposal to do that
  in bats is not feasible.)
- Phase 0's actual effectiveness can only be validated **operationally**:
  re-run `/audit documents` against a project with known doc drift
  (e.g. reddit-reports at the point of the Contabo incident) and verify
  that orphaned entities surface as `doc-orphan` with delete
  recommendations, not as cross-doc rewrite suggestions. That's an
  operational/manual validation, not a CI one.
- The agent file did not previously use explicit "Phase N" headings —
  it used a bare numbered list 1-9. The fix keeps that numbering and
  adds a `## Phase 1+: doc scan` header before item 1 to keep Phase 0
  visually distinct. If a future edit normalizes all phases to explicit
  `## Phase N` headings, the bats structural guard (`grep -F 'Phase 0'`)
  will still pass.
