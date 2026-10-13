#!/usr/bin/env python3
"""Build design/handoff/manifest.json and manifest.md from the pen.dev canvas dump.

Inputs (all in design/handoff/ unless noted):
  canvas-dump.json   output of dump-manifest.js (run in pen.dev `execute`, paste the printed JSON)
  exports-map.json   frame name -> PNG basename in design/exports/
  ../../DESIGN.md    §6 table "| `pen.dev bileşeni` | `SwiftUI` | Durumlar |"

Usage: python3 build_manifest.py   (exit 1 when there are open questions)
stdlib only.
"""
import json, re, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
DUMP, EXPORTS_MAP, EXPORTS = HERE / "canvas-dump.json", HERE / "exports-map.json", ROOT / "design" / "exports"
DESIGN = ROOT / "DESIGN.md"

SECTIONS = [  # by top-level y, see DESIGN.md §6 "Dosya düzeni"
    (-3000, "00 · Tasarım sistemi"), (-800, "00b · Bileşenler"), (600, "01 · Giriş ekranı"),
    (1780, "02 · Proje penceresi"), (3160, "03 · Menüler ve durumlar"), (4540, "04 · Geliştirici paneli"),
    (5920, "05 · Bileşen durumları"), (7070, "06 · İkon ve glifler"),
]
KIND = {"Home Window": "screen", "Project Window": "screen", "Dev Panel": "screen"}


def section_for(y):
    name = SECTIONS[0][1]
    for start, label in SECTIONS:
        if y >= start:
            name = label
    return name


def interaction_ids():
    """DESIGN.md §3 interaction rows `| PREFIX-NN | …` -> {prefix: ["PREFIX-01", …]}."""
    ids = {}
    for m in re.finditer(r"^\| ([A-Z]+)-(\d\d) \|", DESIGN.read_text(), re.M):
        ids.setdefault(m.group(1), []).append(f"{m.group(1)}-{m.group(2)}")
    return ids


def prefixes_for(name):
    """Which interaction tables a screen frame is the visual for (README.md contract, sentence 2)."""
    if name.startswith("Home Window"):
        return ["HOME"] + (["SETTINGS"] if "Ayarlar" in name else [])
    if name.startswith("Dev Panel"):
        return ["DEV", "RAIL"]
    if name.startswith("Project Window"):
        return ["PW", "STRIP", "CARD", "SIDEBAR", "BAR", "RAIL"] + (["SETTINGS"] if "Ayarlar" in name else [])
    return []


def parse_design_table():
    rows, text = {}, DESIGN.read_text()
    for m in re.finditer(r"^\| `([^`]+)` \| `([^`]+)` \| (.+?) \|$", text, re.M):
        rows[m.group(1)] = {"swiftName": m.group(2), "states": m.group(3).strip()}
    return rows


def main():
    dump = json.loads(DUMP.read_text())
    emap = {k: v for k, v in json.loads(EXPORTS_MAP.read_text()).items() if not k.startswith("_")}
    table = parse_design_table()
    questions = []

    components = []
    for c in dump["components"]:
        row = table.get(c["name"])
        if not row:
            questions.append(f"DESIGN.md §6 tablosunda satırı yok: `{c['name']}`")
        used_in = sorted(f["name"] for f in dump["frames"] if c["name"] in f["uses"])
        used_via = sorted(o["name"] for o in dump["components"] if c["name"] in o["contains"])
        components.append({
            "penName": c["name"], "nodeId": c["id"], "swiftName": row["swiftName"] if row else None,
            "states": row["states"] if row else None, "size": [c["w"], c["h"]],
            "contains": c["contains"], "usedIn": used_in, "usedVia": used_via,
            "spec": f"specs/{row['swiftName']}.json" if row else None,
        })
        if not used_in and not used_via:
            questions.append(f"Hiçbir frame'de kullanılmıyor: `{c['name']}`")
    for pen_name in table:
        if pen_name not in {c["name"] for c in dump["components"]}:
            questions.append(f"Tabloda var, pen.dev'de ana kopya yok: `{pen_name}`")

    ids = interaction_ids()
    frames = []
    for f in dump["frames"]:
        png = emap.get(f["name"])
        if png is None:
            questions.append(f"exports-map.json'da yok: `{f['name']}`")
        elif not (EXPORTS / f"{png}@2x.png").exists():
            questions.append(f"PNG eksik: `{png}@2x.png` ({f['name']})")
        prefix = f["name"].split(" · ")[0]
        frames.append({
            "name": f["name"], "nodeId": f["id"], "kind": KIND.get(prefix, "spec"),
            "section": section_for(f["y"]), "size": [f["w"], f["h"]],
            "export": f"exports/{png}@2x.png" if png else None, "components": f["uses"],
        })
        if frames[-1]["kind"] == "screen":
            pre = prefixes_for(f["name"])
            for x in pre:
                if x not in ids:
                    questions.append(f"DESIGN.md §3'te `{x}-NN` satırı yok ({f['name']})")
            frames[-1]["interactions"] = [f"{ids[x][0]}…{ids[x][-1]}" for x in pre if x in ids]
    for name in emap:
        if name not in {f["name"] for f in dump["frames"]}:
            questions.append(f"exports-map.json'da var, pen.dev'de frame yok: `{name}`")

    covered = {x for f in dump["frames"] for x in prefixes_for(f["name"])}
    for x in ids:
        if x not in covered:
            questions.append(f"`{x}-NN` satırlarına hiçbir ekran işaret etmiyor")

    manifest = {
        "$description": "Viewportix design handoff manifest — generated by build_manifest.py; do not edit.",
        "generatedAt": dump.get("generatedAt"), "penFile": "design/viewportix.pen",
        "contract": "pen frame name -> SwiftUI View (DESIGN.md §6); `Project Window · <hal>` -> screen state; variable -> DesignTokens member",
        "tokens": "design/tokens/viewportix.tokens.json",
        "components": components,
        "screens": [f for f in frames if f["kind"] == "screen"],
        "specFrames": [f for f in frames if f["kind"] == "spec"],
        "openQuestions": questions,
    }
    (HERE / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")

    L = ["# Manifest (üretilir, elle düzenlenmez)", "",
         f"Kaynak: `{manifest['penFile']}`, döküm {manifest['generatedAt']}. Sözleşme: `README.md`.", "",
         "## Bileşenler", "", "| pen.dev | SwiftUI | nodeId | Boyut | Durumlar | Kullanıldığı frame sayısı |", "|---|---|---|---|---|---|"]
    for c in components:
        L.append(f"| `{c['penName']}` | `{c['swiftName'] or '?'}` | `{c['nodeId']}` | {c['size'][0]}×{c['size'][1]} | {c['states'] or '?'} | {len(c['usedIn'])} |")
    L += ["", "## Ekranlar", "", "| Frame | Bölüm | nodeId | Boyut | PNG | Bileşenler | Etkileşim (DESIGN.md §3) |", "|---|---|---|---|---|---|---|"]
    for f in manifest["screens"]:
        L.append(f"| {f['name']} | {f['section']} | `{f['nodeId']}` | {f['size'][0]}×{f['size'][1]} | `{(f['export'] or '?').replace('exports/', '')}` | {', '.join(f['components'])} | {', '.join(f['interactions'])} |")
    L += ["", "## Durum ve spec frame'leri", "", "| Frame | Bölüm | nodeId | PNG | Bileşenler |", "|---|---|---|---|---|"]
    for f in manifest["specFrames"]:
        L.append(f"| {f['name']} | {f['section']} | `{f['nodeId']}` | `{(f['export'] or '?').replace('exports/', '')}` | {', '.join(f['components'])} |")
    L += ["", "## Açık sorular", ""] + ([f"- {q}" for q in questions] or ["- yok"])
    (HERE / "manifest.md").write_text("\n".join(L) + "\n")
    print(f"components={len(components)} screens={len(manifest['screens'])} specFrames={len(manifest['specFrames'])} openQuestions={len(questions)}")
    for q in questions:
        print("  ?", q)
    sys.exit(1 if questions else 0)


if __name__ == "__main__":
    main()
