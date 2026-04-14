#!/bin/bash
# Stop hook: validate /session-end produced a well-formed handoff.
# Fires at most once per commit (dedupes via flag file). Silent unless
# the most recent commit is a session-end commit AND the handoff
# artifacts (today's past log + status.md Last updated) look incomplete.
#
# Pattern adapted from shihchengwei-lab/claude-code-session-kit's
# handoff-check.sh.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
PM_DIR="$PROJECT_DIR/docs/rpm"
FLAG="$PM_DIR/~rpm-last-validated-commit"

[ -d "$PM_DIR" ] || exit 0
git -C "$PROJECT_DIR" rev-parse --git-dir >/dev/null 2>&1 || exit 0

# Only act when the most-recent commit is a session-end commit.
LAST_MSG=$(git -C "$PROJECT_DIR" log -1 --format=%s 2>/dev/null)
echo "$LAST_MSG" | grep -qE '^rpm: session end' || exit 0

# Dedupe: each commit gets validated once, then never again.
LAST_COMMIT=$(git -C "$PROJECT_DIR" rev-parse HEAD 2>/dev/null)
[ "$(cat "$FLAG" 2>/dev/null)" = "$LAST_COMMIT" ] && exit 0

TODAY=$(date +%Y-%m-%d)
LOG="$PM_DIR/past/$TODAY.md"
STATUS="$PM_DIR/present/status.md"
ERRORS=""

# Today's daily log: must exist, must have Accomplished + Next sections.
if [ ! -f "$LOG" ]; then
  ERRORS="${ERRORS}  - past/$TODAY.md does not exist\n"
else
  grep -qE '^#+.*Accomplished' "$LOG" \
    || ERRORS="${ERRORS}  - past/$TODAY.md missing Accomplished section\n"
  grep -qE '^#+.*Next' "$LOG" \
    || ERRORS="${ERRORS}  - past/$TODAY.md missing Next section\n"
fi

# ~rpm-last-session: must exist with task + ended + next fields.
LAST_SESSION="$PM_DIR/~rpm-last-session"
if [ ! -f "$LAST_SESSION" ]; then
  ERRORS="${ERRORS}  - ~rpm-last-session not written (next-session resume will have nothing to offer)\n"
else
  grep -qE '^task: .+'  "$LAST_SESSION" || ERRORS="${ERRORS}  - ~rpm-last-session missing 'task:' line\n"
  grep -qE '^ended: .+' "$LAST_SESSION" || ERRORS="${ERRORS}  - ~rpm-last-session missing 'ended:' line\n"
  grep -qE '^next: .+'  "$LAST_SESSION" || ERRORS="${ERRORS}  - ~rpm-last-session missing 'next:' line\n"
fi

# Active-session marker should be gone after session-end.
for f in ~rpm-session-start ~rpm-compact-state ~rpm-learnings.jsonl ~rpm-native-tasks.jsonl ~rpm-task-candidates.jsonl; do
  [ -e "$PM_DIR/$f" ] && ERRORS="${ERRORS}  - $f still present (should be cleared in Phase 5)\n"
done

# status.md: Last updated field should be today.
if [ -f "$STATUS" ]; then
  UPDATED=$(grep -oE 'Last updated[^0-9]*[0-9]{4}-[0-9]{2}-[0-9]{2}' "$STATUS" 2>/dev/null \
            | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)
  if [ -n "$UPDATED" ] && [ "$UPDATED" != "$TODAY" ]; then
    ERRORS="${ERRORS}  - status.md 'Last updated' is $UPDATED (expected $TODAY)\n"
  fi
fi

if [ -n "$ERRORS" ]; then
  {
    echo "rpm: /session-end handoff looks incomplete:"
    printf "%b" "$ERRORS"
  } >&2
fi

# Mark this commit as validated so subsequent Stop fires skip.
echo "$LAST_COMMIT" > "$FLAG"
exit 0
