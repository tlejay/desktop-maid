#!/usr/bin/env bash
# Build and install to ~/Applications for daily use (Launch at Login points here).
set -euo pipefail
cd "$(dirname "$0")/.."
./scripts/build-app.sh
DEST="$HOME/Applications/Desktop Cleaner.app"
pkill -x DesktopCleaner 2>/dev/null || true
mkdir -p "$HOME/Applications"
rm -rf "$DEST"
cp -R "build/Desktop Cleaner.app" "$DEST"
open "$DEST"
echo "✅ installed → $DEST"
