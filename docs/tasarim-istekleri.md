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

## 2026-10-16 — Alt çubuk (BottomBar): BAR-02, BAR-03, BAR-04, BAR-05, BAR-06, BAR-07 bitti; BAR-01 geçici
- Ne: Toolbar'daki senkron, zoom menüsü ve ekran görüntüsü menüsü kalktı; yerine canvas'ın altında ortada (alttan 31) `BottomBar`: senkron (sarı zincir ↔ gri `link.slash`, 150 ms), Sığdır, `ZoomControl` (yüzdeye tık → zoom menüsü; yüzdeyi yatay sürükle → 1 pt = %1, ⇧ kademeye yapışır, imleç ↔; ▲▼ 25/50/100/200/400 kademeleri, 150 ms ease-out, basılı tutunca tekrar), kamera (seçici: "EKRAN GÖRÜNTÜSÜ · n VIEWPORT" · Görünen alan ⌥⌘S · Tam sayfa ⌃⌥⌘S). Hover / basılı / menü açık `surface/header-leader`. Bildirim kapsülü çubuğun 28 pt üstünde; çubuğun menüsü açıkken gizli. Yeni menü maddesi: Viewport › Senkron Açık ⇧⌘L. Canvas en yüksek zoom %200 → %400 (son kademe). Klavye odağında 2 pt gök halka (sistem halkası kapalı). VoiceOver: Senkron (Açık/Kapalı), Sığdır, Yakınlaştırma ("%100", ↑↓ ayarlanabilir), Ekran görüntüsü al.
- Nerede: Proje penceresi, canvas altı; `Viewportix/Chrome/BottomBar.swift`, `ChromeButton.swift`, `ZoomControl.swift`, `MenuAnchor.swift`; `Viewportix/Project/ProjectWindow.swift`, `Viewportix/Toolbar/ProjectToolbar.swift`, `Viewportix/App/ViewportixApp.swift`
- Durum: özel çizim (SwiftUI). Zoom menüsü ve ekran görüntüsü seçicisi şimdilik sistem `NSMenu` (çubuğun 8 pt üstünde, tetikleyiciye sol hizalı); tooltip'ler şimdilik sistem `.help` (BAR-01, `ChromeTooltip` gelince değişecek)
- Tasarım kararı gerekir mi: evet — aşağıdaki "spec: BottomBar" girdisi; seçici ve zoom menüsünün çizilmiş halleri ayrı bileşen olarak spec'te yok
- Bağlantılı: DESIGN.md §3.2 (Alt yüzen çubuk, BAR-01…07), §6 (Pencere chrome'u, VoiceOver tablosu); `KOD-OTURUMU-ISLERI.md` §14

## 2026-10-16 — spec: BottomBar
- Ne: `BottomBar` yalnız `specs/BottomBar.json`, `ChromeButton.json`, `ZoomControl.json` ve `DesignTokens.swift` ile, PNG'ye ve `skeleton/`'a bakmadan kuruldu; sonra `window-project-dark@2x.png` ile piksel taramasıyla karşılaştırıldı (aynı renk uzayında, @2x). Sonuç: yükseklik 49, senkron 30×30, Sığdır ve kamera 32×32, zoom 33 yüksek, stepper 18×25, aralar 8, kenar 1 px — hepsi birebir; renkler birebir. Tek ölçü farkı genişlik: 212 (tasarım 210).
- Bulgular (eksik / yanlış anlaşılabilen alanlar):
  1. **Yazı ağırlığı çelişkisi:** spec'te `ZoomText` ve `ChromeButton › Label` `fontWeight: normal`, ama `font/label` token'ının Swift karşılığı `DesignTokens.Font.label` `.medium`. Spec'e uyuldu (regular, `FontSize.label`). Hangisi doğru?
  2. **`fit` metin genişliği:** `ZoomText` 32 px Inter ölçüsü; SF Pro'da "%100" 34 pt → çubuk 212. Ayrıca değer değiştikçe (%25 ↔ %100) genişlik oynuyor, kapsül ortalı olduğu için çubuk zıplıyordu; kodda üç haneli değere göre sabit genişlik ayrıldı. Spec "sabit genişlik / tabular rakam" demeli mi?
  3. **Senkron düğmesinin hover / basılı hali yok** (not yalnız "Düğmeler Toolbar/Button" için `header-leader` diyor; sarı zeminde ne olacağı yok). Şimdilik hover'da değişmiyor.
  4. **Stepper ▲▼ hover / basılı hali yok.** Şimdilik basılıyken ok `ink/primary`.
  5. **Zoom kontrolünün hover hali yok;** düğmelerle aynı (`header-leader`, tüm kontrol) yapıldı. Zoom kontrolüne tooltip gerekir mi (BAR-01 "ikon hover" diyor)? Şimdilik "Yakınlaştırma".
  6. **Tooltip metinleri:** spec'te yalnız Sığdır (⌘1) örneği var. Diğerleri §6 VoiceOver ve §3.2.1 tablolarından: "Senkron ⇧⌘L", "Ekran görüntüsü ⌥⌘S". Spec düğme başına tooltip metni ve kısayolu taşımalı.
  7. **Basılı tutma tekrarı (BAR-04):** gecikme ve aralık yok; 400 ms sonra 200 ms'de bir yapıldı.
  8. **Tık ile sürükleme ayrımı (BAR-03 / BAR-05):** eşik yok; 3 pt.
  9. **Menülerin konumu:** "çubuğun üstüne açılır" ve "120 ms fade + 4 px" var, çubukla menü arası boşluk ve hizalama yok; 8 pt üstte, tetikleyiciye sol hizalı yapıldı. Zoom menüsü ve ekran görüntüsü seçicisi spec'te bileşen değil (yalnız ekran frame'lerinde); bunlar için de spec gerekir. Seçicinin alt satırındaki ayar özeti (panoya kopyala, ölçek, klasör → Ayarlar) Ayarlar paneli olmadığı için yok.
  10. **Kapsül ile çubuk arası:** spec'te yok; PNG'den 28 pt ölçüldü.
  11. **Odak halkası:** yalnız `ChromeButton` için çizili; senkron düğmesine de aynısı uygulandı, zoom kontrolü (tek erişilebilirlik öğesi) için hal yok.
  12. **Zincir şekli:** Lucide `link-2` yatay, SF `link` çapraz (icons.md "yakın"); karşılaştırmada en göze batan fark bu.
- Nerede: `Viewportix/Chrome/`; karşılaştırma görüntüleri `Scripts/snapshots.sh` ile üretilir
- Durum: özel çizim
- Tasarım kararı gerekir mi: evet — 1, 2, 3, 4, 6, 9 karar ister; diğerleri onay
- Bağlantılı: `design/handoff/PLAN.md` aşama 3 kabulü; `KOD-OTURUMU-ISLERI.md` §14 "Deneme"

## 2026-10-16 — iskelet: BottomBar (aşama 9) — kod kaynağı olarak işe yaramaz, ölçü kontrolü olarak işe yarar
- Ne: Elle kurulan `BottomBar` (`Viewportix/Chrome/`, fe93bfd) ile `design/handoff/skeleton/BottomBar.swift` (+ `ChromeButton`, `ZoomControl`, `SkeletonSymbol`) karşılaştırıldı. İskelet `DesignTokens.swift` ile ayrı derlenip `ImageRenderer` ile aynı koşulda (@2x, 24 pt kenar, canvas zemini) çizildi, iki görüntü satır satır piksel taramasıyla kıyaslandı.
- Kanıt: yatay taramada senkron düğmesi, Sığdır, zoom zemini ve renkler birebir; tek fark zoom metninden sonra 4 px (@2x) kayma. İskelet 210 × 49, elle kurulan 212 × 49. **Düzeltme** (önceki "spec: BottomBar" girdisi madde 2): fark SF Pro'dan değil, benim seçimimden — SF Pro'da "%100" orantılı rakamla 32 pt (tasarımla aynı), tabular rakamla 34 pt. Kodda zoom değiştikçe çubuk zıplamasın diye tabular rakam + üç haneli genişlik kullanılıyor; soru aynı kalıyor: 2 pt'lik sabitlik mi, 210 mu?
- Değerlendirme:
  - **Yerleşim kısmı:** iskelet doğru ve elle yazdığımla aynı sayılar, aynı token'lar. Ama bu kısım işin küçük bölümü; spec JSON'dan elle yazmak kısa sürdü ve aynı sonucu verdi (yukarıdaki piksel eşitliği), yani iskelet bir şey kazandırmadı.
  - **Kullanılamayan kısımlar:** (1) durumlar tek enum (`senkronAcik`, `hoverTooltip`, `menuAcikZoom`): gerçekte senkron açık/kapalı, düğme hover'ı, basılı ve menü açık bağımsız; uygulamada hepsi ayrı değer. (2) Davranış yok: hover izleme, `ButtonStyle`, tık/sürükle ayrımı, basılı tutma tekrarı, menüler, VoiceOver, odak halkası — dosyanın büyük kısmı bunlar. (3) Parametreler katman verisi (`syncIcon: String?`, `syncIconSize`, `background`), anlam değil (`isSyncEnabled`, `zoom`); her metin ve ikon dışarı açılmış. (4) Ad çakışması: `public struct ChromeButton/ZoomControl` uygulamadaki adlarla aynı, yan yana derlenmez; "yeniden üret, düzenleme" kuralı yüzünden üstüne de yazılamaz. (5) Spec'te olmayan karar yok — iskelet spec'in eksiklerini (madde 3–9) göstermiyor, sessizce varsayılanla dolduruyor.
  - **İşe yarayan kullanım:** ölçü kehaneti. İskelet ile uygulama görünümünü aynı koşulda çizip piksel karşılaştırmak, PNG'ye göre daha temiz bir parite kontrolü (aynı yazı tipi ve sembol motoru, tasarım vekili Inter yok). Katmanlı bileşenlerde (kart) iskelet bozuk çiziyor (`design/handoff/PLAN.md` aşama 9 notu), bu kullanım da akışlı bileşenlerle sınırlı.
- Öneri: aşama 9'u kod kaynağı olarak ⛔; üreteç istenirse yalnız "ölçü kehaneti" olarak (önekli adlarla, ör. `SkeletonBottomBar`) sürsün. Spec'in kendisi (aşama 3) kurmaya yetti.
- Nerede: `design/handoff/skeleton/`, `Viewportix/Chrome/`; tarama aracı geçici (scratchpad), görüntüler `Scripts/snapshots.sh` ile yeniden üretilir
- Durum: —
- Tasarım kararı gerekir mi: evet — aşama 9'un sonucu (⛔ / ölçü kehaneti olarak sürsün) ve 210 ↔ 212
- Bağlantılı: `design/handoff/PLAN.md` aşama 9; `KOD-OTURUMU-ISLERI.md` §14 "İskelet denemesi"

## 2026-10-16 — ChromeTooltip: BAR-01 bitti
- Ne: `Window/Tooltip` → `ChromeTooltip` (specs/ChromeTooltip.json): `surface/tooltip` gövde, `line` kenar, ad (12 medium) + isteğe bağlı kısayol (11, `ink/secondary`), üstteki tooltip'te 12×6 aşağı ok; yan tooltip'lerde ok yok. Hedefle ok ucu arası 8 pt, 400 ms gecikme, 100 ms fade; basınca kaybolur. Tooltip açıkken bildirim kapsülü gizli. Alt çubuktaki dört düğme ("Senkron ⇧⌘L", "Sığdır ⌘1", "Yakınlaştırma", "Ekran görüntüsü ⌥⌘S") ve giriş ekranındaki tüm denetimler bunu kullanıyor (sistem `.help` kalktı).
- Nerede: `Viewportix/Chrome/ChromeTooltip.swift` (`.chromeTooltip(_:shortcut:edge:)`); `BottomBar.swift`, `Home/HomeView.swift`
- Durum: özel çizim (SwiftUI)
- Tasarım kararı gerekir mi: evet, iki küçük nokta — (1) giriş ekranının sağ üst düğmelerinde (Aç… ⌘O, Yeni ⌘N, Ayarlar ⌘,) ve ızgara/liste anahtarında tooltip altta açılıyor (pencerenin üst kenarına yakın); alttaki tooltip için ok çizilmedi, spec yalnız aşağı ok tanımlıyor. (2) Henüz yeniden kurulmayan iki yerde sistem tooltip'i kaldı: viewport kartı (AppKit, §12 adım 5) ve sidebar sayfa satırı (`PageSidebar`, §12 adım 3); o bileşenler kurulunca geçer.
- Bağlantılı: DESIGN.md §3.2 BAR-01, §4 (Tooltip bileşen olur; 8 px); `KOD-OTURUMU-ISLERI.md` §14

## 2026-10-16 — Giriş ekranı: HOME-01…06, HOME-08…12, HOME-15, HOME-16, HOME-18 bitti; HOME-13 kısmen; HOME-07 ve HOME-17 yok
- Ne: Giriş penceresi baştan özel çizim (1040×700, başlık çubuğu gizli, koyu): sidebar 200 (Son / Taslaklar, seçim hatırlanır), sağ üstte Aç… / Yeni / ⚙, `URLBox` (boş · dolu · geçersiz: mercan kenar + "Bu bir web adresi değil · örnek: marka.com"; "Aç →" hep sarı, boşken alana odaklanır; yapıştırınca https tamamlanır), üç `TemplateChip`, "SON PROJELER" + arama + ızgara/liste anahtarı (hatırlanır), `ProjectCard` ızgarası (normal, hover kenarı `lineStrong` + ⋯, taslak rozeti, sağ tık hedefi gök kenar + ⋯, dosya bulunamadı: soluk küçük resim + mercan meta, tık → Bul…), liste görünümü (Ad · Cihazlar · Sayfalar · Düzenlendi · ⋯; eksik dosyada "Dosya bulunamadı" + Bul…), boş durum (üç hayalet kart, "Henüz proje yok"), aramada sonuç yok ("“…” ile eşleşen proje yok" + Aramayı temizle, Esc), bağlam menüsü (Aç · Yeniden adlandır · Çoğalt ⌘D · Finder'da göster ⇧⌘R · Dosya yolunu kopyala · Kaldır › Listeden kaldır "Dosya diskte kalır" / Çöp Sepeti'ne taşı "Finder'dan geri alınabilir"; eksik dosyada Bul… ve Çoğalt/Finder pasif), pencereye `.viewportix` sürükleyince gök kenar ve açma, açılamayan proje için NSAlert metinleri.
- Nerede: `Viewportix/Home/` (`HomeView`, `URLBox`, `TemplateChip`, `ProjectCard`, `RecentProjects`), `Viewportix/Chrome/ContextMenuArea.swift`, `Viewportix/App/ViewportixApp.swift`; paket: `ProjectModel/ProjectTemplate.swift`, `ProjectSummary.swift` (+ `ProjectTemplateTests`)
- Durum: özel çizim (SwiftUI); bağlam menüsü ve uyarılar sistem (`NSMenu`, `NSAlert`) — tasarımla aynı
- Eksik / tasarımdan sapan:
  1. **Şablon içerikleri tasarımda yok;** kodda varsayılan: Mobil odaklı = iPhone SE, iPhone 16, iPhone 17 Pro Max, iPad Air 11"; Tam matris = 8 cihaz (3 telefon, 2 tablet, 3 masaüstü); Motor karşılaştırma = iPhone 16 + Masaüstü × üç motor. "Yeni" de seçili şablonu kullanıyor. Onay ya da liste gerekir.
  2. **Motor karşılaştırma çipi pasif** (yarı saydam, tooltip "Chromium ve Firefox ile gelecek"): Chromium (M4) ve Firefox (M6) yokken üç kez WebKit açardı. Tasarımda etkin.
  3. **HOME-07 yerinde yeniden adlandırma yok;** menü maddesi pasif.
  4. **HOME-17 ⚙ pasif:** Ayarlar paneli §12 adım 7 ile gelecek.
  5. **HOME-13:** taslak olmadığı için "Son taslağı aç" yok, düğmeler "Tamam" + "Finder'da Göster" (tasarımın notuna uygun); yeni sürüm uyarısında "Güncellemeleri Denetle" yok (güncelleyici yok), yalnız "Tamam"; metinde uygulama sürümü yerine "dosya sürümü N".
  6. **Taslaklar** listesi boş (taslak saklama yok); boş halinde "Henüz taslak yok" yazıyor — çizimi yok.
  7. **Küçük resim:** `thumbnail.png` henüz üretilmiyor; kart, projenin viewport'larını spec'teki mini kart çizimiyle (gerçek en/boy oranında) gösteriyor. Dosyası bulunamayan kartta proje okunamadığı için küçük resim boş (tasarımda soluk mini kartlar). Favicon yerine spec'teki `surface/pill` kare.
  8. **Kart genişliği:** spec 236 sabit, ekran frame'inde 248; uyarlanabilir ızgara (en az 236, aralık 16) kullanıldı, 1040'ta üç sütun × 248.
- Spec boşlukları (giriş): `ProjectCard` hover ve sağ tık hedefi durumlarında kenar rengi override'ı spec'te yok (yalnız ⋯ görünürlüğü var; renkler DESIGN.md §6 ve PNG'den); `TemplateChip` seçili durumunda override yok (sarı kenar + `surface/header` zemin PNG'den); geçersiz URL açıklamasının yazı boyutu yok (12 kullanıldı); sidebar satırı, arama alanı, ızgara/liste anahtarı ve liste satırı bileşen değil (ölçüler PNG'den: liste sütunları 516 / 648 / 760 pt); çiplerin hover hali yok.
- Tasarım kararı gerekir mi: evet — 1, 2, 6 ve spec boşlukları
- Bağlantılı: DESIGN.md §3.1 (HOME-01…18), §4 (2026-10-13 giriş durumları, `line/strong`); `KOD-OTURUMU-ISLERI.md` §13 "Giriş ekranı", §14

## 2026-10-16 — parite: Giriş ekranı (Home Window)
- Ne: Parite turunun ilk ekranı (`design/handoff/PLAN.md` aşama 8). Kod görüntüleri, karşılaştırılacak dışa aktarımla aynı adla:
  - `docs/parity/window-home-dark@2x.png` ↔ `design/exports/window-home-dark@2x.png` (ızgara; örnek veri "Marka A · 2 sa. önce · 3 cihaz", "Marka B · Dün · 5 cihaz")
  - `docs/parity/window-home-list@2x.png` ↔ `window-home-list@2x.png` (liste; + dosyası bulunamayan "Marka C")
  - `docs/parity/window-home-empty@2x.png` ↔ `window-home-empty@2x.png`
  - `docs/parity/home-states@2x.png` ↔ `home-states@2x.png` (URLBox üç hal; ProjectCard normal / hover / taslak / sağ tık hedefi / dosya bulunamadı; TemplateChip normal / seçili / pasif)
- Nasıl üretildi: Xcode önizlemesi bu makinede imza yüzünden derlenmiyor ("No Accounts", 10-10'daki aynı sorun), bu yüzden `Scripts/snapshots.sh` (DEBUG `--snapshots`): görünüm ekran dışı bir pencerede çizilir, @2x, sRGB'ye çevrilir (dışa aktarımlarla aynı renk uzayı). 53365f3 üzerinde.
- Kodun kendi ölçümü (piksel taraması, x = 700 pt sütunu): URL kutusu, çipler, başlık satırı ve kart üst/alt kenarları dışa aktarımla aynı satırlarda (fark ≤ 2 px @2x); renkler ±2 (sRGB dönüşüm yuvarlaması).
- Bilinen farklar (tasarım listeye eklesin ya da kapatsın):
  1. Trafik ışıkları görüntüde yok: ekran dışı pencere kenarsız; uygulamada sistem ışıkları var.
  2. Motor karşılaştırma çipi ve ⚙ pasif (yarı saydam) — yukarıdaki giriş ekranı girdisi madde 2 ve 4.
  3. Küçük resimler projenin gerçek cihaz oranlarıyla çiziliyor (tasarımda sabit örnek mini kartlar); favicon renkli kare yerine `surface/pill`.
  4. Yazı SF Pro (tasarım vekili Inter): "SON PROJELER" ve sütun başlıklarında harf aralığı farkı göze çarpabilir (kodda 0,5 / 1).
  5. Taslak kartı "Untitled" ızgarada yok (taslak saklama yok); rozet `home-states`'te görülebilir.
- Durum: özel çizim
- Tasarım kararı gerekir mi: evet — karşılaştırma ve farklar `design/handoff/PARITY.md`'ye
- Bağlantılı: `design/handoff/PLAN.md` aşama 8; `KOD-OTURUMU-ISLERI.md` §14

## 2026-10-16 — Proje penceresi çerçevesi, sidebar ve ray: SIDEBAR-01, 02, 03, 05, 06, 07, 08 ve RAIL-03, 04, 05 bitti
- Ne: `NavigationSplitView` ve sistem toolbar'ı kalktı. Pencere: başlık çubuğu gizli, koyu, en küçük 1024×640; yatayda sidebar (240, genişlik tutamacıyla 200–360, uygulamaya kaydedilir) · canvas · ray (44). Sistem trafik ışıkları korunuyor, yalnız yeri değişiyor: sidebar açıkken 48 pt'lik satırın ortasında (x 16), kapalıyken kapsülün içinde.
  - **Sidebar başlığı:** adres alanı (kilit/küre, odakta 1 pt gök kenar, ⌘L odaklar, ⏎ yükler, Esc geri alır; odakta altında SON menüsü: son 5 adres + ne zaman, yazdıkça süzülür, ↑↓ ⏎, "Geçmişi temizle", "Listeye ekle: ⌘D"; geçmiş uygulamaya ait), geri / ileri / yenile.
  - **Sayfa listesi:** "SAYFALAR", satır (ikon adresten: ana sayfa `house`, ürün `shippingbox`, sepet `cart`, ödeme `creditcard`, diğer `doc.text`), hover'da zemin + kalem + ⋯, açık sayfada zemin + nokta, çift tık / kalem ile yerinde yeniden adlandırma (gök kenar, "↩ kaydet · Esc iptal"), sağ tık / ⋯ menüsü (Aç · Yeniden adlandır · URL'yi kopyala ⇧⌘C · Yukarı taşı ⌥⌘↑ · Aşağı taşı ⌥⌘↓ · Kaldır), açık adres listede yoksa sarı kenarlı "Bu sayfayı ekle · /yol · ⌘D", "+ Ekle", boş durum ("Henüz sayfa yok · Açık sayfayı ⌘D ile ekle."). Satır tooltip'i: ad + adres.
  - **Sidebar kapalı:** ⌃⌘S ya da kapsüldeki düğme; canvas sol üstünde (16, 16) `CollapsedSidebarHeader` (ışıklar · ayırıcı · sidebar düğmesi · nav · 191 pt adres).
  - **Ray:** Ayarlar, Cihazlar, MCP, Hesap · ayırıcı · Farklar, Senkron Kaydı · Rayı Gizle; tooltip'ler solda. Gizleyince sağ kenarda üstten 16'da `RailHandle` (tık / ⌥⌘0 geri getirir, tooltip "Rayı göster ⌥⌘0"); tercih uygulamaya kaydedilir.
  - **Canvas:** zemin `canvas` token'ı; Sığdır kartları şeridin altına ve alt çubuğun üstüne sığdırıyor (üstte 72, altta 96 pt pay).
  - **Menü:** Görünüm › Sidebar'ı Gizle ⌃⌘S, Rayı Gizle ⌥⌘0; Gezinme › Adres Çubuğu ⌘L, Bu Sayfayı Listeye Ekle ⌘D, Sonraki Sayfa ⇧⌘], Önceki Sayfa ⇧⌘[.
- Nerede: `Viewportix/Project/ProjectWindow.swift`, `ProjectSidebar.swift`, `SidebarHeader.swift`, `InspectorRail.swift`, `AddDeviceButton.swift`, `URLHistoryStore.swift`; `Viewportix/Chrome/TrafficLights.swift`; `Viewportix/Canvas/CanvasController.swift`; paket `ProjectModel/URLHistory.swift` (`URLHistory`, `PageKind` + testler)
- Durum: özel çizim (SwiftUI); bağlam menüleri sistem `NSMenu`
- Eksik / sapma:
  1. **Ray öğeleri pasif** (yarı saydam): Ayarlar paneli §12 adım 7'de, Farklar/Senkron M5'te gelecek (RAIL-01, RAIL-02 yok). MCP "M7'ye kadar gizli kalabilir" diyordu; çizimdeki gibi görünür bırakıldı.
  2. **SIDEBAR-04 sürükle-bırak yok;** sıralama şimdilik menüdeki Yukarı/Aşağı taşı ile.
  3. **Geçici "+ Cihaz":** canvas'ın üstünde ortada tek `ChromeButton`, sistem menüsü açıyor; `DeviceStrip` (sekmeler) ve `DevicePicker` gelince yerini alacak.
  4. **Tam ekranda** sidebar üst satırını 48 → 16 pt yapma (§5.20 b) henüz yok.
  5. **Geri/ileri pasif hali yok:** motorun geçmiş durumu henüz izlenmiyor.
  6. **Adres kısaltma:** odak dışında ortadan kısaltılıyor, ama "alan adı korunur" kuralı uygulanmadı (uzun alan adında ortası gidebilir).
  7. "+ Ekle" ne yapmalı tanımlı değil; açık adresi ekliyor, adres yoksa adres alanına odaklanıyor.
  8. SON menüsünün zemin, köşe, gölge ve satır ölçüleri spec'te yok (`Sidebar/Header` notu yalnız "altında Son 5 menüsü" diyor); PNG'den alındı: `surface/header`, köşe 12, satır 12 + 10 pt yazı.
- Tasarım kararı gerekir mi: evet — 1, 6, 7, 8
- Bağlantılı: DESIGN.md §3.2 (SIDEBAR-01…08), §3.3 (RAIL-01…05), §5.20, §6 (Pencere chrome'u); `KOD-OTURUMU-ISLERI.md` §9, §11, §12 adım 2–3

## 2026-10-16 — Cihaz şeridi ve bildirim kapsülü: STRIP-01…06 bitti, STRIP-07 geçici; kapsül halleri ve tek kapsül kuralı
- Ne:
  - **`DeviceStrip`:** canvas'ın üstünde ortada (üstten 16), sidebar kapalıyken kapsülle çakışmayacak genişlikte. `DeviceTab`: ad (en çok ~140, sondan "…"), durum ikonu (senkron kaçtı mercan üçgen, yükleniyor dönen gösterge), ✕; lider sekme `surface/header-leader` + 1 pt gök kenar; hover `surface/header-leader`. Tooltip: ad + boyut. Sekmeye tık → kart seçilir ve canvas karta kayar (250 ms). ✕ → viewport kapanır, sekmeler kayar. Taşmada sekmeler kaydırılır, kenarlarda solma, ‹ › düğmeleri, gizlenen sekme sayısıyla "+N" çipi (en ciddi gizli durum: hata mercan kenar + üçgen > lider gök kenar + göz > yükleniyor); çipe tık → "GİZLİ CİHAZLAR · tıkla: sekmeye kaydır" menüsü (satır: cihaz türü ikonu, ad, "1280×800 · WebKit · durum", durum ikonu, odakla, ✕; senkron kaçan satır `status/warning-bg`). Satıra tık şeridi o sekmeye kaydırır ve menüyü kapatır; odakla menüyü açık bırakır; Esc ya da dışarı tık kapatır.
  - **"+ Cihaz"** şeridin sağında; cihaz seçici popover'ı gelene kadar sistem menüsü (STRIP-07 geçici, STRIP-08…11 `DevicePicker` ile).
  - **`ToastCapsule`:** ilerleme ("Ekran görüntüsü alınıyor… 2 / 3"), başarı (sarı tik + "Finder'da Göster", 5 sn), kısmi hata (mercan kenar + üçgen + "Yeniden dene": yakalananlar kaydedilir, yalnız başarısız olanlar yeniden denenir), hata ("Kaydedilemedi" + "Ayrıntılar", kapatılana kadar kalır), geri al ("iPad kapatıldı · Geri al", 5 sn; ⌘Z de geri alır), bilgi. Aynı anda tek kapsül; açık hata başarıyla ezilmez, başarı hata kapanınca gösterilir. 150 ms crossfade.
- Nerede: `Viewportix/Project/DeviceStrip.swift`, `ToastCapsule.swift` (önceki `NoticeBar`), `ProjectWindow.swift`, `Workspace.swift` (bildirim modeli, `loadingIDs`, `selectedViewportID`), `Viewportix/Canvas/CanvasController.swift` (`reveal`)
- Durum: özel çizim (SwiftUI); "+ Cihaz" menüsü sistem `NSMenu`
- Eksik / sapma:
  1. **Hata kapsülünde kapatma yok** spec'te ("kullanıcı kapatana kadar kalır" diyor, nasıl kapatılacağı yok); sağda sessiz bir ✕ (12 pt, `ink/secondary`) eklendi.
  2. **Seçili kartın görünümü** (krem halka) kart yeniden kurulunca (§12 adım 5) gelecek; şimdilik sekmeye tık yalnız canvas'ı kaydırıyor.
  3. **Snapshot sekmesi** (resim ikonu) Firefox (M6) ile; kodda durum yok.
  4. **Gruplu şerit** (ayırıcı, katlı grup çipi; PW-02, PW-03, STRIP-12) §13 gruplama ile.
  5. **Sekme sağ tık menüsü** tasarımda yok; eklenmedi.
  6. "+N" sayısına kısmen görünen sekme de dahil (tamamen görünmeyen değil, tamamen görünen dışındakiler sayılıyor).
- Tasarım kararı gerekir mi: evet — 1 ve 6
- Bağlantılı: DESIGN.md §3.2 (STRIP-01…12, Bildirim kapsülü halleri), §5.20 d–f; `KOD-OTURUMU-ISLERI.md` §12 adım 4

## 2026-10-16 — Viewport kartı yeniden kuruldu: CARD-01…07 bitti; kart başlığı zoom'dan bağımsız
- Ne: Kartın sabit boyutlu parçaları artık canvas'ın üstünde ayrı bir katmanda, kartların ekrandaki konumunu izleyerek çiziliyor; yalnız sayfa (WKWebView) zoom'la ölçekleniyor (çizimlerdeki gibi: %40'ta da başlık 36 pt, yazı 12 pt). Katmanda:
  - **Başlık (36):** ad (12 semibold), boyut (11, `ink/secondary`; dar kartta önce boyut gizlenir, sonra ad ortadan kısalır), senkron kapalıysa gri `pause` (tooltip "Bu viewport için senkron kapalı"), senkron kaçtıysa mercan üçgen; sağda motor glifi (`engine.webkit` sembolü, 14 kutu; lider/seçili iken gök; tooltip "WebKit 26.6 · macOS 26.6") ve kamera (lider iken gök). Lider başlık `surface/header-leader`.
  - **Kenar:** 1 pt `line`; lider 2 pt gök (CARD-01). **Seçili:** dışta 3 pt boşlukla 1,5 pt krem halka, lider çizgisinden bağımsız (CARD-02). Sayfaya ya da başlığa tık seçer; boş canvas'a tık ya da Esc seçimi kaldırır; sekmeye tık seçer ve kaydırır.
  - **Yükleniyor:** başlığın altında 3 pt `line` iz üzerinde kayan krem çizgi, kamera yerine dönen gösterge.
  - **Senkron kaçtı:** kartın altında 30 pt `status/warning-bg` not, "Element bu viewport'ta bulunamadı".
  - **Hover şeridi** (CARD-01): kartın üstünde, sağ kenara hizalı, başlığın 8 pt üstünde; Senkrondan çıkar (`link.slash`) / Senkrona kat (`link`, `ink/primary`) · Döndür (`rectangle.portrait.rotate`) · Kapat; her biri tooltip'li. İmleç karttan şeride geçebilsin diye şerit 250 ms daha kalıyor.
  - **Kamera** (CARD-04): başlığın altından "EKRAN GÖRÜNTÜSÜ · <cihaz>" seçicisi: Görünen alan / Tam sayfa.
  - **Başlık sağ tık** (CARD-05): Döndür ⌥⌘R · Boyutu düzenle… · Senkrondan çıkar / Senkrona kat · — · Motor › (pasif, "WebKit 26.6" işaretli) · — · Kaldır ⌫ (mercan). Önceki sistem menüsündeki "Ekran Görüntüsü" maddeleri kalktı (§4 kararı).
  - **Boyutu düzenle** (CARD-06): sheet yerine başlığın 8 pt altında popover: Ad, Genişlik ⇄ Yükseklik, "200–3840 × 200–4320 px" (sınır dışında alan mercan kenar, ipucu mercan, Kaydet pasif), İptal / Kaydet (sarı); Kaydet'te kart yeni boyuta 200 ms'de geçer.
  - **Senkron aç/kapa** (CARD-07): hover şeridi ve menüden.
  - Canvas'ın üst payı başlık için 144 pt'ye çıktı (şerit + hover şeridi + başlık); sayfa alanının alt köşeleri her zoom'da 12 pt yuvarlak.
- Nerede: `Viewportix/Canvas/CardChrome.swift` (yeni: `CardChromeLayer`, `ViewportCardChrome`, `ViewportHoverStrip`, `SizeEditorPopover`), `ViewportCardView.swift` (yalnız sayfa), `CanvasController.swift` (`publishFrames`, seçim), `Viewportix/Project/Workspace.swift` (`cardFrames`, `hoveredViewportID`), `ProjectWindow.swift`
- Durum: özel çizim (SwiftUI katmanı + AppKit sayfa); menüler sistem `NSMenu`
- Eksik / sapma:
  1. **"Özel Boyut…" ile yeni kart** hâlâ sistem sheet'i (`ViewportSizeSheet`); cihaz seçicinin "Özel boyut" satırı gelince kalkacak.
  2. **Snapshot hali** (Firefox, M6) ve **sayfa yüklenemedi halleri** (ağ, sertifika, localhost, adres; §13) henüz yok.
  3. **Yükleme çizgisi belirsiz** (kayan parça): motor ilerleme yüzdesi vermiyor; tasarımdaki 120 px'lik çubuk ilerlemeyi mi gösteriyor, yoksa animasyon mu?
  4. **Kart sürükleme** (CARD-08, CARD-09) §13'te.
  5. Hover şeridinin karta göre yatay konumu spec'te yok; PNG'den: sağ kenara 4 pt içeride.
- Tasarım kararı gerekir mi: evet — 3 ve 5
- Bağlantılı: DESIGN.md §3.2 (Viewport kartı, CARD-01…07), §4 (kart kararları); `KOD-OTURUMU-ISLERI.md` §8, §12 adım 5

## 2026-10-16 — Cihaz seçici: STRIP-07…11 bitti
- Ne: "+ Cihaz" ve ⌥⌘N (yeni menü maddesi Viewport › Cihaz Ekle…) `DevicePicker` popover'ını açıyor: şeridin 8 pt altında, sağ kenarına hizalı, 660 pt. Arama ("Cihaz ara ya da 1024×768 yaz", açılınca odakta; boyut yazıp ⏎ o boyutta özel cihaz ekler, tek eşleşmede ⏎ onu ekler), motor seçici (WebKit seçili; Chromium ve Firefox soluk "yakında"), SON çipleri (son eklenen 3 cihaz, uygulamaya ait), üç sütun TELEFON / TABLET / MASAÜSTÜ (başlıkta sayı, her sütun 186 pt'lik kendi penceresinde kayar, altı taşarsa solma), satır (tür ikonu, ad, boyut, "+" ya da ekliyse gök tik), alt satırda "Özel boyut" W / H + sarı "Ekle" (sınır dışında alan mercan kenar, Ekle pasif) ve "Cihazları yönet… ↗". Satıra tık cihazı ekler, popover açık kalır, canvas sığdırılır ve yeni kart seçilir; ekli satıra tık o karta kaydırır. Esc ya da dışarı tık kapatır.
- Kalkanlar: "+ Cihaz" sistem menüsü ve "Özel Boyut…" sheet'i (`ViewportSizeSheet`) — yerlerini seçici aldı.
- Nerede: `Viewportix/Project/DevicePicker.swift`, `DeviceStrip.swift`, `ProjectWindow.swift`, `Viewportix/Chrome/OutsideClick.swift`; paket `ProjectModel/DeviceSearch.swift` (`ViewportSize(parsing:)`, arama, son kullanılanlar + testler)
- Durum: özel çizim (SwiftUI)
- Eksik / sapma:
  1. **Katalog tasarımdakinden kısa:** uygulamada 4 telefon, 3 tablet, 3 masaüstü var; çizimde Pixel 9, Galaxy S25, Galaxy Tab S10, MacBook Air, 4K gibi 19 cihaz. Kataloğa eklenecek liste tasarımdan mı gelsin? (Android cihazlar WebKit'te açılır; "gerçek cihaz" değil.)
  2. **"Cihazları yönet…"** soluk ve pasif: Ayarlar › Cihazlar §12 adım 7 ile.
  3. Satır hover zemini spec'te yok; `surface/card` kullanıldı.
- Tasarım kararı gerekir mi: evet — 1 ve 3
- Bağlantılı: DESIGN.md §3.2 (Cihaz seçici, STRIP-07…11), §4 (cihaz seçici kararı); `KOD-OTURUMU-ISLERI.md` §12 adım 6

## 2026-10-16 — Ayarlar paneli: RAIL-01 (Ayarlar, Cihazlar, Hesap), HOME-17, SETTINGS-01, 03, 04 bitti; medya duraklatma varsayılan açık
- Ne: `SettingsPanel` (340 pt, `surface/header`, köşe 12, gölgeli): proje penceresinde canvas'ın üstüne sağdan kayıyor (kenarlardan 16, canvas yerinden oynamıyor); giriş ekranında üst satırın altından, arkası hafif kararıyor, ⚙ basılı kalıyor. Ray öğesi / ⌘, açar; aynı öğe, ✕ ya da Esc kapatır. Başlık "Ayarlar", sekme çipleri (Genel · Cihazlar · Hesap; MCP sekmesi M7'ye kadar gizli), arama.
  - **Genel:** GÖRÜNÜM › Dil (Türkçe); PROJE › Varsayılan şablon (giriş ekranındaki çip seçimiyle aynı ayar), Senkron açık başlasın, Taslakları sakla (pasif), Arka plandaki viewport'larda medyayı duraklat; EKRAN GÖRÜNTÜSÜ › Klasör (seçim kutusu: geçerli klasör · Başka bir klasör… · Finder'da göster), Panoya da kopyala (kapalıyken kapsül "Kaydedildi"), Ölçek 1× / 2× (1× görüntüyü CSS pikseline küçültür); BU PROJE (yalnız proje penceresinde) › Cihazlar (n) › Cihazlar sekmesi, Motor (WebKit 26.6; Chromium ve Firefox "yakında", pasif). Arama satırları ve bölümleri süzer. Hepsi anında uygulanır.
  - **Cihazlar:** "n cihaz · m özel", "İçe aktar…" (pasif), sarı "+ Cihaz" (satır içi form: Ad, G × Y, sınır ipucu, İptal / Kaydet), tür süzgeci Tümü · Telefon · Tablet · Masaüstü · Özel, iki satırlı liste (tür ikonu, ad + "özel" rozeti, "393×852 · Telefon"), hover'da ⋯ (Düzenle — yalnız özel · Çoğalt · Sil — yalnız özel, mercan), "Seçicide" anahtarı (kapalıyken cihaz seçicide görünmez). Alt not çizimdeki metin. Özel cihazlar ve gizlenenler uygulamaya kaydediliyor; cihaz seçici bu listeyi kullanıyor.
  - **Hesap:** hesap sistemi yok, yalnız bu Mac'te doğru olanlar: baş harfli avatar, kullanıcının adı, "Bu Mac'teki kullanıcı", Çıkış yap (pasif); TAKIM "Yakında", LİSANS Plan "Dahili", GÜNCELLEME sürüm + Denetle (pasif), Otomatik güncelle (pasif, açık).
  - **Denetimler:** sarı / `surface/pill` anahtar (30×18), seçim kutusu (değer + chevron, sistem menüsü açar), küçük segment.
  - **Varsayılan değişikliği:** "Arka plandaki medyayı duraklat" artık ilk açılışta açık (`KOD-OTURUMU-ISLERI.md` §10); Görünüm menüsü maddesi ve panel aynı değeri gösteriyor.
  - Açılır yüzeylerin gölgesi artık yalnız zeminden düşüyor (önce yarı saydam öğelerin arkasında koyu leke bırakıyordu).
- Nerede: `Viewportix/Settings/` (`SettingsPanel.swift`, `SettingsControls.swift`, `AppSettings.swift`), `Viewportix/Project/InspectorRail.swift`, `ProjectWindow.swift`, `DevicePicker.swift`, `Viewportix/Home/HomeView.swift`, `Viewportix/App/ViewportixApp.swift`; paket `DeviceCatalog/DeviceLibrary.swift`, `Capture/ScreenshotComposer.scaled` (+ testler)
- Durum: özel çizim (SwiftUI); seçim kutularının menüsü sistem `NSMenu`
- Eksik / sapma:
  1. **Hesap sekmesi** çizimdeki e-posta, takım adı ve kişi sayısını gösteremiyor (hesap yok); Çıkış yap, Denetle, Otomatik güncelle pasif.
  2. **Cihaz satırında piksel yoğunluğu** ("2×", "3×") yok: katalogda yoğunluk bilgisi tutulmuyor.
  3. **Özel cihazın türü** genişlikten çıkarılıyor (< 600 telefon, < 1100 tablet, üstü masaüstü); formda tür seçimi yok.
  4. **Taslakları sakla** pasif: taslak saklama yok.
  5. Panel köşesi PNG'de 12'den büyük görünüyor (16?); `radius/card` 12 kullanıldı.
- Tasarım kararı gerekir mi: evet — 1, 2, 3 ve 5
- Bağlantılı: DESIGN.md §3.3 (RAIL-01, SETTINGS-01…05), §3.1 (HOME-17), §4 (medya duraklatma); `KOD-OTURUMU-ISLERI.md` §10, §11, §12 adım 7

## 2026-10-16 — Sayfa yüklenemedi: CARD-10, CARD-11, CARD-12, PW-04 bitti
- Ne: Motor artık ana çerçevenin yüklenemediğini bildiriyor; kart sayfanın yerinde hata gösteriyor, başlıkta ve sekmede mercan üçgen (senkron kaçtı ile aynı). Dört hal `card-load-errors@2x.png`'deki metinlerle:
  - **Ağ:** `wifi.slash`, "Sayfa açılamadı", "İnternet bağlantısı yok ya da sunucu yanıt vermiyor.", mono "NSURLError -1009", sarı "Yeniden dene" (yalnız o viewport; ⌘R hepsi).
  - **Sertifika:** mercan `exclamationmark.shield`, "Bağlantı güvenli değil", "<host> sertifikası doğrulanamadı.", "SSL · süresi dolmuş" (güvenilmeyen / bilinmeyen kök / henüz geçerli değil), "Geri dön" · "Bu oturumda güven" (yalnız o ana makine, uygulama kapanana kadar; o ana makinede hata veren viewport'lar yeniden yüklenir).
  - **localhost kapalı:** `server.rack`, "localhost:3000 yanıt vermiyor", "Geliştirme sunucun çalışıyor mu?", "ECONNREFUSED", sarı "Şimdi dene" + "2 sn'de bir deneniyor…" (2 sn'de bir kendiliğinden yeniden dener; sunucu açılınca hata kalkar). localhost, 127.0.0.1, *.local ve IP adresleri geliştirme sunucusu sayılıyor.
  - **Adres bulunamadı:** `link.slash`, "Adres bulunamadı", "“marka.comm” adında bir site yok.", "DNS · NXDOMAIN", "Adresi düzenle" (adres alanına odaklanır, ⌘L).
  - Hepsi hatadaysa (2+ viewport) mercan kenarlı kapsül "Sayfa n viewport'ta açılamadı · Hepsini dene".
  - Sitenin kendi 404/500 sayfası hata sayılmıyor, olduğu gibi görünüyor; iptal edilen ve yarıda kesilen yüklemeler de gösterilmiyor.
- Nerede: `Viewportix/Canvas/CardChrome.swift` (`LoadFailureView`), `Viewportix/Project/Workspace.swift`, `DeviceStrip.swift`; paket `EngineCore/LoadFailure.swift`, `WebKitEngine/WebKitSession.swift` (hata bildirimi, sertifika güveni) + testler (sınıflandırma; gerçek WKWebView ile kapalı localhost ve bilinmeyen alan adı)
- Durum: özel çizim (SwiftUI)
- Eksik / sapma:
  1. **"Geri dön"** viewport'un kendi geçmişinde geri gider; ilk yüklemede geri gidecek sayfa yoksa bir şey olmaz. Bu durumda düğme gizlensin mi?
  2. İkincil düğmeler (Geri dön, Bu oturumda güven, Adresi düzenle) için bileşen yok; PNG'den: `surface/header` zemin + `line` kenar, 12 pt.
  3. Ağ hatası dışındaki tanınmayan hatalar (ör. WebKit'in kendi kodları) ağ hatası görünümüyle, kendi koduyla gösteriliyor.
- Tasarım kararı gerekir mi: evet — 1 ve 2
- Bağlantılı: DESIGN.md §3.2 (CARD-10…12, PW-04), §4 (Sayfa yüklenemedi halleri); `KOD-OTURUMU-ISLERI.md` §13

## 2026-10-16 — Kartı sürükleme ve Kartları Diz: CARD-08, CARD-09, PW-01 bitti (eşit aralık rozetleri hariç)
- Ne: Kart başlığından tutup sürükleyince kart kalkıyor (2 pt gök kenar + #000000AA gölge, y 18, blur 40), hover şeridi gizleniyor, imleç kapalı el; başka kartların kenar ve merkezlerine 6 ekran pikselinden yakınsa yapışıyor ve 1 pt gök hizalama çizgisi çiziliyor; ⌥ basılıyken yapışma ve çizgiler kapalı. Bırakınca tüm kartların konumu projeye yazılıyor (yeniden açınca aynı yerde). Sürüklenen kart seçili oluyor. Yeni eklenen cihazlar konumlu kartların sağına diziliyor. Viewport › Kartları Diz (kısayolsuz) otomatik tek sıraya 250 ms'de döndürüyor.
- Nerede: `Viewportix/Canvas/CardChrome.swift` (başlık sürükleme, hizalama çizgileri), `CanvasController.swift` (`beginDrag` / `dragCard` / `endDrag`, konumlu yerleşim), `Viewportix/Project/ProjectWindow.swift`, `Viewportix/App/ViewportixApp.swift`; paket `ProjectModel/CanvasLayout.swift` (`CanvasPoint`, yerleşim, yapışma), `ViewportConfig.position` (eski dosyalarda yok sayılır) + testler
- Durum: özel çizim
- Eksik / sapma:
  1. **Eşit aralık rozetleri** (iki kart arasındaki boşluk diğerine eşitken gök rozet + px) yok; yalnız kenar/merkez hizalaması var.
  2. Kartlar canvas'ın sol/üst sınırının (0) ötesine sürüklenemiyor.
  3. Elle test gerekiyor (sürükleme etkileşimi ekran dışı çizimle doğrulanamıyor).
- Tasarım kararı gerekir mi: hayır (1 tasarımda var, kodda eksik)
- Bağlantılı: DESIGN.md §3.2 (CARD-08, CARD-09, PW-01), §4 (Kartı elle sürükleme); `KOD-OTURUMU-ISLERI.md` §13

## 2026-10-16 — Gruplama: PW-02, PW-03, STRIP-12 bitti; grup menüsü (§5.20 i)
- Ne: Görünüm › Grupla › Yok / Cihaz Türü / Motor (projeye kaydedilir). Gruplu canvas'ta gruplar yan yana, her grup kendi tek sırasında; grup alanı kartların altında (`surface/group` zemin, `line` kenar, köşe 16 — her zoom'da ekranda aynı), üst solunda "⌄ TELEFON 2" başlığı (oka tık katlar/açar). Katlı grup üst hizada "› TELEFON 2" çipine iniyor, kartları gizleniyor, sağdakiler sola kayıyor. Başlıkta hover'da ⋯ (sağ tık da açar): Katla / Aç · Grubu sığdır · — · Gruptakileri kapat (mercan). Şeritte gruplar arasında ince ayırıcı (1×18, `ink/secondary` %45); katlı grup tek çip "Telefon 2 ›" (grubun en ciddi durumu: üçgen) — tıklayınca grup açılır ve canvas gruba sığdırılır. Gruplu iken kartlar elle sürüklenmiyor (yerleşim otomatik).
- Nerede: `Viewportix/Canvas/CanvasController.swift` (gruplu yerleşim, `GroupAreaView`, `fitGroup`), `CardChrome.swift` (`GroupHeader`), `Viewportix/Project/DeviceStrip.swift` (ayırıcı, `FoldedGroupChip`), `ProjectWindow.swift`, `Viewportix/App/ViewportixApp.swift`; paket `ProjectModel/Grouping.swift` (`Grouping`, gruplar, gruplu yerleşim), `CanvasState.grouping/collapsedGroups` (eski dosyalarda yok sayılır) + testler
- Durum: özel çizim; grup menüsü sistem `NSMenu`
- Eksik / sapma:
  1. **Gruplu iken elle konum** yok sayılıyor ve sürükleme kapalı (tasarım "Kartları Diz gruplar açıksa grup içinde" diyor; grup içinde elle yerleşim tanımlı değil).
  2. **Motor grubunda başlıkta motor glifi** ve sekme adında "· Chromium" (M4) henüz yok; tek motor (WebKit) olduğu için motor gruplaması tek grup.
  3. Çok küçük zoom'larda (< %20) grup alanlarının ekran payı gruplar arası boşluğu aşıp üst üste binebilir.
- Tasarım kararı gerekir mi: evet — 1
- Bağlantılı: DESIGN.md §3.2 (PW-02, PW-03, STRIP-12), §4 (Gruplama, katlanmış grup), §5.20 i; `KOD-OTURUMU-ISLERI.md` §13

## 2026-10-16 — Tam ekranda sidebar üst satırı, pencereye bağlantı bırakma (§5.20 b, g)
- Ne: Tam ekranda (trafik ışıkları yok) sidebar'ın 48 pt'lik üst satırı 16 pt'ye iniyor. Canvas'a bir bağlantı sürüklenince 2 pt gök iç kenar ve ortada gök kenarlı kapsül "Bu adresi aç · marka.com/kampanya"; bırakınca adres tüm viewport'larda açılıyor (sayfa listesine eklenmiyor, ⌘D ekler). `.viewportix` dosyası bırakılırsa proje açılıyor.
- Nerede: `Viewportix/Chrome/TrafficLights.swift` (`onFullScreenChange`), `Viewportix/Project/SidebarHeader.swift`, `ProjectWindow.swift` (`LinkDropDelegate`), `Workspace.swift`
- Durum: özel çizim
- Eksik / sapma: kapsülün çizimdeki ölçüleri spec'te yok (bileşen değil); bildirim kapsülüyle aynı ölçüler + gök kenar kullanıldı. Elle test gerekiyor.
- Tasarım kararı gerekir mi: hayır
- Bağlantılı: DESIGN.md §5.20 b, g; `KOD-OTURUMU-ISLERI.md` §13 "Küçük ayrıntılar"

## 2026-10-16 — parite: Proje penceresi (ikinci tur)
- Ne: Proje penceresinin halleri dışa aktarımlarla aynı adla `docs/parity/`'de (@2x, sRGB, `Scripts/snapshots.sh`): `window-project-dark`, `-sidebar-collapsed`, `-rail-hidden`, `-device-picker`, `-settings-panel`, `-settings-devices`, `-settings-account`, `-many-devices`, `-groups`, `-groups-collapsed`, `card-load-errors`, `toast-states`. Giriş ekranı görüntüleri de güncellendi (⚙ artık etkin).
- Bilinen farklar:
  1. **Sayfa içeriği boş:** ekran dışı pencerede WKWebView çizilmiyor ve yükleme bitmiyor; kartlar koyu ve başlıkta yükleniyor göstergesi var. Kartların sayfa alanı için uygulamanın kendisine bakılmalı.
  2. Trafik ışıkları görüntüde yok (kenarsız ekran dışı pencere).
  3. Örnek proje tasarımdaki cihazlarla değil katalogdaki adlarla ("iPad Air 11"", "Masaüstü"); sayfa `sample-product.html` fixture'ı.
  4. Kart sürükleme, hover şeridi, tooltip'ler, menüler ve bağlantı bırakma etkileşim gerektirdiği için görüntülerde yok.
- Durum: özel çizim
- Tasarım kararı gerekir mi: evet — karşılaştırma ve farklar `design/handoff/PARITY.md`'ye
- Bağlantılı: `design/handoff/PLAN.md` aşama 8

## 2026-10-16 — Canlı test düzeltmeleri (1. tur)
- Ne: Uygulama canlıda sürülerek (gerçek pencere, `orca computer` + fare olayları) bulunan hatalar düzeltildi:
  1. **Tooltip'ler, kart hover şeridi ve adres SON menüsü yanlış yerdeydi:** hedefin 8 pt dışında olacakken üstüne biniyordu (SwiftUI bindirmelerinde `alignmentGuide` uygulanmıyor). Hepsi kenara sıfır kalınlıkta çapa ile konumlanıyor; tooltip gösterilirken kardeşlerinin önüne alınıyor (alt çubukta zoom kontrolünün arkasında kalıyordu).
  2. **SON menüsünün üstüne gezinme düğmeleri çiziliyordu;** menü artık önde.
  3. **Yönlendirme yapan adreste** (apple.com/tr → www.apple.com/tr/) açık sayfa listede yokmuş gibi "Bu sayfayı ekle" çıkıyordu; SON listesinde aynı sayfa üç kez görünüyordu. http/https, "www." ve sondaki "/" artık aynı sayfa sayılıyor; eski tekrarlı geçmiş açılışta birleştiriliyor.
  4. **Sistem menüleri İngilizceydi** (File, Edit, View…); uygulamanın dili Türkçe bildirildi: Dosya, Düzen, Görüntü, Pencere, Yardım; "Tam Ekrana Geç", "Adsız" belge vb. Not: sistem "View" menüsünü "Görüntü" diye çeviriyor (DESIGN.md §3.2.1 "Görünüm" diyor).
  5. **Pencere sekme maddeleri** ("Show Tab Bar / Show All Tabs") kaldırıldı.
  6. **Zoom menüsünde "Yakınlaştır" kısayolu** Türkçe klavyede "⌘ :" görünüyordu; Görünüm menüsüyle aynı tuşa alındı.
  7. **Sınır ipucu "200–3.840 × 200–4.320 px"** binlik ayırıcıyla yazılıyordu; düzeltildi.
  8. **Üst üste binen kartlarda** sürüklenen kartın sayfası öne geçiyor ama başlık/kenar katmanı geride kalıyordu; son sürüklenen kart her iki katmanda önde.
  9. **Giriş ekranında trafik ışıkları** sistem varsayılanındaydı (üstten ~16); proje penceresiyle aynı hizaya (24) alındı.
  10. **Çok küçük zoom'da** (%15) telefon kartlarının başlığında ad tamamen kayboluyor, yalnız motor ve kamera kalıyordu. Darlık sırası: önce boyut, sonra ad ortadan kısalır (tasarım kuralı); ad 56 pt'nin altına inince motor glifi, 40 pt'nin altına inince kamera çekiliyor, ad kalıyor.
- Doğrulanan (canlı): zoom menüsü (BAR-03), Sığdır tooltip'i (BAR-01), cihaz seçici (STRIP-07), kart sağ tık menüsü (CARD-05), Boyutu düzenle (CARD-06), Döndür, Kapat + "Geri al" kapsülü ve ⌘Z, hover şeridi (CARD-01), lider ve seçili halleri, kart sürükleme ve konumun kalması (CARD-08), Grupla › Cihaz Türü (PW-02), sidebar gizleme ve kapsüldeki trafik ışıkları (SIDEBAR-06), Ayarlar paneli (RAIL-01), geçersiz adres (HOME-01), şablonla proje açma (HOME-02).
- Nerede: `Viewportix/Chrome/ChromeTooltip.swift` (`outside(_:alignment:gap:)`), `Viewportix/Canvas/CardChrome.swift`, `CanvasController.swift`, `Viewportix/Project/SidebarHeader.swift`, `ProjectSidebar.swift`, `ProjectWindow.swift`, `URLHistoryStore.swift`, `Viewportix/Chrome/BottomBar.swift`, `Viewportix/Home/HomeView.swift`, `Viewportix/App/ViewportixApp.swift`, `project.yml` (`developmentLanguage: tr`); paket `URLHistory` (`isSamePage`) + test
- Durum: özel çizim
- Tasarım kararı gerekir mi: evet — 10 ("motor ve kamera asla gizlenmez" kuralının çok küçük zoom'da esnetilmesi) ve 4 (Görünüm / Görüntü)
- Açık kalan (düşük öncelik): açılır yüzeylerin (cihaz seçici) zemini altındaki web sayfasını ~%1 geçiriyor (piksel ölçümünde 1–3 birim); çıplak gözle zor seçiliyor.
- Bağlantılı: DESIGN.md §3.2, §3.2.1, §5.20 d

## 2026-10-16 — Canlı test düzeltmeleri (2. tur)
- Ne: Uygulama canlıda yerel test sayfalarıyla (`Tests/Fixtures`, 8 cihaz) sürülerek bulunanlar:
  1. **Sayfa yüklenemedi kartı çok küçük zoom'da taşıyordu** (%15'te 56 pt'lik telefon kartında metin harf harf kırılıp şeridin ve başlığın üstüne çıkıyordu): dar kartlarda önce kısa hal (ikon + başlık + ↻), sonra yalnız ikon + ↻, en dar halde yalnız ikon; içerik kartın dışına taşmıyor (CARD-10…12).
  2. **⌘L'den hemen sonra yazılan adres eziliyordu:** sayfanın yüklenmesi bitince adres alanı yarım yazılmış metnin üstüne sayfanın adresini yazıyordu ("…htmlrm.html"). Alan odaktayken sayfa olayları adresi değiştirmiyor (SIDEBAR-01).
  3. **Kart başlıkları, kenarlar ve seçim halkası yüksek zoom'da kayıyordu:** pencereden büyük bir kart varken (%118, ⌘2 sonrası) tüm başlık katmanı sola-yukarı kayıyor, başlık kartın üstünde görünmüyordu (CARD-01…03).
  4. **Trafik ışıkları yerinden oynuyordu:** adres yazıp sayfa değişince ışıklar sistem konumuna (sol üst 16 pt) dönüyordu; AppKit başlık çubuğunu bildirimsiz yeniden yerleştiriyor. Artık her yer değişiminde geri konuyor (§6 Sidebar/Header).
  5. **Cihaz şeridinde "+ Cihaz" öncesi boşluk:** ilk yüklemede sekmelerdeki yükleniyor göstergeleri kalkınca şerit eski genişlikte kalıyordu; şerit artık sekmelere oturuyor (STRIP-01).
  6. **Sidebar ayırıcı çizgisi canvas'ın 3 pt içindeydi;** arada sayfa içeriği görünüyordu (genişlik tutamacı kenara ortalanırken çizgiyi de kaydırıyordu). Çizgi sidebar'ın kendi kenarında; tutamacın gök çizgisi kenara ortalı (SIDEBAR-07).
  7. **Sayfa satırı ipucu pencerenin solundan taşıyordu** ve sağ tık menüsü açıkken altında kalıyordu. Satır ipuçları satırın sol kenarına hizalı; bütün ipuçları pencere kenarına 8 pt kala içeri kayıyor; sağ tık, tuş veya kaydırma ipucunu kapatıyor (SIDEBAR-02, BAR-01).
  8. **Viewport menüsü eksikti** (DESIGN.md §3.2.1): Döndür ⌥⌘R, Boyutu Düzenle…, Senkrondan Çıkar / Senkrona Kat, Kaldır, Sonraki Viewport ⌃⇥, Önceki Viewport ⌃⇧⇥ eklendi; Görünüm'e Seçimi Sığdır ⌘2. Hepsi seçili kartta çalışır (seçim yoksa pasif). Hover şeridindeki "Kapat ⌫" artık gerçekten çalışıyor.
  9. Erişilebilirlik: sekme kapatma etiketi "Masaüstü'ı kapat" yerine "Masaüstü sekmesini kapat".
- Bilinçli sapmalar: **Kaldır ⌫** ve **Seçimi Kaldır Esc** menüde kısayolsuz; tuşları canvas, odak sayfada ya da bir metin alanında değilken işliyor (menü kısayolu olsalar web formlarında ve adres alanında ⌫/Esc'i alırlardı). Esc adres alanındayken artık seçimi değil adresi geri alıyor.
- Doğrulanan (canlı): senkron tık / yazı / onay kutusu (8 kartta aynı), Senkron kapalı ⇧⌘L (BAR-02: yalnız lider değişiyor), ekran görüntüsü seçici + "Kaydedildi ve kopyalandı · Finder'da Göster" kapsülü (BAR-06; 16000 px'lik birleşik görüntü), ⌘D sayfa ekleme (SIDEBAR-05), sayfa sağ tık menüsü ve yeniden adlandırma (SIDEBAR-03), şerit taşması "+4" ve menüden karta gitme (STRIP-03…05), tam ekran 16 pt üst satır ve çıkışta ışıkların yeri (§5.20 b), ⌃⇥ / ⌥⌘R / ⌘2 / ⌫ / ⌘Z.
- Nerede: `Viewportix/Canvas/CardChrome.swift`, `CanvasController.swift`, `Viewportix/Chrome/TrafficLights.swift`, `ChromeTooltip.swift`, `Viewportix/Project/DeviceStrip.swift`, `ProjectSidebar.swift`, `SidebarHeader.swift`, `Workspace.swift`, `ProjectWindow.swift`, `Viewportix/App/ViewportixApp.swift`
- Durum: özel çizim
- Tasarım kararı gerekir mi: evet —
  - Adlandırma: menü "Sidebar'ı Gizle" (§3.2.1), kapsül düğmesi "Kenar çubuğunu göster" (§5.20 tooltip tablosu); biri seçilmeli.
  - Pencere boyutu değişince canvas yeniden sığdırılmıyor (zoom kalıyor, kartlar sağdan kesilebiliyor); Figma gibi bırakmak mı, kullanıcı zoom'a dokunmadıysa yeniden sığdırmak mı?
  - Sekiz cihazda tek sıra (§3.2) %15 zoom'a iniyor ve pencerenin altı boş kalıyor; çok cihazda satıra sarmak istenir mi?
- Bağlantılı: DESIGN.md §3.2, §3.2.1, §5.20

## 2026-10-16 — Canlı test düzeltmeleri (3. tur)
- Ne:
  1. **Canvas yeniden sığdırma (yapışkan ⌘1):** son işlem Sığdır (ya da açılıştaki otomatik sığdırma) ise ve sonra zoom/kaydırma yapılmadıysa, canvas'ın boyutu değişince (pencere, sidebar ⌃⌘S, ray ⌥⌘0) kartlar yeniden sığdırılıyor. Elle zoom ya da kaydırma yapıldıysa zoom korunuyor. Önce: sidebar kapanınca kartlar sol köşede kalıyor, pencere daralınca sağdan kesiliyordu (BAR-03, SIDEBAR-06). 2. turdaki "pencere boyutu değişince yeniden sığdırılmıyor" sorusunun yerine geçer; davranış beğenilmezse geri alınır.
  2. **Sidebar kapalıyken cihaz şeridi erken taşıyordu** ("+6", sağda yer varken): şerit sol kapsülden kaçmak için iki yandan da 428 pt bırakıyordu. Şimdi sığdıkça canvas'a ortalı; sığmazsa kapsülün sağına kayarak genişliyor (STRIP-03, SIDEBAR-06).
  3. **Ayarlar paneli erişilebilirliği:** anahtarların (Senkron açık başlasın, Taslakları sakla, medya duraklatma, Panoya da kopyala, Otomatik güncelle) ve seçicilerin (Dil, Varsayılan şablon, Klasör, Motor) VoiceOver adı yoktu; satır adları verildi (SETTINGS-01).
- Doğrulanan (canlı): cihaz seçici aramaya "1024x768" + ⏎ ile özel cihaz ekleme, seçici açık kalıyor (STRIP-08); Esc ile kapanma; Ayarlar paneli (RAIL-01); tam ekrandan çıkışta trafik ışıkları.
- Nerede: `Viewportix/Canvas/CanvasController.swift` (`fitted`, `isStill(at:)`), `Viewportix/Project/ProjectWindow.swift` (`stripLeadingRoom`), `Viewportix/Settings/SettingsPanel.swift`
- Durum: özel çizim
- Tasarım kararı gerekir mi: evet —
  - Yapışkan sığdırma davranışı (yukarıda 1).
  - Özel boyutla eklenen cihazlar hep "Özel" adını alıyor; iki özel cihaz şeritte ayırt edilemiyor (boyut yalnız tooltip'te). "Özel 1024×768" gibi bir ad mı?
  - Kaydetme penceresinde yeni projenin önerilen adı "Adsız"; sitenin alan adı (ör. "localhost") ya da sayfa başlığı önerilsin mi?
- Bağlantılı: DESIGN.md §3.2, §3.3, §5.20

## 2026-10-16 — Menüler tasarımdaki gibi (sistem menüsü yerine kendi çizimimiz)
- Ne: Kullanıcı isteği: "sağ tık ve basınca çıkan menüler canvas'taki tasarım neyse öyle olsun". Bütün menüler sistem `NSMenu`'süydü (Liquid Glass, saydam, sistem satır ölçüleri). Hepsi tasarımdaki çerçevelerden okunan ölçülerle kendi çizimimiz oldu (`ChromeMenu`): opak `surface/header`, 12 pt köşe, `line` kenar, gölge `#00000066` 0/8/24; satırlar 8 pt köşe, üzerine gelince `surface/header-leader`; kısayollar sağda `ink/secondary` metin; Kaldır `status/warning`.
  - Sayfa sağ tık menüsü (`Context Menu` xvKcu, `.list`: 13 pt, 5/10 dolgu, aralıklı ayraç; "Çift tık" ipucu).
  - Kart sağ tık menüsü (`Card Context Menu` D4fduK, 240): ikonlar kalktı; "Motor · WebKit 26.6 ›" seçilmeyen bilgi satırı.
  - Giriş ekranı bağlam menüsü (`Context Menu` pJ3Y2, 220, 14 pt ikonlar) ve Kaldır alt menüsü (`Remove Submenu` srq56, 260, iki satırlı seçenekler): alt menü tasarımdaki gibi ana menünün **solunda**, 4 pt boşlukla, son satırı tetikleyen satırla aynı hizada; solda yer yoksa sağda.
  - Zoom menüsü (`Zoom Menu` CzmyR, 240): işaret sütunu, geçerli kademede ✓; "Seçimi sığdır ⌘2" artık çalışıyor (seçim yoksa pasif). Zoom kontrolüyle sola hizalı, çubuğun 8 pt üstünde.
  - Ekran görüntüsü seçicisi (`Screenshot Chooser` OBkUO, 300): başlık, açıklamalı iki seçenek + kısayollar, altta ayar özeti satırı (tıklanınca Ayarlar › Genel). Kameranın sağ kenarıyla hizalı, çubuğun 8 pt üstünde.
  - Kart kamerası seçicisi (`Card Screenshot Chooser` BG9Q3, 250): karta ortalı, başlığın 6 pt altında.
  - Grup menüsü (`Menu` vcc5P, 200), Ayarlar seçicileri (Dil, Şablon, Klasör, Motor; tetikleyici genişliğinde, ✓) ve Ayarlar › Cihazlar satır menüsü aynı bileşenle.
  - Klavye: ↑↓ (pasif satırları atlar), ⏎/boşluk seçer, → alt menüyü açar, ← kapatır, Esc kapatır; başka bir tuş menüyü kapatıp yoluna devam eder. Dışarı tık menüyü kapatır (sol tık tüketilir, sağ tık yeni menüyü açar). Seçicilerde ilk seçenek açılışta vurgulu (çizimlerdeki gibi).
- Boyutu düzenle popover'ı da çizime göre yeniden ölçülendi (`Size Popover` emiiU): 10 pt etiketler, 6 pt köşeli kutular, 12 pt yazı, sayılar mono, G/Y alanları 90 pt, ⇄ `surface/card` kutuda, sınır ipucu mono 10 pt, "İptal" düz metin; kartın 20 pt içinden, başlığın 8 pt altından açılıyor. Açıkken diğer kartların kenar çizgileri artık üstünden geçmiyor (canlıda bulundu).
- Kanıt: `docs/parity/menus@2x.png` (yan yana sekiz menü). Ölçü karşılaştırması (pt, kod / tasarım): sayfa 220×182 / 220×184, kart 240×170 / 240×171, giriş 220×201 / 220×202, zoom 240×293 / 240×295, grup 200×104 / 200×106, ekran görüntüsü seçicisi 300×157 / 300×169 (fark yazı satır yüksekliklerinden). Canlıda: sayfa, kart, giriş + alt menü, zoom, iki seçici, Ayarlar Klasör seçicisi açıldı; üzerine gelme, tıklama, klavye ve alt menüye geçiş denendi.
- Nerede: `Viewportix/Chrome/ChromeMenu.swift` (model, çizim, `ChromeMenuPresenter`), `MenuAnchor.swift`, `ContextMenuArea.swift`, `BottomBar.swift`, `Viewportix/Canvas/CardChrome.swift`, `Viewportix/Project/ProjectSidebar.swift`, `Viewportix/Home/HomeView.swift`, `ProjectCard.swift`, `Viewportix/Settings/SettingsControls.swift`, `SettingsPanel.swift`
- Durum: özel çizim
- Tasarım kararı gerekir mi: evet —
  - Alt menünün açıldığı taraf: çizimde solda; macOS'ta alt menüler sağa açılır. Çizime uyuldu; → tuşu yine alt menüyü açıyor.
  - Ayarlar seçicilerinin ve Ayarlar › Cihazlar satır menüsünün çizimi yok; zoom menüsünün (✓ sütunu) ve standart menünün ölçüleri kullanıldı.
  - Giriş ekranı kartındaki ⋯ hâlâ yalnız görüntü (tıklayınca kart açılıyor); menüyü ⋯'dan da açalım mı?
- Bağlantılı: DESIGN.md §3.1 (HOME-06), §3.2 (BAR-03, BAR-06, CARD-04/05/06), §4 (Liquid Glass yok)

## 2026-10-19 — Eylem düğmeleri, AI glifi, hareket değerleri, bizim sayfa (§15 a)
- Ne:
  1. **`ActionButton(.primary / .secondary)`** (`Action/Primary` w0utu, `Action/Secondary` YHwr8 ölçüleri pen'den): 24 pt, `radius/badge`, caption (ana 600, ikincil normal), boşluk 4, iç boşluk 8 / 5 (çipsizde 8 / 8); çip micro normal, 4 pt köşe, 1/3 dolgu, sarıda `accent/ink` %12, grilerde `surface/header` + `ink/secondary`. Üzerinde: ikincil `line/strong`, ana sarı beyaza %6 (sarının parlaklığı zaten %100, "+%6 parlaklık" uygulanamıyor). Basılı (yalnız fare): %97 + ikincil `surface/header` / ana parlaklık −%12 + 1 pt iç gölge, 80 / 120 ms tek eğri; klavyeyle (kısayol, boşluk) basma görünmez. Odak 2 pt `ink/primary`. Pasif `surface/group` + `ink/secondary`.
  2. **`AIActivityGlyph`** (`AI/Glyph` zwcbc): 12 × 12, çubuklar 2×9 · 3×7 · 5×5, 1 pt aralık, 0,6 köşe, alta hizalı. Çalışırken her çubuk kendi adımında yanar ve 1 → .6 → .4 → .25 söner (Motion Spec 1. bölüm kareleri), 120 ms adım, 720 ms döngü; satırlar arası faz kaydırma parametresi. Onay bekliyor `ink/secondary` %60 durgun; bitti `ink/primary`; Hareketi azalt durgun %60. Mercan nokta glifin değil, yanındaki başlığın parçası olarak bırakıldı.
  3. **`Motion`** (paket `DesignSystem`): tek eğri `timingCurve(0.23, 1, 0.32, 1)` ve Motion Spec tablosundaki bütün değerler tek yerde; Hareketi azalt için 150 ms solma. Eski `DesignTokens.Motion` süreleri (hover, panel…) yerinde kaldı; token gerekmedi.
  4. **Bizim sayfa (`chromeSheet`)**: pencerenin üstünden iner (240 ms tek eğri; kalkış 160 ms; Hareketi azalt 150 ms solma), 360 (kaydet 420) genişlik, `surface/card`, `radius/card`, 20 iç boşluk, `line` kenar, gölge 0 12 32 %50, arka plan `canvas` %60. Klavye sayfada kalır (sayfa ayrı bir anahtar alt pencere), kapanınca pencere ve önceki odak geri gelir; VoiceOver rolü sheet. İlk kullanımı PW-06.
- Kanıt: `docs/parity/action-buttons@2x.png` (beş hal × iki tür + glifin üç hali). Paket testleri 80/80.
- Nerede: `Viewportix/Chrome/ActionButton.swift`, `AIActivityGlyph.swift`, `ChromeSheet.swift`, `Packages/ViewportixKit/Sources/DesignSystem/Motion.swift`
- Durum: özel çizim
- Tasarım kararı gerekir mi: evet —
  - Pencerelerimizde başlık çubuğu yok; "sayfa pencerenin başlığından iner" için çizimdeki 36 pt başlık alanı kullanıldı: sayfa üstten 36 pt aşağıda başlıyor, üstteki 36 pt karartılmıyor ama tıklanmıyor. Sayfa pencerenin üst kenarından mı insin, karartma tüm pencereyi mi kaplasın?
  - Ana düğmenin "üzerinde +%6" hali sarıda görünmüyordu; beyaza %6 karıştırıldı. Uygun mu?
  - İkincil düğme basılıyken çip zemini (`surface/header`) düğme zeminiyle aynı oluyor, çip kayboluyor.
- Bağlantılı: DESIGN.md §4 (K4 f, K5, K7, K8), §6 (`Action/Primary`, `Action/Secondary`, `AI/Glyph`); `design/KOD-OTURUMU-ISLERI.md` §15 a

## 2026-10-19 — Taslaklar, kaydet sayfası (PW-06), taslağı sil (HOME-08), hata kodu (HOME-13), diskte değişti (PW-07), kaydedilemedi (PW-09)
- Ne:
  1. **Taslak saklama:** yeni proje (Yeni ⌘N, URL kutusu, şablon) hemen `~/Library/Application Support/Viewportix/Drafts/Untitled N.viewportix` olarak açılıyor ve otomatik kaydediliyor; kapatırken soru yok. Giriş ekranında "Taslaklar" bölümü dolu; "Son"da taslaklar "Taslak" rozetiyle. Ayarlar › Genel › "Taslakları sakla" artık çalışıyor (kapalıyken taslak penceresi kapanınca taslak uygulamanın çöpüne gider).
  2. **Kart küçük resmi:** `thumbnail.png` yazılıyor: kartlar canvas'taki yerlerinde, her sayfa viewport'un o anki görüntüsünden (640 × 280 px, 14 pt kenar, 6 pt başlık şeridi, 3 pt köşe — yer tutucu mini kartların ölçüleri). Sayfa yüklenince (en sık 20 sn'de bir) ve kaydederken yenilenir. Giriş kartı resmi 140 pt banda sol üstten doldurur. "Küçük resmi dosyaya ekle" kapalıysa çizilen yer tutucu kalır.
  3. **PW-06 bitti:** bizim kaydet sayfası (`chromeSheet`, 420): başlık, alt satır (yalnız taslakta), Ad (seçili ve odakta, `.viewportix` gri), Konum (SON KONUMLAR son 5 + iCloud Drive, ayırıcı, Başka klasör… → macOS klasör seçicisi; seçili konumda sağda ✓), iki onay kutusu (hatırlanır; Çoğalt'ta yalnız ilki), Vazgeç esc · Kaydet ⏎. Aynı ad: mercan kenar + açıklama, Kaydet pasif (yazarken 300 ms, konum değişince hemen). ⌘S kayıtlı projede yalnız kaydeder; ⇧⌘S Çoğalt "Kopyasını kaydet" + "<ad> kopya", kopya kendi penceresinde açılır. Dosya menüsü: Yeni ⌘N, Aç… ⌘O, Giriş Ekranı ⇧⌘0, Kapat ⌘W, Kaydet ⌘S, Çoğalt ⇧⌘S (sistemin Farklı Kaydet / Yeniden Adlandır / Taşı / Geri Döndür maddeleri kalktı).
  4. **HOME-08 bitti:** taslağın menüsü Aç · Yeniden adlandır (pasif, HOME-07) · — · Taslağı sil (mercan, onaysız). Kart 150 ms küçülerek gider; altta Geri al kapsülü (`Undo Capsule` ölçüleri: 36 pt, `surface/tooltip`, `line/strong`, "“Untitled 3” silindi", Geri al ⌘Z sarı, kalan saniye) 5 sn; üzerine gelince sayaç durur; ⌘Z (Düzen › Geri Al) de geri alır. Taslak 30 gün `Deleted Drafts`'ta, açılışta temizlenir. Açık taslak silinirse penceresi kapanır.
  5. **HOME-13 bitti:** NSAlert'in altında seçilebilir mono kod satırı (`VPX-0042 · JSON çözümlenemedi`; #1E1C1A, 4 pt köşe, 6/8 dolgu, 10 pt mono #B8B0A8 — panodaki `Alert Accessory Code` değerleri). Bozuk dosyada düğmeler Finder'da Göster / Vazgeç; taslağı tutularak kaydedilmiş projede başta "Son taslağı aç". Katalog `docs/hata-kodlari.md`.
  6. **PW-07 bitti:** pencere ya da uygulama öne gelince dosya dışarıda değişmişse: yazılmamış değişiklik yoksa sessizce yeniden yüklenir; varsa canvas'ın üstünde 40 pt şerit (`surface/header`, alt çizgi, caption 500, Diskteki sürümü aç · Benimkini tut, ikisi gri ve çipsiz) 200 ms iner; canvas aşağı itilir.
  7. **PW-09 bitti:** "“<ad>” kaydedilemedi" sistem uyarısı pencereye bağlı: disk dolu → "Diskte yer kalmadı. Yer açıp yeniden deneyin; değişiklikler taslakta duruyor." Yeniden Dene / Vazgeç; izin yok → "Bu klasöre yazma izni yok; değişiklikler taslakta duruyor." Farklı Yere Kaydet… / Vazgeç; diğerleri sistemin nedeni + Tamam. Kod satırı hepsinde. Kaydet sayfası hata sonrası açık kalır.
- Kanıt (canlı, `orca computer` + gerçek fare/klavye olayları, yerel `sample-product.html`): ⌘N → taslak dosyası ve 25 KB `thumbnail.png`; ⌘S → sayfa, ⏎ → `kayit/Keten Gömlek · Marka.viewportix` (küçük resimli), taslak silindi, pencere yeni dosyaya geçti; aynı adda mercan hal; konum menüsü; Esc'ler; ⇧⌘S → kopya yazıldı ve açıldı; salt okunur klasör → VPX-0102 uyarısı; Taslağı sil → kapsül, ⌘Z ve Geri al düğmesi geri getirdi; bozuk `project.json` → VPX-0042 uyarısı; dışarıdan değişiklik → sessiz yeniden yükleme, çatışmada şerit, iki seçenek de doğru sonuç. Görüntüler `docs/parity/dialogs-save-alerts@2x.png` (snapshot) ve `docs/parity/live-*` (canlı), `live-thumbnail.png`.
- Nerede: `Viewportix/Document/` (`ProjectFiles`, `SaveProjectSheet`, `ErrorAlert`, `ProjectDocument`), `Viewportix/Chrome/UndoCapsule.swift`, `Viewportix/Project/ProjectWindow.swift` (kaydet, PW-07 şeridi, küçük resim), `Viewportix/Home/` (`HomeView`, `RecentProjects`, `ProjectCard`), `Viewportix/App/ViewportixApp.swift` (Dosya menüsü), paket `ProjectModel` (`DraftStore`, `ProjectPackage`, `ErrorCode`), `Capture` (`ThumbnailComposer`)
- Durum: özel çizim (uyarılar sistem)
- Tasarım kararı gerekir mi: evet —
  - Önerilen ad sayfa başlığının tamamı ("Keten Gömlek · Marka"); çizimde "Keten Gömlek". Sitenin " · Marka" / " | Marka" ekini atalım mı?
  - Taslağın penceresi ve dosyası "Untitled N" (çizimdeki gibi İngilizce); Türkçe arayüzde "Adsız N" mı olsun?
  - Onay kutusunun kapalı hali çizilmemiş: `surface/pill` dolgu + `line/strong` kenar kullanıldı.
  - Geri al kapsülünün giriş penceresindeki yeri: çizimdeki gibi alttan 36 pt, içerik alanına ortalı. Proje penceresindeki "iPad kapatıldı · Geri al" kapsülü hâlâ eski `Window/Toast` görünümünde (sarı metin, ⌘Z çipi yok); ikisi aynı mı olmalı?
  - "Taslakları sakla" kapalıyken taslak penceresi kapanınca taslak sorusuz uygulamanın çöpüne gidiyor (30 gün). Kapatırken bir uyarı/kapsül ister misiniz?
  - PW-09 metni kayıtlı projede "değişiklikler pencerede duruyor" (taslak yok); çizimde yalnız taslaklı metin var.
  - Kayıtlı projede dosya başlığında uzantı görünüyor (Pencere menüsünde "Keten Gömlek · Marka kopya.viewportix"): sistemin "uzantıları göster" ayarına bağlı.
  - Uyarılarda uygulama ikonu henüz yok (logo kararı açık); sistem varsayılan ikonu çıkıyor.
- Bağlantılı: DESIGN.md §3.1 (HOME-08, HOME-13), §3.2 (PW-06, PW-07, PW-09), §4 (K7 S2, K8); PLAN.md §3.5 "Taslaklar ve kaydetme"

## 2026-10-19 — §13 kalanlar: senkron kurulamıyor, eşit aralık rozetleri, HOME-07, İçe aktar…, Tab sırası (PW-05), VoiceOver
- Ne:
  1. **Senkron kurulamıyor (§5.20 h) bitti:** motor her yüklemeden sonra ajanın sayfada çalışıp çalışmadığını bildiriyor (`EngineEvent.syncAvailable`; PDF, görsel ve about:blank'te hayır). Kart başlığında gri ‖ + ipucu "Bu sayfada senkron çalışmıyor" (kullanıcının kapattığı senkronla aynı işaret, farklı ipucu), hover şeridinde zincir pasif (%40), kapsül "Bu sayfada senkron çalışmıyor · Neden?" uygulama açıkken yalnız ilk seferde. "Neden?" ikinci bir bilgi kapsülü açar: "Sayfa betik çalıştırmıyor (PDF, görsel ya da boş sayfa); bu viewport kaydırma ve tıklamaları izlemez".
  2. **Eşit aralık rozetleri (CARD-08) bitti:** sürüklenen kart bir sırada ya da sütunda iki kartın arasında, iki aralık 6 ekran px'ten yakınsa ortaya oturur; her aralıkta 1 pt gök çizgi, uçlarda 9 pt çentik, çizginin 3 pt üstünde gök rozet (mono micro 600 `accent/ink`, [1,5], 4 köşe; pen `Gap 62`), değer CSS px. Kenar hizalaması ile eşit aralık çakışırsa eksen başına daha yakın olan kazanır. Sürüklerken imlecin sağ altında "⌥ basılıyken hizalama kapalı" ipucu (pen `Drag hint`: `surface/tooltip`, [3,8], 6 köşe).
  3. **HOME-07 bitti:** "Yeniden adlandır" kartta ve listede ad satırını yerinde metin alanına çevirir (tümü seçili, ince gök kenar, `canvas` zemin); ⏎ ya da alandan çıkmak kaydeder, Esc vazgeçer. Paket bulunduğu klasörde yeniden adlandırılır; açıksa penceresi dosyayı izler. Aynı ad varsa sistem uyarısı + VPX-0103.
  4. **"İçe aktar…" (Ayarlar › Cihazlar) bitti:** JSON cihaz listesi (`[{name|title, width, height}]`, `devices` / `customDevices` altında da; DevTools biçimi `screen.vertical`) özel cihaz olarak eklenir; aynı ad + boyuttakiler atlanır, sınır dışı boyutlar alınmaz; süzgeç "Özel"e geçer. Okunamayan dosya: sistem uyarısı + VPX-0060; yeni cihaz yoksa "Yeni cihaz yok" uyarısı.
  5. **PW-05 Tab sırası:** sidebar başlığı → sayfa listesi → şerit → grup başlıkları → kart düğmeleri → alt çubuk → ray → başa (`focusSection` ile sütunlar). Web sayfaları ve boş canvas artık Tab döngüsünde değil (tıklayınca klavye yine sayfaya geçer); önce Tab sekiz sayfanın bütün bağlantılarından geçiyordu.
  6. **VoiceOver gözden geçirmesi:** her kart adı ve boyutuyla bir grup ("iPhone 16, 393 × 852"), seçiliyse "seçili"; zoom denetimi artık adımlayıcı (değer "%42"); adres alanındaki küre ve giriş ekranındaki bağlantı / büyüteç ikonları okunmuyor (kilit "Güvenli bağlantı" olarak okunur); taslak kartı "Taslak, 35 dk. önce · 8 cihaz". Etiketsiz etkileşimli öğe yok (yalnız sistemin trafik ışıkları; sistem okur).
- Kanıt (canlı): PDF'te sekiz kartta ‖ + kapsül, HTML'e dönünce kalktı (`docs/parity/live-sync-blocked-cards@2x.png`, `live-sync-blocked-toast@2x.png`); %29'da Dizüstü'yü sürükleyince "48 · 48" rozetleri ve ipucu (`live-card-equal-spacing@2x.png`); yeniden adlandırma ⏎ ve Esc (`live-home07-rename@2x.png`), JSON içe aktarma (`live-settings-import@2x.png`); Tab: Klavyeyle gezinme geçici açılıp 45 Tab'da odaklanan öğe sırası AX'ten okundu, sonra ayar geri kapatıldı; VoiceOver: AX ağacı rol/açıklama/değerle döküldü (54 etkileşimli öğe, 3 etiketsiz = trafik ışıkları). Testler: `reportsWhereTheSyncAgentRuns`, `equalSpacingCentresBetweenNeighbours`, `DeviceImportTests`; paket 88/88.
- Nerede: `Packages/ViewportixKit/Sources/WebKitEngine/WebKitSession.swift` (`syncAvailable`, `ViewportWebView`), `EngineCore/EngineSession.swift`, `ProjectModel/CanvasLayout.swift` (`equalSpacing`), `DeviceCatalog/DeviceLibrary.swift` (`importDevices`), `Viewportix/Canvas/CardChrome.swift`, `CanvasController.swift`, `Viewportix/Project/Workspace.swift`, `ProjectWindow.swift`, `Viewportix/Home/ProjectCard.swift` (`RenameField`), `HomeView.swift`, `Viewportix/Settings/SettingsPanel.swift`, `Viewportix/Chrome/ZoomControl.swift`, `Viewportix/Project/SidebarHeader.swift`
- Durum: özel çizim
- Tasarım kararı gerekir mi: evet —
  - "Neden?"in açıklaması çizilmemiş; metin ve biçim (ikinci kapsül) tahmin. Yerine ne olsun?
  - "İçe aktar…" dosya biçimi tanımlı değil; JSON ad/genişlik/yükseklik seçildi. Responsively / Polypane dışa aktarımları da desteklensin mi? Başarıda geri bildirim (kaç cihaz eklendi) gösterilsin mi; şimdi yalnız liste "Özel"e geçiyor.
  - Rozet, çizimde aralık çizgisinin üstünde; dikey (sütun) aralıkta çizginin sağına koyduk (çizimi yok).
  - Yeniden adlandırma alanının görünümü (gök kenar, `canvas` zemin) çizilmemiş.
  - Tab ile kartın sayfasına girmenin yolu yok (tıklamak gerekiyor). Kart başlığında ⏎ ile sayfaya girmek istenir mi?
- Bağlantılı: DESIGN.md §3.1 (HOME-07), §3.2 (CARD-08/09, PW-05), §3.3 (Cihazlar), §5.20 h; `KOD-OTURUMU-ISLERI.md` §13

## 2026-10-19 — Senkron paneli (M5, §15 b)
- Ne: Raydaki "Senkron Kaydı" (ve Görüntü › Senkron Kaydı ⌥⌘2) paneli açar; panel 320 pt, canvas'ı iter, rayın solunda (`Dev Panel · Senkron (sakin)` ölçüleri: başlık [14,16,10,16], OLAY / VIEWPORT micro + 0,6 harf aralığı, satır [7,8] 8 köşe, açık satır `surface/header`, açıklama 46 pt girinti, alt satır [12,16]). Satır: geçen süre (mm:ss, pencere açılışından), olay + argüman ("scroll 640 px", "click “Products”", "input #qty = 2", "navigate /urun"), sağda "5 / 8" (kaçıran varsa yalnız sayı mercan). Satıra tık açar (DEV-01, tek açık): "iPhone SE, iPhone 16 kaçırdı: “Products” bulunamadı" ve eylem satırı tam genişlikte: Yeniden dene R (sarı, yalnız kaçıranda) · Göster ⏎ · Teşhis et D (pasif, ipucu "Teşhis MCP ile gelecek"). R / ⏎ açık satırda çalışır (metin alanı ya da sayfa klavyedeyken değil; satıra tıklamak klavyeyi sayfadan alır); klavyeyle düğme kıpırdamaz. Yeniden dene olayı yalnız kaçıranlara gönderir (DEV-06). Göster: kaçıran viewport'u seçip öne getirir. "Canlı ⌄" (Canlı / Duraklatıldı) ve alt satırdaki Duraklat/Sürdür kaydı durdurur, senkronu değil. ⋯: Yalnız kaçıranlar (süzgeç), Temizle, Dışa aktar…. Liste en yeniden aşağı; aşağı kaydırılmışken gelen olaylar "N yeni olay ↓" ile sayılır, tıklayınca en yeniye döner (DEV-08). Ardışık scroll'lar ve hover'lar 1,5 sn içinde tek satır; imlecin sayfadan çıkması ve zaten her yerde açık adrese gitmek listelenmez.
- Kanıt (canlı): spa.html, Full HD'de "Products" bağlantısı (telefonlarda gizli) → "click “Products” 5 / 8" mercan, şeritte telefonlarda ⚠; satır açıldı; ⏎ iPhone SE'yi seçip öne getirdi (`docs/parity/live-synclog-row@2x.png`, `live-synclog-window@2x.png`). Test `logsEachEventWithItsFollowersAndMergesScrolls`.
- Nerede: `Viewportix/Project/SyncLogPanel.swift`, `Workspace.swift` (`devPanel`, `syncLog`), `InspectorRail.swift`, `ProjectWindow.swift`, `ViewportixApp.swift`; paket `SyncCore/SyncLog.swift`, `SyncCoordinator.swift`; ajan scroll'a `y` ekledi
- Durum: özel çizim
- Tasarım kararı gerekir mi: evet —
  - Saat sütunu: çizimdeki "04:31" saatin dakika:saniyesi mi, pencere açıldığından beri geçen süre mi? Geçen süre seçildi.
  - Liste en yeni üstte (çizimdeki sıra), ama "2 yeni olay ↓" aşağıyı gösteriyor; tıklayınca en yeniye, yani yukarı gidiyor. Ok ↑ mu olmalı?
  - ⋯ menüsünün içeriği çizilmemiş (Yalnız kaçıranlar, Temizle, Dışa aktar… konuldu).
  - "Tasarımcı / Geliştirici" kapsamı: geliştirici kapsamı (ağ, konsol) yok; şimdilik yalnız "Tasarımcı" yazısı (menü değil).
  - Göster: çizimde kaçıran viewport'ta beklenen yerde mercan kutu + "bulunamadı"; eleman o viewport'ta olmadığı için konum bilinmiyor. Şimdilik viewport seçilip öne getiriliyor. Beklenen yer liderdeki konumun orantılısı olarak çizilsin mi?
  - Teşhis et (A) kullanıcı kararıyla ertelendi (2026-10-19, PLAN.md M5); düğme pasif ve ipuçlu duruyor. Gizlensin mi?
- Bağlantılı: DESIGN.md §3.4 (DEV-01, DEV-06, DEV-08), `KOD-OTURUMU-ISLERI.md` §15 b

## 2026-10-19 — Farklar paneli (M5, §15 b)
- Ne: Raydaki "Farklar" (ve Görüntü › Farklar ⌥⌘1) paneli açar (Senkron'la aynı yer ve ölçüler; satır dolgusu 8, solda 6 pt nokta yalnız dikkat isteyende mercan, değer sağda 64 pt). Kullanıcı kararı (2026-10-19): **iki viewport** karşılaştırılır. Başlık menüsü "iPhone SE ↔ iPad mini ⌄": BASELINE (varsayılan lider, yoksa ilk) ve KARŞILAŞTIRILAN listeleri, seçili olanda ✓. Satır: seçici (yalnız her genişlikte aynı anlama gelenler: #id, [data-testid], sayfada tek olan sınıf), özellik (soluk), fark ("yok", "600 → 500", "-2 px", "+12 px"). Yazı (font-size, font-weight, line-height, renk) her genişlikte, kutu (top, height, width) yalnız iki viewport aynı genişlikteyse karşılaştırılır; dikkat (mercan) = eleman yok/gizli ya da aynı genişlikte kaydı. Açık satır (DEV-01): "36px → 34px · aynı fark: iPad Pro 13", Full HD · baseline: iPhone SE" ve tam genişlikte Kabul A (sarı) · Yoksay I · Takip et T (açıkken "Takibi bırak") · Göster ⏎. Kabul ve Yoksay projeye kaydedilir; satır düşer, sonraki açılır (DEV-03/04); Takip et satırı soluk bırakır (DEV-05). J / K sonraki / önceki satırı açar, anında (DEV-02, K5); A · I · T · ⏎ klavyede düğme kıpırdamaz. Göster: eleman kendi viewport'unda ortaya kaydırılır, kart seçilip öne gelir, kartta ince gök kutu + gök rozet ("-2 px"). Alt satır: Yan yana · "1 / 2 incelendi" · Rapor (Markdown). ⋯: Yeniden karşılaştır, Rapor…, Yoksayılanlar › (seçince geri gelir). Sıfır hali: "Fark yok" + "8 viewport, 16 eleman karşılaştırıldı · az önce"; ölçülürken başlıkta `AIActivityGlyph`. Sayfalar yüklenince 1 sn sonra yeniden ölçülür; panel kapalıyken yeni fark çıkarsa raydaki Farklar'da mercan nokta (DEV-07).
- Kanıt (canlı, sample-product.html, 8 viewport): iPhone SE ↔ iPhone 16 "Fark yok"; ↔ iPad mini `.product-title line-height -2 px`, `.price font-weight 600 → 500`; ⏎ Göster iPad mini'de rozet; A kaydetti (`project.json` → `diffReview.accepted`), yeniden açılışta "1 / 2 incelendi"; I ile "Fark yok" (`docs/parity/live-diff-list@2x.png`, `live-diff-row@2x.png`, `live-diff-zero@2x.png`, `live-diff-show-window@2x.png`). Testler: `DiffCoreTests` (2), `collectsElementsAndFindsTheMediaQueryDifferences` (gerçek WKWebView), proje kaydı. DEV-07 noktası canlıda denenmedi.
- Nerede: paket `DiffCore` (`ElementSnapshot`, `DiffEngine`), `ProjectModel/DiffReview.swift`; `Viewportix/Project/DiffCenter.swift`, `DiffPanel.swift`, `Workspace.swift`, `ProjectWindow.swift`, `InspectorRail.swift`, `Viewportix/Canvas/CardChrome.swift` (`DiffHighlightBox`), `ViewportixApp.swift`
- Durum: özel çizim
- Tasarım kararı gerekir mi: evet —
  - Baseline "lider viewport" ama lider imleçle değişiyor; baseline'ı panel açılınca liderden alıp sabitledik ve menüye BASELINE bölümü ekledik (çizimde tek liste).
  - Açıklamadaki "iPhone 16'da aynı fark" birden çok cihazda Türkçe ek sorunu çıkarıyor ("Dizüstü'da"); "aynı fark: …" yazıldı.
  - Üst üste / Yanıp sönme modları yok (canvas'ta bindirme ister); alt satırda yalnız "Yan yana" yazısı.
  - Göster rozeti kutunun sağ üstünde, gök dolgu, `accent/ink` yazı (Senkron'daki mercan "bulunamadı" rozetinin gök karşılığı); kutu kalınlığı 1 pt. Uygun mu?
  - "Açıkla E" (DEV-12) ve "Teşhis et D" ertelendi (AI kararı); E kısayolu boş.
  - Renk farkı #RRGGBB olarak yazılıyor; kutu farkları yalnız aynı genişlikte (farklı genişliklerde düzen zaten farklı).
- Bağlantılı: DESIGN.md §3.4 (DEV-01…07), PLAN.md M5 (2026-10-19), `KOD-OTURUMU-ISLERI.md` §15 b

## 2026-10-19 — PW-07 ve PW-09 tamamlandı (otomatik kaydetme)
- Ne:
  1. **PW-09, sistemin başlattığı kaydetmeler:** otomatik kaydetme ya da pencereyi kapatırken kaydetme disk dolu / yazma izni yok hatası verirse sistemin uyarısı yerine bizim uyarı çıkıyor (aynı metinler + kod satırı; "Yeniden Dene" yeniden otomatik kaydeder, "Farklı Yere Kaydet…" bizim kaydet sayfası). Kapatma iptal olur, pencere ve değişiklikler kalır.
  2. **PW-07, "seçilene kadar otomatik kaydetme durur":** şerit açıkken belge diske yazılmıyor (o arada yapılan değişiklikler de); "Benimkini tut" yazar, "Diskteki sürümü aç" geri yükler. Şerit açıkken pencere kapatılırsa diskteki sürüm kalır, penceredeki değişiklikler gider.
  3. **Pencere öndeyken de:** `project.json` dışarıda değişince (pencere önde olsa bile) yarım saniye içinde denetleniyor; önceden yalnız pencere öne gelince bakılıyordu ve otomatik kaydetme dışarıdaki değişikliği fark etmeden eziyordu (canlıda bulundu).
- Kanıt (canlı): salt okunur klasördeki projede ⌘W → "“Kilitli” kaydedilemedi · VPX-0102" bizim uyarı (`docs/parity/live-pw09-autosave-close@2x.png`); izin geri verilince ⌘W kaydedip kapattı. Pencere öndeyken dışarıdan sayfa adı değişti → şerit 0,5 sn'de (`live-pw07-strip-while-front@2x.png`); ardından gruplama değiştirildi, 30 sn beklendi: diskte dışarıdaki sürüm kaldı; "Benimkini tut" → bizimki yazıldı, kendi kaydımızdan sonra şerit çıkmadı.
- Nerede: `Viewportix/App/AppDelegate.swift` (`willPresentError`), `Viewportix/Document/PackageWatcher.swift`, `Viewportix/Project/ProjectWindow.swift`
- Durum: sistem uyarısı (metin ve kod satırı bizim), şerit özel çizim
- Tasarım kararı gerekir mi: evet — şerit açıkken pencere kapatılırsa ne olsun? Şimdi sorusuz kapanıyor, diskteki sürüm kalıyor (penceredeki değişiklikler gidiyor). Kapatmayı engelleyip şeride mi yönlendirelim?
- Bağlantılı: DESIGN.md §3.2 (PW-07, PW-09), §4 K8

## 2026-10-19 — Proje penceresinde Geri al kapsülü yeni görünümde
- Ne: Proje penceresindeki geri alınabilir işlerin kapsülü ("Full HD kapatıldı") giriş ekranındaki `Undo Capsule` görünümüne geçti: `surface/tooltip`, `line/strong`, "Geri al ⌘Z" sarı `ActionButton`, kalan saniye; üzerine gelince sayaç durur. ⌘Z geri alınca kapsül de kapanır. Diğer kapsül türleri (ilerleme, başarı, hata, bilgi) `Window/Toast` olarak kaldı.
- Kanıt (canlı): sekmede ✕ → "Full HD kapatıldı · Geri al ⌘Z · 4 sn", ⌘Z → sekme geri geldi, kapsül kapandı (`docs/parity/live-undo-capsule-project@2x.png`).
- Nerede: `Viewportix/Project/ProjectWindow.swift`, `Workspace.swift` (`show`: geri alma kapsülünü kendi sayacı kapatır)
- Durum: özel çizim
- Tasarım kararı gerekir mi: evet — `toast-states` panosundaki "iPad kapatıldı · Geri al" eski görünümde; pano yeni kapsüle göre güncellenmeli mi, yoksa proje penceresinde eski görünüm mü kalmalı?
- Bağlantılı: DESIGN.md §4 K8 (U3), §5.20 e-f

## 2026-10-19 — Senkron › Göster: beklenen yerde mercan kutu
- Ne: Kaçıran satırda Göster ⏎: kaçıran viewport seçilip öne gelir, öğenin liderdeki yeri (sayfa genişliğine ve yüksekliğine oranla) o viewport'un sayfasına taşınır, oraya kaydırılır ve 1 pt mercan kutu + sol üstte mercan "bulunamadı" rozeti (`accent/ink` yazı) çizilir. Öğesi olmayan olaylarda (scroll, navigate) yalnız viewport öne gelir. Satır kapanınca ya da panel kapanınca kutu gider.
- Kanıt (canlı): spa.html, Full HD'de "Products" (telefonlarda gizli) → satır ⏎ → iPhone SE'de menünün olacağı yerde kutu + "bulunamadı" (`docs/parity/live-synclog-show-missing@2x.png`).
- Nerede: `Viewportix/Project/Workspace.swift` (`showSyncMiss`), `DiffCenter.swift` (`shareScript`, `spotScript`), `Viewportix/Canvas/CardChrome.swift`, paket `SyncLog.Entry.targetSelector`
- Durum: özel çizim
- Tasarım kararı gerekir mi: evet — konum tahmini oransal (düzen farklıysa yanlış yere düşebilir); kutunun en küçük boyutu 24 × 16 CSS px. Kabul edilebilir mi?
- Bağlantılı: DESIGN.md §3.4 Senkron

## 2026-10-19 — Senkron: Tasarımcı / Geliştirici kapsamı
- Ne: Alt satırdaki "Tasarımcı" artık menü: Tasarımcı ("Senkron olayları") / Geliştirici ("Ayrıca konsol ve ağ"); seçim hatırlanır. Geliştirici kapsamında listeye "konsol" (console.error / warn, yakalanmamış hatalar) ve "ağ" (≥ 400 yanıtlar, ağ hatası, yüklenemeyen kaynak, ana belgenin hata durumu) satırları girer; aynı satır 3 sn içinde birden çok viewport'tan gelirse tek satır, sağda kaç viewport'ta görüldüğü ("8 / 8"), hata düzeyinde sayı mercan. Açılınca metin, adres ve viewport adları (seçilebilir) + Göster ⏎. Konsol ve ağı yakalayan betik sayfanın kendi dünyasında çalıştığı (console, fetch, XMLHttpRequest sarılır) için yalnız Geliştirici kapsamında ve bir sonraki yüklemeden itibaren takılır; bu yüzden kapsam açılınca listede "Konsol ve ağ, sayfalar yeniden yüklenince görünür · Yenile ⌘R" satırı çıkar. Yalnız kaçıranlar süzgecinde konsol/ağ hataları da kalır. Dışa aktar (JSON) geliştirici satırlarını da içerir.
- Kanıt (canlı): dev.html (console.warn, console.error, fetch 404), 8 viewport → Geliştirici seç → Yenile → "ağ 404 sepet.json 8 / 8", "konsol Sepet yüklenemedi {"kod":42} 8 / 8" (mercan), "konsol Eski API kullanılıyor 8 / 8" (`docs/parity/live-synclog-developer@2x.png`, `live-synclog-developer-reload@2x.png`). Test `reportsConsoleAndNetworkTroubleInDeveloperScope` (kapalıyken mesaj yok).
- Nerede: paket `EngineCore` (`DeveloperMessage`, `EngineEvent.developer`, `setDeveloperLogging`), `WebKitEngine/DeveloperLog.swift`, `WebKitSession.swift`; `Viewportix/Project/Workspace.swift` (`developerLog`, `isDeveloperScope`), `SyncLogPanel.swift` (`DeveloperLogRow`)
- Durum: özel çizim
- Tasarım kararı gerekir mi: evet — geliştirici satırlarının çizimi yok (Senkron satır düzeni kullanıldı: "konsol" / "ağ" kelimesi, VIEWPORT sütununda sayı); kapsam menüsünün alt satırları ve "Yenile" satırı tahmin. Uyarılar (warning) gri, hatalar mercan.
- Bağlantılı: DESIGN.md §3.4 Senkron ("geliştirici ağ ve konsolu da görür")

## 2026-10-19 — Farklar: Üst üste ve Yanıp sönme
- Ne: Farklar'ın alt satırındaki "Yan yana" artık menü: Yan yana / Üst üste / Yanıp sönme (✓ seçili). Üst üste: karşılaştırılan viewport'un o anki görüntüsü baseline kartının sayfasına aynı CSS ölçeğinde, sol üstten, %50 saydam bindirilir (sayfa alanına kırpılır). Yanıp sönme: aynı görüntü 500 ms'de bir açılıp kapanır (Hareketi azalt'ta %50 durur). Görüntü mod seçilince, çift değişince ve fark yeniden ölçülünce alınır; panel kapanınca mod Yan yana'ya döner.
- Kanıt (canlı): sample-product, iPhone SE ↔ iPad Pro 13", Üst üste → iPhone SE kartında iPad Pro sayfası %50 (`docs/parity/live-diff-overlay@2x.png`); Yanıp sönme → 500 ms arayla alınan iki karede biri baseline, biri karşılaştırılan (dosya karşılaştırması "FARKLI").
- Nerede: `Viewportix/Project/DiffCenter.swift` (`Mode`, `Overlay`), `DiffPanel.swift` (mod menüsü), `Workspace.swift` (`captureDiffOverlay`), `Viewportix/Canvas/CardChrome.swift` (`DiffOverlay`)
- Durum: özel çizim
- Tasarım kararı gerekir mi: evet — bindirme kart başlığının altından, yalnız sayfa alanında; saydamlık %50 ve yanıp sönme hızı 500 ms tahmin. Bindirme görüntüsü sayfa kaydırılınca kendiliğinden yenilenmiyor (çift ya da mod değişince, yeniden karşılaştırınca yenileniyor).
- Bağlantılı: DESIGN.md §3.4 Farklar (⋯ mod: Yan yana / Üst üste / Yanıp sönme)

## 2026-10-19 — Canlıda denenmeyenler denendi; bulunan üç düzeltme
- Ne (düzeltmeler):
  1. **Bizim sayfa ve sistem uyarısı:** sistem uyarısı (ör. PW-09) kapandıktan sonra klavye kaydet sayfasına dönmüyordu (yazılan ad alana gitmiyordu); artık uyarı tamamen kapanınca sayfa klavyeyi geri alıyor.
  2. **HOME-13 "Son taslağı aç":** son kullanılanlar listesi paketi "/" ile biten ve /tmp ↔ /private/tmp farklı yazılışla verdiği için taslak kaydı bulunamıyor, düğme hiç çıkmıyordu; yollar tek biçime getirildi.
  3. **Kaydet sayfası › Konum:** harici diskteki klasör "Volumes › VPXDolu" görünüyordu; artık yalnız diskin adı.
- Kanıt (canlı):
  - DEV-07: Farklar kapalıyken farkı olan sayfaya geçince raydaki Farklar'da mercan nokta (farksız sayfada çıkmadı); panel açılınca kalktı.
  - Farklar › Rapor (`Farklar.md`, durumlarla) ve Senkron › Dışa aktar (`Senkron kaydı.json`) sistem kaydet panelinden yazıldı.
  - Disk dolu: dolu 2 MB disk görüntüsüne kaydet → "“Adsız” kaydedilemedi · Diskte yer kalmadı… · VPX-0101 · Vazgeç / Yeniden Dene".
  - Kaydet sayfası › Konum › Başka klasör… → macOS klasör seçicisi → Konum "scratchpad › kayit3"; "Kaydedince taslağı listeden kaldır" kapalı → taslak listede kaldı, seçim hatırlandı.
  - "Son taslağı aç": taslağı tutularak kaydedilmiş dosya bozulunca uyarıda en üstte, taslağı açtı (`docs/parity/live-home13-last-draft@2x.png`).
  - "Taslakları sakla" kapalı: yeni taslağın penceresi kapanınca taslak `Deleted Drafts`'a gitti.
- Denenemeyen: Hareketi azalt (sistem ayarı komut satırından yazılamıyor), gerçek VoiceOver ile gezinme (yalnız erişilebilirlik ağacı), Yeniden dene'nin canlıda başarılı olduğu durum (birim testiyle).
- Nerede: `Viewportix/Chrome/ChromeSheet.swift` (`takeKeyboard`), `Viewportix/Document/ProjectFiles.swift` (`DraftOrigins.path`, `SaveLocations.display`)
- Durum: özel çizim / sistem uyarısı
- Tasarım kararı gerekir mi: hayır
- Bağlantılı: DESIGN.md §3.1 (HOME-13), §3.2 (PW-06, PW-09), §3.4 (DEV-07)

## 2026-10-19 — Karar 1 ve 3 uygulandı (kullanıcı: "önerilenleri yap ve canvası da güncelle")
- Ne:
  1. **Bizim sayfa:** artık bütün pencere (üstteki 36 pt bant dahil) `canvas` %60 karartılıyor; sayfa yine 36 pt'den iniyor. Önce bant karartılmıyordu ve cihaz şeridini ikiye bölüyordu (karşılaştırma panosu, scratchpad `karar-1-3@2x.png`).
  2. **Sarı düğmenin üzerinde hali:** değişiklik yok (beyaza %6).
  3. **İkincil düğme basılıyken:** kısayol çipinin zemini `surface/pill` (düğme `surface/header`'a koyulaşınca çip kaybolmuyor). Sarı düğmede çip değişmedi.
- Kanvas (kullanıcının isteğiyle bu kez kod oturumu `design/`'a yazdı): `Dialogs · Kaydet ve uyarılar` panosunda kaydet sayfası (3 hal) ve bizim sayfa (2 hal) sahte pencerelerinde `Dim` katmanı başlık alanını da kaplıyor; 5. bölümdeki 2. kural metni güncellendi. 00b bileşenlerin yanına `Action/Secondary · Haller (2026-10-19)` (G7h17): Normal / Basılı (fare) örneği + not. Dışa aktarımlar: `design/exports/dialogs-save-alerts@2x.png` (yenilendi), `design/exports/action-secondary-states@2x.png` (yeni). `exports-map.json` ve CHK güncellenmedi; tasarım oturumu bakmalı.
- Kanıt: canlı `docs/parity/live-sheet-full-dim@2x.png` (şerit bütünüyle karartılmış); `docs/parity/action-buttons@2x.png` (basılı satırda çipler görünür).
- Nerede: `Viewportix/Chrome/ChromeSheet.swift`, `Viewportix/Chrome/ActionButton.swift` (`KeyChip`)
- Durum: özel çizim
- Tasarım kararı gerekir mi: hayır (verildi 2026-10-19)
- Bağlantılı: DESIGN.md §4 K7/K8 (bizim sayfa), K4 f (eylem düğmeleri), §6 `Action/Secondary`

## 2026-10-19 — Toplu kararlar 4–27 uygulandı (kullanıcı: "hepsini yap")
- Ne (değişenler; diğer maddeler "kalsın"):
  - **4 · Önerilen ad:** kaydet sayfası sayfa başlığını sitenin ekinden ayırıyor: son " · ", " | ", " – ", " — ", " - " ayırıcısından sonrası atılıyor ("Keten Gömlek · Marka" → "Keten Gömlek").
  - **5 · Taslak adı:** yeni taslaklar "Adsız", "Adsız 2"… (dosya, pencere, kart, kapsül, kaydet önerisi). Önceden açılmış "Untitled N" taslakları adlarını korur.
  - **10 · Şerit açıkken kapatmak (PW-07):** diskteki dosya olduğu gibi kalır; penceredeki sürüm "<ad> (senin sürümün)" taslağı olur, giriş ekranı açılır ve "Senin sürümün taslak olarak saklandı · Aç" kapsülü çıkar (5 sn); Aç taslağı açar.
  - **13 · İçe aktar…:** başarıda "N cihaz eklendi" başarı kapsülü (proje penceresinde alttaki kapsül, giriş ekranında alttan 36 pt).
  - **16 · Klavyeyle sayfaya girmek:** klavyeyle gezinme açıkken Tab kart başlığına da odaklanır: başlığın çevresinde 2 pt gök halka, başlığın 6 pt altında "Sayfaya gir ⏎" ipucu, kart öne gelir. ⏎ klavyeyi sayfaya verir; ⏎ ile girilen sayfada Esc başlığa döner (tıklayarak girilen sayfada Esc sayfanındır). VoiceOver: başlıkta "Sayfaya gir" eylemi.
  - **18 · Senkron:** "N yeni olay ↑".
  - **20 · Senkron:** "Teşhis et D" M7'ye kadar gizli.
  - **26 · Farklar Üst üste / Yanıp sönme:** senkronla kaydırma bitince (son kaydırmadan 300 ms sonra) bindirilen görüntü yenilenir.
  - **7 (kanvas):** `Toast States` panosuna "Geri al" satırı (yeni kapsül) eklendi; kanvas değişiklikleri aşağıda.
- Kanıt (canlı): `docs/parity/live-pw06-suggested-name@2x.png` (4), yeni taslak dosyası "Adsız.viewportix" (5), `live-pw07-close-kept-draft@2x.png` + Aç'ın "Keten Gömlek (senin sürümün) 5" taslağını açtığı (AXDocument) (10), `live-settings-import-toast@2x.png` (13), `live-card-header-focus@2x.png` + odak sırası AX'ten: ⏎ sonrası odak sayfada (Tab e-posta alanına gitti), Esc sonrası başlıkta (16), `live-synclog-no-diagnose@2x.png` (20), `live-diff-overlay-scrolled@2x.png` (26). 18 canlıda görülemedi (liste kısa, kaydırılamadı); kodda. Testler: `suggestedNamesDropTheSiteSuffix`, `DraftStoreTests` (Adsız, adlı taslak).
- Nerede: paket `ProjectModel` (`SuggestedName`, `DraftStore.baseName`/`create(name:)`); `Viewportix/Project/ProjectWindow.swift`, `Workspace.swift` (`enterPage`, `leavePage`, overlay yenileme), `Viewportix/Canvas/CardChrome.swift`, `CanvasController.swift`, `Viewportix/Project/SyncLogPanel.swift`, `Viewportix/Settings/SettingsPanel.swift`, `AppSettings.swift` (`HomeNotices`), `Viewportix/Home/HomeView.swift`
- Durum: özel çizim
- Tasarım kararı gerekir mi: evet — 10'daki kapsül önemli bir bilgi ama 5 sn'de kayboluyor (bilgi kapsülü kuralı); hata gibi kapatılana kadar kalsın mı?
- Bağlantılı: DESIGN.md §3.1, §3.2 (PW-05, PW-06, PW-07), §3.3, §3.4

## 2026-10-19 — Kanvas: kararlar 1–27 işlendi (kod oturumu, kullanıcının isteğiyle)
- `Home Window · Liste` ve `Dialogs · Kaydet ve uyarılar`: "Untitled 3" → "Adsız 3" (pencere başlıkları, "“Adsız 3” silindi"). `Test ·` panolarına dokunulmadı.
- `Dev Panel · Senkron (sakin)` ve üç `· AI` panosu: "2 yeni olay ↓" → "↑".
- `Toast States`: "Geri al (U3, 2026-10-19)" satırı, yeni kapsülle ("iPad kapatıldı · Geri al ⌘Z · 5 sn").
- Yeni pano `Kod kararları · 2026-10-19 (10 · 13 · 16)` (e8ztJS, 00b bileşenlerinin sağında): kapatınca saklanan sürüm kapsülü, "2 cihaz eklendi", odaklı kart başlığı + "Sayfaya gir ⏎" ipucu.
- "Teşhis et" Senkron panolarında bırakıldı (M7 hedefi); kodda M7'ye kadar gizli.
- Dışa aktarımlar yenilendi: `dialogs-save-alerts`, `toast-states`, `devpanel-synclog-calm`, `devpanel-synclog-ai-thinking/-waiting/-result`, `window-home-list`; yeni `code-decisions-2026-10-19@2x.png`. `exports-map.json` ve CHK güncellenmedi (tasarım oturumu).

## 2026-10-19 — Düzeltme: bildirim kapsülündeki düğmeler fareyle çalışmıyordu
- Ne: `Window/Toast` kapsülünün eylem düğmeleri (Finder'da Göster, Yeniden dene, Ayrıntılar, Neden?, Aç) fareyle tıklanınca çalışmıyordu: kenar çizgisi katmanı (`Capsule().strokeBorder`) tıklamaları yutuyordu. Çizgi artık tıklamaya kapalı, düğme metnin tamamında tıklanıyor. Erişilebilirlik ve klavye ile basmak zaten çalışıyordu; önceki canlı testler o yolla yapıldığı için görülmemişti. Görünüm değişmedi.
- Kanıt (canlı): PW-07 kapatma senaryosunda giriş ekranındaki "Senin sürümün taslak olarak saklandı · Aç" kapsülünde gerçek fare tıklaması → taslak açıldı (AXDocument "Keten Gömlek (senin sürümün) 3"). Test için kapsül süresi geçici 60 sn yapıldı, sonra 5 sn'ye geri alındı (kullanıcı: "5 sn kalsın").
- Nerede: `Viewportix/Project/ToastCapsule.swift`
- Durum: özel çizim
- Tasarım kararı gerekir mi: hayır
