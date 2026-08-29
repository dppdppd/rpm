#!/usr/bin/env bats

load helpers

setup()    { setup_sandbox; seed_minimal_trackers; }
teardown() {
  rm -f /tmp/rpm-ctx-counter-ctxmon-*
  teardown_sandbox
}

MARKER_REL="docs/rpm/~rpm-session-start"

seed_marker() {
  cat > "$TEST_DIR/$MARKER_REL" <<EOF
session_id: sess-1
started: 2026-04-13T10:00:00Z
task: x
EOF
}

# Run the hook with a synthesized transcript containing one assistant
# message whose usage block sums to the requested token count (placed in
# cache_read_input_tokens — same code path as input/cache_creation).
run_monitor() {
  local tokens="$1"
  local sid="${2:-ctxmon-$$}"
  local window="${3:-}"
  local transcript
  transcript="$(mktemp)"
  if [ "$tokens" -gt 0 ]; then
    printf '{"type":"assistant","message":{"role":"assistant","usage":{"input_tokens":0,"cache_creation_input_tokens":0,"cache_read_input_tokens":%d,"output_tokens":1}}}\n' \
      "$tokens" > "$transcript"
  fi
  if [ -n "$window" ]; then
    RPM_CONTEXT_TOKENS="$window" \
      printf '{"session_id":"%s","transcript_path":"%s"}' "$sid" "$transcript" \
      | RPM_CONTEXT_TOKENS="$window" bash "$CLAUDE_PLUGIN_ROOT/hooks/context-monitor.sh"
  else
    printf '{"session_id":"%s","transcript_path":"%s"}' "$sid" "$transcript" \
      | bash "$CLAUDE_PLUGIN_ROOT/hooks/context-monitor.sh"
  fi
  rm -f "$transcript"
}

prime_counter() {
  local sid="$1"
  echo 9 > "/tmp/rpm-ctx-counter-$sid"
}

@test "no-op when docs/rpm missing" {
  rm -rf "$PM_DIR"
  run run_monitor 500000
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "no-op when no active session marker" {
  run run_monitor 500000
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "skips first tool call silently" {
  seed_marker
  sid="ctxmon-first-$$"
  run run_monitor 800000 "$sid"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "silent when more than 10% of window remains (1M default)" {
  seed_marker
  sid="ctxmon-under-$$"
  prime_counter "$sid"
  # 850K used → 150k remaining (>100k threshold) → silent.
  run run_monitor 850000 "$sid"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "emits recommendation when fewer than 10% of window remains (1M default)" {
  seed_marker
  sid="ctxmon-alert-$$"
  prime_counter "$sid"
  # 950K used → 50k remaining (<100k threshold) → trips.
  run run_monitor 950000 "$sid"
  [ "$status" -eq 0 ]
  [[ "$output" == *"under 50k tokens remaining"* ]]
  [[ "$output" == *"<10% of window"* ]]
  [[ "$output" == *"/compact is the right tool"* ]]
  [[ "$output" == *"/session-end is for stopping"* ]]
  [[ "$output" != *"consider /session-end"* ]]
  [[ "$output" == *"hookSpecificOutput"* ]]
  echo "$output" | jq -e . >/dev/null
}

@test "RPM_CONTEXT_TOKENS override — 30k remaining on 200K window is silent" {
  seed_marker
  sid="ctxmon-200k-$$"
  prime_counter "$sid"
  # 170K tokens on a 200K window → 30k remaining (>20k threshold) → silent.
  run run_monitor 170000 "$sid" 200000
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "RPM_CONTEXT_TOKENS override — 15k remaining on 200K window trips" {
  seed_marker
  sid="ctxmon-200kstop-$$"
  prime_counter "$sid"
  # 185K used on a 200K window → 15k remaining (<20k threshold) → trips.
  run run_monitor 185000 "$sid" 200000
  [ "$status" -eq 0 ]
  [[ "$output" == *"under 15k tokens remaining"* ]]
  [[ "$output" == *"<10% of window"* ]]
}

@test "silent on non-10th call even over threshold" {
  seed_marker
  sid="ctxmon-skip-$$"
  echo 4 > "/tmp/rpm-ctx-counter-$sid"
  # 950K used → 50k remaining → would trip on 10th call.
  run run_monitor 950000 "$sid"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "silent when transcript_path missing from payload" {
  seed_marker
  sid="ctxmon-notp-$$"
  prime_counter "$sid"
  run bash -c "echo '{\"session_id\":\"$sid\"}' | bash \"\$CLAUDE_PLUGIN_ROOT/hooks/context-monitor.sh\""
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "skips sidechain assistant entries, uses main-chain usage" {
  seed_marker
  sid="ctxmon-sidechain-$$"
  prime_counter "$sid"
  transcript="$(mktemp)"
  # Main-chain at 950K (50k remaining, trips on 1M default), sidechain at 5%.
  {
    printf '{"type":"assistant","isSidechain":false,"message":{"role":"assistant","usage":{"input_tokens":0,"cache_creation_input_tokens":0,"cache_read_input_tokens":950000,"output_tokens":1}}}\n'
    printf '{"type":"assistant","isSidechain":true,"message":{"role":"assistant","usage":{"input_tokens":0,"cache_creation_input_tokens":0,"cache_read_input_tokens":50000,"output_tokens":1}}}\n'
  } > "$transcript"
  run bash -c "printf '{\"session_id\":\"$sid\",\"transcript_path\":\"$transcript\"}' | bash \"\$CLAUDE_PLUGIN_ROOT/hooks/context-monitor.sh\""
  [ "$status" -eq 0 ]
  [[ "$output" == *"under 50k tokens remaining"* ]]
  rm -f "$transcript"
}

@test "silent when transcript has no assistant usage block" {
  seed_marker
  sid="ctxmon-nousage-$$"
  prime_counter "$sid"
  transcript="$(mktemp)"
  echo '{"type":"user","message":{"role":"user","content":"hi"}}' > "$transcript"
  run bash -c "printf '{\"session_id\":\"$sid\",\"transcript_path\":\"$transcript\"}' | bash \"\$CLAUDE_PLUGIN_ROOT/hooks/context-monitor.sh\""
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  rm -f "$transcript"
}

# --- Counter-file robustness (race condition fix) ---

@test "recovers from a pre-corrupted multi-line counter file" {
  seed_marker
  sid="ctxmon-corrupt-$$"
  # Simulate a torn write left behind by a previous concurrent run.
  printf '1\n50\n' > "/tmp/rpm-ctx-counter-$sid"
  run run_monitor 0 "$sid"
  [ "$status" -eq 0 ]
  # Stderr would have carried the old "syntax error in expression" crash.
  [ -z "$output" ]
  # Defensive read takes the first line (1), strips digits-only, increments to 2.
  recovered=$(cat "/tmp/rpm-ctx-counter-$sid")
  [ "$recovered" = "2" ]
}

@test "rewrites a clean single-line integer after corrupted read" {
  seed_marker
  sid="ctxmon-rewrite-$$"
  # Pre-seed with junk that previously crashed line 29.
  printf 'garbage\n42\n' > "/tmp/rpm-ctx-counter-$sid"
  run run_monitor 0 "$sid"
  [ "$status" -eq 0 ]
  # File is now exactly one digit-line ending in a newline.
  line_count=$(wc -l < "/tmp/rpm-ctx-counter-$sid")
  [ "$line_count" -eq 1 ]
  body=$(cat "/tmp/rpm-ctx-counter-$sid")
  [[ "$body" =~ ^[0-9]+$ ]]
}

@test "20 concurrent invocations never crash and produce a valid integer counter" {
  seed_marker
  sid="ctxmon-race-$$"
  : > "/tmp/rpm-ctx-counter-$sid"

  transcript="$(mktemp)"
  # Force the silent path (no usage block) so the hook focuses on the
  # counter update only — keeps the test about race safety, not the
  # threshold message.
  echo '{"type":"user","message":{"role":"user","content":"hi"}}' > "$transcript"

  stderr_log="$(mktemp)"

  for _ in $(seq 1 20); do
    (
      printf '{"session_id":"%s","transcript_path":"%s"}' "$sid" "$transcript" \
        | bash "$CLAUDE_PLUGIN_ROOT/hooks/context-monitor.sh" \
            >/dev/null 2>>"$stderr_log"
    ) &
  done
  wait

  # No syntax-error crash output from any worker — the file-format
  # corruption that previously crashed line 29 is gone.
  ! grep -q "syntax error" "$stderr_log"
  ! grep -q "integer expression expected" "$stderr_log"

  # Counter file is a clean one-line integer (atomic mv guarantee).
  line_count=$(wc -l < "/tmp/rpm-ctx-counter-$sid")
  [ "$line_count" -eq 1 ]
  final=$(cat "/tmp/rpm-ctx-counter-$sid")
  [[ "$final" =~ ^[0-9]+$ ]]
  # Atomic-write fix (approach #2) eliminates file corruption but does
  # NOT serialize the read-modify-write — concurrent workers may still
  # lose an increment. Contract: counter is a valid integer in (0, 20].
  [ "$final" -gt 0 ]
  [ "$final" -le 20 ]

  rm -f "$transcript" "$stderr_log"
}
