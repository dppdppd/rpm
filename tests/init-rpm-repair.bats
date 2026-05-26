#!/usr/bin/env bats
# /init-rpm repair helper — gitignore wildcard + AGENTS.md include
# migrations for projects bootstrapped before those rules existed.
#
# Source spec: docs/rpm/future/2026-05-26-init-rpm-gitignore-wildcard.md
#              docs/rpm/future/2026-05-26-init-rpm-agents-md-patch.md

load helpers

setup()    { setup_sandbox; }
teardown() { teardown_sandbox; }

REPAIR_SH() {
  echo "$CLAUDE_PLUGIN_ROOT/skills/init-rpm/scripts/repair.sh"
}

run_repair() {
  RPM_PROJECT_DIR="$TEST_DIR" bash "$(REPAIR_SH)" "$@"
}

# --- .gitignore: wildcard absent → added -----------------------------------

@test "gitignore wildcard absent — appended on repair" {
  cat > "$TEST_DIR/.gitignore" <<'EOF'
node_modules/
*.log
EOF
  run run_repair --auto-yes
  [ "$status" -eq 0 ]
  [[ "$output" == *"action=appended_wildcard"* ]]
  run grep -Fxq 'docs/rpm/~rpm-*' "$TEST_DIR/.gitignore"
  [ "$status" -eq 0 ]
  # Pre-existing content preserved.
  run grep -Fxq 'node_modules/' "$TEST_DIR/.gitignore"
  [ "$status" -eq 0 ]
}

# --- .gitignore: wildcard already present → no duplicate -------------------

@test "gitignore wildcard already present — no duplicate written" {
  cat > "$TEST_DIR/.gitignore" <<'EOF'
node_modules/

# rpm session-state (transient, regenerated per session)
docs/rpm/~rpm-*
EOF
  local before
  before=$(md5sum "$TEST_DIR/.gitignore")
  run run_repair --auto-yes
  [ "$status" -eq 0 ]
  local after
  after=$(md5sum "$TEST_DIR/.gitignore")
  [ "$before" = "$after" ]
  # Wildcard appears exactly once.
  run bash -c "grep -Fxc 'docs/rpm/~rpm-*' '$TEST_DIR/.gitignore'"
  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
}

# --- .gitignore: missing entirely → created --------------------------------

@test "gitignore missing — created with wildcard" {
  rm -f "$TEST_DIR/.gitignore"
  run run_repair --auto-yes
  [ "$status" -eq 0 ]
  [[ "$output" == *"action=created_gitignore"* ]]
  [ -f "$TEST_DIR/.gitignore" ]
  run grep -Fxq 'docs/rpm/~rpm-*' "$TEST_DIR/.gitignore"
  [ "$status" -eq 0 ]
}

# --- .gitignore: explicit entries → collapse offer / auto-collapse ---------

@test "gitignore explicit entries — auto-yes collapses into wildcard" {
  # Same shape as the live repo's .gitignore: 10 explicit entries.
  cat > "$TEST_DIR/.gitignore" <<'EOF'
# Claude Code harness runtime state (lock files, local settings)
.claude/

# Session state — ephemeral, recreated each session
docs/rpm/~rpm-session-start
docs/rpm/~rpm-session-end
docs/rpm/~rpm-compact-state
docs/rpm/~rpm-context.md
docs/rpm/~rpm-learnings.jsonl
docs/rpm/~rpm-native-tasks.jsonl
docs/rpm/~rpm-last-session
docs/rpm/~rpm-last-validated-commit
docs/rpm/~rpm-task-candidates.jsonl
docs/rpm/~rpm-orchestrator-log.jsonl

# Other ignores
node_modules/
EOF

  run run_repair --auto-yes
  [ "$status" -eq 0 ]
  [[ "$output" == *"explicit_count=10"* ]]
  [[ "$output" == *"action=collapsed_explicit count=10"* ]]

  # All 10 explicit lines gone.
  run bash -c "grep -cE '^docs/rpm/~rpm-[A-Za-z0-9.-]+\$' '$TEST_DIR/.gitignore'"
  [ "$output" = "0" ]

  # Wildcard present.
  run grep -Fxq 'docs/rpm/~rpm-*' "$TEST_DIR/.gitignore"
  [ "$status" -eq 0 ]

  # Other content preserved.
  run grep -Fxq '.claude/' "$TEST_DIR/.gitignore"
  [ "$status" -eq 0 ]
  run grep -Fxq 'node_modules/' "$TEST_DIR/.gitignore"
  [ "$status" -eq 0 ]
  run grep -Fxq '# Claude Code harness runtime state (lock files, local settings)' "$TEST_DIR/.gitignore"
  [ "$status" -eq 0 ]
}

@test "gitignore explicit entries — default (no auto-yes) leaves them, offers collapse" {
  cat > "$TEST_DIR/.gitignore" <<'EOF'
docs/rpm/~rpm-session-start
docs/rpm/~rpm-session-end
EOF
  run run_repair
  [ "$status" -eq 0 ]
  # Capture all output-derived assertions BEFORE any other `run` call —
  # bats `run` clobbers $output.
  [[ "$output" == *"action=offer_collapse count=2"* ]]
  [[ "$output" == *"explicit_line=docs/rpm/~rpm-session-start"* ]]
  [[ "$output" == *"explicit_line=docs/rpm/~rpm-session-end"* ]]
  # Wildcard was still appended (non-destructive add).
  run grep -Fxq 'docs/rpm/~rpm-*' "$TEST_DIR/.gitignore"
  [ "$status" -eq 0 ]
  # Explicit lines NOT removed without --auto-yes.
  run grep -Fxq 'docs/rpm/~rpm-session-start' "$TEST_DIR/.gitignore"
  [ "$status" -eq 0 ]
}

# --- AGENTS.md: missing include → prepended --------------------------------

@test "AGENTS.md missing include — prepended at top" {
  cat > "$TEST_DIR/AGENTS.md" <<'EOF'
# Project: foo

This is the agents file.
EOF
  run run_repair --auto-yes
  [ "$status" -eq 0 ]
  [[ "$output" == *"agents_md=include_missing"* ]]
  [[ "$output" == *"action=prepended_at_top"* ]]
  local first_line
  first_line=$(head -n1 "$TEST_DIR/AGENTS.md")
  [ "$first_line" = "# include: docs/rpm/~rpm-context.md" ]
  # Pre-existing content preserved.
  run grep -Fxq '# Project: foo' "$TEST_DIR/AGENTS.md"
  [ "$status" -eq 0 ]
  run grep -Fxq 'This is the agents file.' "$TEST_DIR/AGENTS.md"
  [ "$status" -eq 0 ]
}

# --- AGENTS.md: has include → no change ------------------------------------

@test "AGENTS.md already has include — unchanged" {
  cat > "$TEST_DIR/AGENTS.md" <<'EOF'
# include: docs/rpm/~rpm-context.md

# Project: foo
EOF
  local before
  before=$(md5sum "$TEST_DIR/AGENTS.md")
  run run_repair --auto-yes
  [ "$status" -eq 0 ]
  [[ "$output" == *"agents_md=include_present"* ]]
  local after
  after=$(md5sum "$TEST_DIR/AGENTS.md")
  [ "$before" = "$after" ]
}

# --- AGENTS.md: YAML frontmatter preserved ---------------------------------

@test "AGENTS.md with YAML frontmatter — include lands after frontmatter" {
  cat > "$TEST_DIR/AGENTS.md" <<'EOF'
---
title: Foo agents
version: 2
---

# Project: foo

Body content.
EOF
  run run_repair --auto-yes
  [ "$status" -eq 0 ]
  [[ "$output" == *"action=prepended_after_frontmatter"* ]]
  # First line is still the opening ---.
  local first_line
  first_line=$(head -n1 "$TEST_DIR/AGENTS.md")
  [ "$first_line" = "---" ]
  # Closing --- (the second one) precedes the include line; include must come
  # AFTER the second `---`.
  local close_no inc_no
  close_no=$(awk 'NR>1 && $0=="---" {print NR; exit}' "$TEST_DIR/AGENTS.md")
  inc_no=$(grep -nFx '# include: docs/rpm/~rpm-context.md' "$TEST_DIR/AGENTS.md" | head -n1 | cut -d: -f1)
  [ -n "$close_no" ]
  [ -n "$inc_no" ]
  [ "$inc_no" -gt "$close_no" ]
  # Frontmatter values still intact.
  run grep -Fxq 'title: Foo agents' "$TEST_DIR/AGENTS.md"
  [ "$status" -eq 0 ]
  run grep -Fxq 'version: 2' "$TEST_DIR/AGENTS.md"
  [ "$status" -eq 0 ]
  # Original body still present.
  run grep -Fxq '# Project: foo' "$TEST_DIR/AGENTS.md"
  [ "$status" -eq 0 ]
  run grep -Fxq 'Body content.' "$TEST_DIR/AGENTS.md"
  [ "$status" -eq 0 ]
}

# --- AGENTS.md: absent — tolerated, no offer surfaces ----------------------

@test "AGENTS.md absent — no include offer surfaces" {
  rm -f "$TEST_DIR/AGENTS.md"
  run run_repair --auto-yes
  [ "$status" -eq 0 ]
  [[ "$output" == *"agents_md=absent"* ]]
  [[ "$output" != *"action=prepended"* ]]
  [ ! -f "$TEST_DIR/AGENTS.md" ]
}

# --- --check mode is read-only ---------------------------------------------

@test "--check mode reports but writes nothing" {
  cat > "$TEST_DIR/.gitignore" <<'EOF'
docs/rpm/~rpm-session-start
EOF
  cat > "$TEST_DIR/AGENTS.md" <<'EOF'
# Project: foo
EOF
  local before_gi before_a
  before_gi=$(md5sum "$TEST_DIR/.gitignore")
  before_a=$(md5sum "$TEST_DIR/AGENTS.md")
  run run_repair --check
  [ "$status" -eq 0 ]
  [[ "$output" == *"wildcard=absent"* ]]
  [[ "$output" == *"agents_md=include_missing"* ]]
  local after_gi after_a
  after_gi=$(md5sum "$TEST_DIR/.gitignore")
  after_a=$(md5sum "$TEST_DIR/AGENTS.md")
  [ "$before_gi" = "$after_gi" ]
  [ "$before_a" = "$after_a" ]
}

# --- scope flags isolate each check ----------------------------------------

@test "--gitignore-only skips AGENTS.md check" {
  cat > "$TEST_DIR/AGENTS.md" <<'EOF'
# Project: foo
EOF
  local before
  before=$(md5sum "$TEST_DIR/AGENTS.md")
  run run_repair --gitignore-only --auto-yes
  [ "$status" -eq 0 ]
  [[ "$output" == *"=== gitignore ==="* ]]
  [[ "$output" != *"=== agents_md ==="* ]]
  local after
  after=$(md5sum "$TEST_DIR/AGENTS.md")
  [ "$before" = "$after" ]
}

@test "--agents-only skips gitignore check" {
  rm -f "$TEST_DIR/.gitignore"
  cat > "$TEST_DIR/AGENTS.md" <<'EOF'
# Project: foo
EOF
  run run_repair --agents-only --auto-yes
  [ "$status" -eq 0 ]
  [[ "$output" != *"=== gitignore ==="* ]]
  [[ "$output" == *"=== agents_md ==="* ]]
  # gitignore left untouched.
  [ ! -f "$TEST_DIR/.gitignore" ]
}
