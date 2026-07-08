#!/usr/bin/env bats

load helpers

setup()    { setup_sandbox; }
teardown() { teardown_sandbox; }

@test "docs/rpm/ missing — stderr hint about /init-rpm, no stdout" {
  rm -rf "$PM_DIR"
  # Capture stdout and stderr separately — stdout (model context) must stay
  # empty; the discoverability hint goes to stderr (user terminal only).
  local stderr_file
  stderr_file=$(mktemp)
  run bash -c "echo '{\"source\":\"startup\",\"session_id\":\"test-sess-123\"}' | bash '$CLAUDE_PLUGIN_ROOT/hooks/session-start-auto.sh' 2>'$stderr_file'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  local stderr_content
  stderr_content=$(cat "$stderr_file")
  rm -f "$stderr_file"
  [[ "$stderr_content" == *"/init-rpm"* ]]
}

@test "source=compact exits 0 with no output" {
  seed_minimal_trackers
  run run_session_start compact
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "active marker + clear source — resume path regardless of last-session state" {
  seed_minimal_trackers
  cat > "$PM_DIR/~rpm-session-start" <<EOF
task: fix flux capacitor
started: 2026-04-12T10:00:00Z
EOF
  # No ~rpm-last-session file — but source=clear means same CC process, so resume.
  run run_session_start clear
  [ "$status" -eq 0 ]
  [[ "$output" == *"rpm: resuming"* ]]
  [[ "$output" == *"fix flux capacitor"* ]]
  [[ "$output" != *"didn't wrap up"* ]]
}

@test "active marker resume is committed, not an A/B/C confirmation prompt" {
  seed_minimal_trackers
  cat > "$PM_DIR/~rpm-session-start" <<EOF
session_id: test-sess-123
started: 2026-04-12T10:00:00Z
task: fix flux capacitor
EOF
  run run_session_start clear test-sess-123
  [ "$status" -eq 0 ]
  [[ "$output" == *"Treat that task as already selected"* ]]
  [[ "$output" == *"Create or continue the native task for: fix flux capacitor"* ]]
  [[ "$output" != *"with ONE question offering these options"* ]]
  [[ "$output" != *"A. Continue the in-flight task"* ]]
  [[ "$output" != *"B. Switch to something else"* ]]
  [[ "$output" != *"C. Wrap up with /session-end"* ]]
}

@test "active marker + startup + no last-session = stale — soft note, falls through to backlog" {
  seed_minimal_trackers
  cat > "$PM_DIR/~rpm-session-start" <<EOF
task: fix flux capacitor
started: 2026-04-12T10:00:00Z
session_id: abc123def
EOF
  run run_session_start startup
  [ "$status" -eq 0 ]
  [[ "$output" == *"previous session didn't wrap up"* ]]
  [[ "$output" == *"/resume abc123def"* ]]
  [[ "$output" != *"Do NOT present the backlog menu"* ]]
  [[ "$output" != *"rpm: resuming"* ]]
  # Falls through to normal flow — backlog menu visible.
  [[ "$output" == *"Your rpm backlog"* ]]
}

@test "active marker + startup + fresh last-session = resume" {
  seed_minimal_trackers
  cat > "$PM_DIR/~rpm-session-start" <<EOF
task: fix flux capacitor
started: 2026-04-12T10:00:00Z
EOF
  # last-session ended AFTER current marker started — current work is in-flight.
  cat > "$PM_DIR/~rpm-last-session" <<EOF
task: earlier thing
ended: 2026-04-12T11:00:00Z
next: follow-up
EOF
  run run_session_start startup
  [ "$status" -eq 0 ]
  [[ "$output" == *"rpm: resuming"* ]]
  [[ "$output" != *"didn't wrap up"* ]]
}

@test "--continue workflow (source=resume, mismatched session_id) still detects stale" {
  # The user's `c` wrapper adds --continue by default; CC loads the prior
  # conversation but spawns a NEW process with a NEW session_id. Source
  # comes through as "resume". Stale detection must fire on session_id
  # mismatch regardless of source.
  seed_minimal_trackers
  cat > "$PM_DIR/~rpm-session-start" <<EOF
task: old task
started: 2026-04-12T10:00:00Z
session_id: old-process-sess
EOF
  # last-session is missing → stale
  run run_session_start resume  # new CC process via --continue
  [ "$status" -eq 0 ]
  [[ "$output" == *"previous session didn't wrap up"* ]]
}

@test "active marker + mismatched session_id + stale last-session = stale path" {
  seed_minimal_trackers
  cat > "$PM_DIR/~rpm-session-start" <<EOF
task: current task
started: 2026-04-12T15:00:00Z
session_id: prior-sess-id
EOF
  # last-session predates current marker — stale.
  cat > "$PM_DIR/~rpm-last-session" <<EOF
task: some older thing
ended: 2026-04-11T12:00:00Z
next: something
EOF
  # default hook session_id is test-sess-123 — mismatch from marker's prior-sess-id
  run run_session_start startup
  [ "$status" -eq 0 ]
  [[ "$output" == *"previous session didn't wrap up"* ]]
}

@test "paired start + handoff markers — silently cleaned, no stale warning" {
  # Repro for the /clear-after-/session-end bug: prior CC process ran
  # /session-end (writing ~rpm-session-end) then /clear proactively rewrote
  # ~rpm-session-start with the same session_id. The next CC process
  # should see the pair and silently reset — nothing to wrap up.
  seed_minimal_trackers
  cat > "$PM_DIR/~rpm-session-start" <<EOF
session_id: prior-proc-sess
started: 2026-04-12T10:30:00Z
task: (unassigned)
EOF
  cat > "$PM_DIR/~rpm-session-end" <<EOF
session_id: prior-proc-sess
EOF
  run run_session_start startup new-sess
  [ "$status" -eq 0 ]
  [[ "$output" != *"didn't wrap up"* ]]
  [[ "$output" != *"rpm: resuming"* ]]
  # Both paired markers are consumed; proactive block writes a fresh one.
  [ ! -f "$PM_DIR/~rpm-session-end" ]
  marker_content=$(cat "$PM_DIR/~rpm-session-start")
  [[ "$marker_content" == *"session_id: new-sess"* ]]
  [[ "$marker_content" == *"task: (unassigned)"* ]]
}

@test "start marker without handoff = stale (unpaired)" {
  # A start marker from a prior CC process without a matching handoff
  # means /session-end never ran — real unfinished work.
  seed_minimal_trackers
  cat > "$PM_DIR/~rpm-session-start" <<EOF
session_id: prior-proc-sess
started: 2026-04-12T10:30:00Z
task: real work
EOF
  run run_session_start startup new-sess
  [ "$status" -eq 0 ]
  [[ "$output" == *"didn't wrap up"* ]]
}

@test "handoff with mismatched session_id does not rescue stale marker" {
  # Handoff claims session-a wrapped up, but the start marker belongs to
  # session-b. They don't pair — session-b never wrapped up.
  seed_minimal_trackers
  cat > "$PM_DIR/~rpm-session-start" <<EOF
session_id: session-b
started: 2026-04-12T12:00:00Z
task: real work
EOF
  cat > "$PM_DIR/~rpm-session-end" <<EOF
session_id: session-a
EOF
  run run_session_start startup session-c
  [ "$status" -eq 0 ]
  [[ "$output" == *"didn't wrap up"* ]]
}

@test "orphan handoff (no start marker) is cleaned up" {
  # A handoff left over from a prior CC process with no active marker
  # should just be deleted — nothing to pair with.
  seed_minimal_trackers
  cat > "$PM_DIR/~rpm-session-end" <<EOF
session_id: long-gone-sess
EOF
  run run_session_start startup fresh-sess
  [ "$status" -eq 0 ]
  [ ! -f "$PM_DIR/~rpm-session-end" ]
  # Fresh proactive marker written for the new session
  marker_content=$(cat "$PM_DIR/~rpm-session-start")
  [[ "$marker_content" == *"session_id: fresh-sess"* ]]
}

@test "handoff matching current CC session is preserved (mid-/clear)" {
  # /session-end just wrote the handoff for this CC process; /clear fires
  # SessionStart, marker is absent. The handoff must survive so the next
  # proactive-created start marker pairs with it on the NEXT restart.
  seed_minimal_trackers
  cat > "$PM_DIR/~rpm-session-end" <<EOF
session_id: same-proc-sess
EOF
  run run_session_start clear same-proc-sess
  [ "$status" -eq 0 ]
  [ -f "$PM_DIR/~rpm-session-end" ]
  # Proactive block still wrote the new start marker with same session_id
  marker_content=$(cat "$PM_DIR/~rpm-session-start")
  [[ "$marker_content" == *"session_id: same-proc-sess"* ]]
}

@test "fresh session renders backlog menu with rpm backlog title" {
  seed_minimal_trackers
  cat > "$PM_DIR/future/tasks.org" <<'EOF'
* Work
** TODO alpha task
   :PROPERTIES:
   :ID: alpha
   :END:
** DONE done task
   :PROPERTIES:
   :ID: delta
   :END:
EOF
  run run_session_start startup
  [ "$status" -eq 0 ]
  [[ "$output" == *"Your rpm backlog:"* ]]
  [[ "$output" != *"scoreboard:"* ]]
  [[ "$output" == *"alpha task"* ]]
  [[ "$output" != *"done task"* ]]
}

@test "menu has no blank lines between parent groups" {
  seed_minimal_trackers
  cat > "$PM_DIR/future/tasks.org" <<'EOF'
* First group
** TODO task-a
   :PROPERTIES:
   :ID: a
   :END:
* Second group
** TODO task-b
   :PROPERTIES:
   :ID: b
   :END:
EOF
  run run_session_start startup
  [ "$status" -eq 0 ]
  # Between the last item of First group and the "Second group" heading
  # there should be no blank line.
  [[ "$output" != *$'1. task-a\n\nSecond group'* ]]
  [[ "$output" == *$'1. task-a\nSecond group'* ]]
}

@test "BLOCKED_BY with incomplete dep hides task" {
  seed_minimal_trackers
  cat > "$PM_DIR/future/tasks.org" <<'EOF'
* Work
** TODO first
   :PROPERTIES:
   :ID: first
   :END:
** BLOCKED blocked-task
   :PROPERTIES:
   :ID: second
   :BLOCKED_BY: first
   :END:
EOF
  run run_session_start startup
  [[ "$output" == *"first"* ]]
  [[ "$output" != *"blocked-task"* ]]
}

@test "BLOCKED_BY with completed dep surfaces task" {
  seed_minimal_trackers
  cat > "$PM_DIR/future/tasks.org" <<'EOF'
* Work
** DONE first
   :PROPERTIES:
   :ID: first
   :END:
** BLOCKED second
   :PROPERTIES:
   :ID: second
   :BLOCKED_BY: first
   :END:
EOF
  run run_session_start startup
  [[ "$output" == *"second"* ]]
}

@test "CANCELLED tasks are hidden like DONE" {
  seed_minimal_trackers
  cat > "$PM_DIR/future/tasks.org" <<'EOF'
* Work
** TODO visible task
   :PROPERTIES:
   :ID: v1
   :END:
** CANCELLED abandoned task
   :PROPERTIES:
   :ID: c1
   :END:
EOF
  run run_session_start startup
  [[ "$output" == *"visible task"* ]]
  [[ "$output" != *"abandoned task"* ]]
}

@test "BLOCKED_BY with CANCELLED dep unblocks (terminal states)" {
  seed_minimal_trackers
  cat > "$PM_DIR/future/tasks.org" <<'EOF'
* Work
** CANCELLED killed prerequisite
   :PROPERTIES:
   :ID: killed
   :END:
** BLOCKED downstream
   :PROPERTIES:
   :ID: down
   :BLOCKED_BY: killed
   :END:
EOF
  run run_session_start startup
  [[ "$output" == *"downstream"* ]]
}

@test "empty backlog — no Pick prompt, brainstorm instructions instead" {
  seed_minimal_trackers
  # tasks.org exists but has no actionable TODOs
  cat > "$PM_DIR/future/tasks.org" <<'EOF'
#+TITLE: test
* Active
** DONE already done
   :PROPERTIES:
   :ID: d1
   :END:
EOF
  run run_session_start startup
  [ "$status" -eq 0 ]
  [[ "$output" == *"(no actionable tasks)"* ]]
  [[ "$output" != *"Pick #"* ]]
  [[ "$output" != *"S: something else"* ]]
  [[ "$output" == *"Review every TODO/BLOCKED/"* ]]
  [[ "$output" == *"Draft 2"*"candidate task"* ]]
}

@test "fresh startup writes proactive marker with unassigned task" {
  seed_minimal_trackers
  run run_session_start startup test-sess-xyz
  [ "$status" -eq 0 ]
  [ -f "$PM_DIR/~rpm-session-start" ]
  marker_content=$(cat "$PM_DIR/~rpm-session-start")
  [[ "$marker_content" == *"session_id: test-sess-xyz"* ]]
  [[ "$marker_content" == *"task: (unassigned)"* ]]
  [[ "$marker_content" == *"started:"* ]]
}

@test "stale-path clears the old marker and writes a fresh one for the new session" {
  # Soft stale handling: old task info is surfaced in the note, then the
  # marker is rewritten for the current session so the user can move on.
  seed_minimal_trackers
  cat > "$PM_DIR/~rpm-session-start" <<EOF
session_id: original-sess
started: 2026-04-12T10:00:00Z
task: original task
EOF
  run run_session_start startup new-sess
  [ "$status" -eq 0 ]
  # Note preserves the old task + session_id for manual /resume.
  [[ "$output" == *"original task"* ]]
  [[ "$output" == *"/resume original-sess"* ]]
  # But the marker is refreshed for the new session.
  marker_content=$(cat "$PM_DIR/~rpm-session-start")
  [[ "$marker_content" == *"session_id: new-sess"* ]]
  [[ "$marker_content" == *"task: (unassigned)"* ]]
  [[ "$marker_content" != *"original-sess"* ]]
}

@test "last-session next message appears when present" {
  seed_minimal_trackers
  : > "$PM_DIR/future/tasks.org"
  cat > "$PM_DIR/~rpm-last-session" <<EOF
task: prior thing
ended: 2026-04-11T12:00:00Z
next: wire up the widget
EOF
  run run_session_start startup
  [[ "$output" == *"wire up the widget"* ]]
}

@test "last-session next handoff is committed, not a confirmation prompt" {
  seed_minimal_trackers
  : > "$PM_DIR/future/tasks.org"
  cat > "$PM_DIR/~rpm-last-session" <<EOF
task: prior thing
ended: 2026-04-11T12:00:00Z
next: wire up the widget
EOF
  run run_session_start startup
  [ "$status" -eq 0 ]
  [[ "$output" == *"Treat that handoff as already selected"* ]]
  [[ "$output" == *"Do NOT ask whether to"*"continue it"* ]]
  [[ "$output" == *"task: wire up the widget"* ]]
  [[ "$output" != *"confirm you should start"* ]]
  [[ "$output" != *"offer picking something else"* ]]
}

# --- (unassigned) fallback for display: prefer last-session top_actionable ---

@test "(unassigned) marker + last-session top_actionable → resume nudge shows top_actionable" {
  seed_minimal_trackers
  # Marker has the placeholder, same session_id so we hit the resume path.
  cat > "$PM_DIR/~rpm-session-start" <<EOF
session_id: same-proc-sess
started: 2026-04-12T10:00:00Z
task: (unassigned)
EOF
  cat > "$PM_DIR/~rpm-last-session" <<EOF
task: prior session task
ended: 2026-04-11T12:00:00Z
top_actionable: Wire up the widget
next: something else
EOF
  run run_session_start clear same-proc-sess
  [ "$status" -eq 0 ]
  # Display substitution: resume header should show top_actionable, not (unassigned).
  [[ "$output" == *"rpm: resuming — Wire up the widget"* ]]
  [[ "$output" != *"rpm: resuming — (unassigned)"* ]]
}

@test "(unassigned) marker + last-session with only next: → falls back to next:" {
  seed_minimal_trackers
  cat > "$PM_DIR/~rpm-session-start" <<EOF
session_id: same-proc-sess
started: 2026-04-12T10:00:00Z
task: (unassigned)
EOF
  cat > "$PM_DIR/~rpm-last-session" <<EOF
task: prior session task
ended: 2026-04-11T12:00:00Z
next: do the thing
EOF
  run run_session_start clear same-proc-sess
  [ "$status" -eq 0 ]
  [[ "$output" == *"rpm: resuming — do the thing"* ]]
  [[ "$output" != *"(unassigned)"* ]]
}

@test "(unassigned) marker with no last-session → displays (no task recorded)" {
  seed_minimal_trackers
  cat > "$PM_DIR/~rpm-session-start" <<EOF
session_id: same-proc-sess
started: 2026-04-12T10:00:00Z
task: (unassigned)
EOF
  # No ~rpm-last-session file
  run run_session_start clear same-proc-sess
  [ "$status" -eq 0 ]
  [[ "$output" == *"rpm: resuming — (no task recorded)"* ]]
  [[ "$output" != *"rpm: resuming — (unassigned)"* ]]
}

# --- ~rpm-context.md mirror (Codex SessionStart strategy) ---
# Claude captures SessionStart stdout natively; Codex does not. The hook
# mirrors the same stdout to docs/rpm/~rpm-context.md so AGENTS.md can
# pick it up via a `# include:` directive. Both runtimes use the file.

@test "context mirror: main path writes ~rpm-context.md byte-equivalent to stdout" {
  seed_minimal_trackers
  # Capture stdout only (bats `run` merges stderr — the rpm-tip line goes
  # to stderr and would not appear in the file mirror).
  local stdout_file
  stdout_file=$(mktemp)
  echo '{"source":"startup","session_id":"test-sess-123"}' \
    | bash "$CLAUDE_PLUGIN_ROOT/hooks/session-start-auto.sh" \
      > "$stdout_file" 2>/dev/null
  [ -f "$PM_DIR/~rpm-context.md" ]
  # The file contains the same banner/sections the model would receive.
  grep -q '^=== git ===$' "$PM_DIR/~rpm-context.md"
  grep -q '^=== context ===$' "$PM_DIR/~rpm-context.md"
  grep -q '^=== backlog_menu ===$' "$PM_DIR/~rpm-context.md"
  grep -q '^=== instructions ===$' "$PM_DIR/~rpm-context.md"
  grep -q 'rpm: session active' "$PM_DIR/~rpm-context.md"
  # Stdout content matches the file content, byte for byte.
  cmp -s "$stdout_file" "$PM_DIR/~rpm-context.md"
  cmp_status=$?
  rm -f "$stdout_file"
  [ "$cmp_status" -eq 0 ]
}

@test "context mirror: resume path also writes ~rpm-context.md" {
  seed_minimal_trackers
  cat > "$PM_DIR/~rpm-session-start" <<EOF
session_id: same-proc-sess
started: 2026-04-12T10:00:00Z
task: fix flux capacitor
EOF
  run run_session_start clear same-proc-sess
  [ "$status" -eq 0 ]
  [ -f "$PM_DIR/~rpm-context.md" ]
  grep -q 'rpm: resuming' "$PM_DIR/~rpm-context.md"
  grep -q 'fix flux capacitor' "$PM_DIR/~rpm-context.md"
}

@test "context mirror: not written when docs/rpm/ missing (skip-no-init guard)" {
  rm -rf "$PM_DIR"
  local stderr_file
  stderr_file=$(mktemp)
  run bash -c "echo '{\"source\":\"startup\",\"session_id\":\"abc\"}' | bash '$CLAUDE_PLUGIN_ROOT/hooks/session-start-auto.sh' 2>'$stderr_file'"
  rm -f "$stderr_file"
  [ "$status" -eq 0 ]
  # PM_DIR doesn't exist → file can't be written.
  [ ! -f "$PM_DIR/~rpm-context.md" ]
}

@test "context mirror: compact source skips file write (no stdout to mirror)" {
  seed_minimal_trackers
  run run_session_start compact
  [ "$status" -eq 0 ]
  # compact returns before the mirror is set up; no file should be created.
  [ ! -f "$PM_DIR/~rpm-context.md" ]
}

@test "context mirror: re-running overwrites prior file (no append leak)" {
  seed_minimal_trackers
  # First run produces a file.
  run run_session_start startup first-sess
  [ -f "$PM_DIR/~rpm-context.md" ]
  size_first=$(wc -c < "$PM_DIR/~rpm-context.md")
  # Second run should overwrite — not append.
  run run_session_start startup second-sess
  [ -f "$PM_DIR/~rpm-context.md" ]
  size_second=$(wc -c < "$PM_DIR/~rpm-context.md")
  # Sizes should be similar (same content shape). Either way, no run-on.
  # The new content should contain only one "=== git ===" header.
  count=$(grep -c '^=== git ===$' "$PM_DIR/~rpm-context.md")
  [ "$count" -eq 1 ]
}
