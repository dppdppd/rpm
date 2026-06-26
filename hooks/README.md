# rpm hook manifests

`hooks.json` is the Claude Code hook manifest, but Codex can also see it
when a user accidentally installs the Claude-side `rpm@dppdppd-plugins`
package instead of the Codex-specific `rpm@dppdppd-rpm` package. For that
reason hook commands do not invoke `${CLAUDE_PLUGIN_ROOT}` directly.

Each command uses a small inline resolver that tries `RPM_PLUGIN_ROOT`,
`CODEX_PLUGIN_ROOT`, and `CLAUDE_PLUGIN_ROOT`, then falls back to the
known Codex cache and marketplace paths for both rpm package names. This
keeps normal Claude installs on the standard root while making accidental
Codex loads fail closed with `rpm hook not found` instead of `bash:
/hooks/<script>: No such file or directory` / exit `127`.
