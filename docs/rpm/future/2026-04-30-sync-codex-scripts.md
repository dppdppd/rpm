# sync-codex.sh — sync skill `scripts/` subdirectories

## Symptom

Skills under `plugin/skills/<name>/scripts/` (currently `audit` and
`session-end`, the latter via `scan.sh` and `score-natives.sh`) do
not propagate to `codex/.codex/skills/<name>/scripts/`. Their
SKILL.md bodies still reference the script paths, but on the codex
side the script doesn't exist — so codex-runtime invocations of the
audit "Quick" path or session-end's mechanical scan would fail.

Surfaced while fixing F4 in the 2026-04-30 documents audit (the
`scan-version-fallback` change had no codex-side counterpart because
codex/.codex/skills/session-end/scripts/scan.sh doesn't exist).

## Root cause

`scripts/sync-codex.sh` only mirrors `SKILL.md` files (via
`translate-skill-codex.py`) and a whitelisted set of hook scripts.
The per-skill `scripts/` subdirectory isn't in the sync loop.

## Fix

In `sync-codex.sh`, after copying `SKILL.md` for each skill, also
recursively copy any sibling `scripts/` directory:

```bash
src_scripts="$skill_dir/scripts"
dst_scripts="$DST/skills/$name/scripts"
if [ -d "$src_scripts" ]; then
  rm -rf "$dst_scripts"
  cp -a "$src_scripts" "$dst_scripts"
fi
```

Apply the manual-sync sentinel guard to `scripts/*.sh` as well — a
hand-tweaked codex-specific script (rare but possible) should be
preserved like manual SKILL.md files are.

Drop stale `scripts/` dirs whose source is gone, mirroring the
existing stale-skill cleanup loop.

## Test

Run `bash scripts/sync-codex.sh` against the current tree; assert
`codex/.codex/skills/audit/scripts/` and
`codex/.codex/skills/session-end/scripts/` end up populated with
the same files as their plugin counterparts.

## Scope

- ~10 lines in `sync-codex.sh`.
- No new translator — scripts are copied verbatim, no Codex-specific
  rewrites needed (they use bash + `${CLAUDE_SKILL_DIR:-...}` style
  fallbacks already, same as everything else).

## Estimate

15 minutes including the verification run.
