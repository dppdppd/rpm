#!/usr/bin/env bash
# Serve the injection canary for Module B. Ctrl-C to stop.
# Usage: bash serve.sh [port]   (default 8723)
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT="${1:-8723}"
echo "Serving $DIR on http://localhost:$PORT/canary.html  (Ctrl-C to stop)"
exec python3 -m http.server "$PORT" --directory "$DIR"
