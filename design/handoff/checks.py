#!/usr/bin/env python3
"""Consistency checks for the design handoff; writes design/handoff/CHECKS.md.

Inputs: the printed output of checks.js (CHK-1, 2, 5, 6 + COMPONENTS) and of checks-hash.js (HASHES), as saved tool
outputs or one text on stdin ("-"); DESIGN.md §6 table; exports-map.json + design/exports/; export-hashes.json.
  CHK-3  component without a DESIGN.md §6 row, or a row without a component
  CHK-4  exported frame whose PNG is missing or older than the frame (resolved-tree hash differs from the hash
         recorded when the PNG was exported), or a frame with no exports-map entry
Usage: python3 checks.py <checks-output> [<hash-output>]          # exit 1 when any check fails
       python3 checks.py ... --accept "Frame name" [...]           # record current hashes after exporting PNGs
       python3 checks.py ... --accept-all
stdlib only.
"""
import json, re, sys
from datetime import date
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
DESIGN, EXPORTS = ROOT / "DESIGN.md", ROOT / "design" / "exports"
EMAP, BASE, OUT = HERE / "exports-map.json", HERE / "export-hashes.json", HERE / "CHECKS.md"
TITLES = {1: "Token dışı renk / yazı değeri", 2: "Bileşen yerine elle çizilmiş kopya", 3: "§6 tablosu ↔ bileşenler",
          4: "PNG'si eksik ya da frame'den eski ekran", 5: "Hiç kullanılmayan bileşen", 6: "TEMP / tmp / copy / placeholder kalıntısı"}


def read(paths):
    return "\n".join(sys.stdin.read() if p == "-" else Path(p).read_text() for p in paths)


def main():
    args = sys.argv[1:]
    accept = []
    if "--accept" in args:
        i = args.index("--accept")
        accept, args = args[i + 1:], args[:i]
    accept_all = "--accept-all" in args
    args = [a for a in args if a != "--accept-all"]
    text = read(args)
    if "ERROR:" in text:
        sys.exit("snippet printed ERROR (wrong file active?)")
    results = {}
    for m in re.finditer(r"^CHK\|(\d+)\|(PASS|FAIL)\|(\d+)\|(.*)$", text, re.M):
        results[int(m.group(1))] = (m.group(2), int(m.group(3)), m.group(4).strip())
    comps = json.loads(re.search(r"^COMPONENTS (.*)$", text, re.M).group(1))
    hm = re.search(r"^HASHES (.*)$", text, re.M)
    hashes = json.loads(hm.group(1)) if hm else None

    rows = set(re.findall(r"^\| `([^`]+)` \| `[^`]+` \| .+ \|$", DESIGN.read_text(), re.M))
    p3 = [f"§6'da satırı yok: `{c}`" for c in comps if c not in rows]
    p3 += [f"pen'de ana kopyası yok: `{r}`" for r in sorted(rows) if r not in comps]
    results[3] = ("FAIL" if p3 else "PASS", len(p3), " ; ".join(p3))

    if hashes is not None:
        emap = {k: v for k, v in json.loads(EMAP.read_text()).items() if not k.startswith("_")}
        base = json.loads(BASE.read_text()) if BASE.exists() else {"_description": "", "hashes": {}}
        if accept_all or accept:
            for name in (hashes if accept_all else accept):
                base["hashes"][name] = {"hash": hashes[name], "accepted": date.today().isoformat()}
            base["_description"] = ("Frame name -> resolved-tree hash recorded when its PNG was exported (checks-hash.js). "
                                    "Update with `checks.py ... --accept <frame>` right after exporting that PNG.")
            BASE.write_text(json.dumps(base, ensure_ascii=False, indent=2) + "\n")
        p4 = []
        for name, h in hashes.items():
            png = emap.get(name)
            if png is None:
                p4.append(f"exports-map'te yok: `{name}`")
            elif not (EXPORTS / f"{png}@2x.png").exists():
                p4.append(f"PNG yok: `{png}@2x.png`")
            elif base["hashes"].get(name, {}).get("hash") != h:
                p4.append(f"PNG eski: `{png}@2x.png` ({name})")
        results[4] = ("FAIL" if p4 else "PASS", len(p4), " ; ".join(p4))

    L = ["# Tutarlılık kontrolleri (üretilir)", "",
         f"Son çalıştırma {date.today().isoformat()}. Yöntem: `checks.js` + `checks-hash.js` pen.dev `execute` içinde → "
         "`python3 checks.py <çıktılar>`. Çıktı biçimi `CHK|id|PASS/FAIL|n|detay`.", "",
         "| CHK | Kontrol | Sonuç | n | Ayrıntı |", "|---|---|---|---|---|"]
    for i in sorted(TITLES):
        st, n, d = results.get(i, ("—", 0, "çalıştırılmadı"))
        L.append(f"| {i} | {TITLES[i]} | {'✅ PASS' if st == 'PASS' else ('❌ FAIL' if st == 'FAIL' else st)} | {n} | {d.replace('|', '·') or '—'} |")
    L += ["", "## Kurallar ve istisnalar", "",
          "- CHK-1 arşiv dışı tüm frame'leri instance'lar çözülmüş hâlde tarar. İzinli (bilinçli ham): `Page`, `Thumb`, "
          "`Traffic Lights`, `Favicon`, `Alert*` adlı katmanlar (örnek web içeriği, sistem parçası taklidi); gölge renkleri; "
          "gradyan durakları; RGB'si bir token olan alfalı renk (`#16141244` = `canvas` + alfa → kodda `.opacity()`); "
          "belgeleme panoları `Design System · Tokens`, `Shortcut Map`, `Engine Glyphs`, `App Icon · B variants` ve keşif "
          "`Selected Options` (DESIGN.md §4, 2026-10-13).",
          "- CHK-2 bileşen olmayan bir frame'in adı bir bileşenin tam adı ya da son parçasıysa (`Tooltip`, `BottomBar` …) yakalar; "
          "genel adlar (`Card`, `Row`, `Button`, `Header`, `Picker`) hariç.",
          "- CHK-4 plandaki \"commit tarihi\" yerine içerik özeti kullanır: `.pen` her commit'te değiştiği için tarih her PNG'yi "
          "eski gösterirdi. Taban `export-hashes.json`; PNG dışa aktarılınca `--accept <frame>` ile güncellenir. "
          "İlk taban 2026-10-13'te, bu oturumda değişen 16 PNG yeniden dışa aktarıldıktan sonra tüm frame'ler için alındı "
          "(önceki PNG'lerin güncel olduğu varsayımı).",
          "- CHK-5 instance'ları ana kopyalar ve slot değişimleri dahil sayar. CHK-6 ad kalıntılarına ve pen.dev `placeholder` "
          "bayrağına bakar."]
    OUT.write_text("\n".join(L) + "\n")
    fails = [i for i, r in results.items() if r[0] == "FAIL"]
    for i in sorted(results):
        print(f"CHK|{i}|{results[i][0]}|{results[i][1]}|{results[i][2][:160]}")
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
