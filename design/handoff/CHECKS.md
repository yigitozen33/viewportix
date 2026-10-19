# Tutarlılık kontrolleri (üretilir)

Son çalıştırma 2026-10-19. Yöntem: `checks.js` + `checks-hash.js` pen.dev `execute` içinde → `python3 checks.py <çıktılar>`. Çıktı biçimi `CHK|id|PASS/FAIL|n|detay`.

| CHK | Kontrol | Sonuç | n | Ayrıntı |
|---|---|---|---|---|
| 1 | Token dışı renk / yazı değeri | ✅ PASS | 0 | · izinli: gradyan durağı 46, gölge rengi 47, token + alfa 53 |
| 2 | Bileşen yerine elle çizilmiş kopya | ✅ PASS | 0 | — |
| 3 | §6 tablosu ↔ bileşenler | ✅ PASS | 0 | — |
| 4 | PNG'si eksik ya da frame'den eski ekran | ✅ PASS | 0 | — |
| 5 | Hiç kullanılmayan bileşen | ✅ PASS | 0 | — |
| 6 | TEMP / tmp / copy / placeholder kalıntısı | ✅ PASS | 0 | — |

## Kurallar ve istisnalar

- CHK-1 arşiv dışı tüm frame'leri instance'lar çözülmüş hâlde tarar. İzinli (bilinçli ham): `Page`, `Thumb`, `Traffic Lights`, `Favicon`, `Alert*` adlı katmanlar (örnek web içeriği, sistem parçası taklidi); gölge renkleri; gradyan durakları; RGB'si bir token olan alfalı renk (`#16141244` = `canvas` + alfa → kodda `.opacity()`); belgeleme panoları `Design System · Tokens`, `Shortcut Map`, `Engine Glyphs`, `App Icon · B variants` ve keşif `Selected Options` (DESIGN.md §4, 2026-10-13).
- CHK-2 bileşen olmayan bir frame'in adı bir bileşenin tam adı ya da son parçasıysa (`Tooltip`, `BottomBar` …) yakalar; genel adlar (`Card`, `Row`, `Button`, `Header`, `Picker`) hariç.
- CHK-4 plandaki "commit tarihi" yerine içerik özeti kullanır: `.pen` her commit'te değiştiği için tarih her PNG'yi eski gösterirdi. Taban `export-hashes.json`; PNG dışa aktarılınca `--accept <frame>` ile güncellenir. İlk taban 2026-10-13'te, bu oturumda değişen 16 PNG yeniden dışa aktarıldıktan sonra tüm frame'ler için alındı (önceki PNG'lerin güncel olduğu varsayımı).
- CHK-5 instance'ları ana kopyalar ve slot değişimleri dahil sayar. CHK-6 ad kalıntılarına ve pen.dev `placeholder` bayrağına bakar.
