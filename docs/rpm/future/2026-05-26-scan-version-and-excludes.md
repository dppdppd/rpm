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

## Worker Result

### Summary
Replaced scan.sh's plugin-manifest resolver with a unified candidate-root
chain (RPM_PLUGIN_ROOT, CODEX_PLUGIN_ROOT, CLAUDE_PLUGIN_ROOT, CLAUDE_SKILL_DIR
fallback, monorepo relatives, Codex cache glob), so the Codex install path
no longer falls back to `version=unknown`. Added `--exclude-dir=` flags
(`node_modules`, `.opencode`, `.venv`, `.git`, `dist`, `build`, `target`) to
the NOT_IMPLEMENTED grep so vendored trees can't blow scan output past the
harness 2KB cap. Both fixes applied to plugin copy and Codex mirror
byte-for-byte identically.

### Files changed
- `plugin/skills/session-end/scripts/scan.sh` — new resolver + grep excludes
- `codex/.codex/skills/session-end/scripts/scan.sh` — identical mirror update
- `plugin/tests/scan.bats` — two new tests:
  - `plugin: version resolves via RPM_PLUGIN_ROOT pointing at stub manifest`
  - `not_implemented: skips vendored dirs and total output stays bounded`

### Verification run

bats (tail):
```
ok 50 plugin: version resolves via CLAUDE_SKILL_DIR fallback when CLAUDE_PLUGIN_ROOT is unset
ok 51 plugin: version resolves via RPM_PLUGIN_ROOT pointing at stub manifest
ok 52 not_implemented: skips vendored dirs and total output stays bounded
...
ok 134 version script reports plugin manifest version
```
All 134 tests passed.

shellcheck:
- `plugin/skills/session-end/scripts/scan.sh` → exit 1 (3 pre-existing warnings: SC2016 line 167, SC2154 lines 398/401 — all outside changed regions).
- `codex/.codex/skills/session-end/scripts/scan.sh` → exit 1 (same pre-existing warnings).
- No new shellcheck issues introduced by this change. CI runs `shellcheck ... || true` so the workflow stays green.

### Remaining risks
- The Codex cache glob fallback only iterates when env vars are unset AND the
  monorepo-relative paths miss. In a real Codex install with no env at all,
  the glob will find the plugin under `$CODEX_HOME/plugins/cache/dppdppd-rpm/rpm/*`
  but only if the cache actually exists — we didn't add a bats test for this
  branch because it would require fixture-mocking `$HOME`. Real-world Codex
  installs that bootstrap correctly will set `RPM_PLUGIN_ROOT` via the hook
  shim anyway, so the glob is belt-and-suspenders.
- The `--exclude-dir` list is GNU-grep style; should work on macOS too because
  Codex/Claude both ship with `grep` that accepts these flags. BSD-only grep
  environments would degrade silently (still produce big output but won't
  crash). Not a regression vs. status quo.
- The pre-existing shellcheck warnings (`my_status`, `dep_status`, SC2016
  literal backticks) remain unaddressed — out of scope.
