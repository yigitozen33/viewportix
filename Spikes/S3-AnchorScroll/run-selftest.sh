#!/bin/zsh
# Run from anywhere. Builds the S3 spike and runs its self-test through LaunchServices so the app gets focus.
cd /Users/yigitozen/orca/viewportix
xcodebuild -project Spikes/S3-AnchorScroll/S3AnchorScroll.xcodeproj -scheme S3AnchorScroll -derivedDataPath .build/spikes build 2>&1 | grep -E "error:|BUILD FAILED" && exit 1
rm -f .build/s3-selftest.log
open -W -n --stdout .build/s3-selftest.log --stderr /dev/null .build/spikes/Build/Products/Debug/S3AnchorScroll.app --args --self-test &
pid=$!
for i in 1 2 3 4 5 6 7 8 9 10; do sleep 0.5; osascript -e 'tell application id "com.viewportix.spike.S3AnchorScroll" to activate' 2>/dev/null && break; done
for i in $(seq 1 600); do kill -0 $pid 2>/dev/null || break; sleep 0.5; done
kill $pid 2>/dev/null; pkill -x S3AnchorScroll
grep -E "\||SELF-TEST" .build/s3-selftest.log
