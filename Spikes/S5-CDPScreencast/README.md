# S5 — CDP screencast canlı hissettiriyor mu?

**Soru (PLAN.md §5.1):** Kurulu Chrome'u headless çalıştırıp her viewport'u `Page.startScreencast` ile bir karta akıtırsak kabul edilebilir FPS, giriş gecikmesi ve retina netliği alır mıyız?

**Sonuç (2026-10-19): Evet, iki koşulla.** Kareler kartın ekrandaki boyutuna sınırlanmalı ve her viewport kendi headless penceresinde açılmalı. Bu Mac (M1, 8 çekirdek), Chrome 141 headless, `long-page.html`, 4 viewport (iPhone 16 · iPad Air 11" · Masaüstü 1440 · Full HD), JPEG %80:

| Durum | Kare boyutu | 1 viewport kayarken | 4 viewport birlikte kayarken | İlk tepki |
|---|---|---|---|---|
| %30 zoom, kare = kartın boyutu × 2 | 236×511 … 1152×648 px | 49 fps | 47–49 fps, en uzun ara 42 ms | 6–37 ms |
| %100 zoom, tam 2× | 786×1704 … 3840×2160 px | 48–49 fps | 21–29 fps, en uzun ara 100–230 ms | 18–297 ms |
| 2× bayraksız | 1× (393×852 …) | 48 fps | 46 fps | 10–53 ms |

- Başlatma → ilk kare: 2,8–3,6 sn (Chrome açılışı dahil).
- Sayfada değişiklik → kare: ort 9–32 ms. JPEG çözme 0,1–0,7 ms / kare.
- Fare, tekerlek, tıklama, onay kutusu, yazı, silme `Input.dispatch*` ile çalışıyor (form.html).

**Bulgular (ürüne taşınacak):**
1. **Her viewport ayrı pencere** (`Target.createTarget` `newWindow: true`): headless Chrome bir penceredeki sekmelerden yalnız öndekini çiziyor; aynı pencerede yalnız son açılan viewport kare gönderdi. Ayrıca `Emulation.setFocusEmulationEnabled` + `--disable-background-timer-throttling`, `--disable-renderer-backgrounding`, `--disable-backgrounding-occluded-windows`.
2. **Retina için `--force-device-scale-factor=2`**: `setDeviceMetricsOverride` `deviceScaleFactor: 2` tek başına kareyi 1× bırakıyor.
3. **Kare boyutu zoom'a bağlı** (`maxWidth`/`maxHeight` = kartın ekrandaki boyutu × ekran ölçeği; zoom değişince akış yeniden başlatılır). Tam 2× dört büyük viewport'ta akışı yarıya düşürüyor; %100 zoom'da da kart ekrandan büyükse görünen kadarı istenmeli.
4. **Akış gezinmeden önce başlatılmalı**: site değiştiren gezinme sırasında `Page.startScreencast` "Not attached to an active page" ile reddediliyor.
5. **Tuş kodları çevrilmeli**: Chrome `windowsVirtualKeyCode` bekliyor; Mac tuş kodu gönderilince "m" (46) Delete oldu. Harf/rakam için büyük ASCII, diğerleri tablo.
6. **`<select>` açılır listesi kareye çizilmiyor** (klavyeyle değer değişiyor). Ürün: seçim kutusuna tıklanınca listeyi ajan okuyup bizim menümüzle göstermeli (ya da `Emulation`/`DOM` ile seçenekler). Aynı risk: `alert()` / `confirm()` diyalogları (`Page.javascriptDialogOpening` ile ele alınmalı), dosya seçici.
7. **macOS "uygulamaları değiştirme engellendi" uyarısı**: Chrome'un kendi güncelleme / bileşen indirmesi App Management izni istiyor (TCC `kTCCServiceSystemPolicyAppBundles`, imzasız uygulamaya istem yok, reddedildi). `--disable-component-update --disable-background-networking` ile kayboldu.

**Karar önerisi:** Chromium canlı (screencast) kalır; CEF ya da snapshot moduna gerek yok. M4'te `ChromiumEngine` yukarıdaki yedi maddeyle yazılır.

Çalıştırma: fixture'ları sun (`python3 -m http.server 8765`, `Packages/ViewportixKit/Tests/Fixtures`), sonra `Spikes/S5-CDPScreencast/run-selftest.sh --cap --zoom=0.3` (ya da elle: `--zoom=0.6 --cap http://localhost:8765/form.html`). Çıktı `.build/s5-selftest.log`, örnek kare `.build/s5-frame.png`.
