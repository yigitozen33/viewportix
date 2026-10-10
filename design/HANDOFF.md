# Tasarım oturumu — güncel durum

> Bu dosya **üzerine yazılır**; yalnızca tasarım oturumu yazar. Tarihçe: `notlar/`. Kod oturumu salt okur.
> Son güncelleme: 2026-10-10

## Şu an neredeyiz

- pen.dev MCP bağlantısı çalışıyor. Açık dosya şimdilik `~/Desktop/viewportix.pen` (boş, 800×600 tek frame). `design/` altına taşınmadı.
- Karar: Figma / Apple kit aktarımı **yok**. `viewportix.lib.pen` pen.dev'de elle kurulacak (DESIGN.md §4, 2026-10-10).
- Karar (2026-10-10): arayüz tamamen bizim. Toolbar ve sidebar dahil her şey pen.dev'de tam çizilir; pencere standart, sistem davranışları korunur; Apple metrikleri token olarak uyarlanır.
- Palet onaylandı (DESIGN.md §4): koyu canvas, vurgu `#FFF36B`, lider `#8EC9E6`, uyarı `#FF8F85`, zemin `#161412`. Denemeler `viewportix.pen` içinde (`Style Exploration`, `Palette Exploration`, `Yellow Palette Exploration`, `Leader Softening`, `Palette Candidate`); onaylanan örnek `Palette Candidate`.
- Değişkenler (koyu) kuruldu; açık tema değerleri bekliyor.
- `Viewport/Card` bileşeni kuruldu (`viewportix.pen`, çerçeve `Viewport States` altı durumu gösterir: default, leader, selected, syncMissed, snapshot, loading). Varsayımlar onay bekliyor: selected = `ink/primary` 2 px çerçeve (tutamaç yok), snapshot rozeti sayfa içeriğinin sol üstünde, loading = 3 px çizgi + dönen ikon (onaylandı, L1), syncMissed = başlıkta uyarı ikonu + altta not.
- Proje penceresi kesinleşti (`Project Window`, B2 düzeni; ayrıca `Project Window · Sidebar kapalı` ve `Project Window · 8 cihaz`). Dışa aktarımlar: `window-project-dark@2x.png`, `window-project-sidebar-collapsed@2x.png`, `window-project-many-devices@2x.png`, `tab-states-overflow-menu@2x.png`. Alternatifler `Alt · …` adıyla dosyada arşiv.
- Bileşenler: `Viewport/Card`, `Viewport/HoverStrip`, `Window/Toast`, `Sidebar/Row`, `Toolbar/Button`, `Toolbar/DeviceTab` (durum ikonlu).
- Ek durumlar: `Project Window · 8 cihaz · menü açık` (+N menüsü), `· Zoom menüsü açık` (Sığdır ⌘1, Seçimi sığdır ⌘2, 50/100/200, Gerçek boyut ⌘0, Yakınlaştır/Uzaklaştır), `· İkon çubuklar + tooltip` (alt çubuk ikon-only, Sığdır üstünde tooltip). Karar: alt çubuk ikon-only; tooltip koyu; menü satırında seç/odakla/kapat. Davranışlar DESIGN.md §3.2 etkileşim tablosunda.
- Motor rozeti → ikon + tooltip (`Engine Tooltip` frame, `card-engine-tooltip@2x.png`). Motor ikonları şimdilik Lucide yer tutucu (compass); üç özel glif tasarlanacak.
- `Toolbar/ZoomControl` (Z2) kuruldu ve tüm pencere frame'lerine uygulandı.
- Tasarım sistemi token'ları tamamlandı (DESIGN.md §6); 7 bileşen token'lara bağlandı. Bulgu: pen.dev `width/height`'ta sayı değişkenini çözmüyor (0'a düşüyor), boyutlar sayı yazılıyor.
- Giriş ekranı kesinleşti: `Home Window` + Liste + Boş durum + Bağlam menüsü; DESIGN.md §3.1 (etkileşim tablosuyla). Bileşenler `Home/ProjectCard`, `Home/TemplateChip`, `Home/URLBox`.
- Cihaz seçici kesinleşti (`Device/Picker`, `window-project-device-picker@2x.png`); Kaldır alt menüsü (`window-home-remove-submenu@2x.png`).
- Ayarlar penceresi çizildi (4 sekme, DESIGN.md §3.3 + etkileşim tablosu; `window-settings-*.png`). Cihaz yönetimi artık Ayarlar › Cihazlar.
- Sağ ray + paneller kesinleşti (DESIGN.md §3.3–3.4): ayarlar kayan panel, Farklar/Senkron iten sakin paneller; yerleşim varsayımı kullanımda doğrulanacak.
- Açık tema: token'lar ve iki referans frame hazır, MVP dışı (kullanıcı kararı).
- URL son 5 menüsü, sidebar durumları, ekran görüntüsü menüsü çizildi; §5 9–11 kapandı. Motor glifleri ve ikon eskizleri alt ajanlarda (frame'ler `Engine Glyphs` x=-3200,y=0 ve `App Icon Concepts` x=-3200,y=1200).
- Uygulama ikonu kararı: B6 Vx monogram (DESIGN.md §4).
- Tasarım sistemi kuruldu: `Design System · Tokens` panosu + `design/tokens/` (JSON, Swift taslağı, README). Ekranlar 6 bölümde gruplandı (DESIGN.md §6). Ana `Project Window`'a kalıcı ray eklendi; `Project Window · Ayarlar paneli` (ray + kayan panel) çizildi.
- Ayarlar ayrı penceresi kaldırıldı (kullanıcı sildi, karar: yalnızca sağ panel); ayarlar panelinden ⧉ kaldırıldı. Giriş ekranında ⚙ + kayan panel (`Home Window · Ayarlar paneli`); ray proje penceresinde varsayılan açık, daraltılabilir.
- Dosya düzeni: asıl tasarımlar x ≥ 0; keşifler "Archive ·" önekiyle solda (x < −400), açık tema "Future ·" önekiyle arşivin altında. Kart `selected` kararı: S3 çift halka (`Viewport States` içinde `selected` ve `selected + leader` sütunları).
- Pencere chrome'u bileşen (2026-10-10): `Sidebar/Header`, `Window/CollapsedHeader`, `Window/DeviceStrip` (sekmeler slot), `Window/BottomBar`, `Window/Rail`. Tüm proje penceresi ve dev panel frame'leri instance kullanır; değişiklik 00b'deki ana kopyada. Spec: `Chrome Spec` (05), `chrome-spec@2x.png`. Token düzeltmesi: sidebar 240, iten panel 320.
- Bilinen eksikler: `viewportix.lib.pen` kütüphane dönüşümü yapılmadı (pen.dev'de elle); Icon Composer dosyası yok; HTML/CSS ölçü dışa aktarımı yapılmadı (token dosyaları var).

## Sıradaki iş

Kod oturumunun istekleri (`docs/tasarim-istekleri.md`) ile karşılaştırıldı, 2026-10-10:

**Tasarımda karşılandı (kod oturumu DESIGN.md'den uygulasın):** sayfa listesi boş durumu, yerinde yeniden adlandırma ve sürükle-bırak (sidebar durumları), giriş ekranı boş durumu, cihaz ekleme menüsü (`Device/Picker`), viewport kartı + lider + senkron kaçtı, döndür/kapat düğmeleri (hover şeridinde, başlıkta değil), kapsülde glass yok.

**Açık tasarım işleri:** yok — dokuz isteğin hepsi 2026-10-10'da çizildi ve DESIGN.md'ye işlendi (kısayol haritası §3.2.1; canvas boş durumu, kart sağ tık menüsü, boyut düzenleme, senkron kapalı, kapsül halleri, sayfa sağ tık menüsü §3.2; zoom yüzdesi "%100"; medya duraklatma Ayarlar › Proje).

**İleride:** Icon Composer (B6), açık tema, inspector. **Kullanıcıda:** `viewportix.lib.pen` kütüphane dönüşümü.

## Oturum başında oku

- `docs/tasarim-istekleri.md` (kod oturumunun tasarıma bıraktığı istekler): son işlenen girdiden sonrakileri DESIGN.md §5'e işle ve aşağıya "son işlenen" yaz.
- Son işlenen: "Görünüm menüsünde Arka Plandaki Viewport'larda Medyayı Duraklat" (2026-10-10), 12 girdi okundu

## Kurallar

- Yazma alanı: yalnızca `DESIGN.md` ve `design/`. Kod oturumunun işleri için `design/KOD-OTURUMU-ISLERI.md`.
- `.pen` dosyalarına yalnızca pen.dev MCP ile eriş.
- Notlara kanıt yaz (dosya yolu, commit, ekran görüntüsü); modelin "inandığını" değil, doğrulananı.
