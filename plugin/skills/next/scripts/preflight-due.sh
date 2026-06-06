#!/bin/bash
# preflight-due.sh — decide whether a /next tick needs a FULL preflight
# (drift scan + guidance/contradiction check + worker review) or only a
# LITE pass (cheap inline blocker check + a conditional worker review).
#
# This is for the external `/loop /next` path, where every tick is a
# separate turn with no memory of the last one: it lets repeated ticks
# skip the heavy preflight when it already ran recently and nothing the
# guidance check cares about has changed. The internal `/next <count>`
# sequence does not need this helper — it knows its own first and last
# cycle directly — though it may call it for consistency.
#
# Output: exactly one word on stdout, `full` or `lite`.
# Always exits 0. On ANY uncertainty (no log, no jq, unparseable date,
# clock skew) it prints `full` — the safe, complete choice — so a broken
# read can never silently skip a real preflight.
#
# Freshness window: seconds since the most recent `preflight-full` log
# entry. Default 600 (10 minutes); override with RPM_PREFLIGHT_WINDOW.

set -euo pipefail

WINDOW="${RPM_PREFLIGHT_WINDOW:-600}"

PROJECT_DIR="${RPM_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"
LOG="$PROJECT_DIR/docs/rpm/~rpm-orchestrator-log.jsonl"

emit() { printf '%s\n' "$1"; exit 0; }

# No log yet, or no jq → can't prove freshness → run full.
[ -f "$LOG" ] || emit full
command -v jq >/dev/null 2>&1 || emit full

# Timestamp of the most recent full preflight.
LAST_TS=$(jq -s -r 'map(select(.kind == "preflight-full")) | (.[-1].ts // "")' "$LOG" 2>/dev/null || true)
[ -n "$LAST_TS" ] || emit full

# Convert to epoch; if the date can't be parsed, run full.
LAST_EPOCH=$(date -d "$LAST_TS" +%s 2>/dev/null || true)
[ -n "$LAST_EPOCH" ] || emit full

NOW_EPOCH=$(date +%s 2>/dev/null || echo 0)
AGE=$(( NOW_EPOCH - LAST_EPOCH ))

# Older than the window, or a future timestamp (clock skew) → run full.
if [ "$AGE" -gt "$WINDOW" ] || [ "$AGE" -lt 0 ]; then
  emit full
fi

# Within the window: stay lite only if the guidance inputs (CLAUDE.md,
# AGENTS.md, memory rules, skill bodies) haven't changed since the last
# consistency check. contradiction-check.sh reports `dispatch` when an
# input is newer than its cache — that warrants a fresh full preflight.
CC_SCRIPT="$(dirname "$0")/contradiction-check.sh"
if [ -f "$CC_SCRIPT" ]; then
  CC=$(bash "$CC_SCRIPT" check 2>/dev/null | head -1 | awk '{print $1}' || true)
  if [ "$CC" = "dispatch" ]; then
    emit full
  fi
fi

emit lite
