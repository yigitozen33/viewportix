#!/bin/sh
# Builds every Viewportix logo asset from make-logo.swift, then the .icns with iconutil. Run from the repo root.
set -eu
cd "$(dirname "$0")/../.."
OUT=design/logo/out
swift design/logo/make-logo.swift "$OUT"
iconutil -c icns "$OUT/Viewportix.iconset" -o "$OUT/Viewportix.icns"
echo "  Viewportix.icns"
