#!/bin/zsh
# Profiles Viewportix with five live viewports on a real page.
#
#   Scripts/perf.sh [url]        default: https://www.apple.com/iphone/
#
# Builds the Debug app, opens a generated 5-viewport project with --perf (Viewportix/Debug/PerfProbe.swift),
# samples CPU and memory of the app plus the WebKit processes it spawned once per second, and summarises
# them per phase (load, idle, scroll). The app window comes to the front for about 30 seconds.
set -u
ROOT=${0:A:h:h}
URL=${1:-https://www.apple.com/iphone/}
OUT=$ROOT/.build/perf
APP=$ROOT/.build/xcode/Build/Products/Debug/Viewportix.app
mkdir -p $OUT
rm -rf $OUT/Perf.viewportix $OUT/app.log $OUT/samples.tsv

cd $ROOT
xcodebuild -project Viewportix.xcodeproj -scheme Viewportix -derivedDataPath .build/xcode -allowProvisioningUpdates build 2>&1 \
  | grep -E "error:|BUILD FAILED" && exit 1

python3 - "$OUT/Perf.viewportix" "$URL" <<'EOF'
import json, os, sys, uuid
path, url = sys.argv[1], sys.argv[2]
os.makedirs(path)
new_id = lambda: str(uuid.uuid4()).upper()
devices = [("iPhone 16", 393, 852, "iphone-16"), ("iPhone SE", 375, 667, "iphone-se"),
           ("iPad Air 11\"", 820, 1180, "ipad-air-11"), ("Dizüstü", 1280, 800, "laptop"),
           ("Masaüstü", 1440, 900, "desktop")]
page = new_id()
json.dump({
    "schemaVersion": 1,
    "pages": [{"id": page, "name": "Perf", "url": url}],
    "selectedPageID": page,
    "viewports": [{"id": new_id(), "name": n, "size": {"width": w, "height": h}, "engine": "webKit", "presetID": p}
                  for n, w, h, p in devices],
    "canvas": {"zoom": 1, "offsetX": 0, "offsetY": 0},
}, open(os.path.join(path, "project.json"), "w"))
EOF

webkit_pids() { pgrep -f 'com.apple.WebKit.(WebContent|Networking|GPU)' | sort; }
before=$(webkit_pids)

pkill -x Viewportix; sleep 1
open -n --stdout $OUT/app.log --stderr /dev/null -a $APP $OUT/Perf.viewportix --args --perf
for i in {1..20}; do sleep 0.5; osascript -e 'tell application id "com.viewportix.Viewportix" to activate' 2>/dev/null && break; done

printf "phase\tseconds\tprocesses\trss_mb\tcpu_pct\tapp_cpu_pct\n" > $OUT/samples.tsv
for second in {1..120}; do
  app=$(pgrep -x Viewportix | head -1)
  [[ -z $app ]] && break
  phase=$(grep -o 'PHASE [a-z]*' $OUT/app.log 2>/dev/null | tail -1 | cut -d' ' -f2)
  [[ $phase == done ]] && break
  ours=$(comm -13 <(echo "$before") <(webkit_pids) | tr '\n' ',')
  pids="$app,${ours%,}"
  read count rss cpu <<< $(ps -o rss=,%cpu= -p ${pids%,} | awk '{n++; r+=$1; c+=$2} END {printf "%d %.0f %.1f", n, r/1024, c}')
  app_cpu=$(ps -o %cpu= -p $app | tr -d ' ')
  printf "%s\t%d\t%d\t%s\t%s\t%s\n" "${phase:-start}" $second $count $rss $cpu $app_cpu >> $OUT/samples.tsv
  sleep 1
done

echo "== Phases (app + WebKit processes it spawned) =="
awk -F'\t' 'NR > 1 { n[$1]++; cpu[$1] += $5; app[$1] += $6; if ($4 > rss[$1]) rss[$1] = $4; if ($3 > procs[$1]) procs[$1] = $3 }
  END { for (p in n) printf "%-6s samples=%-3d processes=%-3d peak_rss=%5d MB  avg_cpu=%6.1f%%  (app process %5.1f%%)\n", p, n[p], procs[p], rss[p], cpu[p] / n[p], app[p] / n[p] }' $OUT/samples.tsv | sort
echo "== Probe =="
grep -E 'PERF (LOADED|STATS|SCROLLY)' $OUT/app.log | sed 's/^PERF //'
