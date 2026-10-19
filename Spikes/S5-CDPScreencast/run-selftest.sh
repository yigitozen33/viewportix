#!/bin/zsh
# Run from anywhere. Builds the S5 spike and runs its self-test (needs Chrome and the fixtures served
# on :8765: `python3 -m http.server 8765` in Packages/ViewportixKit/Tests/Fixtures).
cd /Users/yigitozen/orca/viewportix
xcodebuild -project Spikes/S5-CDPScreencast/S5CDPScreencast.xcodeproj -scheme S5CDPScreencast -derivedDataPath .build/spikes build 2>&1 | grep -E "error:|BUILD FAILED" && exit 1
rm -f .build/s5-selftest.log
open -W -n --stdout .build/s5-selftest.log --stderr /dev/null .build/spikes/Build/Products/Debug/S5CDPScreencast.app --args --self-test "--frame=$PWD/.build/s5-frame.png" "$@" &
pid=$!
for i in 1 2 3 4 5 6 7 8 9 10; do sleep 0.5; osascript -e 'tell application id "com.viewportix.spike.S5CDPScreencast" to activate' 2>/dev/null && break; done
for i in $(seq 1 120); do kill -0 $pid 2>/dev/null || break; sleep 0.5; done
kill $pid 2>/dev/null; pkill -x S5CDPScreencast
grep -E "SELF-TEST|S5 HATA" .build/s5-selftest.log
