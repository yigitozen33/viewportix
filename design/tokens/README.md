# Tasarım token'ları

Kaynak: `design/viewportix.pen` değişkenleri (DESIGN.md §6). Bu klasör tasarım oturumunca üretilir; kod oturumu buradan **kopyalar**, burada düzenlemez.

| Dosya | Ne |
|---|---|
| `viewportix.tokens.json` | W3C Design Tokens biçimi: renk (koyu + `viewportix.light`), köşe, aralık, boyut, çizgi, yazı boyutu, font (sistem + tasarım vekili), motor glifleri (SVG path) |
| `DesignTokens.swift` | `gen_swift.py` üretir: `DesignTokens.Color`, `.Radius`, `.Space`, `.Size`, `.Stroke`, `.FontSize`, `.Font`, `.Motion`. Elle düzenlenmez |
| `export-variables.js` | pen.dev `execute` içinde çalışır, değişkenleri JSON basar (yalnız okur; Viewportix dosyası değilse reddeder) |
| `pen-variables.json` | Son dökümün anlık görüntüsü (üretilir) |
| `gen_swift.py` | `viewportix.tokens.json` → Swift; `--check` eskimiş mi, `--diff` pen ↔ JSON farkı (`DIFF: none` beklenir) |

Kurallar:
- Yalnızca koyu tema yayımlanır; açık değerler ileride (DESIGN.md §4).
- `accent` (sarı) yalnızca eylem ve onay; üstündeki metin `accentInk`.
- Fontlar uygulamada sistem fontu (SF Pro / SF Mono); Inter / JetBrains Mono yalnızca tasarım dosyası vekili, uygulamaya gömülmez.
- pen.dev `width/height`'ta sayı değişkenini çözmediği için `size/*` dosyada referans; kodda kullanılır.
- Bileşen → SwiftUI ad eşlemesi: DESIGN.md §6 ve pen.dev'de `Design System · Tokens` panosu.

Yenileme sırası: pen.dev'de `export-variables.js` → çıktıyı `pen-variables.json`'a yaz → `python3 gen_swift.py --diff` (fark varsa JSON'u düzelt) → `python3 gen_swift.py` → `swiftc -typecheck DesignTokens.swift`. Yalnızca kodda olan token'lar (`size/rail`, panel genişlikleri, ek stroke'lar, glifler, `motion/*`) script'te `CODE_ONLY` listesinde.
