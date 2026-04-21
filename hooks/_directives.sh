#!/bin/bash
# Shared behavioral directives injected into the instruction block by
# session-start-auto.sh (both resume and normal paths) and post-compact.sh.
# Single source so rules stay consistent across every session entry point.
# Do NOT execute directly.

emit_rpm_directives() {
  echo "When the user mentions future work, capture it as a task."
  echo "When you suggest deferrable work (\"we could X later\", \"worth Y eventually\", \"follow up on Z\"), STOP and ask \"Add to your rpm backlog?\" before moving on — don't just suggest and continue."
  echo "When the user shifts to a new task with little carry-over, suggest /session-end first; one-liner in your rpm backlog (\`future/tasks.org\`) + detail in \`future/<date>-<slug>.md\`."
  echo "When the user pivots mid-session to new multi-step work (TaskCreate-worthy — multi-step, multi-file, or explicit 'work on X'), immediately: (1) edit \`docs/rpm/~rpm-session-start\` to update the \`task:\` field, (2) insert a \`** TODO\` at the TOP of the actionable band in \`docs/rpm/future/tasks.org\`. No user question — the ask IS the confirmation. Skip for tactical follow-ups (single-step, operational, conversational). Keeps the backlog truthful if the session dies before /session-end."
  echo "When you discover a root cause or change approach, lead with \"Key finding:\" so learnings are captured automatically."
  echo "When you ask the user a question, prefix it with \"QUESTION:\" so questions are visually unmistakable."
}
