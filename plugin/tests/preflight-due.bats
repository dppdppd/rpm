#!/usr/bin/env bats

# preflight-due.sh decides full vs lite preflight for `/loop /next` ticks.
# It prints `full` when there is no marker, when the last `preflight-full`
# is older than the freshness window, or when guidance inputs changed;
# `lite` when a recent marker exists and inputs are unchanged. On any
# uncertainty it must fail safe to `full`.

load helpers

setup()    { setup_sandbox; }
teardown() { teardown_sandbox; }

run_due() {
  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/preflight-due.sh"
}

@test "preflight-due: full when no log exists" {
  run run_due
  [ "$status" -eq 0 ]
  [ "$output" = "full" ]
}

@test "preflight-due: full when the log has no preflight-full marker" {
  printf '{"ts":"%s","kind":"actionable-backlog","target":"t1"}\n' \
    "$(date -Iseconds)" > "$PM_DIR/~rpm-orchestrator-log.jsonl"
  run run_due
  [ "$status" -eq 0 ]
  [ "$output" = "full" ]
}

@test "preflight-due: lite when a fresh preflight-full marker exists" {
  printf '{"ts":"%s","kind":"preflight-full"}\n' \
    "$(date -Iseconds)" > "$PM_DIR/~rpm-orchestrator-log.jsonl"
  run run_due
  [ "$status" -eq 0 ]
  [ "$output" = "lite" ]
}

@test "preflight-due: full when the last preflight-full is stale" {
  printf '{"ts":"%s","kind":"preflight-full"}\n' \
    "$(date -Iseconds -d '20 minutes ago')" > "$PM_DIR/~rpm-orchestrator-log.jsonl"
  run run_due
  [ "$status" -eq 0 ]
  [ "$output" = "full" ]
}

@test "preflight-due: a narrow window override forces full on an aged marker" {
  printf '{"ts":"%s","kind":"preflight-full"}\n' \
    "$(date -Iseconds -d '60 seconds ago')" > "$PM_DIR/~rpm-orchestrator-log.jsonl"
  export RPM_PREFLIGHT_WINDOW=10
  run run_due
  unset RPM_PREFLIGHT_WINDOW
  [ "$status" -eq 0 ]
  [ "$output" = "full" ]
}

@test "preflight-due: uses the most recent preflight-full marker" {
  {
    printf '{"ts":"%s","kind":"preflight-full"}\n'                "$(date -Iseconds -d '30 minutes ago')"
    printf '{"ts":"%s","kind":"actionable-backlog","target":"a"}\n' "$(date -Iseconds -d '2 minutes ago')"
    printf '{"ts":"%s","kind":"preflight-full"}\n'                "$(date -Iseconds)"
  } > "$PM_DIR/~rpm-orchestrator-log.jsonl"
  run run_due
  [ "$status" -eq 0 ]
  [ "$output" = "lite" ]
}
