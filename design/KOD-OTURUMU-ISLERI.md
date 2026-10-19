# Kod oturumunun yapması gerekenler

> Tasarım oturumu CLAUDE.md, `.gitignore`, `docs/` veya kod dosyalarına dokunamaz. Aşağıdakileri kod oturumu yapar. Bitenleri `[x]` yap ve tarihle.
> Yazan: tasarım oturumu, 2026-10-10

## 1. Hafıza yapısı (Obsidian ile paralel çalışma)

- [ ] `.gitignore`'a ekle: `.obsidian/` ve `.trash/` (vault repo kökü olacak).
- [ ] `docs/HANDOFF.md` oluştur: kod oturumunun güncel durumu. **Üzerine yazılır**; yalnızca kod oturumu yazar. İçerik: şu an neredeyiz, sıradaki iş, açık sorular.
- [ ] `docs/oturumlar/` oluştur; her oturum sonunda `YYYY-MM-DD.md` ekle (yalnızca eklenir): karar, denenen/reddedilen, kanıt (commit, dosya yolu, test çıktısı).
- [ ] CLAUDE.md "Paralel oturumlar" kuralını güncelle: oturum başında kendi `HANDOFF.md`'ni ve karşı tarafınkini oku; tasarım tarafı `design/HANDOFF.md` + `design/notlar/`, kod tarafı `docs/HANDOFF.md` + `docs/oturumlar/`.
- [ ] CLAUDE.md'yi kısa tut; ayrıntı HANDOFF ve günlüklerde kalsın.
- [ ] İsteğe bağlı, sonra: SessionStart hook'u ile ilgili `HANDOFF.md`'yi bağlama ekle (çıktıyı küçük tut). Önce elle işe yaradığını gör.

Kurallar (araştırmadan): iki oturum aynı dosyaya yazmaz; notlara modelin inandığını değil kanıtı yaz; kesinleşen karar DESIGN.md/PLAN.md'ye taşınır, günlükte "işlendi" işaretlenir; eski karar silinmez, "superseded" yazılır.

## 2. Tasarımı uygulamak için (superseded, 2026-10-11: tasarım hazır — DESIGN.md §3 ekranlar, §6 bileşen → SwiftUI tablosu, `Chrome Spec`, `design/exports/`; M3 "Arayüz tasarımının uygulanması" başlayabilir)

- Tasarım henüz yok. Bileşen adları (`Window/Chrome`, `Viewport/Card`, `ViewportCardState`) ve durumlar hazır olunca `DESIGN.md` + `design/*.pen` + `design/exports/` üzerinden gelecek.
- O zamana kadar arayüz koduna tasarım kaynaklı değişiklik yapma.

## 3. Bilmen gerekenler

- CLAUDE.md'ye göre tasarım oturumu yalnızca `DESIGN.md` ve `design/`'i commit'ler. Kod oturumundaki commit edilmemiş Swift değişikliklerine dokunulmadı.
- Figma kullanılmıyor; tasarım kütüphanesi pen.dev'de elle kuruluyor (DESIGN.md §4).

## 4. Tasarıma haber verme (kullanıcıyı aracı yapmadan)

- [ ] `docs/tasarim-istekleri.md` oluştur. Yalnızca kod oturumu yazar, yalnızca eklenir. Tasarım oturumu her oturum başında okur, işlediği satırı `[işlendi]` yapamaz (salt okur); işlenenleri `design/HANDOFF.md`'de "son işlenen: <tarih/başlık>" olarak izler.
- [ ] Arayüze dokunan her değişiklikte (yeni düğme, menü, panel, durum, metin, boş/hata hali) aynı commit'te bu dosyaya girdi ekle. Kullanıcıya sorma, kullanıcıdan aktarmasını bekleme.
- Girdi biçimi:

```
## YYYY-MM-DD — <öğe adı>
- Ne: <ne eklendi / değişti>
- Nerede: <ekran, bileşen, dosya yolu veya commit>
- Durum: sistem varsayılanı | özel çizim
- Tasarım kararı gerekir mi: evet/hayır — neden
- Bağlantılı: <varsa DESIGN.md bölümü>
```

Hazır istem (kod oturumuna yapıştır):

> Arayüze dokunan her değişikliği (yeni düğme, menü, panel, bildirim, durum, metin, boş/hata hali) `docs/tasarim-istekleri.md` dosyasına, değişikliği yaptığın commit'te, yukarıdaki biçimle ekle. Dosya yalnızca eklenir. Bunu kullanıcıya sormadan ve kullanıcıdan tasarım oturumuna aktarmasını beklemeden yap. DESIGN.md ve `design/` altına yazma. Oturum bitiminde `docs/oturumlar/` günlüğüne o gün eklenen satırları da özetle.

## 5. Karar: arayüz tamamen özel (2026-10-10, kullanıcı kararı)

Tasarım toolbar ve sidebar dahil tamamen özel olacak (DESIGN.md §1 ve §4). Kod oturumu için sonuçlar:

- [ ] Sistem `NSToolbar`/`NavigationSplitView` sidebar'ı yerine özel görünümler planla. Pencere standart kalır: şeffaf/gizli başlık çubuğu, traffic lights, taşıma, tam ekran.
- [ ] Korunacak sistem davranışları: menü çubuğu ve kısayollar, klavye gezinmesi, VoiceOver etiketleri, sidebar aç/kapa ve genişlik ayarı (kendin yaz).
- [ ] Kendi yüzeylerimizde Liquid Glass kullanma. Görünüm macOS 26 ve sonrasında aynı olacak.
- [ ] Mimari etkisi büyükse PLAN.md'ye sen işle (tasarım oturumu PLAN.md'ye dokunmaz). Tasarım gelene kadar mevcut sistem görünümü kalsın.

## 6. Etkileşim sözleşmesi (2026-10-10)

DESIGN.md §3.2 sonundaki **etkileşim tablosu** tetikleyici → etki → hareket (süre/easing) biçiminde; her ekran için aynı biçim kullanılacak. Kod bu tabloyu doğrudan uygular; soru varsa `docs/tasarim-istekleri.md`'ye yaz. Tasarım dosyasındaki frame adları (`Project Window · Zoom menüsü açık` gibi) tablodaki durumlara karşılık gelir.

- [ ] Kart başlığındaki motor rozeti ikon oldu; sürüm tooltip'te ("WebKit 26 · macOS 26"). Sürümü sistemden oku (WKWebView user agent / sistem sürümü). Başlık taşma sırası: boyut gizlenir → ad ortadan kısaltılır (DESIGN.md §3.2).

- [ ] Ayarlar penceresi (⌘,) tasarımı hazır: DESIGN.md §3.3. MCP sekmesi M7'ye kadar gizli kalabilir; Hesap sekmesindeki lisans/takım alanları iş modeli netleşince doldurulur.

- [ ] Ayarlar artık sağ raydan açılan panel (DESIGN.md §3.3); ayrı pencere yalnızca "pencereye çıkar". Geliştirici paneli (M5) §3.4; panel yerleşimi varsayım, kullanımda geri bildirim `docs/tasarim-istekleri.md`'ye.

- [ ] Açık tema MVP dışı: uygulama yalnızca koyu tema ile çıkar; Ayarlar › Tema segmenti şimdilik gizli ya da yalnızca "Koyu". Token'ların açık değerleri DESIGN.md §6'da, ileride açılır.

- [ ] Motor glifleri hazır: DESIGN.md §6'daki üç SVG path (16×16, evenodd). Kart başlığında WebKit glifi; M4/M6'da Chromium/Firefox. SF Symbols yerine bu path'ler kullanılacak.
- [ ] URL alanı: son 5 URL geçmişi (uygulama düzeyi, `UserDefaults`/app support; proje dosyasına girmez); ⌘D açık URL'yi sayfa listesine ekler. DESIGN.md §3.2.

- [ ] Uygulama ikonu B6 "Vx monogram" seçildi (DESIGN.md §4). Icon Composer dosyası tasarım oturumundan gelecek; o zamana kadar yer tutucu ikon kalsın.

- [ ] Yazı tipi: SwiftUI'de sistem fontu (`.system`, SF Pro) ve sayısal değerler/seçiciler için `.monospaced` (SF Mono); `.monospacedDigit()` boyut ve yüzdelerde. Tasarım dosyasındaki Inter / JetBrains Mono yalnızca vekil, uygulamaya gömme. Boyutlar DESIGN.md §6 (`font/title` 15 … `font/micro` 10).

- [ ] Kart `selected` durumu: kartın dışında 3 px boşlukla 1.5 px krem halka (kartın kendi çizgisinden bağımsız overlay). Lider (gök iç çizgi) ile aynı anda olabilir. Seçim: karta tık, sekmeye tık, "+N"/cihaz seçici, Farklar › Göster; Esc veya boşluğa tık kaldırır. DESIGN.md §4 ve §3.2 etkileşim tablosu.

## 7. Tasarım sistemi teslimi (2026-10-10)

- [ ] `design/tokens/DesignTokens.swift` dosyasını `Packages/ViewportixKit` içine (ör. `Sources/DesignSystem/`) kopyala; tasarım oturumu güncelledikçe yeniden kopyala, elle düzenleme.
- [ ] SwiftUI görünüm adları DESIGN.md §6 tablosundaki adlarla birebir (`ViewportCard`, `DeviceTab`, `ZoomControl`…); durumlar enum.
- [ ] Motor glifleri `viewportix.tokens.json` › `glyph` içinde SVG path; `Shape` olarak çiz.

- [ ] Ayrı ayarlar penceresi yok (önceki not geçersiz): ayarlar yalnızca sağ raydan açılan kayan panel; yalnız giriş ekranı açıksa ⌘, aynı paneli giriş ekranının sağında açar. DESIGN.md §3.3.

## 8. `docs/tasarim-istekleri.md` yanıtları (2026-10-10)

- [ ] Kısayollar DESIGN.md §3.2.1 tablosundan; ⌥⌘S / ⌃⌥⌘S senin seçimin korundu. "+ Cihaz" ⌥⌘N, sidebar ⌃⌘S, rotate ⌥⌘R (⌘R yenile), sayfa geçişi ⇧⌘] / ⇧⌘[, ⌘L adres çubuğu, ⌘D sayfayı listeye ekle.
- [ ] Zoom yüzdesi Türkçe yazımla "%100" (NumberFormatter percent, tr_TR); menüde %25 %50 %100 %200.
- [ ] Döndür ve kaldır kart başlığında değil hover şeridinde; başlıkta yalnız motor glifi ve kamera.
- [ ] Kart sağ tık menüsü, Boyutu düzenle popover'ı (sheet değil), senkron kapalı durumu (gri ‖, şeritte zincir), canvas ve sayfa listesi boş durumları, sayfa sağ tık menüsü, kapsül halleri: DESIGN.md §3.2.
- [ ] "Arka plandaki viewport'larda medyayı duraklat": Görünüm menüsünde kalır, ayrıca Ayarlar › Proje'de toggle.

- [ ] Ekran görüntüsü akışı değişti (DESIGN.md §3.2): alt çubuk kamerası ve kart kamerası tıklanınca önce seçici (Görünen alan / Tam sayfa) açar; kart başlığı sağ tık menüsünden "Ekran Görüntüsü" ve "Tam Sayfa Ekran Görüntüsü" çıkar. ⌥⌘S / ⌃⌥⌘S kısayolları seçiciyi atlar.

## 9. Pencere chrome'u (2026-10-10)

- [ ] Pencere parçaları ayrı SwiftUI görünümleri: `SidebarHeader`, `CollapsedSidebarHeader`, `DeviceStrip`, `BottomBar`, `InspectorRail` (DESIGN.md §6 tablosu). Ölçü, token ve durumlar `Chrome Spec` frame'inde ve `design/exports/chrome-spec@2x.png`.
- [ ] Yerleşim: şerit canvas'ın üstünde ortada (üstten 16), alt çubuk altta ortada (alttan 31), kapsül canvas sol üstü (16, 16), ray sağ kenarda. Ortalama sidebar, ray ve iten panel çıktıktan sonra kalan canvas alanına göre; bağlı menüler tetikleyicisine hizalı.
- [ ] Token düzeltmesi: `Size.sidebar` 240 (220 değil), `Size.panelDocked` 320 (300 değil). `design/tokens/DesignTokens.swift` güncellendi, yeniden kopyala.

## 10. Medya duraklatma varsayılanı (2026-10-10, kullanıcı kararı)

- [ ] "Arka Plandaki Medyayı Duraklat" **varsayılan açık** gelsin (senin girdinde varsayılan kapalıydı). İlk açılışta tikli; kullanıcı kapatırsa tercih saklanır. Görünüm menüsü maddesi ve Ayarlar › Genel › PROJE toggle'ı aynı değeri gösterir. DESIGN.md §3.3, §4.

## 11. Ayarlar sekmeleri, ray tutamacı (2026-10-11)

- [ ] Ayarlar › Cihazlar, MCP, Hesap sekmeleri çizildi: DESIGN.md §3.3, `design/exports/window-project-settings-{devices,mcp,account}@2x.png`. Cihazlar iki satırlı liste + tür süzgeci; MCP sekmesi M7'ye kadar gizli kalabilir.
- [ ] Ray gizliyken `RailHandle` (24×56, sağ kenarda üstten 16): tık / ⌥⌘0 rayı geri getirir; Farklar bulgusu varken mercan nokta. `window-project-rail-hidden@2x.png`, etkileşim tablosu §3.3.
- [ ] Sidebar 240 kesin (`Size.sidebar`). Boş URL alanı ipucu "Adres yaz ya da yapıştır".

## 12. Uygulama sırası önerisi (2026-10-11)

Tasarım hazır; M3 "Arayüz tasarımının uygulanması" için önerilen sıra (her adım kendi başına çalışır halde bırakılabilir):

1. [ ] `DesignTokens.swift`'i pakete kopyala (§7). Renkler yalnızca koyu.
2. [ ] Pencere çerçevesi (PLAN.md §3.8): şeffaf başlık, `HStack` = sidebar (240) + canvas + `InspectorRail` (44). Sidebar kapalıyken `CollapsedSidebarHeader`.
3. [ ] `SidebarHeader` (URL alanı + son 5 menüsü, nav), `SidebarRow` ve sayfa listesi durumları.
4. [ ] Canvas üstü: `DeviceStrip` (sekmeler, taşma, +N menüsü), `BottomBar` (senkron, sığdır, `ZoomControl`, kamera + seçici), `ToastCapsule`. Yerleşim DESIGN.md §6 "Pencere chrome'u".
5. [ ] `ViewportCard` durumları + `ViewportHoverStrip` + kart menüsü + Boyutu düzenle popover'ı.
6. [ ] `DevicePicker` popover'ı.
7. [ ] Ayarlar kayan paneli (Genel, Cihazlar, Hesap; MCP M7'ye kadar gizli), ray öğeleri, `RailHandle`.
8. [ ] Giriş ekranı (`ProjectCard`, `TemplateChip`, `URLBox`, ızgara/liste, bağlam menüsü, ⚙ paneli).

Her etkileşim için DESIGN.md'deki etkileşim tablosu sözleşmedir. Arayüze dokunan her değişikliği `docs/tasarim-istekleri.md`'ye eklemeye devam et; tasarımda olmayan bir hal çıkarsa oraya yaz.

- Not (medya): kullanıcı "Arka Plandaki Medyayı Duraklat"ı **varsayılan açık** istedi (§10). Gerekçe performans değil, birden çok viewport'ta seslerin üst üste binmesi; PLAN.md'deki "ölçülebilir kazanç yok" bulgusu bu kararı değiştirmez.

## 13. 10–13 Ekim kararları: yeni haller (2026-10-13, kullanıcı "aktar" dedi)

§12'deki iskelet bitince sırayla. Her biri DESIGN.md §3.2 etkileşim tablosunda ve §4'te; görseller `design/exports/`.

- [ ] **Sayfa yüklenemedi** (`card-load-errors@2x.png`): ağ, sertifika ("Bu oturumda güven" yalnız o host, uygulama kapanana kadar), `localhost` kapalı (2 sn'de bir otomatik dene), adres bulunamadı; kapsül "Sayfa n viewport'ta açılamadı · Hepsini dene". Hata kodu mono küçük.
- [ ] **Kartı sürükleme** (`window-project-dragging@2x.png`): başlıktan tutulur, gölge, gök hizalama çizgileri + eşit aralık rozetleri, 6 px yapışma, ⌥ hizalamayı kapatır; konum projeye; Viewport › Kartları Diz.
- [ ] **Gruplama** (`window-project-groups*.png`): Görünüm › Grupla (Yok / Cihaz Türü / Motor); grup alanı + katlanır başlık; şeritte ayırıcı; katlı grup şeritte tek çip; grup başlığı ⋯ menüsü (Katla · Grubu sığdır · Gruptakileri kapat).
- [ ] **Sidebar yalnız sayfalar (V1):** PLAN.md M3 "Sidebar'da viewport listesi ve gruplar" maddesini şeride/canvas'a taşı (PLAN'ı sen güncelle; tasarım dokunmaz).
- [ ] **Sidebar genişlik tutamacı:** 6 px, hover/sürüklemede 2 px gök + genişlik etiketi, 200–360, varsayılan 240, bırakınca kaydet; 200 altı kapatmaz.
- [ ] **Klavye odak halkası:** 2 px `status/leader`, 2 px dışarıda, yalnız klavye odağında; Tab sırası DESIGN.md §3.2.
- [ ] **Giriş ekranı:** aramada sonuç yok; dosyası bulunamayan kart (Bul…); açılamayan proje NSAlert metinleri (`home-file-errors@2x.png`).
- [ ] **Küçük ayrıntılar** (`misc-states-2@2x.png`): en küçük pencere 1024×640; tam ekranda sidebar üst boşluğu 16; ray tooltip'leri; kısaltma kuralları (URL ortadan, ad/sekme sondan, sekme ≤140); tek kapsül kuralı + "Geri al" 5 sn / ⌘Z; bağlantı sürükle-bırak; sayfada senkron kurulamıyor (‖ + "Neden?"); çoklu seçim MVP dışı.
- [ ] **VoiceOver etiketleri:** DESIGN.md §6 tablosu birebir.
- [ ] **Menü:** Görünüm › Grupla ›, Viewport › Kartları Diz (kısayolsuz). Ayarlar › Tema satırı açık temaya kadar yok.

## 14. Aktarım paketi: bileşen spec'leri (2026-10-13)

`design/handoff/` tasarımı makinece okunur veriyor: `manifest.json` (bileşen · ekran · PNG · nodeId), `specs/<SwiftName>.json` (ana kopyanın katman ağacı: layout, boyut `fill`/`fit`/sabit, token'lar → `DesignTokens` üyeleri, durum override'ları, yanına çizilen parçalar, ekranlardaki görünümler), `specs/README.md` (durum kapsamı, token dışı değerler). Sözleşme `design/handoff/README.md`.

- [ ] **Deneme:** `BottomBar`'ı yalnız `specs/BottomBar.json` (+ `ChromeButton.json`, `ZoomControl.json`) ve `DesignTokens.swift` ile, PNG'ye bakmadan kur; sonra `window-project-dark@2x.png` ile karşılaştır. Eksik ya da yanlış anlaşılan alanları `docs/tasarim-istekleri.md`'ye "spec: BottomBar" başlığıyla yaz (ikon adları Lucide; SF Symbols eşlemesi `design/handoff/icons.md` ile gelecek).
- [ ] **Yeni bileşen `ChromeTooltip`** (`Window/Tooltip`, `specs/ChromeTooltip.json`): gövde + aşağı ok, ad + isteğe bağlı kısayol; yan tooltip'lerde ok yok; hedefle ok ucu arası her yerde 8 px, 400 ms gecikme. Tüm tooltip'ler bunu kullanır.
- [ ] **Yeni token `DesignTokens.Color.lineStrong`** (`line/strong`, #4F4945): proje kartı hover kenarı. `DesignTokens.swift`'i yeniden kopyala.
- [ ] **Giriş ekranı durumları** (`home-states@2x.png`, DESIGN.md §4 2026-10-13): "Aç →" hep sarı (boşken tık alana odaklanır); geçersiz URL'de mercan kenar + altında "Bu bir web adresi değil · örnek: marka.com"; proje kartında ⋯ yalnız hover ve sağ tıkta, hover kenarı `lineStrong`.
- [ ] **İkonlar SF Symbols** (`design/handoff/icons.md`): her Lucide adının SF karşılığı, macOS 26'da doğrulandı. Assets'e iki özel sembol grubu: `link.slash` (SF Symbols uygulamasında `link`'ten türet; senkron kapalı / Senkrondan çıkar / adres hatalı) ve motor glifleri (`engine.webkit/chromium/firefox`, geometri spec'lerde). Yükleniyor = `ProgressView`, imleçler `NSCursor`.
- [ ] **Yeni token `DesignTokens.Color.surfaceGroup`** (%2 beyaz, gruplama alanı zemini) ve `DesignTokens.swift`'te alfa desteği (`opacity:`); dosyayı yeniden kopyala. Yarı saydam karartma = `canvas.opacity(...)` (token + alfa).
- [ ] **Kabul listesi = DESIGN.md §3 etkileşim id'leri** (`HOME-01`…, `STRIP-01`…, `CARD-`, `SIDEBAR-`, `BAR-`, `PW-`, `RAIL-`, `SETTINGS-`, `DEV-`; toplam 80). Bir ekranın hangi id'lere baktığı `design/handoff/manifest.md` › Ekranlar › Etkileşim. Commit ve `docs/tasarim-istekleri.md` girdilerinde id'yi an (ör. "CARD-07 bitti").
- [ ] **Örnek sayfa:** `design/fixtures/sample-product.html`'i `Packages/ViewportixKit/Tests/Fixtures/`'a kopyala (tek dosya). Seçiciler `.product-title`, `.price`, `.add-to-cart`, `.size-m`, `#qty`; telefon/tablet arası bilinçli farklar dosya başındaki yorumda; `?missing-cart` masaüstünde `.add-to-cart`'ı kaldırır (senkron kaçırma testi). Referans görüntüler `design/fixtures/renders/`.
- [ ] **İskelet denemesi (aşama 9):** `design/handoff/skeleton/BottomBar.swift` (+ `ChromeButton`, `ZoomControl`, `SkeletonSymbol`) spec'ten üretildi, `DesignTokens.swift` ile typecheck temiz, dört durum 210×49 (`BottomBar-compare@2x.png`). Elle kurduğun `BottomBar` (§14 ilk madde) ile karşılaştır ve `docs/tasarim-istekleri.md`'ye "iskelet: işe yarar / yaramaz + neden" yaz. Not: SF Symbols aynı puntoda Lucide'den iri; ikon boyutu için tasarım kararı gelecek.
- [ ] **İkon boyutu (karar 2026-10-13):** SF Symbol puntosu = tasarımdaki ikon kutusu × 0.875, regular (16 → 14 pt). Örnek: `Image(systemName:).font(.system(size: DesignTokens.Size.icon * 0.875))`. MCP ikonu `powerplug.portrait`. Pano `design/handoff/skeleton/icon-size-options@2x.png`.
- [ ] **`link.slash`:** kalıcı çözüm asset (`.symbolset`, tasarım oturumu hazırlayacak). O zamana kadar `design/handoff/skeleton/SkeletonSymbol.swift` › `LinkSlashSymbol` (sistem `link` + eğik çizgi, boyut/ağırlığı fonttan alır) geçici olarak kullanılabilir; asset gelince `Image("link.slash")` ile değiştir. Tasarımda karşılığı Lucide `link-2-off`.
- [ ] **`link.slash` asset'i hazır:** `design/handoff/symbols/link.slash.symbolset`'i uygulamanın `Assets.xcassets`'ine kopyala; `Image("link.slash")` (ağırlık ve ölçeği font/`imageScale`'den alır, `actool` ile doğrulandı). Önceki maddedeki geçici `LinkSlashSymbol` artık yok.
- [ ] **Motor glifleri sembol oldu:** `design/handoff/symbols/engine.{webkit,chromium,firefox}.symbolset`'i `Assets.xcassets`'e kopyala; `Image("engine.webkit")` vb. (ağırlık ve ölçeği fonttan alır; kart başlığında kamerayla aynı punto, 14 × 0.875). Path olarak çizme.

## 15. 18–19 Ekim kararları: eylem düğmeleri, hareket dili, uygulama içi AI, kaydetme ve uyarılar (2026-10-19, kullanıcı "kod tarafına ver" dedi)

Kaynak: DESIGN.md §3.1 (HOME-08, HOME-13), §3.2 (PW-06…09), §3.4 ("Uygulama içi AI", DEV-02, DEV-09…12), §4 (2026-10-18 / 19 satırları: K1–K8, A / B), §6 (yeni bileşen satırları). Görseller `design/exports/`: `devpanel-diff-calm`, `devpanel-synclog-calm`, `devpanel-synclog-ai-thinking / -waiting / -result`, `devpanel-diff-ai-explain`, `window-project-agents-panel`, `window-project-agent-driving`, `motion-spec`, `dialogs-save-alerts`. `test-ai-*` ve `test-save-alerts` **keşif, uygulama için değil**. Oynayan hâl: `design/prototypes/animasyon-lab.html` (tarayıcıda aç; 0. bölüm A2 v2 = hedef davranış).

**a) Şimdi yapılabilir (kilometre taşı beklemez)**

- [ ] **`ActionButton(.primary / .secondary)`** (`Action/Primary`, `Action/Secondary`; DESIGN.md §4 "Eylem düğmeleri (K4 f)"): 24 px, `radius/badge`, caption; ana: `accent` dolgu + `accentInk` 600; ikincil: `surfacePill` + `inkPrimary`. Kısayol çipi micro, sarıda `accentInk` %12, grilerde `surfaceHeader`; çip yalnız odaktaki satırda (açık satır ya da klavye odağı) ve sayfa / uyarı içinde hep. Basma yalnız farede: 80 ms %97 + bir ton koyu + 1 px iç gölge (sarıda parlaklık −%12), bırakınca 120 ms; **klavyeyle tetiklenince animasyon yok**. Hover bir ton açık (sarıda +%6), odak 2 px `inkPrimary`, pasif `surfaceGroup` + `inkSecondary`. Tek sarı: bir yüzeyde en çok bir ana eylem.
- [ ] **`AIActivityGlyph`** (`AI/Glyph`): 12 × 12, üç çubuk 2×9 · 3×7 · 5×5 (telefon · tablet · masaüstü), `accent`; 720 ms döngü, 120 ms adım, opaklık 1 / .6 / .4 / .25, linear, sırayla yanar. Haller: çalışıyor · onay bekliyor (durur, `inkSecondary` %60 + mercan nokta) · bitti (üçü mürekkep). Hareketi azalt: durur, %60.
- [ ] **Hareket değerleri** (`motion-spec@2x.png`, tablo 2. bölüm): tek eğri `cubic-bezier(0.23, 1, 0.32, 1)` (SwiftUI `.timingCurve(0.23, 1, 0.32, 1, duration:)`); kutu açılır 220 ms opaklık + 4 px; yeni adım 220 ms 4 px + blur 4 → 0; katlanma 2 sn bekle + 300 ms, yarıda kesilebilir, imleç kutudaysa bekler; ⌄ ile açınca adımlar 40 ms arayla (en çok 6); bildirim yığını 400 ms, en fazla 3. Kurallar: tek ışık, tek sarı, kayma yok, klavye canlanmaz, kutlama yok, hata ve onay durdurur. Değerleri tek yerde tut (`Motion` gibi); token gerekirse `docs/tasarim-istekleri.md`'ye yaz, tasarım `DesignTokens.swift`'e ekler.
- [ ] **HOME-08:** taslakta "Taslağı sil" (üç nokta yok) onaysız; kart 150 ms daralır, kapsülde "“<ad>” silindi · Geri al" 5 sn (⌘Z da geri alır, üzerine gelince süre durur); taslak 30 gün uygulamanın çöpünde. Önceki "Taslağı sil…" + onay superseded. Taslak saklamayla birlikte gelir.
- [ ] **HOME-13 hata kodu satırı:** mevcut `NSAlert`'in `accessoryView`'ına mono, seçilebilir tek satır (`VPX-0042 · JSON çözümlenemedi`). `VPX-NNNN` kataloğunu sen tanımla (dosya / senkron / motor hataları), listeyi `docs/`'ta tut.
- [ ] **PW-06 Kaydet (K7 S2, bizim sayfa; aynı gün S1 superseded):** taslağa ilk ⌘S ve ⇧⌘S Çoğalt'ta **`NSSavePanel` değil**, aşağıdaki "Bizim sayfa" görünümünde 420 genişlik, alanlar arası 14 (`dialogs-save-alerts@2x.png` 1. bölüm, üç hal): "Projeyi kaydet" (Çoğalt'ta "Kopyasını kaydet") + alt satır; **Ad** (28 px, `canvas` zemin, sayfa başlığından, seçili ve odakta; `.viewportix` gri ve değiştirilemez); **Konum** seçicisi (`surfacePill`, klasör ikonu + yol; açılınca `ChromeMenu`: SON KONUMLAR son 5 + iCloud Drive, ayırıcı, "Başka klasör…" → `NSOpenPanel` `canChooseDirectories`, seçilen yer listeye eklenir); iki onay kutusu "Küçük resmi dosyaya ekle", "Kaydedince taslağı listeden kaldır" (varsayılan açık, seçim hatırlanır; Çoğalt'ta yalnız ilki); Vazgeç esc · Kaydet ⏎ (`ActionButton`). Aynı ad seçili klasörde varsa (yazarken 300 ms gecikmeyle ve konum değişince denetle) alan `statusWarning` kenar + altında "Bu klasörde “<ad>” var · başka ad ver ya da başka klasör seç", Kaydet pasif; üzerine yazma yok. Klasöre yazma izni için security-scoped bookmark gerekiyorsa sen karar ver, PLAN.md'ye yaz. Kaydedilmiş projede ⌘S yalnız kaydeder; kapatırken "Kaydedilsin mi?" **yok**.
- [ ] **PW-07 Dosya diskte değişti:** pencere odaklanınca denetle. Bizde kaydedilmemiş değişiklik yoksa sessizce yeniden yükle; ikisi de değiştiyse canvas üstünde 40 px şerit `surfaceHeader` + alt çizgi: "Dosya başka yerde değişti" · Diskteki sürümü aç · Benimkini tut (ikisi `ActionButton(.secondary)`, çipsiz); seçilene kadar otomatik kaydetme durur; şerit 200 ms iner.
- [ ] **PW-09 Kaydedilemedi:** `NSAlert` "“<ad>” kaydedilemedi" · "Diskte yer kalmadı. Yer açıp yeniden deneyin; değişiklikler taslakta duruyor." · Yeniden Dene / Vazgeç; izin yokta "Bu klasöre yazma izni yok" · Farklı Yere Kaydet… / Vazgeç. Altında hata kodu satırı.
- [ ] **Bizim sayfa (U2) görünümü** — `ChromeSheet` gibi tek görünüm; ilk kullanımı PW-06 Kaydet (yukarıda), sonra PW-08 ve MCP onayı: pencerenin başlığından iner, 360 genişlik, `surfaceCard`, `radius/card`, 20 iç boşluk, 10 aralık, `line` çizgi, gölge 0 12 32 %50; arka plan `canvas` %60. İniş 240 ms tek eğri, kapanış 160 ms; Hareketi azalt 150 ms solma. ⏎ ana eylem, esc vazgeç, odak sayfada kalır, kapanınca açan denetime döner; VoiceOver sheet rolü, önce başlık. Yıkıcı ana eylem düğmesi yok (mercan düğme türü eklenmedi). Ölçüler `dialogs-save-alerts@2x.png` 3. ve 5. bölüm.

**b) M5 ile (Farklar / Senkron panelleri)**

- [ ] Paneller `devpanel-diff-calm`, `devpanel-synclog-calm`, `devpanel-diff-zero-calm`: eylem satırı açılımın **tam genişliğinde**, açıklamanın altında; Farklar Kabul A (ana) · Yoksay I · Takip et T · Göster ⏎; Senkron Yeniden dene R (ana) · Göster ⏎ · Teşhis et D. DEV-02 J / K **anında** (önceki 150 ms superseded).
- [ ] **A · satır içi teşhis** (DEV-09…12): Senkron "Teşhis et D" ve Farklar "Açıkla E" satırın altında AI kutusu açar: düşünüyor (başlık `AIActivityGlyph` + "Düşünüyor 3 sn" + model, zaman damgalı adımlar, aktif adımda sarı ışık geçişi, mono canlı kaynak satırı, Durdur ⌘., araç / token sayısı) → seni bekliyor (K6 üç satırlı liste: "1 Evet, bu sefer ⏎" · "2 Evet, bu projede `<komut>` için bir daha sorma" · "3 Hayır, ne yapacağını söyle esc"; ↑ ↓ ⏎, 1 / 2 / 3; kalıcı izin komut adına, Ayarlar › Ajanlar › İzinler) → sonuç (2 sn sonra adımlar "6 sn çalıştı · 4 adım ⌄" başlığına katlanır; Farklara ekle ⌘⏎ · Kapat esc). Kutuda sarı varken satırın ana eylemi gri. **Mimari (model çağrısı, araç katmanı, izin saklama) senin kararın, önce PLAN.md'ye.**

**c) M7 ile (MCP)**

- [ ] **B · Ajanlar paneli** (rayda; Seni bekliyor / Çalışıyor / Bitti; açık satırda K6 listesi + Göster; altta bağlı istemciler + Tümünü durdur), **ajan sürüş şeridi** (Senkron üstünde "Claude Code sürüyor", Devral · Durdur ⌘. · Göster ⏎; olaylarda ✦ kaynak; canvas'ta ajan imleci ve okuma vurgusu), **bildirim yığını**.
- [ ] **MCP istemci onayı** (bizim sayfa): "“<istemci>” bu projeye bağlanmak istiyor", istediği araçlar, K6 listesi (ayrı düğme satırı yok); kapsam istemci adına.
- [ ] **PW-08 ajan çalışırken çıkış** (bizim sayfa): "N ajan çalışıyor", ajan listesi (`AIActivityGlyph` · ad · iş · süre), Vazgeç esc · Durdur ve çık ⏎; ajan yokken sorulmaz, "bir daha sorma" yok.

**Kısayollar:** Teşhis et D, Açıkla E, Farklara ekle ⌘⏎, Kapat esc, Durdur ⌘., izin 1 / 2 / 3 (hepsi bağlama özel, odak panelde). Çakışma görürsen `docs/tasarim-istekleri.md`'ye yaz.

## 16. M4 sonrası: onboarding, motorlar, Chromium kart halleri, `<select>`, sayfa uyarıları, başlıkta motor adı (2026-10-19)

Kaynak: DESIGN.md §3.1 (onboarding, HOME-19, HOME-20), §3.2 (Viewport kartı › motor adı, Chromium kartı halleri, `<select>` listesi, sayfanın JS uyarıları, CARD-13, CARD-14, PW-10, PW-11), §3.3 (Genel › MOTORLAR, BU PROJE › Yeni cihazlar, SETTINGS-06, SETTINGS-07), §4 (K9–K12 ve "M4 tasarım istekleri" satırı). Kanvas: `07 · MOTORLAR (M4)` sırası (y 8100). Görseller `design/exports/`.

- [ ] **Başlıkta motor adı (K12 a)** — kare `Card · Motor halleri` 2–3. bölüm, `card-engine-states@2x.png`; bileşen `Viewport/Card` › `EngineName` (label, normal, `inkSecondary`, varsayılan gizli). Biçim kodda bugünkü gibi ayrı gri kelime: ad (label 600) · motor (label normal) · boyut (caption), aralar 6. Gizlenme sığmaya göre: boyut → motor adı → ad sondan "…"; glif + kamera hep. Sekme / Farklar / Senkron: "Masaüstü · WebKit". Değişiklik yoksa yalnız doğrula.
- [ ] **Ayarlar › Genel › MOTORLAR + BU PROJE › Yeni cihazlar** — kare `Project Window · Ayarlar › Motorlar` (`window-project-settings-engines@2x.png`). Bölüm sırası: GÖRÜNÜM · MOTORLAR · BU PROJE · PROJE · EKRAN GÖRÜNTÜSÜ. Motor satırı: 16 glif · ad label · alt satır caption (Chromium'da altında mono micro yol) · sağda durum caption ("Hazır" / "Yakında"); satır [8, 0], alt çizgi `line`; Firefox %50. Chromium'un bulunamadı / indiriliyor / indirilemedi halleri onboarding satırıyla aynı (aşağıda). Altta açıklama caption. **Yeni cihazlar**: seçim (110 genişlik, mevcut `Select` stili) WebKit / Chromium; cihaz seçicinin motoruyla aynı ayar, **projeye yazılır** (önceki "pencereye özel, dosyaya yazılmaz" ve "Bu proje › Motor: hepsini geçir / Karışık" superseded; hepsini geçirmek isteyen kart › Motor › ya da grup menüsü). Altında açıklama caption. SETTINGS-06, SETTINGS-07.
- [ ] **Onboarding (K9 A, K10)** — kare `Onboarding · Motorlar` (`onboarding-engines@2x.png`, 5 hal). İlk açılışta giriş penceresinde `ChromeSheet`, 520 genişlik, 24 iç boşluk, 14 aralık. Adım 1: üç motor glifi 24 (aralık 14) · başlık title "Viewportix'e hoş geldin" · gövde body `inkSecondary` · üç madde (16 lucide ikon `monitor-smartphone`, `link`, `git-compare` + label) · alt satır: Atla esc (ikincil) · boşluk · "1 / 2" caption · Devam ⏎ (ana). Adım 2: başlık "Motorlar", gövde, `canvas` zeminli liste (`radius/control`, iç [2, 12]); satır [10, 0] alt çizgili: 16 glif · ad label · alt satır caption · sağda ✓ (16, `inkSecondary`) ya da eylem. Chromium halleri: **bulundu** "Google Chrome 155 bulundu" ✓ · **bulunamadı** açıklama + "İndir" (`ActionButton(.secondary)`, çipsiz) + altında gök "ya da Chrome'u kendin kur ↗" (google.com/chrome açar) · **indiriliyor** alt satır "İndiriliyor · 64 / 152 MB · 20 sn kaldı" + 3 pt ilerleme (`line` zemin, `accent` dolgu, köşe 2) + Durdur · **indirilemedi** alt satır `statusWarning`, altında mono micro kod (`VPX-0310 · NSURLError -1005`) + Yeniden dene. Firefox %50 "Yakında". Alt satır: Atla esc · "2 / 2" · Başla ⏎ (her halde açık). İndirme = Chrome for Testing, uygulamanın `Application Support` klasörüne; kullanıcının Chrome'una dokunmaz; tek iş (onboarding, Ayarlar, kart aynı ilerlemeyi gösterir), Başla'dan sonra arka planda sürer, bitince kapsül "Chromium hazır" ve Chromium kartları kendiliğinden yüklenir. Kendiliğinden bir daha açılmaz; menü maddesi yok (aşağıdaki Kuruluma devam et açar). HOME-19, HOME-20. Hata kodlarını `docs/hata-kodlari.md`'ye ekle (VPX-0310 indirme, VPX-0320 başlatma — numaraları sen ver).
- [ ] **Kuruluma devam et (HOME-21)** — kareler `Setup Reminder · Kuruluma devam et` (`setup-reminder-states@2x.png`), `Home Window · Kuruluma devam et`, `Project Window · Başlarken kartı`. Kurulum adımı eksik oldukça (bugün: Chromium yok) ve kullanıcı kapatmadıkça: **giriş ekranında** URL kutusu / şablonlar ile SON PROJELER arasında tam genişlik şerit (`surfaceHeader`, `radius/card`, iç [10, 10, 10, 14], aralık 12; Chromium glifi 16 · "Kuruluma devam et" label 600 + caption "Chromium motoru eksik: Chrome bulunamadı. Kartlar şimdilik yalnız WebKit'te açılır." · Devam et `ActionButton(.secondary)` çipsiz · ✕ 14); **proje penceresinde** sidebar'ın en altında "Başlarken" kartı (sidebar iç genişliği 216, `surfaceHeader`, çerçevesiz, `radius/card`, iç 12, aralık 8: üstte micro "BAŞLARKEN" + ✕; satırda 24 rozet `surfaceCard` + glif, başlık label 600 "Chromium motorunu kur", caption açıklama; altta sağda Devam et `ActionButton(.secondary)` çipsiz). Pencere başına tek hatırlatıcı. Onboarding'i **yalnız Devam et düğmesi** açar: doğrudan son adım (Motorlar), **indirme hemen başlar** (satır "indiriliyor" halinde açılır); bu girişte 1. adım, Atla ve "2 / 2" yok, gövde metni "Chromium motoru indiriliyor. Başla'ya basabilirsin; indirme arka planda sürer."; Başla ⏎ ya da esc sayfayı kapatır, indirme arka planda sürer (kare `Onboarding · Motorlar` › "Kuruluma devam et'ten", akış `Setup Reminder` 3. bölüm). Şeridin / kartın kendisi tıklanmaz, ✕ kapatır. **Tek hal:** şerit ve kart indirme sürerken de, hata olsa da aynı görünür (indiriliyor / indirilemedi halleri yok); ilerleme ve hata onboarding'in 2. adımında ve Ayarlar'da. Adım bitince rozet `inkPrimary` + tik, 900 ms sonra sıradaki eksik adıma kayar; adım kalmadıysa kart 200 ms yükseklik + opaklıkla kalkar. ✕ tek bayrak: şerit ve kart birlikte emekli olur, bir daha çıkmaz (Ayarlar kalır). Birden çok adım (M6 Firefox, M7 AI ajanı) gelince noktalar: etkin hap 14 × 5 `inkPrimary`, bekleyen 5 × 5 `line`, biten 5 × 5 `inkSecondary`; ← → ile gezilir. Hareketi azalt: kayma yok, opaklık.
- [ ] **İndirme arka planda: bildirimler (HOME-22)** — kare `Setup Reminder · Kuruluma devam et` 4. bölüm; mevcut `Window/Toast` halleri (ilerleme / başarı / hata). Başla ya da esc ile sayfa kapanınca ilerleme kapsülü (`loader-circle`, "Chromium arka planda indiriliyor · %42", eylem Ayrıntı → Ayarlar › Genel › Motorlar) 5 sn; sonra kaybolur (şerit / kart ilerleme göstermez; Devam et onboarding'i "indiriliyor" satırıyla yeniden açar). Bitince başarı "Chromium hazır · N kart yüklendi" + Göster (canvas ilk Chromium kartına kayar), 5 sn. Hata: hata kapsülü "Chrome indirilemedi: <neden>" + Yeniden dene, kapatılana kadar. Çıkışta sorma; yarım dosyayı sakla, sonraki açılışta kendiliğinden sürdür.
- [ ] **Chromium kartı halleri** — kare `Card · Motor halleri` 1. bölüm. "Sayfa yüklenemedi" kartının hata alanı aynen (ikon 22, başlık body, açıklama caption 180 ortalı, kod mono micro, eylem satırı üstte 6 boşluk, düğmeler 6 aralık, kartın küçük düğmeleri [5, 10]); başlıkta mercan üçgen, sekmede aynı. Dört hal: **Chrome bulunamadı** (Chromium glifi 22 `inkSecondary`; "Bu kart Chromium'da açılıyor; Mac'te Chrome yok. İndirmesi ~150 MB."; İndir sarı · WebKit'te aç gri; altında gök caption "Motorlar…") · **İndiriliyor** (150 × 3 ilerleme, mono "64 / 152 MB · 20 sn", Durdur; üçgen yok) · **İndirilemedi** (glif `statusWarning`, kod, Yeniden dene sarı · WebKit'te aç) · **Chromium başlatılamadı** (`triangle-alert` 22 `statusWarning`, "Chrome açıldı ama yanıt vermedi.", kod, Yeniden başlat sarı · WebKit'te aç). Birden çok kart Chrome bekliyorsa kapsül "n kart Chrome bekliyor · İndir". Bugünkü `#1F1F1F` + gri metin yerine. CARD-13.
- [ ] **`<select>` listesi (Chromium)** — kare `Select Menu · Chromium` (`select-menu-chromium@2x.png`, 3 sahne). `ChromeMenu`, ekran noktası. Konum: kutunun sol kenarı, alt kenarın **4 pt** altı (bugün 2); altta 3 satır (88 pt) yer yoksa üstte 4 pt; iki yönde de sığmazsa geniş tarafta. Görünen alana (pencere) göre hesapla, kart kenarına göre değil. Genişlik = kutunun ekrandaki genişliği, **en az 160, en çok 320**. Satır yüksekliği 26 (iç [0, 10]), menü iç boşluğu 5, tik yuvası 14 + 6. **En çok 12 satır** (12 × 26 + 10 = 322); fazlası kaydırılır, altta 24 pt solma (`surfaceHeader` → saydam) + 3 pt kaydırma çubuğu (`line`, sağdan 4). Açılışta seçili satır tikli, `surfaceCard` vurgulu ve görünür (gerekirse ortaya kaydır). `<optgroup>` başlığı caption 600 `inkSecondary`, [6, 10, 2, 10], seçilemez, metni olduğu gibi. disabled %50. Uzun metin sondan "…". Yazınca ilk eşleşene atla; ↑ ↓ ⏎ esc. CARD-14.
- [ ] **Sayfanın JS uyarıları (K11)** — kare `Page Dialogs · alert confirm prompt` 1. bölüm (`page-dialogs@2x.png`; 2. bölüm A elendi). Canvas'ın altında kapsül, alt çubuğun 8 pt üstü; bildirim kapsülüyle aynı yerde, onu ezmez (ikisi üst üste). Kapsül: `surfaceTooltip`, köşe 20 (iki satırlıda 14), `line` çizgi, iç [6, 8, 6, 14], aralık 10; 14 ikon · kaynak caption (`statusLeader`, ör. "iPhone 16 + 2 kart") · mesaj caption `inkPrimary` · eylemler. Kurallar: **alert beklemez** (sayfaya hemen dön; metni 5 sn bilgi kapsülünde "Sayfa · 3 kart"); **aynı uyarı birleşir** (tür + metin + sayfa adresi; yanıt hepsine; kaynağın üzerine gelince o kartlarda 2 pt gök halka, tıklayınca canvas ilk karta kayar); **confirm** İptal esc · Tamam ⏎ + onay kutusu "Aynısını sorma" (varsayılan kapalı); **prompt** iki satır (en çok 520): üstte ikon · kaynak · soru, altta metin alanı (24, `canvas`, odakta 2 pt `inkPrimary`, varsayılan değer seçili) · "Aynısını sorma" · İptal · Tamam; **Sustur**: aynı uyarı 10 sn içinde 3. kez gelince kapsüle eklenir; susturulan sayfa bu pencerede uyarı açamaz (alert geçer, confirm İptal, prompt boş). "Aynısını sorma" / Sustur sonrası kapsül çıkmaz; her otomatik yanıt Senkron'da satır (geliştirici kapsamı gerekmez): "confirm · <mesaj> · otomatik Tamam · 3 kart" + gök "Kuralı kaldır". Kurallar pencereye özel, kapanınca silinir. WebKit'in sistem paneli de bununla değişir (WKUIDelegate). PW-10, PW-11.

**Açık kalan (kod oturumunun sorusu, tasarım cevabı):** "Senin sürümün taslak olarak saklandı" kapsülü — kullanıcı 5 sn kalsın dedi (docs/tasarim-istekleri.md düzeltme girdisi); değişiklik yok.

## 17. Kaynak paneli (CPU · GPU · Bellek · Disk) — sağ kenar çentiği + Morph (2026-10-19)

Kaynak: DESIGN.md §4 "Kaynak paneli" (2026-10-19); kare `Resource Monitor · Kaynaklar` (`resource-monitor@2x.png`): 1 panel, 2 çentik ve morph kareleri, 3 kart şeridi, 4 ölçüm. Elenen denemeler kanvastan silindi (commit adda36e'de duruyor).

- [ ] **Çentik (gösterge):** `BottomBar`'ın sağ kenarına kaynamış 20 × 33 dil, çubuğun dikey ortasında (üstten 8); `surfaceHeader`, `line` çizgi üst / sağ / alt, sağ köşeler 10, çubukla birleşim yerinde çizgi yok. İçinde üç dikey çizgi 2 × 14, aralık 2 (CPU · GPU · Bellek; iz `line`, dolgu alttan `inkPrimary`, sakin yükte `inkSecondary`). Üzerine gelince sağa uzar (spring) ve toplam bellek görünür (mono micro, ör. "2,4 GB"); tıklama alanı dilin çevresinde 6 pt geniş. Kritik (bellek baskısı kritik ya da bir viewport bütçeyi 2 katı aştı): çizgiler, rakam ve dil kenarı `statusWarning`. Çubuğun ortalaması dili saymaz. VoiceOver: "Kaynaklar, CPU %148, GPU %22, bellek 2,4 GB", düğme. Kısayol ⌥⌘3 (çakışma görürsen yaz).
- [ ] **Morph:** tık / ⌥⌘3 → dil panel şekline dönüşür (SwiftUI `matchedGeometryEffect` + `.spring(response: 0.32, dampingFraction: 1)`): panel çubuğun 8 pt sağında, alt kenarı çubuğun alt kenarıyla hizalı, köken sol alt. İçerik şekil yerleşince 60 ms sonra solarak gelir, satırlar 40 ms kademe (en çok 6). Kapanış (Esc, dışarı tık, ⌥⌘3, dile tık): içerik 80 ms söner, şekil 200 ms'de aynı yoldan dile döner. Kesilebilir (o anki değerden geri döner). Karartma yok, canvas kullanılabilir. Sağda 388 pt yer yoksa panel çubuğun üstünde, çentiğin üstüne sağa hizalı açılır (morph yine çentikten). Hareketi azalt: morph yok, 150 ms solma.
- [ ] **Panel (380, sabit yükseklik):** `surfaceHeader`, köşe 12, iç 12, aralık 10, `line` çizgi, gölge 0 8 24 %40. Başlık: micro "KAYNAKLAR" · caption "6 viewport · 14 süreç" · sağda micro "● canlı · 2 sn". Dört kutu (`surfaceCard`, `radius/control`, iç [8, 10]): micro başlık, mono body 600 değer, 62 × 14 son örnekler çubukları, micro alt satır (CPU "%148 · 2 çekirdek dolu" + tooltip "Toplam CPU; %100 üstü birden çok çekirdek", GPU "motor başına", Bellek "baskı: sakin / sıkışık / kritik", Disk "önbellek dahil" → tık Temizle…). VIEWPORT'LAR (belleğe göre; başlığa tık sıralar): satır 30, iç [0, 8]: glif 14 · ad caption 600 (+ ikizse gri motor adı) · 48 × 14 CPU çubukları · CPU mono 36 sağa · bellek mono 64 sağa + altında 2 pt çubuk ve bütçe işareti (varsayılan 300 MB). Bütçeyi aşan satırın bellek rakamı ve çubuğu `statusWarning`. Uyuyan satır %50 + "uyuyor". Liste 6 satırdan sonra kendi içinde kayar. Satıra gelince canvas'ta kart 2 pt gök halka; tık kartı seçer ve kaydırır; sağ tık / ⋯: Yeniden yükle · Uyut · Kapat. PAYLAŞILAN: motor başına (WebKit GPU + ağ süreçleri, Chromium tarayıcı + GPU süreci) GPU % ve bellek. Alt satır (üstte `line`): anahtar "Kartlarda göster" · "Arka plandakileri uyut" (`ActionButton(.secondary)`, çipsiz). Çubuk renkleri: yük 0–45 % `inkSecondary`, 45–80 % `inkPrimary`, üstü `statusWarning`. Sarı yok.
- [ ] **Kartlarda yük şeridi:** başlığın altında 3 pt (başlık katmanında, zoom'dan bağımsız), son 40 sn CPU, saniyede bir kare, kareler arası 1; renkler paneldekiyle aynı. Üzerine gelince sayfa alanının sağ üstünde rozet (`surfaceTooltip`, mono micro "412 MB · %38" + bütçe farkı mercan "+112"). Uyuyan kart: sayfa son anlık görüntü %45, ortada kapsül "Uyuyor · 210 MB boşaldı" (ay ikonu); tık ya da kaydırma uyandırır. Açma: panel anahtarı ya da Görünüm › Kaynakları Kartlarda Göster.
- [ ] **Ölçüm (mimari senin, PLAN.md'ye yaz):** süreç başına `proc_pid_rusage` (`ri_phys_footprint`, CPU farkı); WebKit viewport ↔ WebContent pid (`_webProcessIdentifier`, gezinmede değişebilir), Chromium viewport ↔ süreç ağacı (CDP `SystemInfo.getProcessInfo`); GPU yalnız motor başına (IORegistry, Apple Silicon); yoklama 2 sn yalnız panel ya da kart şeridi açıkken, kapalıyken çentik 10 sn'de bir. Uyutma = viewport'u anlık görüntüye çevirip süreci kapatmak (Edge uyuyan sekmeler gibi); bütçe Ayarlar'da (varsayılan 300 MB).
