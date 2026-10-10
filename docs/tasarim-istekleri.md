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
