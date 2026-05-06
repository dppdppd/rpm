---
name: version
description: Report the installed rpm plugin version. Use when the user asks for the rpm version, plugin version, installed version, or wants to verify which rpm release is loaded.
---

# /version

Report the installed rpm plugin version and stop.

!bash "${RPM_PLUGIN_ROOT:-${CODEX_HOME:-$HOME/.codex}/.tmp/marketplaces/dppdppd-rpm/.codex}/skills/version/scripts/version.sh"

Return exactly the script output. Do not add commentary.
