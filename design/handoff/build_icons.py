#!/usr/bin/env python3
"""Build design/handoff/icons.md: every Lucide icon on the pen.dev canvas -> SF Symbol for the app.

Inputs: icons-dump.json (dump-icons.js, saved with save_dump.py). The mapping lives in MAP below (edit by hand when
an icon is added); the script fails when the canvas has an icon MAP does not cover, or MAP keeps one the canvas no
longer uses.

Usage: python3 build_icons.py            # write icons.md (exit 1 on missing / stale rows)
       python3 build_icons.py --verify   # also check every SF Symbol name on this Mac (NSImage(systemSymbolName:))
stdlib only (+ `swift` for --verify).
"""
import json, subprocess, sys, tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
DUMP, OUT = HERE / "icons-dump.json", HERE / "icons.md"

# kind: "1:1" same meaning and shape · "yakın" close shape, same meaning · "öneri" no direct match, proposal ·
#       "özel" needs a custom symbol (Assets .symbolset) · "sistem" drawn by AppKit (cursor, progress, menu)
MAP = {
    "activity": ("Ray › Senkron kaydı", "waveform.path.ecg", "öneri", "Alternatif `list.bullet.rectangle`."),
    "arrow-left-right": ("Boyut popover'ı › en ↔ boy", "arrow.left.arrow.right", "1:1", ""),
    "arrow-right": ("URL kutusu › Aç →", "arrow.right", "1:1", ""),
    "arrow-up-right": ("Cihaz seçici › Cihazları yönet…", "arrow.up.right", "1:1", ""),
    "camera": ("Kart başlığı kamerası, alt çubuk ekran görüntüsü", "camera", "1:1", ""),
    "check": ("Kapsül başarı, cihaz seçicide eklendi", "checkmark", "1:1", ""),
    "chevron-down": ("Menü okları, zoom ▼, \"+N\" çipi", "chevron.down", "1:1", "Zoom ▲▼ küçük (10 pt) çizilir."),
    "chevron-left": ("Sidebar nav › Geri", "chevron.left", "1:1", ""),
    "chevron-right": ("Nav › İleri, şerit kaydırma ›, alt menü oku", "chevron.right", "1:1", "Alt menü okunu NSMenu kendisi çizer."),
    "chevron-up": ("Zoom ▲", "chevron.up", "1:1", ""),
    "copy": ("Bağlam menüsü › Çoğalt, MCP komutu kopyala", "doc.on.doc", "1:1", ""),
    "credit-card": ("Sidebar sayfa ikonu (örnek: Ödeme)", "creditcard", "1:1", "Örnek veri; sayfa ikonu türüne göre seçilir."),
    "ellipsis": ("⋯ düğmeleri (kart, satır, panel)", "ellipsis", "1:1", ""),
    "eye": ("Gizli cihaz menüsü › satır durumu", "eye", "1:1", ""),
    "file-down": ("Ekran görüntüsü seçici › Tam sayfa", "arrow.down.document", "yakın", ""),
    "file-pen": ("Giriş sidebar › Taslaklar", "square.and.pencil", "öneri", "Alternatif `doc.badge.ellipsis`."),
    "file-text": ("Sidebar/Row varsayılan sayfa ikonu", "doc.text", "1:1", ""),
    "folder": ("Bağlam menüsü › Finder'da göster", "folder", "1:1", ""),
    "folder-open": ("Giriş › Aç… düğmesi", "folder", "yakın", "SF'de açık klasör yok."),
    "git-compare": ("Ray › Farklar", "square.split.2x1", "öneri", "Yan yana karşılaştırma; alternatif `arrow.left.and.right.square`."),
    "globe": ("URL alanı boşken ipucu", "globe", "1:1", ""),
    "hand-grab": ("Kart sürüklenirken imleç", "NSCursor.closedHand", "sistem", "Sembol değil, imleç."),
    "history": ("Giriş sidebar › Son", "clock.arrow.circlepath", "1:1", ""),
    "house": ("Sidebar sayfa ikonu (örnek: Ana sayfa)", "house", "1:1", "Örnek veri."),
    "image": ("Sekme / kart durumu snapshot", "photo", "1:1", ""),
    "info": ("Kapsül bilgi (senkron kurulamıyor)", "info.circle", "1:1", ""),
    "laptop": ("Cihaz türü dizüstü", "laptopcomputer", "1:1", ""),
    "layout-grid": ("Giriş › ızgara görünümü", "square.grid.2x2", "1:1", ""),
    "link": ("URL kutusu, hover şeridi › Senkrona kat", "link", "1:1", ""),
    "link-2": ("Alt çubuk › senkron açık", "link", "yakın", "SF'de tek zincir şekli var; `link` ile aynı sembol."),
    "link-2-off": ("Senkron kapalı (alt çubuk), Senkrondan çıkar (hover şeridi), adres hatalı", "link.slash (özel)", "özel", "SF'de yok; `link`'ten türetilmiş özel sembol (`.symbolset`). Pen'de de eğik çizgili zincir (DESIGN.md §4)."),
    "list": ("Giriş › liste görünümü", "list.bullet", "1:1", ""),
    "list-x": ("Kaldır › Listeden kaldır", "text.badge.xmark", "yakın", ""),
    "loader-circle": ("Yükleniyor (kart, sekme, kapsül)", "ProgressView", "sistem", "`ProgressView().controlSize(.small)`; sembol değil."),
    "lock": ("URL alanı › güvenli bağlantı", "lock", "1:1", ""),
    "maximize-2": ("Alt çubuk › Sığdır", "arrow.up.left.and.arrow.down.right", "1:1", ""),
    "monitor": ("Cihaz türü masaüstü", "display", "1:1", ""),
    "mouse-pointer-2": ("Bağlantı bırakma örneğinde imleç", "NSCursor.arrow", "sistem", "Sembol değil, imleç."),
    "move-horizontal": ("Sidebar genişlik tutamacı imleci", "NSCursor.resizeLeftRight", "sistem", "Sembol değil, imleç."),
    "package": ("Sidebar sayfa ikonu (örnek: Ürün)", "shippingbox", "1:1", "Örnek veri."),
    "panel-left": ("Kenar çubuğu düğmesi (kapsülde)", "sidebar.left", "1:1", ""),
    "panel-right-close": ("Ray › Rayı gizle", "sidebar.right", "yakın", "SF'de aç/kapa ayrımı yok; aynı sembol."),
    "panel-right-open": ("Ray tutamacı › Rayı göster", "sidebar.right", "yakın", "SF'de aç/kapa ayrımı yok; aynı sembol."),
    "pause": ("Kart başlığı › senkron kapalı ‖", "pause", "1:1", ""),
    "pencil": ("Yeniden adlandır", "pencil", "1:1", ""),
    "plug": ("Ray › MCP", "powerplug.portrait", "1:1", "Dikey fiş, Lucide ile aynı yön (DESIGN.md §4)."),
    "plus": ("+ Cihaz, + Ekle, + Yeni", "plus", "1:1", ""),
    "rotate-ccw": ("Hover şeridi › Döndür", "rectangle.portrait.rotate", "öneri", "`arrow.counterclockwise` Geri al ile karışır; cihaz döndürme sembolü daha açık."),
    "rotate-cw": ("Sidebar nav › Yenile", "arrow.clockwise", "1:1", ""),
    "ruler": ("Cihaz seçici › Özel boyut", "ruler", "1:1", ""),
    "scan": ("Ekran görüntüsü › Görünen alan; menü › odakla", "viewfinder", "1:1", ""),
    "search": ("Arama alanları", "magnifyingglass", "1:1", ""),
    "search-x": ("Aramada sonuç yok", "magnifyingglass", "yakın", "SF'de çarpılı büyüteç yok."),
    "server-off": ("Kart yükleme hatası › localhost kapalı", "server.rack", "öneri", "SF'de kapalı sunucu yok."),
    "settings": ("Ray / giriş › Ayarlar", "gearshape", "1:1", ""),
    "shield-alert": ("Kart yükleme hatası › sertifika", "exclamationmark.shield", "1:1", ""),
    "shopping-cart": ("Sidebar sayfa ikonu (örnek: Sepet)", "cart", "1:1", "Örnek veri."),
    "smartphone": ("Cihaz türü telefon, şablon çipi, ray › Cihazlar", "iphone", "1:1", ""),
    "tablet": ("Cihaz türü tablet", "ipad", "1:1", ""),
    "trash-2": ("Kaldır › Çöp Sepeti'ne taşı", "trash", "1:1", ""),
    "triangle-alert": ("Uyarı: senkron kaçtı, hata, \"+N\" durumu", "exclamationmark.triangle", "1:1", ""),
    "user": ("Ray › Hesap", "person", "1:1", ""),
    "wifi-off": ("Kart yükleme hatası › ağ", "wifi.slash", "1:1", ""),
    "x": ("Kapat (sekme, kart, menü satırı, panel)", "xmark", "1:1", ""),
}


def where(e):
    parts = [f"`{c}`" for c in e["components"]]
    parts += [f"{k} ×{v}" for k, v in sorted(e["screens"].items())]
    if e["specFrames"]:
        parts.append(f"{len(e['specFrames'])} durum frame'i")
    return ", ".join(parts)


def verify(names):
    src = "import AppKit\nfor n in CommandLine.arguments.dropFirst() { print(n, NSImage(systemSymbolName: n, accessibilityDescription: nil) != nil) }\n"
    with tempfile.NamedTemporaryFile("w", suffix=".swift", delete=False) as f:
        f.write(src)
    out = subprocess.run(["swift", f.name, *names], capture_output=True, text=True, check=True).stdout
    return {l.split()[0]: l.split()[1] == "true" for l in out.splitlines() if l.strip()}


def main():
    dump = json.loads(DUMP.read_text())
    icons = dump["icons"]
    problems = [f"MAP'te yok: `{k}`" for k in icons if k not in MAP]
    problems += [f"pen'de artık yok: `{k}`" for k in MAP if k not in icons]
    sf_names = sorted({v[1] for v in MAP.values() if v[2] not in ("özel", "sistem")})
    checked = verify(sf_names) if "--verify" in sys.argv else {}
    missing = [n for n, ok in checked.items() if not ok]
    problems += [f"SF Symbol bu Mac'te yok: `{n}`" for n in missing]

    L = ["# İkon eşleme (Lucide → SF Symbols)", "",
         f"Üretilir: `build_icons.py` (eşleme elle, script'teki `MAP`); kaynak `icons-dump.json` (`dump-icons.js`, {dump['generatedAt']}). "
         "Arşiv dışı tüm görünür ikon düğümleri, instance içleri dahil.", "",
         "Tür: **1:1** aynı anlam ve şekil · **yakın** aynı anlam, şekil biraz farklı · **öneri** birebir karşılık yok, öneri "
         "(onaylandı, DESIGN.md §4 2026-10-13) · **özel** Assets'e özel sembol gerekir · **sistem** sembol değil, AppKit çizer.", "",
         "**Boyut:** SF Symbol puntosu = tasarımdaki Lucide kutusu × 0.875, ağırlık regular (16 → 14 pt, 14 → 12,25, 10 → 8,75); "
         "aynı puntoda SF Symbols Lucide'den iri görünür. Karşılaştırma `skeleton/icon-size-options@2x.png`, karar DESIGN.md §4 (2026-10-13).", "",
         ("SF adları macOS 26'da `NSImage(systemSymbolName:)` ile doğrulandı (`python3 build_icons.py --verify`)."
          if checked else "SF adları bu çalıştırmada doğrulanmadı (`--verify` yok)."), "",
         "| Nerede | Lucide | SF Symbol | Tür | Not | Kaynak (bileşen · ekran) |", "|---|---|---|---|---|---|"]
    order = {"1:1": 3, "yakın": 2, "öneri": 1, "özel": 0, "sistem": 4}
    for k in sorted(icons, key=lambda k: (order[MAP[k][2]] if k in MAP else -1, k)):
        place, sf, kind, note = MAP.get(k, ("?", "?", "?", ""))
        sf_cell = sf if kind in ("özel", "sistem") or sf == "—" else f"`{sf}`"
        L.append(f"| {place} | `{k}` | {sf_cell} | {kind} | {note} | {where(icons[k])} |")
    L += ["", "## Özel semboller (Assets'e eklenecek)", "",
          "- `link.slash`: hazır — `symbols/link.slash.symbolset` (Assets.xcassets'e kopyala). Apple'ın `link` glifinden 27 varyant (9 ağırlık × S/M/L), "
          "eğik çizgi Apple'ın `wifi.slash` ölçüleriyle (45°, ağırlık başına kalınlık ve boşluk); üreteç `symbols/make_link_slash.swift`. "
          "`actool` derledi (27 Vector Glyph), `NSImage(symbolName:bundle:)` yükledi; kontrol panosu `skeleton/link-slash@2x.png`. DESIGN.md §4, 2026-10-13.",
          "- Motor glifleri `engine.webkit`, `engine.chromium`, `engine.firefox`: hazır — `symbols/engine.*.symbolset` (27 varyant), pen.dev `Engine Glyphs` "
          "çiziminden; boyut SF `circle` halkasına oturtuldu (dış çap 14 ızgara = halka çapı), bant her ağırlıkta SF halkası kadar (W1, en az 0,6 birim). "
          "Üreteç `symbols/make_engine_symbols.swift`; kart başlığı ve cihaz seçici aynı sembolü kullanır. Seçenekler `skeleton/engine-weights-options@2x.png`, "
          "kontrol `symbols/custom-symbols-check@2x.png`. DESIGN.md §4, 2026-10-13.",
          "", "## Açık sorular", ""] + ([f"- {p}" for p in problems] or ["- (yok)"])
    OUT.write_text("\n".join(L) + "\n")
    kinds = {}
    for k in icons:
        kinds[MAP.get(k, ("", "", "?"))[2]] = kinds.get(MAP.get(k, ("", "", "?"))[2], 0) + 1
    print(f"wrote icons.md: {len(icons)} icons {kinds}; verified {len(checked)} SF names; problems {len(problems)}")
    for p in problems:
        print("  ?", p)
    sys.exit(1 if problems else 0)


if __name__ == "__main__":
    main()
