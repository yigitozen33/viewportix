#!/bin/zsh
# Renders the chrome previews in Viewportix/Debug/PreviewSnapshots.swift to @2x PNGs.
# Usage: Scripts/snapshots.sh [folder]   (default: .build/snapshots)
set -euo pipefail
cd "${0:A:h}/.."
out="${1:-.build/snapshots}"
xcodebuild -project Viewportix.xcodeproj -scheme Viewportix -derivedDataPath .build/xcode -allowProvisioningUpdates build -quiet
.build/xcode/Build/Products/Debug/Viewportix.app/Contents/MacOS/Viewportix --snapshots "${out:A}" | grep '^SNAPSHOT'
