#!/bin/bash
# Shared scoring helpers for native-task ↔ tasks.org matching.
# Sourced by hooks/task-capture.sh and skills/session-end/scripts/score-natives.sh.
# Do NOT execute directly.

# Lowercase, strip non-alnum → spaces, trim.
normalize() {
  local s
  s=$(echo "$1" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' ' ')
  [[ "$s" =~ ^[[:space:]]*(.*[^[:space:]])[[:space:]]*$ ]] && s="${BASH_REMATCH[1]}"
  printf '%s' "$s"
}

# Integer confidence 0-100:
#   100 = equal after normalize
#    80 = one contains the other
#    60 = Jaccard word overlap ≥ 0.6
#    40 = Jaccard ≥ 0.3
#     0 = below floor (emit match:null)
confidence() {
  local a="$1" b="$2"
  [ -z "$a" ] || [ -z "$b" ] && { echo 0; return; }
  [ "$a" = "$b" ] && { echo 100; return; }
  case "$a" in *"$b"*) echo 80; return ;; esac
  case "$b" in *"$a"*) echo 80; return ;; esac
  local inter union pct
  inter=$(printf '%s\n%s\n' "$a" "$b" | tr ' ' '\n' | grep -v '^$' | sort | uniq -d | wc -l)
  union=$(printf '%s\n%s\n' "$a" "$b" | tr ' ' '\n' | grep -v '^$' | sort -u | wc -l)
  [ "$union" -eq 0 ] && { echo 0; return; }
  pct=$((inter * 100 / union))
  if [ "$pct" -ge 60 ]; then echo 60
  elif [ "$pct" -ge 30 ]; then echo 40
  else echo 0
  fi
}
