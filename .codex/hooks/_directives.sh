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
  echo "Delegate aggressively. For independent token-heavy work — broad codebase searches, multi-step web research, log/transcript mining, image analysis, large file reads — dispatch a subagent (background mode where the runtime supports it, e.g. Claude Code's \`run_in_background: true\`) instead of doing it inline. The main session stays lean and interactive while the agent runs; its result arrives as a notification you surface to the user. Foreground only when the result gates your immediate next step. Run the cheapest inline experiment first (1-minute bash, targeted grep) before dispatching — wrong hypotheses validated by a throwaway script save more than a thorough agent on the wrong question. Once delegated, do NOT redo the same searches in the main session."
  echo "When the user asks \"next?\" or any semantic variant (\"what's next\", \"what now\", \"what should I work on\", \"what should we do\"), reach for the backlog FIRST: Read \`docs/rpm/future/tasks.org\` and offer the topmost unblocked task in each \`* Parent\` group — skip entries whose \`:BLOCKED_BY:\` deps aren't all DONE/CANCELLED, and skip POSTPONED items. Present them as a numbered menu (parent → top unblocked task → detail-file path). Don't invent next steps from session memory or propose ad-hoc work until the backlog has been consulted — that's where the user's recorded intent already lives."
}
