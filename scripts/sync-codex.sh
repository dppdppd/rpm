#!/bin/bash
# Mirror plugin/{skills,hooks,agents} into codex/.codex/ so Codex CLI
# sees rpm's surface. Run after editing anything under plugin/ that
# should propagate to the Codex port.
#
# Codex on-disk convention (per openai/codex repo's own .codex/):
#   .codex/skills/<name>/SKILL.md
#   .codex/hooks/<name>.sh + .codex/hooks.json
# Per-skill subagent system prompts go in `<skill>/references/` since
# Codex has no separate subagent-definition file format.
#
# HAND-TWEAK GUARD: a destination SKILL.md (or hook script) may include
# the sentinel
#   <!-- codex-sync: manual -->   (in the first 20 lines)
# When present, sync-codex skips that file so Codex-specific hand-edits
# survive across syncs.

set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SRC="$REPO_ROOT/plugin"
DST="$REPO_ROOT/codex/.codex"
SENTINEL='codex-sync: manual'

# Hooks Codex actually fires (the others have no event source — see codex/README.md).
CODEX_HOOK_SCRIPTS=(
  session-start-auto.sh
  context-monitor.sh
  codex-sync-reminder.sh
  stop-learn-capture.sh
  handoff-validator.sh
  _directives.sh
  _scoring.sh
  tips.txt
)

# Auditor system prompt lives under the audit skill as a reference doc.
# `<plugin-agent>:<codex-skill>` pairs.
AGENT_TO_SKILL=(
  "auditor.md:audit"
)

mkdir -p "$DST/skills" "$DST/hooks" "$DST/.codex-plugin"

is_manual() {
  [ -f "$1" ] && head -n 20 "$1" | grep -qF "$SENTINEL"
}

# --- Skills -----------------------------------------------------------------
synced_skills=()
skipped_skills=()

for skill_dir in "$SRC"/skills/*/; do
  name=$(basename "$skill_dir")
  src_md="$skill_dir/SKILL.md"
  dst_md="$DST/skills/$name/SKILL.md"
  [ -f "$src_md" ] || continue

  if is_manual "$dst_md"; then
    skipped_skills+=("$name")
    continue
  fi

  mkdir -p "$DST/skills/$name"
  python3 "$REPO_ROOT/scripts/translate-skill-codex.py" "$src_md" "$dst_md"
  synced_skills+=("$name")

  # Mirror per-skill scripts/ subdirectory (e.g. session-end/scripts/scan.sh,
  # next/scripts/status.sh). Codex skill bodies reference these by relative
  # path; without the copy the codex side can't run them.
  src_scripts="$skill_dir/scripts"
  dst_scripts="$DST/skills/$name/scripts"
  if [ -d "$src_scripts" ]; then
    rm -rf "$dst_scripts"
    cp -a "$src_scripts" "$dst_scripts"
  fi

  # Mirror same-directory skill support docs/resources (for example
  # audit/findings-menu.md and audit/project-mode.md). SKILL.md itself
  # is translated above; scripts/ is handled separately.
  find "$skill_dir" -maxdepth 1 -type f ! -name 'SKILL.md' -print0 \
    | while IFS= read -r -d '' support_file; do
        cp "$support_file" "$DST/skills/$name/$(basename "$support_file")"
      done
done

# --- Plugin manifest --------------------------------------------------------
python3 - "$SRC/.claude-plugin/plugin.json" \
  "$DST/.codex-plugin/plugin.json" <<'PY'
import json
import sys
from pathlib import Path

src, *dests = map(Path, sys.argv[1:])
manifest = json.loads(src.read_text())
manifest["skills"] = "./skills/"
manifest["hooks"] = "./hooks.json"
manifest["interface"] = {
    "displayName": "rpm",
    "shortDescription": "Session lifecycle, backlog, audit, and research support for Codex.",
    "longDescription": (
        "rpm is a local-first project manager for LLM-assisted development. "
        "It keeps hot context, backlog state, session handoffs, audit findings, "
        "and research artifacts in the repository."
    ),
    "developerName": manifest.get("author", {}).get("name", "dppdppd"),
    "category": "Productivity",
    "capabilities": ["Interactive", "Write"],
    "websiteURL": manifest.get("homepage", ""),
    "defaultPrompt": [
        "Set up rpm for this project.",
        "Show my rpm backlog.",
        "Run an rpm project audit.",
    ],
    "brandColor": "#2563EB",
}
text = json.dumps(manifest, indent=2) + "\n"
for dest in dests:
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(text)
PY

# Drop stale skill dirs whose source is gone, except manual ones.
for existing in "$DST/skills"/*/; do
  [ -d "$existing" ] || continue
  name=$(basename "$existing")
  if [ ! -f "$SRC/skills/$name/SKILL.md" ]; then
    if is_manual "$existing/SKILL.md"; then
      skipped_skills+=("$name (orphan, kept)")
    else
      rm -rf "$existing"
    fi
  fi
done

# --- Hooks ------------------------------------------------------------------
synced_hooks=()
skipped_hooks=()

for f in "${CODEX_HOOK_SCRIPTS[@]}"; do
  src_f="$SRC/hooks/$f"
  dst_f="$DST/hooks/$f"
  [ -f "$src_f" ] || continue

  if is_manual "$dst_f"; then
    skipped_hooks+=("$f")
    continue
  fi

  cp "$src_f" "$dst_f"
  synced_hooks+=("$f")
done

# --- Agents → references inside skills --------------------------------------
synced_refs=()

for pair in "${AGENT_TO_SKILL[@]}"; do
  agent_file="${pair%%:*}"
  skill_name="${pair##*:}"
  src_a="$SRC/agents/$agent_file"
  dst_a="$DST/skills/$skill_name/references/$agent_file"
  [ -f "$src_a" ] || continue

  if is_manual "$dst_a"; then
    continue
  fi

  mkdir -p "$DST/skills/$skill_name/references"
  cp "$src_a" "$dst_a"
  synced_refs+=("$agent_file → skills/$skill_name/references/")
done

# --- Report -----------------------------------------------------------------
echo "sync-codex: $DST"
echo "  manifest synced: codex/.codex/.codex-plugin/plugin.json"
[ ${#synced_skills[@]} -gt 0 ] && printf '  skills synced:   %s\n' "${synced_skills[*]}"
[ ${#skipped_skills[@]} -gt 0 ] && printf '  skills skipped:  %s\n' "${skipped_skills[*]}"
[ ${#synced_hooks[@]} -gt 0 ]  && printf '  hooks synced:    %s\n' "${synced_hooks[*]}"
[ ${#skipped_hooks[@]} -gt 0 ] && printf '  hooks skipped:   %s\n' "${skipped_hooks[*]}"
[ ${#synced_refs[@]} -gt 0 ]   && printf '  refs synced:     %s\n' "${synced_refs[*]}"
echo
echo "Static files (not synced): hooks.json, config.toml.sample, README.md"
echo "Sentinel for hand-tweaked files: <!-- $SENTINEL -->"
