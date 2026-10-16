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
