#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
./scripts/build-app.sh
pkill -x DesktopCleaner 2>/dev/null || true
open "build/Desktop Cleaner.app"
