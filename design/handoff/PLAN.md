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
| 0 | Klasör ve sözleşme | ✅ | 2026-10-13 | (bu commit) |
| 1 | Token zinciri (pen → JSON → Swift) | ✅ | 2026-10-13 | (bu commit) |
| 2 | Manifest (bileşen · ekran · PNG · nodeId) | ⬜ | | |
| 3 | Bileşen spec'leri (ölçülü katman ağacı) | ⬜ | | |
| 4 | CHK tutarlılık kontrolleri | ⬜ | | |
| 5 | İkon eşleme (Lucide → SF Symbols) | ⬜ | | |
| 6 | Örnek sayfa HTML'i | ⬜ | | |
| 7 | Etkileşim tablolarına id, ekran başına bölme | ⬜ | | |
| 8 | Parite döngüsü protokolü | ⬜ | | |
| 9 | SwiftUI iskelet üretimi (deneme, isteğe bağlı) | ⬜ | | |

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

- (yok)

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
