#!/usr/bin/env bats

# Covers the session-end mechanical scan script
# (plugin/skills/session-end/scripts/scan.sh). Each test sets up
# a sandbox with specific fixtures, invokes the script, and asserts
# against the key=value output contract that downstream skills
# (/session-end, /audit quick) consume.

load helpers

setup()    { setup_sandbox; }
teardown() { teardown_sandbox; }

SCAN_REL="skills/session-end/scripts/scan.sh"

run_scan() {
  bash "$CLAUDE_PLUGIN_ROOT/$SCAN_REL"
}

# Restrict grep to one section so assertions don't accidentally hit
# a key that appears in another section.
section() {
  local name="$1"
  sed -n "/=== $name ===/,/^$/p" <<< "$output"
}

# ----------------------------------------------------------------
# git
# ----------------------------------------------------------------

@test "git: clean repo reports all zeros" {
  run run_scan
  [ "$status" -eq 0 ]
  section git | grep -qE '^modified=0$'
  section git | grep -qE '^untracked=0$'
  section git | grep -qE '^staged=0$'
  section git | grep -qE '^stashes=0$'
}

@test "git: staged and untracked files are counted separately" {
  ( cd "$TEST_DIR" && echo a > a.txt && echo b > b.txt && git add a.txt )
  run run_scan
  [ "$status" -eq 0 ]
  section git | grep -qE '^staged=1$'
  section git | grep -qE '^untracked=1$'
  section git | grep -qE '^modified=0$'
}

# ----------------------------------------------------------------
# claude_md
# ----------------------------------------------------------------

@test "claude_md: absent file reports status=missing" {
  run run_scan
  section claude_md | grep -qE '^lines=0$'
  section claude_md | grep -qE '^status=missing$'
}

@test "claude_md: short file reports status=ok and line count" {
  ( cd "$TEST_DIR" && printf 'a\nb\nc\n' > CLAUDE.md )
  run run_scan
  section claude_md | grep -qE '^lines=3$'
  section claude_md | grep -qE '^status=ok$'
}

# ----------------------------------------------------------------
# broken_refs
# ----------------------------------------------------------------

@test "broken_refs: count=0 when all backticked refs resolve" {
  ( cd "$TEST_DIR" && mkdir -p src && touch src/app.js )
  ( cd "$TEST_DIR" && printf 'See `src/app.js`.\n' > CLAUDE.md )
  run run_scan
  section broken_refs | grep -qE '^count=0$'
}

@test "broken_refs: count=1 for missing relative path" {
  ( cd "$TEST_DIR" && printf 'See `missing/file.md`.\n' > CLAUDE.md )
  run run_scan
  section broken_refs | grep -qE '^count=1$'
  section broken_refs | grep -Fq 'broken=CLAUDE.md:missing/file.md'
}

@test "broken_refs: ignores URLs, absolute paths, shell-command prefixes" {
  ( cd "$TEST_DIR" && printf 'Run `bash plugin/tests/run.sh`; visit `https://example.com/x`; path `/usr/local/bin/thing`.\n' > CLAUDE.md )
  run run_scan
  section broken_refs | grep -qE '^count=0$'
}

@test "broken_refs: context.md paths resolve relative to docs/rpm/" {
  ( cd "$TEST_DIR" && mkdir -p docs/rpm/future && touch docs/rpm/future/tasks.org )
  ( cd "$TEST_DIR" && printf 'Backlog at `future/tasks.org`.\n' > docs/rpm/context.md )
  run run_scan
  section broken_refs | grep -qE '^count=0$'
}

# ----------------------------------------------------------------
# daily_log
# ----------------------------------------------------------------

@test "daily_log: today_exists=true when today's file is present" {
  today=$(date +%Y-%m-%d)
  touch "$PM_DIR/past/$today.md"
  run run_scan
  section daily_log | grep -qE '^today_exists=true$'
  section daily_log | grep -qE "^latest=$today$"
}

# ----------------------------------------------------------------
# session_marker
# ----------------------------------------------------------------

@test "session_marker: exists toggles based on marker file" {
  run run_scan
  section session_marker | grep -qE '^exists=false$'

  echo "session_id: x" > "$PM_DIR/~rpm-session-start"
  run run_scan
  section session_marker | grep -qE '^exists=true$'
}

# ----------------------------------------------------------------
# specs_inventory
# ----------------------------------------------------------------

@test "specs_inventory: status=no_spec_dir when no spec dir exists" {
  printf '# status\n' > "$PM_DIR/present/status.md"
  run run_scan
  section specs_inventory | grep -qE '^status=no_spec_dir$'
}

@test "specs_inventory: counts listed vs unlisted specs, emits samples, excludes _template" {
  printf '# status\n\nActive: spec-a.md\n' > "$PM_DIR/present/status.md"
  mkdir -p "$TEST_DIR/docs/spec"
  touch "$TEST_DIR/docs/spec/_template.md"
  touch "$TEST_DIR/docs/spec/spec-a.md" "$TEST_DIR/docs/spec/spec-b.md" "$TEST_DIR/docs/spec/spec-c.md"
  run run_scan
  section specs_inventory | grep -qE '^total=3$'
  section specs_inventory | grep -qE '^listed=1$'
  section specs_inventory | grep -qE '^unlisted=2$'
  section specs_inventory | grep -qE '^unlisted_sample=spec-b$'
  section specs_inventory | grep -qE '^unlisted_sample=spec-c$'
}

# ----------------------------------------------------------------
# task_deps
# ----------------------------------------------------------------

@test "task_deps: status=no_future_org when tasks.org missing" {
  run run_scan
  section task_deps | grep -qE '^status=no_future_org$'
}

@test "task_deps: detects dangling BLOCKED_BY reference" {
  cat > "$PM_DIR/future/tasks.org" <<'EOF'
* Active
** TODO First
   :PROPERTIES:
   :ID: first
   :END:
** TODO Second
   :PROPERTIES:
   :ID: second
   :BLOCKED_BY: nonexistent
   :END:
EOF
  run run_scan
  section task_deps | grep -qE '^ids=2$'
  section task_deps | grep -qE '^with_deps=1$'
  section task_deps | grep -Fq 'second→nonexistent'
}

@test "task_deps: ready= flags TODO whose blockers are DONE" {
  cat > "$PM_DIR/future/tasks.org" <<'EOF'
* Active
** DONE First
   :PROPERTIES:
   :ID: first
   :END:
** TODO Second
   :PROPERTIES:
   :ID: second
   :BLOCKED_BY: first
   :END:
EOF
  run run_scan
  section task_deps | grep -Fq 'ready='
  section task_deps | grep -Fq 'second'
}

@test "task_deps: DONE entry archived to done.org still satisfies BLOCKED_BY" {
  cat > "$PM_DIR/future/tasks.org" <<'EOF'
* Active
** TODO Second
   :PROPERTIES:
   :ID: second
   :BLOCKED_BY: first
   :END:
EOF
  cat > "$PM_DIR/future/done.org" <<'EOF'
* Active
** DONE First
   CLOSED: [2026-04-21]
   :PROPERTIES:
   :ID: first
   :END:
EOF
  run run_scan
  section task_deps | grep -qE '^ids=2$'
  section task_deps | grep -Fq 'ready='
  section task_deps | grep -Fq 'second'
  # No dangling reference — first resolves via done.org
  ! section task_deps | grep -qE '^dangling='
}

# ----------------------------------------------------------------
# migration
# ----------------------------------------------------------------

@test "migration: count=0 when no old names exist" {
  run run_scan
  section migration | grep -qE '^count=0$'
}

@test "migration: detects flat-era + dir-era old names with move= lines" {
  touch "$PM_DIR/FUTURE.org"          # flat era
  touch "$PM_DIR/future/FUTURE.org"   # dir era
  touch "$PM_DIR/RPM.md"              # context rename
  run run_scan
  section migration | grep -Fq 'move=docs/rpm/FUTURE.org→docs/rpm/future/tasks.org'
  section migration | grep -Fq 'move=docs/rpm/future/FUTURE.org→docs/rpm/future/tasks.org'
  section migration | grep -Fq 'move=docs/rpm/RPM.md→docs/rpm/context.md'
  section migration | grep -qE '^count=3$'
}

# ----------------------------------------------------------------
# learnings_capture
# ----------------------------------------------------------------

@test "learnings_capture: entries=0 when file absent" {
  run run_scan
  section learnings_capture | grep -qE '^entries=0$'
}

@test "learnings_capture: counts lines and echoes excerpts" {
  cat > "$PM_DIR/~rpm-learnings.jsonl" <<'EOF'
{"ts":"2026-04-17T10:00:00Z","session":"s","excerpt":"first excerpt"}
{"ts":"2026-04-17T11:00:00Z","session":"s","excerpt":"second excerpt"}
EOF
  run run_scan
  section learnings_capture | grep -qE '^entries=2$'
  section learnings_capture | grep -Fq 'excerpt=first excerpt'
  section learnings_capture | grep -Fq 'excerpt=second excerpt'
}
