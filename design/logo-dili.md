# Viewportix — Logo dili

> Son güncelleme: 2026-10-16 · Küçük boyut kararı K1 (§5). Logo kararı: DESIGN.md §4, 2026-10-10 ("B6 Vx monogram"). Eskiz: `design/exports/app-icon-B-variants@2x.png`, pen frame `App Icon · B variants`.
> Bu dosya logonun **ne olduğunu, neden öyle olduğunu ve nasıl üretileceğini** tek yerde tutar. Görsel kararlar kullanıcıya aittir; buradaki "öneri" satırları karar bekler.

## 1. Fikir

Logo bir **vizör**: dört köşe bracket'i bir viewport'u çerçeveler. Uygulamanın yaptığı şey de budur: bir sayfayı farklı genişliklerde çerçevelemek. Ortada **"Vx"** monogramı (View·port·ix) durur; Dock'ta uygulama adıyla eşleşir, harf tabanlı olduğu için küçük boyutta okunur.

Elenen yönler (DESIGN.md §4): A ailesi (üç genişlik blokları), C (V harfi), B1–B5 (bracket + üç genişlik, bracket + üç motor halkası, V vizör, port lumboz, bracket + cetvel). Gerekçe: B6 en kurumsal ve en küçük boyutta en okunur olanı; motor halkaları (B2) marka logolarına yaklaşıyor, cetvel (B5) 32 px'te siliniyor.

## 2. Anatomi (B6, 220 px eskiz → 1024 px üretim)

Oranlar 220 px eskizden ölçeklenir (×4.6545). Kesin ölçüler pen frame'inden okunur; aşağıdakiler eskizden türetilmiştir.

| Öğe | @220 | @1024 | Not |
|---|---|---|---|
| Karo | 220 × 220, squircle | 1024 × 1024 | Apple'ın macOS ikon ızgarası; köşe maskesini sistem (Icon Composer) uygular, elle squircle çizilmez |
| Bracket uzunluğu | 30 | 140 | Köşeden iki yöne eşit kol |
| Bracket kalınlığı | 14 | 64 | Köşeler keskin (yuvarlatma yok) |
| Bracket kenar boşluğu | 44 | 204 | Karo kenarından bracket dış köşesine |
| "Vx" kap yüksekliği | ≈ 44 | ≈ 205 | Eskizden ölçüm (~%20 karo); kesin değer pen'den |
| "Vx" genişliği | ≈ 80 | ≈ 370 | Eskizden ölçüm (~%36 karo) |
| "Vx" yazı | Kalın, sıkı letter-spacing (negatif tracking) | — | Uygulamada SF Pro Display Bold; pen'de vekil Inter Bold |

Hizalama: "Vx" optik merkezde (x'in alt ucu ile V'nin tepesi bracket'lerin iç kenarına değmez; dört yanda eşit nefes payı).

## 3. Renk

Logo yalnızca arayüz paletinin üç rengini kullanır; yeni renk yok.

| Rol | Token | Koyu | Açık (ileride) |
|---|---|---|---|
| Karo zemini | `canvas` | `#161412` | `#F4F1EC` |
| Bracket'ler | `accent` | `#FFF36B` | `#E6C800` (hardal; sarı açık zeminde kayboluyor) |
| "Vx" | `ink/primary` | `#F4EFE9` | `#1D1B19` |

Not: DESIGN.md §4 kararında Vx için `#FAF8F5` yazıyor; token zincirinde `ink/primary` `#F4EFE9`. Üretimde **token değeri** esas alınır (aradaki fark gözle seçilmez; CHK-1 "token dışı değer yok" kuralı).

Sarı yalnızca bracket'lerde: arayüzdeki "sarı = eylem" kuralının logodaki karşılığı "sarı = çerçeve". Vx asla sarı olmaz, bracket'ler asla krem olmaz.

## 4. Üslup kuralları

- **Düz.** Gradyan, kenar parlaması, iç gölge, doku yok. Arayüzde Liquid Glass yok; ikonda da cam, derinlik, 3B yok. macOS 26 ikon katmanlarına sistemin kendi eklediği hafif parlama kabul (kontrol bizde değil).
- **Tek motif.** Bracket + Vx. Motor halkaları, cihaz siluetleri, cetvel eklenmez.
- **Keskin köşeler.** Bracket köşeleri 90°, uçlar düz kesim. Yuvarlatılmış bracket vizör hissini yok ediyor.
- **Sessiz zemin.** Karo zemini tek renk; sarı zemin üstüne koyu bracket (B1/B3/B5 yönü) elendi, kullanılmaz.
- **Font yok.** Marka fontu reddedildi (DESIGN.md §4); Vx sistem fontuyla yazılır, sonra path'e çevrilir. Kimliği palet + bracket taşır.

## 5. Varyantlar

| Varyant | Nerede | Ne |
|---|---|---|
| Uygulama ikonu | Dock, Finder, Launchpad | Koyu karo + sarı bracket + krem Vx; Icon Composer `.icon` paketi, üç katman: `background` / `brackets` / `monogram` |
| Düz `.icns` yedeği | Icon Composer dışı araçlar, eski dağıtım yolları | Aynı tasarımın tek katmanlı `.iconset` → `.icns` (16–1024, 1x/2x) |
| README logosu, koyu | GitHub koyu mod | Şeffaf zemin, sarı bracket + krem Vx |
| README logosu, açık | GitHub açık mod | Şeffaf zemin, hardal bracket + koyu Vx (açık token'lar) |
| Tek renkli glif | Menü çubuğu, favicon, template image | Bracket + Vx tek renk, `template` olarak işaretli; sistem rengi uygular |

**Küçük boyut (karar, 2026-10-16: K1).** 16 ve 32 px'te "Vx" kaldırılır, yalnız dört bracket kalır; vizör motifi tek başına da logodur. Kollar piksel ızgarasına oturur: 16 px'te kenar boşluğu 2, kol 4, kalınlık 2 px (aralarında 4 px boşluk); 32 px'te hepsi iki katı. 1024 ızgarasında karşılığı: boşluk 128, kol 256, kalınlık 128. 64 px ve üstü tam monogram. Pano: `design/logo/small-size-options@2x.png` (betik `design/logo/make-small-options.swift`). Elenen: K2 bracket + tek "V" (16 px'te krem leke, bracket'ler bulanık), K3 değişmez (32 px'te "Vx" seçilmiyor, 16 px'te gri leke).

## 6. Üretim yöntemi

Logo bir görsel modelle değil, **kodla** çizilir (yöntem Fox uygulamasından; `~/Downloads/fox-logo-prompt.md`, 2026-10-16). Gerekçe: her boyut keskin, renkler birebir token, bir satır değişince her şey yeniden üretilir; `.pen` dosyası tasarım kaynağı, betik üretim kaynağı.

Araçlar: Swift betiği (CoreGraphics, Xcode gerekmez), `iconutil`; Icon Composer (`.icon` paketi, macOS 26). Betik ve çıktılar `design/logo/` altında (2026-10-16'da yazıldı ve çalıştırıldı):

- `make-logo.sh` → `make-logo.swift` + `iconutil`; repo kökünden `sh design/logo/make-logo.sh`.
- `out/background.png`, `out/brackets.png`, `out/monogram.png` — Icon Composer katmanları (1024, alfa; zemin tam kare, şekli sistem verir).
- `out/Viewportix.iconset/` + `out/Viewportix.icns` + `out/icon-1024.png` — düz yedek (köşe yarıçapı %22,37 yaklaşık squircle).
- `out/logo-dark.png`, `out/logo-light.png` (512, şeffaf) + `out/README-picture.html` — README `<picture>` parçası.
- `out/glyph-template@2x.png` — tek renk, siyah/şeffaf.
- `out/check@2x.png` — 16–512 px kontrol panosu.

Betik "Vx"i sistem fontundan (SF Pro Display Bold, tracking −0,05 em) path'e çevirir, token'ları JSON'dan okur, K1 kuralını 32 px ve altında uygular. Icon Composer paketi (`.icon`) henüz kurulmadı; katmanlar hazır.

Doğrulama: `out/check@2x.png` ve `out/icon-1024.png` gözle açılır; 2026-10-16'da yapıldı, 16/32 yalnız bracket, 64+ tam monogram, açık varyant hardal + koyu mürekkep. Renkler `design/tokens/viewportix.tokens.json`'dan okunur; sabit hex yazılmaz.

## 7. Claude Code promptu (uyarlanmış)

Bu prompt `make-logo.swift`'i üretti (2026-10-16); betiği yeniden yazdırmak ya da başka araca taşımak için saklanır. Fox'un promptundan türetildi; Viewportix'e özgü farklar: squircle elle çizilmez (Icon Composer katmanları), gradyan/parlama yok, renkler token dosyasından, küçük boyut kuralı bracket'e iner.

```
Write a Swift script (CoreGraphics only, no Xcode project) at design/logo/make-logo.swift and a shell
script design/logo/make-logo.sh that runs it and builds every output with iconutil/sips.

Brand: the Viewportix app icon is a "viewfinder": four L-shaped corner brackets framing a bold "Vx"
monogram on a dark square tile. Decision record: DESIGN.md §4 (2026-10-10, "B6 Vx monogram");
sketch: design/exports/app-icon-B-variants@2x.png (bottom-right tile). Reference doc: design/logo-dili.md.

Geometry (1024 px tile, scaled from the 220 px sketch):
- brackets: arm length 140, stroke 64, square corners, 204 from the tile edge to the bracket's outer corner
- "Vx": SF Pro Display Bold, tight negative tracking, cap height ≈ 205, optically centered; convert to a path
- do NOT draw a squircle mask or any depth: flat fills only, no gradient, no edge highlight, no shadow.
  macOS 26 applies the shape and lighting itself.

Colors: read design/tokens/viewportix.tokens.json; never hard-code hex.
- tile = canvas, brackets = accent, monogram = ink/primary (dark mode values)
- light README variant uses the light values of the same tokens

Outputs under design/logo/out/:
1. Icon Composer layers, 1024×1024 PNG with alpha: background.png (tile), brackets.png, monogram.png
2. Flat fallback: Viewportix.iconset (16/32/128/256/512 at 1x and 2x) and Viewportix.icns
3. README logos on transparent background: logo-dark.png (for dark mode) and logo-light.png (for light mode),
   plus a <picture> snippet
4. Single-color template glyph: glyph-template.png (brackets + Vx, black on transparent, 2x)
5. check@2x.png: a contact sheet showing 16/32/64/128/512/1024 side by side on the canvas color

Small sizes (decision K1, design/logo-dili.md §5): at 16 and 32 px drop the monogram and draw only the four
brackets on the pixel grid: 16 px → margin 2, arm 4, stroke 2 (1024 grid: 128 / 256 / 128); 32 px → double.
64 px and up render the full design. Reuse the geometry in design/logo/make-small-options.swift.

Verify: open every generated PNG yourself at small and large sizes before finishing. Report the token
values used, the final geometry, and the file list. Do not edit DESIGN.md or design/viewportix.pen.
```

İstenirse Fox'taki çalışan betik örnek olarak verilebilir: Fox deposu `scripts/make-icon.swift`, `scripts/make-icon.sh`.

## 8. Kaynak: Fox promptu (özet)

Fox ikonu da aynı yöntemle üretildi: Claude Code'a (Opus) "halftone küre" motifi, Big Sur/Tahoe squircle, 824/1024 güvenli alan, gradyan karo, kenar parlaması, gölge; 90 px altında noktaların altına dolu küre, 16/32'de yalnız dolu küre; palet `#2c2c30→#121214`, turuncu `#ed7d33 / #fdc78c / #b8521a`. Bizde tutulan: kodla üretim, token'lanmış palet, küçük boyutta basitleştirme, gözle doğrulama, README `<picture>`. Bizde atılan: squircle ve gölgeyi elle çizmek, gradyan, kenar parlaması, çok tonlu palet.
