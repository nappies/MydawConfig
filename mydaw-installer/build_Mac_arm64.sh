#!/usr/bin/env bash
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$PROJECT_ROOT/config"
PACKAGES_DIR="$PROJECT_ROOT/packages_mac"
IFW_BIN="/Users/rzr/Qt/QtIFW-4.6.1/bin/binarycreator"
OUTPUT_APP="$PROJECT_ROOT/MyDawInstaller.app"

# Clean old installer
[ -e "$OUTPUT_APP" ] && rm -rf "$OUTPUT_APP"

# Create new installer
"$IFW_BIN" \
    --offline-only \
    -c "$CONFIG_DIR/config.xml" \
    -p "$PACKAGES_DIR" \
    "$OUTPUT_APP"

echo "Built installer: $OUTPUT_APP"