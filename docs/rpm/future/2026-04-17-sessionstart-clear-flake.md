# SessionStart:clear flake on Opus 4.7

## Description
User reports `/clear` did not trigger the `SessionStart:clear` hook
while on Claude Opus 4.7. Quitting Claude Code and restarting
(fresh `SessionStart:startup`) recovered it.

Likely a Claude Code harness bug — hooks shouldn't be model-sensitive.
This is a watch-and-file item, not an rpm code change.

## Action
- Watch for repro across sessions.
- If it recurs, capture:
  - `claude --version`
  - Exact command sequence (was it `/clear`, a menu, a shortcut?)
  - Any other plugins/hooks active
  - Whether stderr tip line appeared (partial hook run) or
    nothing at all (hook never fired)
- File upstream at anthropics/claude-code with the repro.

## Notes
- In the session where the task was logged, `SessionStart:clear` *did*
  fire cleanly — so the flake is intermittent, not a total break.
- Not blocking any rpm work; park as a bug-watch.
