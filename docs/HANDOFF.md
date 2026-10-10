# Kod oturumu — güncel durum

> Bu dosya **üzerine yazılır**; yalnızca kod oturumu yazar. Tarihçe: `docs/oturumlar/`. Tasarım oturumu salt okur.
> Son güncelleme: 2026-10-10

## Şu an neredeyiz

- M0, M1 tamam; M2 (MVP) çalışıyor. Ayrıntı ve ölçümler: PLAN.md §6 M2 "Durum" ve "Performans".
- M3'ten biten: form ve hover senkronu, ekran görüntüsü (tek/tüm, görünür/tam sayfa), özel boyut ve döndürme, viewport bazında senkron açma/kapama, isteğe bağlı arka plan medyası duraklatma (varsayılan kapalı; ölçülebilir kazanç yok).
- Testler: 47 paket testi geçiyor (`swift test --package-path Packages/ViewportixKit`).
- Arayüz hâlâ sistem görünümünde (yer tutucu). Arayüze giren her öğe `docs/tasarim-istekleri.md`'de.

## Sıradaki iş

1. Tasarım beklemeyen M3 işleri bitti; kalanlar tasarıma bağlı (sürükleme, gruplama, giriş ekranının tam hali) veya dağıtım (Developer ID).
2. Tasarım gelince: özel pencere çerçevesi (PLAN.md §3.8), sonra bileşenler.
3. Tasarımı beklerken yapılabilecekler: M4 Chromium spike'ı (S4 yerine S5 adı alacak: CDP screencast), elle testlerin yapılması.

## Açık sorular

- Elle testler bekliyor: S1 kontrol listesi (`Spikes/S1-CanvasGestures/README.md`), uygulamada gerçek kaydırma/tıklama senkronu, lider vurgusu, boyut sheet'i.
- Hover taklidi CORS'suz başka alan adı stil dosyalarında çalışmıyor; gerçek sitelerde ne kadar sık olduğu ölçülmedi.
- Dağıtım için Apple Developer Program (şirket hesabı) gerekecek.

## Tasarım oturumunun istekleri (`design/KOD-OTURUMU-ISLERI.md`) — durum

İşaretler burada tutuluyor; kod oturumu `design/` altına yazmaz.

- §1 Hafıza yapısı: `.gitignore`'a `.obsidian/`, `.trash/` ✅ · `docs/HANDOFF.md` ✅ · `docs/oturumlar/` ✅ · CLAUDE.md okuma kuralı ve kısaltma ✅ · SessionStart hook ⏸ (dosyanın önerdiği gibi sonra; önce elle okuma alışkanlığı denensin). 2026-10-10
- §4 Tasarıma haber verme: `docs/tasarim-istekleri.md` ✅ ve kural CLAUDE.md'de ✅. 2026-10-10
- §5 Tamamen özel arayüz: mimari etki PLAN.md §3.8'e ve M3 listesine işlendi ✅; bildirim kapsülündeki Liquid Glass kaldırıldı ✅; geri kalanı tasarım gelince (M3). 2026-10-10

## Tasarım tarafından son okunan

- `design/HANDOFF.md`, 2026-10-10 sürümü (e421381): A yönü (tamamen özel), kütüphane pen.dev'de elle kurulacak, henüz bileşen yok.
