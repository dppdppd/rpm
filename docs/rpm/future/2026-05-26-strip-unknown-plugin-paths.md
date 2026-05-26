# Strip `claude-plugins-official/rpm/unknown/` placeholders from skill bodies

## Gap
At least one skill body (session-end and likely /next) contains a hardcoded
path of the shape:

```
~/.claude/plugins/cache/claude-plugins-official/rpm/unknown/skills/.../scan.sh
```

This looks like an unrendered template — `claude-plugins-official` is the
wrong marketplace name and `unknown` is a literal-`unknown` version segment.
Assistants follow the path verbatim and `bash` errors with
`No such file or directory`, then have to `find` the real install location.

## Evidence
- BGSD `8e17a9ec:26-32`: assistant ran
  `bash /home/coder/.claude/plugins/cache/claude-plugins-official/rpm/unknown/skills/session-end/scripts/scan.sh`
  → `No such file or directory`. Recovered by `find`.

Real install locations on the same machine:
- `~/.claude/plugins/cache/dppdppd-plugins/rpm/{2.15.0,2.16.0,2.17.7}/...`
- `~/.codex/plugins/cache/dppdppd-rpm/rpm/2.17.9/...`
- `/home/coder/projects/rpm/plugin/...` (dev tree)

## Platform
**CC-only effective issue** — Codex hooks.json resolves via env-var chain
so the placeholder never reaches there. But skill bodies are shared, so
the chunk lives in shipped skill content.

## Proposed fix
1. `rg -l 'claude-plugins-official/rpm/unknown' plugin/skills/` — find all
   occurrences.
2. Replace each with `${CLAUDE_PLUGIN_ROOT}` (CC) or instruct via the
   resolver pattern (Codex).
3. Add a CI test that grep-fails on `claude-plugins-official` or `rpm/unknown`
   in plugin source.

## Validation
- CI grep fails on placeholder strings.
- Manual: invoke `/session-end` in BGSD-style fresh project, confirm no
  `No such file` errors.
