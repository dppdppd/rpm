#!/usr/bin/env bash
# Extract every URL from a report and HEAD-check it.
# Usage: bash url_liveness.sh <report.md>
set -uo pipefail
f="${1:?usage: url_liveness.sh <report.md>}"
[ -f "$f" ] || { echo "no such file: $f" >&2; exit 2; }

mapfile -t urls < <(grep -oE 'https?://[^][:space:]"<>)(]+' "$f" \
  | sed -E 's/[).,;:]+$//' | sort -u)

total=0 live=0
printf '%-5s  %s\n' code url
for u in "${urls[@]}"; do
  code=$(curl -sIL -m 15 -o /dev/null -w '%{http_code}' "$u" 2>/dev/null)
  printf '%-5s  %s\n' "${code:-000}" "$u"
  total=$((total+1))
  case "$code" in 2??|3??) live=$((live+1));; esac
done
echo "---"
echo "live $live / $total"
