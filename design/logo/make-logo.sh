#!/bin/bash
# Builds every Viewportix logo asset from make-logo.swift, the .icns with iconutil, and renders the
# Icon Composer package with ictool (Xcode 26). Run from the repo root.
set -eu
cd "$(dirname "$0")/../.."
OUT="$PWD/design/logo/out"
swift design/logo/make-logo.swift "$OUT"
iconutil -c icns "$OUT/Viewportix.iconset" -o "$OUT/Viewportix.icns"
echo "  Viewportix.icns"
ICTOOL="/Applications/Xcode.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool"
if [ -x "$ICTOOL" ]; then
  mkdir -p "$OUT/icon-composer"
  for spec in "Default 512 2" "Default 128 2" "Default 32 2" "Default 16 2" "Dark 512 2"; do
    set -- $spec
    "$ICTOOL" "$PWD/design/logo/Viewportix.icon" --export-image --output-file "$OUT/icon-composer/macos-$1-$2@${3}x.png" \
      --platform macOS --rendition "$1" --width "$2" --height "$2" --scale "$3" >/dev/null
    echo "  icon-composer/macos-$1-$2@${3}x.png"
  done
else
  echo "  (ictool not found; Icon Composer renders skipped)"
fi
