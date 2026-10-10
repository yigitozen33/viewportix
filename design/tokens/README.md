# Tasarım token'ları

Kaynak: `design/viewportix.pen` değişkenleri (DESIGN.md §6). Bu klasör tasarım oturumunca üretilir; kod oturumu buradan **kopyalar**, burada düzenlemez.

| Dosya | Ne |
|---|---|
| `viewportix.tokens.json` | W3C Design Tokens biçimi: renk (koyu + `viewportix.light`), köşe, aralık, boyut, çizgi, yazı boyutu, font (sistem + tasarım vekili), motor glifleri (SVG path) |
| `DesignTokens.swift` | Aynı değerlerin SwiftUI taslağı: `DesignTokens.Color`, `.Radius`, `.Space`, `.Size`, `.Stroke`, `.FontSize`, `.Font`, `.Motion` |

Kurallar:
- Yalnızca koyu tema yayımlanır; açık değerler ileride (DESIGN.md §4).
- `accent` (sarı) yalnızca eylem ve onay; üstündeki metin `accentInk`.
- Fontlar uygulamada sistem fontu (SF Pro / SF Mono); Inter / JetBrains Mono yalnızca tasarım dosyası vekili, uygulamaya gömülmez.
- pen.dev `width/height`'ta sayı değişkenini çözmediği için `size/*` dosyada referans; kodda kullanılır.
- Bileşen → SwiftUI ad eşlemesi: DESIGN.md §6 ve pen.dev'de `Design System · Tokens` panosu.
