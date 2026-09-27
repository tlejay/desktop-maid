#!/usr/bin/env bash
# Regenerates docs/images from the real layout code. Run after changing any mode.
# Needs Node, ffmpeg and the kiki-gh-readme render scripts (override with KIKI_README=<dir>).
set -euo pipefail
cd "$(dirname "$0")"
ROOT=../..
K="${KIKI_README:-$HOME/.claude/skills/kiki-gh-readme/scripts}"
OUT=$ROOT/docs/images
TMP="$(mktemp -d)"

swiftc -swift-version 5 -o "$TMP/dump" dump/main.swift $ROOT/Sources/DesktopCleaner/Modes/*.swift $ROOT/Sources/DesktopCleaner/Core/WindowInfo.swift
echo "window.FRAMES=$("$TMP/dump");" > frames.js

node "$K/render.mjs" hero.html "$OUT/hero.png" --assets .
node "$K/render.mjs" modes.html "$OUT/modes.png" --size 1280x770 --assets .
sips -Z 1280 "$OUT/hero.png" --out "$OUT/social-preview.png" >/dev/null

node record.mjs "$TMP/frames"
ffmpeg -y -loglevel error -framerate 12 -i "$TMP/frames/f%04d.png" \
  -vf "split[a][b];[a]palettegen=max_colors=128:stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=4:diff_mode=rectangle" \
  "$OUT/demo.gif"
rm -f frames.js
ls -la "$OUT"
