# scan.sh version=unknown fallback

## Symptom

During `/rpm:session-end` on 2026-04-18, `scan.sh`'s `=== plugin ===`
section emitted `version=unknown`. The Phase 1 header instruction in
`session-end/SKILL.md` expects `version=X.Y.Z` so Claude can render
`## Phase 1 (of 4): Collecting Findings (rpm X.Y.Z)`. With
`version=unknown` the header loses the version tag.

## Root cause

`plugin/skills/session-end/scripts/scan.sh` resolves the manifest as:

```bash
PLUGIN_MANIFEST="${CLAUDE_PLUGIN_ROOT:-}/.claude-plugin/plugin.json"
```

When `$CLAUDE_PLUGIN_ROOT` is unset at skill-body-bash invocation time
(the `!bash ${CLAUDE_SKILL_DIR}/scripts/scan.sh` injection), this
becomes `/.claude-plugin/plugin.json` — a path that doesn't exist —
and the fallback prints `version=unknown`.

Hooks (`session-start-auto.sh`) already have `$CLAUDE_PLUGIN_ROOT`
set correctly by the harness; the discrepancy is skill-bash vs
hook-bash env propagation. Not worth chasing upstream — fix
defensively.

## Fix

Add a second fallback using `CLAUDE_SKILL_DIR` (which IS set for
skill-body bash) to derive the plugin root:

```bash
PLUGIN_MANIFEST="${CLAUDE_PLUGIN_ROOT:-}/.claude-plugin/plugin.json"
if [ ! -f "$PLUGIN_MANIFEST" ] && [ -n "${CLAUDE_SKILL_DIR:-}" ]; then
  PLUGIN_MANIFEST="${CLAUDE_SKILL_DIR}/../../.claude-plugin/plugin.json"
fi
```

One-line change. Add a bats test in `scan-sh.bats` that sets
`CLAUDE_SKILL_DIR` and not `CLAUDE_PLUGIN_ROOT` and asserts the
emitted `version=` is not `unknown`.

## Effort

~10 minutes including test. Ship as v2.7.4.
