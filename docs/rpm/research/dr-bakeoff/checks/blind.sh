#!/usr/bin/env bash
# Randomly assign the two arms' reports to A/B for blind grading,
# stripping telltale path markers. Seals the mapping in bakeoff/.mapping.
# Usage: bash blind.sh
set -euo pipefail
base="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="$base/bakeoff"; mkdir -p "$out"
rpm="$base/runs/rpm/report.md"
nat="$base/runs/native/report.md"
for r in "$rpm" "$nat"; do
  [ -f "$r" ] || { echo "missing report: $r — run both arms first" >&2; exit 2; }
done

if (( RANDOM % 2 )); then
  a="$rpm"; b="$nat"; map="A=rpm  B=native"
else
  a="$nat"; b="$rpm"; map="A=native  B=rpm"
fi

# Strip path tells that would reveal the source system.
strip='s#docs/rpm/research[^ )"]*##g; s#docs/research[^ )"]*##g'
sed -E "$strip" "$a" > "$out/report-A.md"
sed -E "$strip" "$b" > "$out/report-B.md"
printf '%s\n' "$map" > "$out/.mapping"   # DO NOT show the grader

echo "Blinded → $out/report-A.md, $out/report-B.md"
echo "Mapping sealed in $out/.mapping (reveal only AFTER grading)"
