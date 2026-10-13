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
