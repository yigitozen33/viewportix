# Aktarım paketi · plan ve ilerleme

> Amaç: tasarımı kod oturumuna makinece okunur, ölçülü ve kontrol edilebilir biçimde vermek. Analiz: [[2026-10-13-ikas-pendev-analizi]] (`design/notlar/`).
> Bu dosya **birden çok oturumda** kullanılır. Her oturum: (1) "Yeni oturuma başlarken"i uygula, (2) ilk tamamlanmamış aşamadan devam et, (3) bitince "Oturum raporları"na satır ekle ve ilerleme tablosunu güncelle.
> Yazan: tasarım oturumu. Kod oturumu salt okur; isteklerini `docs/tasarim-istekleri.md`'ye yazar.

## Yeni oturuma başlarken

1. Bu dosyayı ve `design/HANDOFF.md`'yi oku.
2. `git log --oneline -5 -- design/handoff design/tokens` ile son durumu doğrula; tabloya değil commit'e güven.
3. pen.dev'de `design/viewportix.pen` açık olmalı (`get_app_state`). `.pen`'e yalnızca MCP ile eriş.
4. Yazma alanı: yalnızca `DESIGN.md` ve `design/`. Kod dosyalarına, `docs/`'a, `Packages/`'a dokunma.
5. Aşama bitince: çıktıları commit'le, aşağıya rapor yaz, `.pen` değiştiyse kullanıcıdan ⌘S iste ve dosyayı commit'e ekle.

## İlerleme

| # | Aşama | Durum | Bitiş | Commit |
|---|---|---|---|---|
| 0 | Klasör ve sözleşme | ✅ | 2026-10-13 | 06b3e3b |
| 1 | Token zinciri (pen → JSON → Swift) | ✅ | 2026-10-13 | 06b3e3b |
| 2 | Manifest (bileşen · ekran · PNG · nodeId) | ✅ | 2026-10-13 | 0459780 |
| 3 | Bileşen spec'leri (ölçülü katman ağacı) | 🟡 | | 36fa3fa, 2ed5d9d |
| 4 | CHK tutarlılık kontrolleri | ✅ | 2026-10-13 | f717fc8 |
| 5 | İkon eşleme (Lucide → SF Symbols) | ✅ | 2026-10-13 | 13e2899 |
| 6 | Örnek sayfa HTML'i | ✅ | 2026-10-13 | f223f0f |
| 7 | Etkileşim tablolarına id, ekran başına bölme | ✅ | 2026-10-13 | 162a467 |
| 8 | Parite döngüsü protokolü | ⬜ | | |
| 9 | SwiftUI iskelet üretimi (deneme, isteğe bağlı) | 🟡 | | 91a9590 |

Durum: ⬜ başlanmadı · 🟡 sürüyor · ✅ bitti · ⛔ vazgeçildi (nedeni raporda)

Öncelik: 0 → 1 → 2 → 3 → 5 → 4 → 7 → 6 → 8 → 9. Tahmin: 0–5 bir oturum, 6–7 yarım oturum, 8 kod ilk ekranı çıkarınca, 9 bir saatlik deneme.

## Aşamalar

### 0 · Klasör ve sözleşme
- Çıktı: `design/handoff/README.md` — üç cümlelik sözleşme: kök frame adı → SwiftUI View adı (DESIGN.md §6 tablosu); frame adı `Project Window · <hal>` → ekran durumu; token adı → `DesignTokens` üyesi. Dosya listesi ve "nasıl yenilenir" notu.
- Kabul: README var, bu plan ve HANDOFF'tan bağlantılı.

### 1 · Token zinciri
- Çıktı: `design/tokens/export-variables.js` (pen.dev `execute` içinde çalışır, `GetVariables` → JSON basar), `design/tokens/gen_swift.py` (`viewportix.tokens.json` → `DesignTokens.swift`, stdlib). JSON'da `$extensions.viewportix.penName` ile pen adı; Swift'te elle düzenleme yasağı başlık yorumu.
- Kabul: `python3 gen_swift.py` çıktısı mevcut Swift ile aynı değerleri verir; `swiftc -typecheck` temiz; pen değişkenleri ile JSON arasında fark listesi boş (script `DIFF: none` basar).
- Not: pen.dev sayı değişkenlerini width/height'ta çözmez; boyutlar JSON'da kalır, pen'de sayı yazılı (DESIGN.md §6).

### 2 · Manifest
- Çıktı: `design/handoff/manifest.json` + üretici `design/handoff/dump-manifest.js` (execute snippet). İçerik: `components[]` (penName, nodeId, swiftName, states[], usedIn[]), `screens[]` (frameName, nodeId, section, export, components[]), `tokens` özeti, `generatedAt`.
- Kabul: §6 tablosundaki her bileşen manifest'te ve her manifest bileşeni tabloda (fark → "Açık sorular" bölümü manifest.md'de); her ekran frame'inin `design/exports/` altında PNG'si var.

### 3 · Bileşen spec'leri
- Çıktı: `design/handoff/specs/<SwiftName>.json` — ana kopyanın katman ağacı: ad, tip, layout (yön, gap, padding, hizalama), boyut (sabit / fill / fit), köşe, fill/stroke token'ı, yazı (token, boyut, ağırlık), ikon adı; durum override'ları ayrı `states` anahtarında (durum frame'lerinden okunur: `Viewport States`, `Chrome Spec`, `Tab States`, `Toast States`, `Sidebar States`, `Card Actions`).
- Kabul: 17 bileşen + `RailHandle` için spec var; token dışı ham değerler listelenmiş (CHK-1 ile tutarlı); kod oturumu bir bileşeni PNG'ye bakmadan kurabilir (`BottomBar` ile deneme).

### 4 · CHK kontrolleri
- Çıktı: `design/handoff/checks.js` (salt-okunur execute snippet) ve `design/handoff/CHECKS.md` (son çalıştırma sonucu). Kontroller: CHK-1 token dışı renk/yazı değeri (arşiv hariç); CHK-2 ana kopyası olmayan kopya chrome; CHK-3 §6 tablosunda satırı olmayan bileşen; CHK-4 PNG'si frame'den eski ekran (commit tarihi ile); CHK-5 hiç kullanılmayan bileşen; CHK-6 `TEMP`/`tmp` kalıntısı.
- Kabul: `CHK|id|PASS|n|detay` biçiminde çıktı; tüm CHK PASS ya da nedeni CHECKS.md'de.

### 5 · İkon eşleme
- Çıktı: `design/handoff/icons.md` — tablo `| Nerede | Lucide | SF Symbol | Not |`; birebir karşılığı olmayanlar için öneri ve gerekirse özel glif notu (motor glifleri zaten path).
- Kabul: pen'deki tüm `icon` düğümleri (arşiv hariç) tabloda; SF Symbol adları macOS 26'da var (SF Symbols uygulamasıyla doğrulanır, doğrulanamayan "?" işaretli).

### 6 · Örnek sayfa HTML'i
- Çıktı: `design/fixtures/sample-product.html` (+ gerekirse `.css`): çizimlerdeki "Keten Gömlek ₺1.290" sayfası; responsive, 393 / 820 / 1440'ta tasarımdaki gibi; `.add-to-cart`, `.price`, `.product-title` sınıfları (Farklar paneli örnekleriyle uyumlu).
- Kabul: Safari'de üç genişlikte açılıp tasarımla karşılaştırıldı; kod oturumuna "Tests/Fixtures'a kopyala" notu `KOD-OTURUMU-ISLERI.md`'de.

### 7 · Etkileşim tabloları
- Çıktı: DESIGN.md §3 tabloları ekran başına bölünür (`HOME`, `PW` proje penceresi, `CARD`, `STRIP`, `SIDEBAR`, `BAR`, `RAIL`, `SETTINGS`, `DEV`), her satıra id (`PW-01` …). Mevcut satırlar silinmez, taşınır.
- Kabul: 120+ satırın hepsi id'li; manifest'teki ekranlar ilgili id aralığına işaret eder; `KOD-OTURUMU-ISLERI.md`'ye "kabul listesi = bu id'ler" notu.

### 8 · Parite döngüsü
- Çıktı: `design/handoff/PARITY.md` — protokol: kod oturumu Xcode önizlemesini PNG olarak `docs/parity/<ekran>.png`'ye koyar ve `docs/tasarim-istekleri.md`'ye "parite: <ekran>" girdisi yazar; tasarım oturumu `design/exports/` ile yan yana karşılaştırıp farkları `PARITY.md`'ye tarih + ekran + fark listesi olarak yazar; kapanan farklar ✅.
- Kabul: ilk ekran (giriş ya da proje penceresi) için bir tur tamamlandı.

### 9 · İskelet üretimi (deneme)
- Çıktı: `design/handoff/skeleton/<SwiftName>.swift` — spec JSON'dan VStack/HStack + token referanslı iskelet; önce yalnız `BottomBar`.
- Kabul: `swiftc -typecheck` geçer ve kod oturumu "işe yarar" der; yaramazsa ⛔ ve nedeni rapora.

## Açık sorular

- Aşama 9: kabulün ikinci yarısı (kod oturumu "işe yarar" der) kod oturumunda; istek `KOD-OTURUMU-ISLERI.md` §14. Yaramazsa ⛔ ve nedeni rapora.
- Aşama 3: kabulün son maddesi (kod oturumu `BottomBar`'ı PNG'siz kurar) kod oturumunda; istek `KOD-OTURUMU-ISLERI.md` §14. Yanıt gelince 3 → ✅.

## Oturum raporları

Yalnızca eklenir. Biçim: `### YYYY-MM-DD · <aşamalar>` altında: yapılan, kanıt (commit, dosya), takılan, sonraki adım.

### 2026-10-13 · plan
- Plan yazıldı; analiz `design/notlar/2026-10-13-ikas-pendev-analizi.md`.

### 2026-10-13 · aşama 0 ve 1
- 0: `design/handoff/README.md` (sözleşme + dosya tablosu).
- 1: `design/tokens/export-variables.js` (execute snippet, dosya koruması var), `pen-variables.json` (döküm), `gen_swift.py` (üretim + `--check` + `--diff`), `motion/*` token'ları JSON'a taşındı; Swift tamamen üretiliyor, typecheck temiz, `--diff` → `DIFF: none`.
- Bulgu: ilk `--diff` `accent/ink` renginin JSON'da eksik olduğunu yakaladı (Swift'te elle vardı) → `color/accent-ink` eklendi (`PEN_RENAME` ile eşlenir). Zincir daha ilk çalışmada bir sapma buldu.
- Takılan: pen.dev'de yanlışlıkla `ismail.pen` aktifti; `GetVariables` başka dosyanın değişkenlerini verdi. Önlem: snippet Viewportix değişkenlerini görmezse `ERROR` basıyor; yeni oturum kuralı 3 (`get_app_state`) bunun için.
- Sonraki adım: aşama 2 (manifest).

### 2026-10-13 · aşama 2
- `dump-manifest.js` (execute snippet, arşiv/future frame'leri atlar, dosya koruması), `canvas-dump.json`, `exports-map.json` (48 frame → PNG), `build_manifest.py` → `manifest.json` + `manifest.md`. Sonuç: 17 bileşen, 31 ekran frame'i, 17 durum/spec frame'i, açık soru 0.
- Script DESIGN.md §6 tablosunu okuyup swiftName/states'i bağlıyor; tabloda olmayan bileşen, pen'de olmayan tablo satırı, PNG'si olmayan frame "açık soru" olarak çıkıyor. İlk çalışmada tek yanlış pozitif (`ZoomControl` yalnız `BottomBar` içinde kullanılıyor) → `usedVia` alanı eklendi.
- Sonraki adım: aşama 3 (bileşen spec'leri); öncelik sırasına göre sonra 5 (ikon eşleme).

### 2026-10-13 · aşama 3
- Yapılan: `dump-specs.js` (ana kopya ağaçları + çözülmüş ölçüler, durum frame'lerindeki instance'lar + etiket + sarmalayıcı + yanına çizilen parçalar, Chrome Spec anatomi notları), `dump-instances.js` (ekran frame'lerindeki 388 instance; tek snippet execute süre sınırına takıldığı için ayrıldı), `save_dump.py` (çıktı dosyasından JSON'u FNV-1a hash + uzunlukla doğrulayarak kaydeder; 120 KB'lık döküm elle kopyalanmıyor), `build_specs.py` → `specs/<SwiftName>.json` ×17 + `specs/README.md` (indeks, durum kapsamı, token dışı değerler).
- Kanıt: `python3 build_specs.py` → `wrote 17 specs; raw colour/type values 119; open questions 0`; iki çalıştırma çıktısı aynı (`diff -r` boş); `save_dump.py` → `specs-dump.json: 123999 chars, hash 2633899507`, `instances-dump.json: 114543 chars, hash 2632373712`.
- Not: planda "17 bileşen + `RailHandle`" yazıyordu; `RailHandle` 17'nin içinde, toplam 17 spec.
- Durum adları: etiket metninden; bir etiket birden çok örneği kapsıyorsa ya da etiket uzun bir notsa `build_specs.py` › `LABEL_BY_INSTANCE` / `LABEL_BY_PREFIX`. Sidebar satırında "selected (açık sayfa)" = `surface/header` + nokta; kanıt: aynı görünüm 23 Project Window frame'inde açık sayfa satırında. Yalnız veri (metin, ikon, boyut) ya da ana kopya değerini tekrarlayan örnekler atılır; `onScreens` ekranlardaki görünümleri çizili durumlara eşler.
- `BottomBar` denemesi (tasarım tarafı): spec + `ChromeButton` + `ZoomControl` spec'leri ve `notes` ile kapsül, sıralama, senkron açık/kapalı, hover/basılı/menü açık (`surface/header-leader`), tooltip yerleşimi (`arrangement`: dikey, gap 6) ve konum (alttan 31) PNG'siz okunuyor. Eksik: ikon karşılıkları (Lucide adları; aşama 5).
- Bulgular: (1) tooltip durum frame'lerinde 8 yerde bileşen değil elle çizilmiş frame (ekranlar sayılmadı), yazı boyutları token yerine sayı (12/11); (2) token'a eşit ham değerler: `SnapshotPill` (`#161412` = canvas, `#F4EFE9` = ink/primary), `ProjectCard` MiniHeader (`#2D2926` = surface/header), yazı boyutları 13/12/11/10; (3) bilinçli ham görünenler: kart içi örnek sayfa renkleri, trafik ışıkları, gölge renkleri (`#00000066/80/AA`), kaydırma solması (`#2D292600`); (4) `Window/Rail` › Rail Diff ve 3 ekran instance'ında `#00000000` dolgu (boş dolgu); (5) BottomBar notu "tooltip düğmenin 8 px üstünde" diyor, frame'de ok ile çubuk arası 6; (6) çizimi olmayan §6 durumları: `URLBox` boş/geçersiz, `ProjectCard` hover/taslak (ekranlarda 4 adsız görünüm), `TemplateChip` seçili yalnız ekranda.
- Kullanıcı kararları (DESIGN.md §4, 2026-10-13) ve uygulama: (a) token'a eşit ham değerler bağlandı: 210 yazı boyutu (`$font/*`), 10 renk; 4 boş dolgu kaldırıldı (`fill: []`); (b) `Window/Tooltip` → `ChromeTooltip` bileşeni, 10 tooltip instance oldu (planlanan 8 + `Project Window · İkon çubuklar + tooltip` + `· Motor tooltip`); (c) tooltip–hedef 8 px: Chrome Spec `Tooltip wrap` gap 6 → 8, iki ekran tooltip'i 2 / 7 px kaydırıldı; (d) `Home States` frame'i: URLBox boş/dolu/geçersiz (Aç hep sarı, U2), ProjectCard normal/hover/taslak/sağ tık hedefi, TemplateChip normal/seçili; yeni token `line/strong` (#4F4945 / açık #C7C0B4; H2); ⋯ ana kopyada gizli, bağlam menüsü ekranlarındaki 2 kartta açık.
- Kanıt: `build_manifest.py` → `components=18 screens=31 specFrames=18 openQuestions=0`; `build_specs.py` → `wrote 18 specs; raw colour/type values 37; open questions 0` (önce 119); `gen_swift.py --diff` → `DIFF: none`, `--check` güncel, `swiftc -typecheck` temiz; 13 PNG yeniden dışa aktarıldı + `home-states@2x.png`.
- Sonraki adım: kod oturumunun `BottomBar` denemesi (§14) → 3 ✅; tasarım tarafında aşama 5 (ikon eşleme).
- Commit: `2ed5d9d` (kararların uygulanması, `.pen` dahil).

### 2026-10-13 · aşama 5
- Yapılan: `dump-icons.js` (arşiv dışı görünür ikon düğümleri, instance içleri dahil; ikon → sayı, katman adları, bileşenler, durum frame'leri, pencere türüne göre ekran sayısı), `build_icons.py` (eşleme `MAP` elle; pen'de olup tabloda olmayan ya da tersini açık soru sayar; `--verify` her SF adını bu Mac'te `NSImage(systemSymbolName:)` ile dener) → `icons.md`.
- Kanıt: `python3 build_icons.py --verify` → `wrote icons.md: 66 icons {'öneri': 5, '1:1': 46, 'yakın': 8, 'sistem': 4, 'özel': 3}; verified 55 SF names; problems 0` (macOS 26.6.1). Doğrulama gerçekten eler: `link.slash`, `xmark.magnifyingglass`, `doc.badge.arrow.down` → yok.
- Bulgu: SF Symbols'te kırık zincir yok → özel sembol `link.slash`. Cihaz seçicide motor ikonları Lucide yer tutucusuydu (kartta özel glif) → pen'de `Engine Glyphs` path'leriyle değiştirildi (3 ikon; 69 → 66 ikon), `window-project-device-picker@2x.png` yenilendi, spec yeniden üretildi.
- Kullanıcı kararları (DESIGN.md §4): `link.slash` özel sembol; seçicide glifler; Farklar `square.split.2x1`, Senkron kaydı `waveform.path.ecg`; Döndür `rectangle.portrait.rotate`, Taslaklar `square.and.pencil`, localhost kapalı `server.rack`.
- Not: `save_dump.py` 12 KB'lık satır içi çıktıyı da stdin'den (`-`) hash'le doğruluyor; ikinci dökümde JSON eskisinden türetildi ve snippet'in hash'iyle eşleşti (elle kopya yok).
- Sonraki adım: aşama 4 (CHK kontrolleri).

### 2026-10-13 · aşama 4
- Yapılan: `checks.js` (CHK-1, 2, 5, 6 + bileşen listesi; salt-okunur), `checks-hash.js` (her frame'in çözülmüş ağacının FNV özeti; tek snippet execute süre sınırına takıldığı için ayrı), `checks.py` (CHK-3 DESIGN.md §6 ↔ bileşenler, CHK-4 PNG eksik/eski; `CHECKS.md` yazar, FAIL'de exit 1; `--accept <frame>` dışa aktarımdan sonra tabanı günceller), `export-hashes.json` (taban).
- Plandan sapma: CHK-4 commit tarihi yerine içerik özeti kullanır; `.pen` her commit'te değiştiği için tarih her PNG'yi eski gösterirdi. Kanıt: taban yokken `CHK|4|FAIL|49`; `Design System · Tokens`'a örnek eklenince yalnız o frame `FAIL|1` (`PNG eski: design-system-tokens@2x.png`), PNG yenilenip `--accept` sonrası `PASS`.
- İlk tarama (bağlamadan önce) CHK-1'de yüzlerce bulgu verdi: ekranlarda token'a eşit yazı boyutları, boş dolgular, `#FFFFFF05` grup zemini, `#0E0D0C` drag hint, ad verilmemiş örnek sayfa katmanları. Uygulanan: 138 yazı boyutu + 13 renk bağlandı, 19 boş dolgu kaldırıldı, iki katman `Page` adını aldı; kullanıcı kararıyla `surface/group` token'ı (zincir: JSON → Swift, `gen_swift.py` artık alfa kanalını da yazıyor; önce `#FFFFFF05` opak beyaz üretirdi), drag hint `surface/tooltip`, panolar CHK-1 dışı.
- Kanıt: `CHK|1..6|PASS` (CHECKS.md); `gen_swift.py --diff` → `DIFF: none`, typecheck temiz; `build_specs.py` → açık soru 0; `build_manifest.py` → açık soru 0.
- Sonraki adım: aşama 7 (etkileşim tablolarına id).

### 2026-10-13 · aşama 7
- Yapılan: DESIGN.md §3'teki dört etkileşim tablosuna `ID` sütunu; §3.2 tablosu bölgelere bölündü (STRIP 12, CARD 12, SIDEBAR 8, BAR 7, PW 5), §3.3 RAIL 5 + SETTINGS 5, §3.1 HOME 18, §3.4 DEV 8. Satırlar yalnızca taşındı, metinleri aynı. §3 başına id kuralı (değişmez; silinen "superseded"; yeni satır sona). `build_manifest.py` her ekrana `interactions` (id aralıkları) ekler; tablosuz önek ya da hiçbir ekranın göstermediği önek açık soru olur.
- Kanıt: dönüşüm sonrası eski 80 satırın 80'i yeni tablolarda birebir (script denetimi, eksik 0); `grep -c "^| [A-Z]*-[0-9][0-9] |" DESIGN.md` → 80; `build_manifest.py` → `openQuestions=0`.
- Plandan sapma: planda "120+ satır" tahmini vardı, gerçek sayı 80. Menü çubuğu tablosu (§3.2.1) tetikleyici–etki tablosu değil, kısayol kaynağı; id almadı.
- Sonraki adım: aşama 6 (örnek sayfa HTML'i).

### 2026-10-13 · aşama 6
- Yapılan: `design/fixtures/sample-product.html` (tek dosya, gömülü CSS): kartlardaki "Keten Gömlek ₺1.290" sayfası; tek sütun (görsel 200 / 280 / 340 px, başlık, fiyat), altında beden (`.size-m`), adet (`#qty`), `.add-to-cart`, ürün bilgisi, öneriler, yorumlar, gezinme linkleri. Dev Panel çizimlerindeki seçicilerin hepsi var. Farklar paneli için bilinçli farklar: telefonda `.price` 600 (tablette 500), `.product-title` satır yüksekliği +2 px, `.add-to-cart` daha aşağıda; `?missing-cart` masaüstünde düğmeyi kaldırır ("Masaüstü kaçırdı" örneği).
- Kanıt: WebKit (`WKWebView`, Safari'nin motoru; Safari uygulaması değil) ile 393 / 820 / 1440 genişlikte görüntü, üst 900 px `design/fixtures/renders/sample-product-<genişlik>.png`. Ölçüm: 393 → `.price fw=600`, `.product-title lh=36px`; 820 ve 1440 → `fw=500`, `lh=34px`; sayfa yüksekliği 2132 / 2656 / 2102 px (her genişlikte ≥ 640 px kaydırma, Senkron örneğindeki "scroll 640 px").
- Düzeltme: ilk sürümde masaüstü iki sütundu ve üstte site çubuğu vardı; kartlardaki çizim tek sütun ve görselle başlıyor → tek sütuna döndü, gezinme alta indi.
- Sonraki adım: 8 (parite döngüsü) kod oturumunun ilk ekranını bekliyor; 3'ün kabulü `BottomBar` denemesini bekliyor. 9 isteğe bağlı.

### 2026-10-13 · aşama 9 (deneme)
- Yapılan: `gen_skeleton.py` (spec JSON → SwiftUI): katman ağacı → `HStack`/`VStack`/`ZStack`, padding/spacing/köşe/renk/yazı `DesignTokens` üyeleri (ham sayılar literal), ikonlar `icons.md` eşlemesinden (`build_icons.MAP`), her metin ve ikon katmanı için init parametresi + kök `background`/`padding` (instance override'ları bunlarla geçer), çizili durumlardan `State` enum'u ve override'lardan ternary'ler; içteki bileşenler de üretilir. Çıktı: `skeleton/BottomBar.swift`, `ChromeButton.swift`, `ZoomControl.swift`, `SkeletonSymbol.swift` (özel sembol yardımcı görünümü).
- Kanıt: `swiftc -typecheck skeleton/*.swift ../tokens/DesignTokens.swift` temiz. `ImageRenderer` ile dört durum (senkron açık / kapalı / hover / menü açık) çizildi: her biri 210×49, tasarımla aynı. Yan yana görüntü `skeleton/BottomBar-compare@2x.png` (sol tasarım, sağ iskelet).
- Takılan: ilk sürüm `ChromeButton`'ın "+ Cihaz" örneğini durum sandı ve varsayılan ikonu `plus`'a zorladı (Sığdır düğmesi `plus` gösterecekti). Düzeltme: yalnız veri (metin, ikon, boyut) değiştiren örnekler durum sayılmıyor; tek kalan varsayılan görünümse enum üretilmiyor.
- Bulgular (parite için): (1) SF Symbols aynı puntoda Lucide'den belirgin iri; uygulamada ikon boyutu küçültülmeli, oran görsel karar (kullanıcıya). (2) Senkron kapalı ikonu boş: `link.slash` özel sembolü Assets'e eklenince görünür. (3) Metinler SF Pro, tasarım Inter vekili; genişlikler aynı çıktı.
- Sınırlar: durumlar tek enum (spec frame'lerindeki gibi); gerçek uygulamada senkron açık/kapalı ile düğme hover'ı bağımsız durumlar olmalı. Tooltip gibi yanına çizilen parçalar üretilmiyor, yorumda listeleniyor. Davranış (tık, menü) yok.
- Sonraki adım: kod oturumunun değerlendirmesi → ✅ ya da ⛔.
