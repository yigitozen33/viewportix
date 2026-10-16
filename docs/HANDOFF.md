# Kod oturumu — güncel durum

> Bu dosya **üzerine yazılır**; yalnızca kod oturumu yazar. Tarihçe: `docs/oturumlar/`. Tasarım oturumu salt okur.
> Son güncelleme: 2026-10-16 (üçüncü bölüm: canlı test)

## Şu an neredeyiz

- M0, M1 tamam; M2 (MVP) çalışıyor; M3'te arayüz tasarımı uygulandı (PLAN.md §6 M3, §3.8).
- **Özel arayüz bitti** (`KOD-OTURUMU-ISLERI.md` §12 adım 1–8): başlık çubuğu gizli pencere; sidebar (adres + SON menüsü, gezinme, sayfa listesi, genişlik tutamacı), kapalıyken kapsül; ray ve tutamacı; cihaz şeridi (sekme durumları, taşma, "+N" menüsü, katlı grup çipi); cihaz seçici; alt çubuk; bildirim kapsülü (tek kapsül kuralı, Geri al); viewport kartı (sabit boyutlu başlık katmanı, lider/seçili, yükleniyor, senkron kaçtı, hover şeridi, kamera seçicisi, sağ tık menüsü, Boyutu düzenle popover'ı); Ayarlar paneli (Genel, Cihazlar kitaplığı, Hesap); giriş ekranı.
- **§13'ten biten:** sayfa yüklenemedi (ağ, sertifika + "Bu oturumda güven", localhost 2 sn'de bir, adres bulunamadı, "Hepsini dene"), kart sürükleme + Kartları Diz, gruplama (cihaz türü / motor, katlama, grup menüsü), giriş ekranı halleri, sidebar genişlik tutamacı, odak halkası (kendi denetimlerimizde), tam ekranda 16 pt üst satır, bağlantı sürükle-bırak, tek kapsül + Geri al.
- Etkileşim id'leri: biten / eksik listesi `docs/tasarim-istekleri.md`'de her girdide.
- **Canlı test yapıldı** (üç tur, `orca computer` + gerçek fare olayları, yerel test sayfaları `Tests/Fixtures` 8 cihazda): bulunan hatalar düzeltildi (b18b5bf, f5d4bd2, 4b96728); ayrıntı ve doğrulanan etkileşimler `docs/tasarim-istekleri.md` "Canlı test düzeltmeleri" 1–3. turlarında. Senkron (tık, yazı, onay kutusu, senkron kapalı), ekran görüntüsü + kapsül, sayfa listesi, şerit taşması, tam ekran, Viewport menüsü canlıda çalışıyor.
- **Menüler kendi çizimimiz** (`ChromeMenu`, 64e8e04): sağ tık, zoom, ekran görüntüsü seçicileri, giriş + Kaldır alt menüsü, grup, Ayarlar seçicileri tasarım çerçevelerinin ölçüleriyle; `NSMenu` kalmadı (sistem menü çubuğu hariç). Boyutu düzenle popover'ı `Size Popover`'a göre. Görüntü: `docs/parity/menus@2x.png`.
- Viewport menüsü DESIGN.md §3.2.1'e tamamlandı (seçili kartta); ⌫ ve Esc menü kısayolu değil, canvas işliyor (odak sayfada / metin alanındayken değil).
- Canvas "yapışkan sığdırma": son işlem ⌘1 ise boyut değişince yeniden sığar (`CanvasController.fitted`).
- Mimari not: kart başlığı ve kenarları canvas'ın üstünde ayrı SwiftUI katmanında (`CardChromeLayer`), konumları `Workspace.cardFrames`'ten; grup alanı zemini belge görünümünde (`GroupAreaView`), kartların altında.
- Testler: 80 paket testi geçiyor (`swift test --package-path Packages/ViewportixKit`; 4'ü kapalı localhost / bilinmeyen alan adı gibi gerçek WKWebView testleri). Uygulama derleniyor.
- Görüntü almak: `Scripts/snapshots.sh [klasör]` (DEBUG `--snapshots`; ekran dışı pencere, @2x, sRGB; dokunduğu tercihleri geri yükler). WKWebView orada çizilmez ve yüklemesi bitmez. Xcode önizlemesi bu makinede imza yüzünden derlenmiyor.

## Sıradaki iş

1. Tasarım oturumunun yanıtları: `docs/tasarim-istekleri.md` 2026-10-16 girdilerindeki "Tasarım kararı gerekir mi: evet" maddeleri (spec: BottomBar, şablon içerikleri, katalog listesi, Hesap sekmesi, ikincil düğme, eşit aralık rozetleri…) ve iki parite turu (`design/handoff/PARITY.md`).
2. §13'ten kalan: senkron kurulamıyor (‖ + "Neden?" kapsülü; ajanın sayfaya girip girmediğini motor bildirmeli), eşit aralık rozetleri, Tab sırası (PW-05) gözden geçirme, VoiceOver gözden geçirme.
3. Kalan pasifler: "Taslakları sakla" ve Taslaklar listesi (taslak saklama), yerinde proje adlandırma (HOME-07), "İçe aktar…", kart küçük resmi (`thumbnail.png`), MCP sekmesi (M7), Farklar/Senkron panelleri (M5).
4. Canlıda denenmeyenler: bağlantı sürükle-bırak, giriş ekranında son projeler (kaydetme Belgeler'e yazacağı için atlandı), gruplar canlıda yalnız Cihaz Türü, VoiceOver ile gerçek gezinme, Tab sırası.

## Açık sorular

- **Canlı test aracı:** `orca computer` ile sürmek çalışıyor; koordinatla tık için pencere önde olmalı, kısayollar System Events `key code` ile güvenilir (`keystroke` Türkçe klavyede ⌥ ve , için yanlış karakter gönderiyor). Tasarım kararı bekleyen sorular 3 tur girdisinin sonunda.
- Şablon içerikleri ve cihaz kataloğu tasarımdan bekleniyor.
- Hover taklidi CORS'suz başka alan adı stil dosyalarında çalışmıyor; gerçek sitelerde sıklığı ölçülmedi.
- Dağıtım için Apple Developer Program (şirket hesabı) gerekecek.

## Tasarım oturumunun istekleri (`design/KOD-OTURUMU-ISLERI.md`) — durum

İşaretler burada tutuluyor; kod oturumu `design/` altına yazmaz.

- §1, §4, §5: ✅ (SessionStart hook ⏸).
- §7: token'lar paket hedefi `DesignSystem`'de ✅; görünüm adları §6 tablosuyla aynı ✅; motor glifleri sembol ✅; ayrı ayarlar penceresi yok, panel ✅.
- §8: kısayollar (⌥⌘N, ⌃⌘S, ⌘L, ⌘D, ⇧⌘]/[, ⌥⌘0, ⇧⌘L) ✅; "%100" ✅; döndür/kaldır hover şeridinde ✅; kart menüsü, Boyutu düzenle popover'ı, senkron kapalı ‖, boş durumlar, sayfa menüsü, kapsül halleri ✅; medya duraklatma Görünüm menüsü + Ayarlar ✅; ekran görüntüsü seçicisi ✅.
- §9: chrome parçaları ayrı görünümler ✅; yerleşim ✅; sidebar 240 / panel token'ları ✅.
- §10: medya duraklatma varsayılan açık ✅.
- §11: Cihazlar sekmesi C1 ✅, MCP gizli ✅, Hesap ✅ (hesap olmadığı için kısmi); RailHandle ✅; sidebar 240 ✅; boş URL ipucu ✅.
- §12: adım 1–8 ✅.
- §13: sayfa yüklenemedi ✅, kart sürükleme ✅ (eşit aralık rozetleri yok), gruplama ✅, sidebar V1 (PLAN.md) ✅, genişlik tutamacı ✅, odak halkası ✅ (kendi denetimlerimizde), giriş ekranı ✅, küçük ayrıntılar a b c d e f g ✅ / h yok / i ✅ / j MVP dışı, VoiceOver etiketleri ✅ (gözden geçirilmeli), menü (Grupla, Kartları Diz) ✅.
- §14: hepsi ✅ (ilk bölüm); aşama 9 için ⛔ önerildi.
- Uygulama ikonu (`design/logo/Viewportix.icon`) alınmadı: logo kararı açık.

## Tasarım tarafından son okunan

- `design/HANDOFF.md`, 2026-10-16 sürümü (6d09af8).
