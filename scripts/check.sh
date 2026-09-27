#!/usr/bin/env bash
# Run layout-math checks (pure functions only — no windows are touched).
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="$(mktemp -d)/checks"
swiftc -swift-version 5 -o "$OUT" Checks/main.swift Sources/DesktopCleaner/Modes/*.swift Sources/DesktopCleaner/Core/WindowInfo.swift
"$OUT"
