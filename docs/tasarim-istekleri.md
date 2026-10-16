# Tasarım istekleri (kod → tasarım)

Kod oturumunun arayüze dokunan her değişikliği, değişikliğin commit'inde buraya eklenir. Yalnızca kod oturumu yazar, yalnızca eklenir; tasarım oturumu okur ve işlediğini `design/HANDOFF.md`'de izler.

## 2026-10-10 — Canvas boş durumu
- Ne: Projede hiç viewport yokken canvas ortasında "Viewport yok" başlığı, `rectangle.dashed` ikonu ve "Toolbar'daki + Cihaz ile ekle." açıklaması.
- Nerede: Proje penceresi, canvas; `Viewportix/Project/ProjectWindow.swift` (ad376cb)
- Durum: sistem varsayılanı (`ContentUnavailableView`)
- Tasarım kararı gerekir mi: evet — boş canvas'ın görünümü ve metni tasarlanmadı
- Bağlantılı: DESIGN.md §3.2

## 2026-10-10 — Sayfa listesi boş durumu
- Ne: Projede sayfa yokken sidebar'da "Henüz sayfa yok" başlığı, `doc` ikonu ve "Bir adres aç, sonra listeye ekle." açıklaması.
- Nerede: Proje penceresi, sidebar; `Viewportix/Project/PageSidebar.swift` (ad376cb)
- Durum: sistem varsayılanı (`ContentUnavailableView`)
- Tasarım kararı gerekir mi: evet — boş halin görünümü ve metni
- Bağlantılı: DESIGN.md §3.2 (Sidebar)

## 2026-10-10 — Sayfa satırı bağlam menüsü ve yeniden adlandırma
- Ne: Sayfa satırında sağ tık menüsü ("Yeniden Adlandır", "Kaldır"); yeniden adlandırırken satır yerinde metin alanına dönüşür. Delete tuşu seçili sayfayı kaldırır. Satırın ipucu (tooltip) sayfanın URL'si.
- Nerede: Proje penceresi, sidebar; `Viewportix/Project/PageSidebar.swift` (ad376cb)
- Durum: sistem varsayılanı
- Tasarım kararı gerekir mi: evet — yerinde düzenleme ve sürükleyerek sıralama halleri (DESIGN.md'deki rapor istemi 4.3 bunları istiyor)
- Bağlantılı: DESIGN.md §3.2 (Sidebar)

## 2026-10-10 — Giriş ekranında "Henüz proje yok"
- Ne: Son projeler listesi boşken "Henüz proje yok." metni. Liste satırı: proje adı, altında klasör yolu.
- Nerede: Giriş ekranı; `Viewportix/Home/HomeView.swift` (ad376cb)
- Durum: sistem varsayılanı
- Tasarım kararı gerekir mi: evet — giriş ekranının boş hali ve satır düzeni (küçük resimli ızgara M3'te)
- Bağlantılı: DESIGN.md §3.1

## 2026-10-10 — Cihaz Ekle menüsünün içeriği
- Ne: Toolbar'daki `+` menüsü Telefon / Tablet / Masaüstü bölümlerine ayrılı; satır biçimi "iPhone 16 · 393×852". Seçince viewport canvas'ın sonuna eklenir.
- Nerede: Proje penceresi, toolbar; `Viewportix/Toolbar/ProjectToolbar.swift` (ad376cb)
- Durum: sistem varsayılanı (`Menu`)
- Tasarım kararı gerekir mi: evet — DESIGN.md'deki cihaz seçici popover'ı (arama, özel boyut, motor seçimi) bunun yerini alacak
- Bağlantılı: DESIGN.md §5 madde 5

## 2026-10-10 — Zoom menüsünün içeriği
- Ne: Toolbar'da zoom yüzdesini gösteren menü ("100%"): "Sığdır", ayraç, "%25", "%50", "%100", "%200".
- Nerede: Proje penceresi, toolbar; `Viewportix/Toolbar/ProjectToolbar.swift` (ad376cb)
- Durum: sistem varsayılanı (`Menu`)
- Tasarım kararı gerekir mi: evet — menü içeriği ve yüzde yazımı ("%50" mi "50%" mi; düğme "100%" yazıyor, menü "%100")
- Bağlantılı: DESIGN.md §3.2 (Toolbar)

## 2026-10-10 — Menü çubuğu komutları
- Ne: Dosya: "Giriş Ekranı" (⇧⌘0), "Ekran Görüntüsü Al" (⌥⌘S), "Tam Sayfa Ekran Görüntüsü Al" (⌃⌥⌘S; ⌥⇧⌘S "Farklı Kaydet" olduğu için). Görünüm: "Yakınlaştır" (⌘=), "Uzaklaştır" (⌘-), "Gerçek Boyut" (⌘0), "Sığdır" (⌘1). Yeni "Gezinme" menüsü: "Geri" (⌘[), "İleri" (⌘]), "Yenile" (⌘R).
- Nerede: Menü çubuğu; `Viewportix/App/ViewportixApp.swift` (ad376cb, 4d7ddd8)
- Durum: sistem varsayılanı
- Tasarım kararı gerekir mi: evet — menü adları ve kısayollar (HIG: her toolbar öğesi menüde de olmalı)
- Bağlantılı: DESIGN.md §3.2

## 2026-10-10 — Viewport kartının yer tutucu görünümü
- Ne: Başlık: kalın cihaz adı, yanında gri "393×852 · WebKit · Safari 26.0"; sağda kamera ve `xmark` (kaldır) düğmeleri. Lider kart 2 pt vurgu rengi çerçeve, diğerleri 1 pt ayırıcı rengi; köşe yarıçapı 10. Senkron kaçınca başlıkta turuncu `exclamationmark.triangle.fill`, ipucu "Tıklanan eleman bu viewport'ta bulunamadı", 3 sn sonra kaybolur.
- Nerede: Canvas; `Viewportix/Canvas/ViewportCardView.swift` (ad376cb, 4d7ddd8)
- Durum: özel çizim (AppKit)
- Tasarım kararı gerekir mi: evet — kart, lider ve senkron kaçtı tasarımı bekleniyor; bu kayıt yalnızca şu anki yer tutucuyu tarif ediyor
- Bağlantılı: DESIGN.md §5 madde 2 ve 6

## 2026-10-10 — Bildirim kapsülünün ilerleme ve hata halleri
- Ne: Ekran görüntüsü alınırken küçük dönen gösterge ve "Ekran görüntüsü alınıyor…"; hata halleri "<cihaz> yakalanamadı: <hata>", "Ekran görüntüsü oluşturulamadı", "Kaydedilemedi: <hata>". Başarı ve hata 5 sn sonra kaybolur. Kapsül Liquid Glass (`glassEffect`).
- Nerede: Proje penceresi, canvas altı; `Viewportix/Project/NoticeBar.swift`, `Workspace.swift` (4d7ddd8)
- Durum: sistem varsayılanı (glass kapsül)
- Tasarım kararı gerekir mi: evet — başarı hali DESIGN.md §5 madde 11'de; ilerleme ve hata halleri ile metinleri orada yok
- Bağlantılı: DESIGN.md §5 madde 11

## 2026-10-10 — Form ve hover senkronu (görünür arayüz yok)
- Ne: Takipçi viewport'larda form alanları doldurulur ve hover taklit edilir. Taklit hover için sayfaya `data-viewportix-hover` özniteliği ve bir `<style data-viewportix="hover">` eklenir; kullanıcıya görünen yeni bir öğe yok.
- Nerede: Viewport içerikleri; `Packages/ViewportixKit/Sources/SyncCore/Resources/sync-agent.js` (1a163b3)
- Durum: sistem varsayılanı (sayfanın kendi stilleri)
- Tasarım kararı gerekir mi: hayır — ileride senkron türlerini (scroll, tıklama, form, hover) ayrı açıp kapatma ayarı gelirse evet
- Bağlantılı: PLAN.md §3.3

## 2026-10-10 — Viewport kartında döndürme düğmesi
- Ne: Kart başlığında kamera düğmesinin solunda `rotate.right` ikonlu düğme; tıklayınca viewport yatay ↔ dikey döner (genişlik ve yükseklik yer değiştirir, cihaz adı aynı kalır). İpucu: "Döndür".
- Nerede: Canvas, viewport kartı başlığı; `Viewportix/Canvas/ViewportCardView.swift`
- Durum: özel çizim (AppKit, SF Symbol)
- Tasarım kararı gerekir mi: evet — başlıkta artık üç düğme var (döndür, kamera, kaldır); hangilerinin hep, hangilerinin hover'da görüneceği (Polypane yıkıcı eylemleri hover'da gösteriyor)
- Bağlantılı: DESIGN.md §3.2 (Viewport kartı), §5 madde 2

## 2026-10-10 — Viewport kartı başlığında sağ tık menüsü
- Ne: Kart başlığına sağ tıklayınca menü: "Döndür", "Boyutu Düzenle…", ayraç, "Ekran Görüntüsü", "Tam Sayfa Ekran Görüntüsü", ayraç, "Kaldır". Sayfa alanında WebKit'in kendi sağ tık menüsü kalır.
- Nerede: Canvas, viewport kartı başlığı; `Viewportix/Canvas/ViewportCardView.swift`
- Durum: sistem varsayılanı (`NSMenu`)
- Tasarım kararı gerekir mi: evet — menü maddeleri ve sırası
- Bağlantılı: DESIGN.md §3.2 (Viewport kartı)

## 2026-10-10 — "Özel Boyut…" ve boyut düzenleme penceresi
- Ne: Cihaz Ekle menüsünün sonunda ayraç ve "Özel Boyut…". Açılan sheet: "Ad", "Genişlik", "Yükseklik" alanları, "Döndür" düğmesi, "İptal" ve "Ekle". Aynı sheet kart menüsündeki "Boyutu Düzenle…" ile "Boyutu Düzenle" başlığı ve "Kaydet" düğmesiyle açılır. Sınır dışı değerde kırmızı uyarı: "Genişlik 200–3840, yükseklik 200–4320 px olmalı" ve onay düğmesi pasif. Varsayılan: "Özel", 1024×768.
- Nerede: Toolbar Cihaz Ekle menüsü ve sheet; `Viewportix/Toolbar/ProjectToolbar.swift`, `Viewportix/Project/ViewportSizeSheet.swift`
- Durum: sistem varsayılanı (SwiftUI `Form`, grouped)
- Tasarım kararı gerekir mi: evet — DESIGN.md'deki cihaz seçici popover'ının "Özel boyut…" satırı (W/H stepper'lı) ile aynı ihtiyaç; sheet mi popover mı, düzenleme nereden açılır
- Bağlantılı: DESIGN.md §5 madde 5

## 2026-10-10 — Bildirim kapsülünde Liquid Glass kaldırıldı
- Ne: Kapsülün arka planı glass yerine düz zemin rengi, ince ayırıcı çerçeve ve hafif gölge. İçerik ve metinler aynı.
- Nerede: Proje penceresi, canvas altı; `Viewportix/Project/NoticeBar.swift`
- Durum: sistem varsayılanı (SwiftUI `.background` + `.separator`)
- Tasarım kararı gerekir mi: evet — kapsülün özel tasarımı hâlâ bekliyor; bu yalnızca "kendi yüzeylerde Liquid Glass yok" kararına uyum
- Bağlantılı: DESIGN.md §1, §4 (A yönü), §5 madde 11; PLAN.md §3.8

## 2026-10-10 — Viewport'ta "senkron kapalı" göstergesi ve menü maddesi
- Ne: Kart başlığının sağ tık menüsüne "Senkronu Kapat" / "Senkronu Aç" eklendi ("Boyutu Düzenle…"nin altına). Senkronu kapalı kartın başlığında, boyut metninin yanında gri `pause.circle` ikonu; ipucu "Bu viewport için senkron kapalı". Ayar projeye kaydedilir.
- Nerede: Canvas, viewport kartı başlığı; `Viewportix/Canvas/ViewportCardView.swift`
- Durum: özel çizim (AppKit, SF Symbol) + sistem varsayılanı menü
- Tasarım kararı gerekir mi: evet — kapalı halin kartta nasıl görüneceği (ikon, soluk kart, rozet) ve açıp kapamanın başlıkta görünür bir denetimle mi yapılacağı
- Bağlantılı: DESIGN.md §3.2 (Viewport kartı), §5 madde 2 ve 6

## 2026-10-10 — Görünüm menüsünde "Arka Plandaki Viewport'larda Medyayı Duraklat"
- Ne: Görünüm menüsünde, zoom komutlarının altında açılıp kapanan madde. Açıkken ses ve video yalnızca imlecin üstündeki viewport'ta oynar. Varsayılan kapalı; uygulama genelinde saklanır.
- Nerede: Menü çubuğu, Görünüm; `Viewportix/App/ViewportixApp.swift`
- Durum: sistem varsayılanı
- Tasarım kararı gerekir mi: hayır — yalnızca menü maddesi; ileride bir ayarlar penceresi olursa oraya taşınabilir
- Bağlantılı: PLAN.md §6 M2 "Performans"

## 2026-10-16 — Kart ikonları SF Symbols eşlemesine ve × 0.875 puntoya geçti
- Ne: Viewport kartı başlığındaki ikonlar `design/handoff/icons.md` adlarıyla ve kutu × 0.875 punto, regular ağırlıkla çiziliyor (kutu `Size.iconSm` 14 → 12,25 pt): senkron kaçtı `exclamationmark.triangle` (önce `.fill`), senkron kapalı `pause` (önce `pause.circle`), döndür `rectangle.portrait.rotate` (önce `rotate.right`; boyut sheet'indeki Döndür düğmesi de), kamera `camera`, kaldır `xmark`. Kartın yerleşimi ve renkleri değişmedi (kart hâlâ yer tutucu; §12 adım 5'te yeniden kurulacak). Özel semboller `link.slash`, `engine.webkit/chromium/firefox` Assets'te (`Image("link.slash")`; derlenen `Assets.car`'da her biri 27 vektör glif).
- Nerede: Canvas, viewport kartı başlığı; `Viewportix/Canvas/ViewportCardView.swift`, `Viewportix/Project/ViewportSizeSheet.swift`, yardımcı `Viewportix/Chrome/ChromeSymbol.swift`
- Durum: özel çizim (AppKit, SF Symbol)
- Tasarım kararı gerekir mi: hayır — eşleme ve boyut kuralı tasarımdan (DESIGN.md §4, 2026-10-13)
- Bağlantılı: DESIGN.md §4 (İkonlar SF Symbols, SF Symbols boyutu); `KOD-OTURUMU-ISLERI.md` §14
