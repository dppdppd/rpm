#!/usr/bin/env bats
# Structural guard: the auditor agent must keep its Phase 0 noun
# cross-check section and the three finding tags. Prevents accidental
# strip during edits.
#
# See docs/rpm/future/2026-05-26-auditor-code-crosscheck.md for the
# rationale (reddit-reports incident: 13 confident findings against
# drifted docs without grepping the code).
#
# NOTE: This is a STRUCTURAL test only. The auditor is an LLM agent
# following a markdown prompt — bats cannot exercise its runtime
# behavior. Phase-0 effectiveness can only be validated operationally
# by re-running /audit documents against a project with known doc
# drift and verifying that orphaned entities surface as doc-orphan.

REPO_ROOT="$BATS_TEST_DIRNAME/../.."
CLAUDE_AGENT="$BATS_TEST_DIRNAME/../agents/auditor.md"
CODEX_AGENT="$REPO_ROOT/codex/.codex/skills/audit/references/auditor.md"

# Codex mirror only exists in the monorepo layout. Subtree-split CI
# (plugin/ only) skips codex-side assertions.
have_codex_mirror() {
  [ -f "$CODEX_AGENT" ]
}

auditor_files() {
  printf '%s\n' "$CLAUDE_AGENT"
  have_codex_mirror && printf '%s\n' "$CODEX_AGENT"
}

@test "auditor agent exists (Claude side always; Codex mirror in monorepo)" {
  [ -f "$CLAUDE_AGENT" ]
  if have_codex_mirror; then
    [ -f "$CODEX_AGENT" ]
  fi
}

@test "auditor agent contains a Phase 0 section" {
  for f in $(auditor_files); do
    run grep -F 'Phase 0' "$f"
    [ "$status" -eq 0 ] || { echo "missing 'Phase 0' in $f"; return 1; }
  done
}

@test "auditor agent mentions doc-stale exactly once" {
  for f in $(auditor_files); do
    count=$(grep -c 'doc-stale' "$f")
    [ "$count" -eq 1 ] || { echo "expected 1 'doc-stale' in $f, got $count"; return 1; }
  done
}

@test "auditor agent mentions doc-orphan exactly once" {
  for f in $(auditor_files); do
    count=$(grep -c 'doc-orphan' "$f")
    [ "$count" -eq 1 ] || { echo "expected 1 'doc-orphan' in $f, got $count"; return 1; }
  done
}

@test "auditor agent mentions code-undocumented exactly once" {
  for f in $(auditor_files); do
    count=$(grep -c 'code-undocumented' "$f")
    [ "$count" -eq 1 ] || { echo "expected 1 'code-undocumented' in $f, got $count"; return 1; }
  done
}

@test "auditor agent Claude + Codex mirrors are byte-identical" {
  have_codex_mirror || skip "codex mirror not present (subtree-split layout)"
  run diff "$CLAUDE_AGENT" "$CODEX_AGENT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
