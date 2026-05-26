#!/usr/bin/env bats

# Tests F4 of 2026-04-30-next-refinements.md: is-pre-completed.sh
# detects stale TODOs whose linked detail file already has a populated
# `## Worker Result` section so /next can skip them without round-trip.

load helpers

setup()    { setup_sandbox; }
teardown() { teardown_sandbox; }

seed_tasks() {
  cat > "$PM_DIR/future/tasks.org" <<'EOF'
#+TODO: TODO IN-PROGRESS BLOCKED WATCH | DONE

* Active

** TODO Already completed [[file:2026-05-09-task-done.md]]
   :PROPERTIES:
   :ID: task-done
   :END:

** TODO Not yet started [[file:2026-05-09-task-fresh.md]]
   :PROPERTIES:
   :ID: task-fresh
   :END:

** TODO Missing detail file [[file:2026-05-09-task-missing.md]]
   :PROPERTIES:
   :ID: task-missing
   :END:
EOF

  cat > "$PM_DIR/future/2026-05-09-task-done.md" <<'EOF'
# Task done

## Worker Result

Summary: handled in a prior run.
EOF

  cat > "$PM_DIR/future/2026-05-09-task-fresh.md" <<'EOF'
# Task fresh

Body text only. No worker result yet.
EOF
}

run_is_pre_completed() {
  bash "$CLAUDE_PLUGIN_ROOT/skills/next/scripts/is-pre-completed.sh" "$@"
}

@test "is-pre-completed exits 0 when detail file has Worker Result" {
  seed_tasks
  run run_is_pre_completed task-done
  [ "$status" -eq 0 ]
}

@test "is-pre-completed exits 1 when detail file lacks Worker Result" {
  seed_tasks
  run run_is_pre_completed task-fresh
  [ "$status" -eq 1 ]
}

@test "is-pre-completed exits 1 for unknown task id" {
  seed_tasks
  run run_is_pre_completed task-not-in-org
  [ "$status" -eq 1 ]
}

@test "is-pre-completed exits 1 when linked detail file is missing" {
  seed_tasks
  run run_is_pre_completed task-missing
  [ "$status" -eq 1 ]
}

@test "is-pre-completed exits 1 when no task id is passed" {
  seed_tasks
  run run_is_pre_completed
  [ "$status" -eq 1 ]
}

@test "is-pre-completed exits 1 when tasks.org is missing" {
  # Don't seed; PM_DIR/future exists but tasks.org does not.
  rm -f "$PM_DIR/future/tasks.org"
  run run_is_pre_completed any-id
  [ "$status" -eq 1 ]
}
