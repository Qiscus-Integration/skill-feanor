#!/bin/bash
# ============================================================
#  build.sh — rebuild the skill-feanor.plugin file
#
#  Run from the repo root:
#    ./skill-feanor/build.sh
#
#  Or from inside the plugin folder:
#    ./build.sh
# ============================================================

set -euo pipefail

# Resolve the plugin directory (wherever this script lives)
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_NAME="skill-feanor"
OUTPUT_FILE="${PLUGIN_DIR}/../${PLUGIN_NAME}.plugin"

echo "Building ${PLUGIN_NAME}.plugin..."

# Build into /tmp first to avoid permission issues, then copy
cd "$PLUGIN_DIR"
zip -r "/tmp/${PLUGIN_NAME}.plugin" . -x "*.DS_Store" -x "build.sh" -q
cp "/tmp/${PLUGIN_NAME}.plugin" "$OUTPUT_FILE"

echo "✅ Built: $(realpath "$OUTPUT_FILE")"
echo "   Size:  $(du -sh "$OUTPUT_FILE" | cut -f1)"
echo ""
echo "Next steps:"
echo "  1. Commit both this folder and ${PLUGIN_NAME}.plugin to your repo"
echo "  2. Share ${PLUGIN_NAME}.plugin with teammates to install"
