# scan.sh: fix version resolution + exclude vendored dirs

## Gap
`plugin/skills/session-end/scripts/scan.sh` has two bugs:

1. **`version=unknown` in Codex**: emits the placeholder because it relies
   on `$RPM_VERSION` env var, which is unset in Codex. session-start-auto.sh
   resolves version correctly via plugin manifest — scan.sh doesn't.

2. **Walks `node_modules` / `.opencode` / `.venv`**: the NOT_IMPLEMENTED grep
   has no `--exclude-dir`, so a single session in reddit-reports produced
   **3.6MB of output**, all from `.opencode/node_modules/effect/...` — got
   truncated at the harness 2KB cap, gutting the audit.

## Evidence
- Codex: **47 occurrences** of `=== plugin === / version=unknown` across
  sampled sessions.
- reddit Claude `L1284`: scan.sh truncated at 3.6MB; first match
  `./.opencode/node_modules/effect/dist/unstable/httpapi/internal/
  httpApiSwagger.js:1`.
- BGSD `26c4bc56:844,1968`: same `version=unknown` in /session-end Phase 1.

## Platform
**Both**.

## Proposed fix
1. Replace `echo "version=${RPM_VERSION:-unknown}"` with the same fallback
   chain Codex hooks.json uses:
   `RPM_PLUGIN_ROOT → CODEX_PLUGIN_ROOT → CLAUDE_PLUGIN_ROOT →
   $CODEX_HOME/plugins/cache/dppdppd-rpm/rpm/*` then `jq -r .version
   "$root/plugin.json"`.

2. Add `--exclude-dir={node_modules,.opencode,.venv,.git,dist,build,target}`
   to the NOT_IMPLEMENTED grep.

## Validation
- bats: invoke scan.sh in a fixture with vendored dir present, assert
  output < 10KB and contains real plugin version.
- Manual: run scan.sh in reddit-reports, confirm version + clean output.
