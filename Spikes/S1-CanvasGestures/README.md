# S1 — Canvas hareketleri

**Soru:** Zoom'lanmış bir canvas üzerindeki canlı WKWebView'lar, PLAN.md 3.4'teki hareket kurallarına uyuyor mu?

**Yaklaşım:** `NSScrollView` + `magnification`, document view içinde 5 gerçek `WKWebView` (iPhone SE, iPhone 16, iPad Air 11", Dizüstü, Masaüstü). Hareketleri tek bir yerel olay izleyicisi (`CanvasController.route`) yönlendiriyor: pinch ve ⌘ + scroll her zaman canvas'a gidiyor, düz scroll imlecin altındaki görünüme bırakılıyor, Space + sürükleme canvas'ı kaydırıyor. Sol alttaki HUD, son olayın nereye gittiğini ve zoom yüzdesini gösteriyor.

Atılabilir kod; ürüne taşınmaz.

## Çalıştırma

```sh
cd Spikes/S1-CanvasGestures && xcodegen generate && open S1CanvasGestures.xcodeproj   # ⌘R
```

Otomatik test (pencere ~30 sn öne gelir):

```sh
Spikes/S1-CanvasGestures/run-selftest.sh   # önce bir kez xcodegen generate
```

## Otomatik test sonuçları (2026-10-10)

| Test | Sonuç |
|---|---|
| Tıklama doğru elemente gidiyor: %100, %50, %30 zoom × 5 viewport | ✅ 15/15, sapma 0,9 px |
| Viewport üstünde dikey scroll sayfayı kaydırıyor, canvas sabit | ✅ |
| Boşlukta scroll canvas'ı kaydırıyor | ✅ |
| Viewport üstünde ⌘ + scroll canvas'ı zoom'luyor, sayfa sabit | ✅ |
| Sayfanın kullanamadığı scroll canvas'a sızmıyor | ⏸ Elle (sentetik olayla ayırt edilemiyor) |
| Pinch | ⏸ Elle (sentetik pinch üretilemiyor) |

Notlar:
- Uygulama arka plandayken ilk tıklama yalnızca pencereyi öne getiriyor, sayfaya ulaşmıyor. Standart Mac davranışı; üründe de böyle olacak.
- Self-test, scroll olaylarını pencere sunucusu olmadan teslim etmek için pencereyi ekranın sol altına taşıyor.

## Elle kontrol listesi (trackpad ile)

Uygulamayı ⌘R ile aç; açılışta tüm viewport'lar `long-page.html` yükler ve canvas sığdırılır. Her adımda HUD'a bak.

1. **Pinch, viewport üstünde:** Canvas zoom'lanmalı, sayfa zoom'lanmamalı. HUD: `pinch → canvas zoom`. Zoom imlecin altındaki noktaya sabitlenmeli.
2. **Pinch, boşlukta:** Aynı davranış.
3. **İki parmak dikey kaydırma, viewport üstünde:** Sayfa kaymalı, canvas sabit. HUD: `scroll → page (…)`.
4. **Sayfanın sonuna kadar kaydırıp devam et:** Sayfa dibe vurduktan sonra canvas **kaymamalı** (sızıntı testi). Aynısını yatay kaydırmayla da dene.
5. **Boşlukta kaydırmaya başlayıp imleci bir viewport'un üstüne getir (parmağı kaldırmadan):** Canvas kaymaya devam etmeli, hareket sayfaya geçmemeli.
6. **Momentum:** Viewport üstünde hızlı kaydırıp parmağı kaldır, momentum devam ederken imleci boşluğa çek. Hareket sayfada kalmalı.
7. **⌘ + scroll:** Her yerde canvas zoom'u.
8. **Space + sürükleme:** Önce boşluğa bir kez tıkla (sayfadan odağı almak için), sonra Space'e basılı tutup sürükle: canvas kaymalı. Bir sayfadaki input'a tıklayıp Space'e bas: input'a boşluk yazılmalı, pan olmamalı.
9. **Kısayollar:** ⌘0 %100, ⌘1 sığdır, ⌘= / ⌘- zoom.
10. **Render kalitesi:** %25'te ve %200'de metin netliği; zoom sırasında takılma veya beyaz kare.
11. **Performans:** Üst alana gerçek bir site yaz (ör. `apple.com`), Enter. 5 viewport yüklüyken pinch ve kaydırma akıcı mı?
12. **Tıklama, gerçek sitede:** %50 zoom'da bir bağlantıya tıkla; doğru yere gitmeli.

Her madde için ✅ / ❌ ve kısa not yeterli.
