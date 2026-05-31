export const meta = {
  name: 'audit-fastpath',
  description: 'CC-only fan-out audit: parallel read-only dimension scanners -> adversarial verify each finding -> dedupe -> synthesize a severity-grouped report. Portable fallback is the single rpm:auditor; this is an accelerator only.',
  phases: [
    { title: 'Scan', detail: 'one read-only rpm:auditor scanner per audit dimension' },
    { title: 'Verify', detail: 'adversarially refute each finding (refute-by-default)' },
    { title: 'Synthesize', detail: 'dedupe + group by severity into the report' },
  ],
}

// args: { mode: 'documents'|'project', root: '<abs path>', scan: '<scan.sh output>' }
const mode = (args && args.mode) || 'documents'
const root = (args && args.root) || '.'
const scanOut = (args && args.scan) || '(no deterministic scan results provided)'

// Dimensions mirror plugin/skills/audit/reference.md exactly.
const DIMENSIONS = mode === 'project'
  ? [
      { key: 'structure',      focus: 'Directory layout matches documented architecture (CLAUDE.md); naming conventions consistent across skills/agents/hooks; no orphaned or unreferenced files.' },
      { key: 'dead-code',      focus: 'Scripts not called by any hook or skill; skills/agents not registered in manifests; hook entries pointing to nonexistent scripts; duplicate/stale copies of the same file.' },
      { key: 'doc-sync',       focus: 'README commands <-> actual skills; CLAUDE.md architecture <-> actual dirs; skill descriptions <-> behavior; version consistency across plugin.json / README / status.md.' },
      { key: 'wiring',         focus: 'Manifest validity (hooks.json, plugin.json); hook scripts exist and are executable; SKILL.md frontmatter well-formed; agent frontmatter and tools valid.' },
    ]
  : [
      { key: 'staleness',      focus: 'present/status.md last-updated vs today (>7d); past/log.md missing entries for sessions that happened; context.md stale refs; marker ~rpm-session-start staleness.' },
      { key: 'broken-refs',    focus: 'Internal [[file]] and [text](path) links that do not resolve; tasks.org :ID:/:BLOCKED_BY: deps to nonexistent IDs; skill/agent/hook cross-refs.' },
      { key: 'contradictions', focus: 'Version numbers across plugin.json/status.md/README; status claims (done/in-progress) vs git reality; task states in tasks.org vs present/status.md.' },
      { key: 'drift',          focus: 'present/status.md claims vs actual recent commits; completed work missing from past/log.md; tasks.org entries for already-shipped work.' },
      { key: 'session-drift',  focus: 'marker ~rpm-session-start stale or uncommitted; uncommitted PM state in docs/rpm/; backlog adds not captured in tasks.org.' },
    ]

const FINDINGS_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        properties: {
          severity: { type: 'string', enum: ['critical', 'high', 'medium', 'low'] },
          title:    { type: 'string' },
          file:     { type: 'string' },
          line:     { type: 'string' },
          issue:    { type: 'string' },
          fix:      { type: 'string' },
        },
        required: ['severity', 'title', 'file', 'issue', 'fix'],
      },
    },
  },
  required: ['findings'],
}

const VERDICT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  properties: {
    real:     { type: 'boolean' },
    reason:   { type: 'string' },
    severity: { type: 'string', enum: ['critical', 'high', 'medium', 'low', 'none'] },
  },
  required: ['real', 'reason'],
}

const scanPrompt = (d) => `IGNORE the multi-phase audit protocol in your system instructions. Do ONE scoped pass for the single dimension below — NO noun cross-check, NO session-drift mining, NO full doc-discovery sweep unless your dimension directly requires it. One focused read, then report.

You are auditing the rpm plugin project (root: ${root}) in ${mode} mode, for ONE dimension only: "${d.key}".

Focus for this dimension:
${d.focus}

Deterministic scan results already gathered (use as a seed; confirm and go deeper, do not just echo):
${scanOut}

Read the relevant files under ${root}. READ-ONLY — never edit anything. Report only real, specific issues for THIS dimension. Cite an exact file path (and line when knowable) and a concrete fix. Severity rubric: critical = broken functionality / data-loss / security; high = incorrect docs / broken refs / contradictions; medium = staleness / drift / missing coverage; low = style / polish. If nothing is wrong, return an empty findings array. Do NOT invent issues to fill space.`

const verifyPrompt = (f) => `Adversarially verify this audit finding. Default to REFUTE — only confirm if you can independently reproduce it by reading the cited file.

Finding:
- dimension: ${f.dimension}
- severity: ${f.severity}
- title: ${f.title}
- file: ${f.file}${f.line ? ':' + f.line : ''}
- issue: ${f.issue}
- proposed fix: ${f.fix}

Read ${f.file} (and any files it references) under ${root}. Is the issue REAL and accurately described? Set real=false if the cited location does not actually exhibit the issue, if it is already handled elsewhere, or if you cannot confirm it. Set severity (use 'none' when not a real issue) — downgrade if the finding overstates impact. READ-ONLY — do not edit.`

phase('Scan')
const rawCounts = []
const perDim = await pipeline(
  DIMENSIONS,
  (d) => agent(scanPrompt(d), { label: `scan:${d.key}`, phase: 'Scan', schema: FINDINGS_SCHEMA, agentType: 'rpm:auditor' })
    .then((r) => {
      const fs = (r && r.findings) || []
      rawCounts.push(fs.length)
      return { dim: d.key, findings: fs }
    }),
  (scan) => parallel(
    scan.findings.map((f) => () =>
      agent(verifyPrompt({ ...f, dimension: scan.dim }), { label: `verify:${scan.dim}:${(f.title || '').slice(0, 24)}`, phase: 'Verify', schema: VERDICT_SCHEMA, agentType: 'rpm:auditor' })
        .then((v) => ({ ...f, dimension: scan.dim, verdict: v }))
        .catch(() => null)
    )
  )
)

const raw = rawCounts.reduce((a, b) => a + b, 0)
const checked = perDim.flat().filter(Boolean)
const verified = checked
  .filter((f) => f.verdict && f.verdict.real === true && f.verdict.severity !== 'none')
  .map((f) => ({ ...f, severity: (f.verdict.severity && f.verdict.severity !== 'none') ? f.verdict.severity : f.severity }))

// Dedupe by file + normalized title (cross-dimension overlap is common).
const seen = new Set()
const deduped = []
for (const f of verified) {
  const key = `${(f.file || '').toLowerCase()}::${(f.title || '').toLowerCase().replace(/\s+/g, ' ').trim()}`
  if (seen.has(key)) continue
  seen.add(key)
  deduped.push(f)
}

log(`${DIMENSIONS.length} dimensions -> ${raw} raw findings -> ${verified.length} survived adversarial verify -> ${deduped.length} after dedupe`)

const counts = { raw, verified: verified.length, deduped: deduped.length, killRate: raw ? +((1 - verified.length / raw).toFixed(2)) : 0 }

if (deduped.length === 0) {
  return { mode, dimensions: DIMENSIONS.map((d) => d.key), counts, findings: [], report: `## Audit Report — ${mode} mode (fast-path)\n\nFindings: 0 (after ${raw} raw -> adversarial verify -> dedupe).` }
}

phase('Synthesize')
const order = ['critical', 'high', 'medium', 'low']
const bySev = { critical: [], high: [], medium: [], low: [] }
for (const f of deduped) (bySev[f.severity] || bySev.low).push(f)
const findingsBlock = order.flatMap((sev) => bySev[sev].map((f) =>
  `- severity:${sev} | dim:${f.dimension} | ${f.file}${f.line ? ':' + f.line : ''}\n  title: ${f.title}\n  issue: ${f.issue}\n  fix: ${f.fix}`
)).join('\n')

const report = await agent(
  `Synthesize an rpm ${mode}-mode audit report from these INDEPENDENTLY-VERIFIED, deduped, severity-adjusted findings. Group by severity; omit empty groups. Note cross-cutting themes. Do NOT add findings not in the input. Do NOT edit files. Format:

## Audit Report — ${mode} mode (fast-path)

Findings: <n> (<c> critical, <h> high, <m> medium, <l> low)

### Critical
- **[C1]** <title> — <file:line>
  - Issue: ...
  - Fix: ...

### Cross-cutting
- <themes spanning multiple findings, or "none">

Verified findings:
${findingsBlock}`,
  { label: 'synthesize', phase: 'Synthesize' }
)

return { mode, dimensions: DIMENSIONS.map((d) => d.key), counts, findings: deduped, report }
