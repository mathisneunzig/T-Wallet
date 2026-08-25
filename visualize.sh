#!/usr/bin/env bash
# Runs the T-Wallet Python statistics visualizer.
# Usage: bash visualize.sh [path/to/stats-query-binary]
#
# Requires python3. matplotlib is optional — falls back to ASCII output.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

BINARY="${1:-./bin/stats-query}"

# Check the stats-query binary exists
if [ ! -x "$BINARY" ]; then
    echo "Error: stats-query binary not found at '$BINARY'."
    echo "Run ./build.sh first, or pass the binary path as an argument."
    exit 1
fi

# Install matplotlib if missing (optional, ASCII fallback works without it)
if ! python3 -c "import matplotlib" 2>/dev/null; then
    echo "Note: matplotlib not found — charts will be rendered as ASCII."
    echo "      To get graphical charts: pip3 install matplotlib"
fi

python3 stats/visualize.py "$BINARY"
