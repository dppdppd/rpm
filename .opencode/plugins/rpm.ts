import type { Plugin } from "@opencode-ai/plugin"
import { fileURLToPath } from "node:url"
import { dirname, resolve } from "node:path"
import { realpathSync } from "node:fs"

// rpm-opencode — prototype. Bridges opencode's event stream to rpm's
// existing bash hooks in plugin/hooks. Hook path resolves relative to
// this file (unfurled through any symlink so dev installs via symlink
// still work): monorepo layout is
//   rpm/opencode/.opencode/plugins/rpm.ts → rpm/plugin/hooks/
// For shipping, hooks will be bundled alongside this file and resolved
// via `${PLUGIN_FILE_DIR}/hooks` instead.
const PLUGIN_FILE_DIR = dirname(realpathSync(fileURLToPath(import.meta.url)))
const PLUGIN_PKG_ROOT = resolve(PLUGIN_FILE_DIR, "../../..", "plugin")
const HOOKS_DIR = resolve(PLUGIN_PKG_ROOT, "hooks")

export const RpmPlugin: Plugin = async ({ $, directory }) => {
  console.log(`[rpm-opencode] plugin loaded; hooks=${HOOKS_DIR}`)
  const projectRoot = directory

  async function runHook(script: string, payload: unknown) {
    const json = JSON.stringify(payload)
    try {
      await $`echo ${json} | bash ${HOOKS_DIR}/${script}`
        .env({
          ...process.env,
          CLAUDE_PROJECT_DIR: projectRoot,
          CLAUDE_PLUGIN_ROOT: PLUGIN_PKG_ROOT,
        })
        .quiet()
      console.log(`[rpm-opencode] ran ${script}`)
    } catch (e) {
      console.error(`[rpm-opencode] hook ${script} failed:`, e)
    }
  }

  // Run SessionStart logic inline: opencode loads plugins lazily, so
  // the first session's session.created publishes BEFORE the event
  // hook is registered. Invoking session-start-auto.sh here covers the
  // initial project bootstrap; subsequent session.created events (new
  // sessions in the same running server) are caught by the event hook.
  await runHook("session-start-auto.sh", {
    source: "startup",
    session_id: "plugin-init",
  })

  return {
    "shell.env": async (_input, output) => {
      // rpm's bash scripts (called from inside commands via !`bash
      // "${CLAUDE_PLUGIN_ROOT}/..."` blocks) need CLAUDE_PLUGIN_ROOT
      // set. Claude Code injects this per-plugin; opencode does not,
      // so we inject it for every shell invocation in this project.
      // translate-skill.py rewrites ${CLAUDE_SKILL_DIR} references
      // into ${CLAUDE_PLUGIN_ROOT}/skills/<name> at sync time so one
      // env var covers both.
      output.env.CLAUDE_PLUGIN_ROOT = PLUGIN_PKG_ROOT
    },
    event: async ({ event }) => {
      const type = (event as { type: string }).type
      console.log(`[rpm-opencode] event=${type}`)
      switch (type) {
        case "session.created":
          await runHook("session-start-auto.sh", {
            source: "startup",
            session_id:
              (event as { properties?: { info?: { id?: string } } })
                .properties?.info?.id ?? "unknown",
          })
          break
        case "session.compacted":
          await runHook("post-compact.sh", {
            compact_summary:
              (event as { properties?: { summary?: string } }).properties
                ?.summary ?? "",
          })
          break
        case "session.deleted":
          await runHook("session-end.sh", { reason: "other" })
          break
      }
    },
  }
}
