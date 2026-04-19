import { test } from "node:test"
import assert from "node:assert/strict"
import { resolve, dirname } from "node:path"
import { fileURLToPath } from "node:url"
import { realpathSync } from "node:fs"

import { RpmPlugin } from "../.opencode/plugins/rpm.ts"

const TEST_DIR = dirname(fileURLToPath(import.meta.url))
const OPENCODE_ROOT = resolve(TEST_DIR, "..")
const EXPECTED_PLUGIN_ROOT = resolve(OPENCODE_ROOT, ".opencode")
const EXPECTED_HOOKS = resolve(EXPECTED_PLUGIN_ROOT, "plugins", "hooks")

type Captured = {
  cmd: string
  env: Record<string, string>
}

// Minimal chainable stand-in for BunShell's `$`. Captures the rendered
// command, records .env() calls, and resolves the await.
function makeShell(captured: Captured[]) {
  return (strings: TemplateStringsArray, ...values: unknown[]) => {
    let cmd = ""
    for (let i = 0; i < strings.length; i++) {
      cmd += strings[i]
      if (i < values.length) cmd += String(values[i])
    }
    const entry: Captured = { cmd, env: {} }
    captured.push(entry)
    const chain: any = {
      env(e: Record<string, string>) {
        entry.env = e
        return chain
      },
      quiet() {
        return chain
      },
      then(resolve: (v: unknown) => void) {
        resolve(undefined)
        return chain
      },
    }
    return chain
  }
}

function makeInput(captured: Captured[]) {
  return {
    $: makeShell(captured),
    directory: "/tmp/fake-project",
    project: {},
    worktree: "/tmp/fake-project",
    client: {},
    serverUrl: new URL("http://localhost:0"),
    experimental_workspace: { register() {} },
  } as any
}

test("plugin init invokes session-start-auto.sh", async () => {
  const captured: Captured[] = []
  await RpmPlugin(makeInput(captured))
  const init = captured.find((c) => c.cmd.includes("session-start-auto.sh"))
  assert.ok(init, "expected session-start-auto.sh to run on init")
  assert.equal(init!.env.CLAUDE_PROJECT_DIR, "/tmp/fake-project")
  assert.equal(init!.env.CLAUDE_PLUGIN_ROOT, EXPECTED_PLUGIN_ROOT)
  assert.ok(
    init!.cmd.includes(`${EXPECTED_HOOKS}/session-start-auto.sh`),
    `hook path resolved via realpathSync; got: ${init!.cmd}`,
  )
})

test("event hook dispatches session.deleted to session-end.sh", async () => {
  const captured: Captured[] = []
  const hooks = await RpmPlugin(makeInput(captured))
  captured.length = 0 // clear init noise
  await hooks.event!({ event: { type: "session.deleted" } as any })
  const end = captured.find((c) => c.cmd.includes("session-end.sh"))
  assert.ok(end, "expected session-end.sh to run on session.deleted")
  assert.ok(
    end!.cmd.includes('"reason":"session_deleted"'),
    `payload should tag reason=session_deleted; got: ${end!.cmd}`,
  )
})

test("event hook dispatches server.instance.disposed to session-end.sh", async () => {
  const captured: Captured[] = []
  const hooks = await RpmPlugin(makeInput(captured))
  captured.length = 0
  await hooks.event!({ event: { type: "server.instance.disposed" } as any })
  const end = captured.find((c) => c.cmd.includes("session-end.sh"))
  assert.ok(end, "expected session-end.sh to run on server.instance.disposed")
  assert.ok(
    end!.cmd.includes('"reason":"instance_disposed"'),
    `payload should tag reason=instance_disposed; got: ${end!.cmd}`,
  )
})

test("event hook dispatches session.compacted to post-compact.sh", async () => {
  const captured: Captured[] = []
  const hooks = await RpmPlugin(makeInput(captured))
  captured.length = 0
  await hooks.event!({
    event: {
      type: "session.compacted",
      properties: { summary: "example summary" },
    } as any,
  })
  const post = captured.find((c) => c.cmd.includes("post-compact.sh"))
  assert.ok(post, "expected post-compact.sh to run on session.compacted")
  assert.ok(
    post!.cmd.includes("example summary"),
    `summary should flow to stdin JSON; got: ${post!.cmd}`,
  )
})

test("event hook ignores unrelated event types", async () => {
  const captured: Captured[] = []
  const hooks = await RpmPlugin(makeInput(captured))
  captured.length = 0
  await hooks.event!({ event: { type: "message.updated" } as any })
  assert.equal(captured.length, 0, "non-lifecycle events should be no-ops")
})

test("shell.env hook injects CLAUDE_PLUGIN_ROOT", async () => {
  const hooks = await RpmPlugin(makeInput([]))
  const output = { env: {} as Record<string, string> }
  await hooks["shell.env"]!({ cwd: "/tmp/fake-project" } as any, output)
  assert.equal(output.env.CLAUDE_PLUGIN_ROOT, EXPECTED_PLUGIN_ROOT)
})
