#!/bin/bash
# Codex PostToolUse hook: surface completed rpm workers to the active session.
#
# Codex background agents have an experimental parent wake path, but it is
# best-effort. Workers always write durable backlog-result rows; this hook
# notices pending review rows during later tool use and injects a concise
# reminder into model context.

set -u

PAYLOAD=$(cat)

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-}"
[ -z "$PROJECT_DIR" ] && PROJECT_DIR=$(echo "$PAYLOAD" | jq -r '.cwd // empty' 2>/dev/null)
[ -z "$PROJECT_DIR" ] && PROJECT_DIR=$(echo "$PAYLOAD" | sed -n 's/.*"cwd" *: *"\([^"]*\)".*/\1/p')
[ -z "$PROJECT_DIR" ] && PROJECT_DIR="."

PM_DIR="$PROJECT_DIR/docs/rpm"
[ -d "$PM_DIR" ] || exit 0

PLUGIN_ROOT="${RPM_PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}}"
REVIEW_READY="$PLUGIN_ROOT/skills/next/scripts/review-ready.sh"
[ -f "$REVIEW_READY" ] || exit 0

READY=$(RPM_PROJECT_DIR="$PROJECT_DIR" bash "$REVIEW_READY" 2>/dev/null || true)
[ -n "$READY" ] || exit 0

FIRST=$(printf '%s\n' "$READY" | sed -n '1p')
[ -n "$FIRST" ] || exit 0

NUDGE_DIR="${RPM_REVIEW_READY_NUDGE_DIR:-/tmp}"
mkdir -p "$NUDGE_DIR" 2>/dev/null || NUDGE_DIR="/tmp"
KEY=$(printf '%s' "$PROJECT_DIR|$FIRST" | cksum | awk '{print $1}')
MARKER="$NUDGE_DIR/rpm-review-ready-nudge-$KEY"
[ -f "$MARKER" ] && exit 0
: > "$MARKER" 2>/dev/null || true

SUMMARY=$(printf '%s\n' "$READY" | head -3)
MESSAGE=$(printf 'rpm: worker result ready for review. Run rpm:next before dispatching more backlog work.\n%s' "$SUMMARY")

if command -v jq >/dev/null 2>&1; then
  jq -n --arg msg "$MESSAGE" \
    '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$msg}}'
else
  printf '%s\n' "$MESSAGE"
fi

exit 0
