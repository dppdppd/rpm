---
name: version
description: Report the installed rpm plugin version. Use when the user asks for the rpm version, plugin version, installed version, or wants to verify which rpm release is loaded.
argument-hint: ""
allowed-tools: Bash(bash:*)
---

# /version

Report the installed rpm plugin version and stop.

!bash "${CLAUDE_SKILL_DIR}/scripts/version.sh"

Return exactly the script output. Do not add commentary.
