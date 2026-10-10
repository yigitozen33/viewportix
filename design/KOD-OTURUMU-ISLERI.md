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

## 2. Tasarımı uygulamak için (şimdilik beklemede)

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
