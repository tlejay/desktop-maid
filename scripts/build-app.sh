#!/usr/bin/env bash
# Build the SwiftPM executable and wrap it into a signed .app bundle.
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${CONFIG:-release}"
APP="build/Desktop Cleaner.app"
SIGN_ID="Desktop Cleaner Dev"

swift build -c "$CONFIG"
BIN="$(swift build -c "$CONFIG" --show-bin-path)/DesktopCleaner"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/DesktopCleaner"
cp Resources/Info.plist "$APP/Contents/Info.plist"

# A stable identity keeps the Accessibility grant across rebuilds; ad-hoc resets it every time.
if security find-identity -p codesigning | grep -q "$SIGN_ID"; then
  codesign --force --sign "$SIGN_ID" "$APP"
else
  echo "⚠️  '$SIGN_ID' certificate not found — signing ad-hoc (Accessibility must be re-granted after each build)"
  codesign --force --sign - "$APP"
fi

echo "✅ $APP"
