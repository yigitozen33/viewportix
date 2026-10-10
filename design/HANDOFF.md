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
- Ek durumlar: `Project Window · 8 cihaz · menü açık` (+N menüsü), `· Zoom menüsü açık` (Sığdır ⌘1, Seçimi sığdır ⌘2, 50/100/200, Gerçek boyut ⌘0, Yakınlaştır/Uzaklaştır), `· İkon çubuklar + tooltip` (alt çubuk ikon-only, Sığdır üstünde tooltip). Karar bekliyor: alt çubuk metinli mi ikon-only mi.
- Bilinen eksikler: zoom düğmesinde chevron solda; sidebar hover/rename durumları; gizli-lider çip rengi yalnızca açıklamada; açık tema.

## Sıradaki iş

1. `.pen` dosyalarını `design/viewportix.lib.pen` ve `design/viewportix.pen` olarak repoya taşı (kullanıcı pen.dev'de yeniden açacak).
2. Referans: Apple HIG sayfaları ve kullanıcının vereceği Finder/Keynote ekran görüntüleri.
3. Giriş ekranı (1040×700), sonra cihaz seçici popover, sonra açık tema.
4. Boyut ve aralık değişkenleri; zoom düğmesi varyantı; sidebar durumları.
5. Kod oturumundan gelen yeni öğeler tasarıma girecek (DESIGN.md §5, madde 9–11): kart başlığında kamera düğmesi (`Viewport/Card` hover/başlık satırı), toolbar'da ekran görüntüsü menüsü, pencere altında bildirim kapsülü ("Kaydedildi ve kopyalandı · Finder'da Göster").
6. Her görsel karar kullanıcıya sorulur, DESIGN.md §4'e tarihiyle işlenir.

## Açık sorular (kullanıcıya)

- `.pen` dosyalarının taşınması ve referans kaynağı (HIG sayfaları mı, ekran görüntüsü mü).
- Başlangıç: değişkenlerle mi, kaba proje penceresiyle mi.

## Oturum başında oku

- `docs/tasarim-istekleri.md` (kod oturumunun tasarıma bıraktığı istekler): son işlenen girdiden sonrakileri DESIGN.md §5'e işle ve aşağıya "son işlenen" yaz.
- Son işlenen: yok (dosya henüz oluşturulmadı)

## Kurallar

- Yazma alanı: yalnızca `DESIGN.md` ve `design/`. Kod oturumunun işleri için `design/KOD-OTURUMU-ISLERI.md`.
- `.pen` dosyalarına yalnızca pen.dev MCP ile eriş.
- Notlara kanıt yaz (dosya yolu, commit, ekran görüntüsü); modelin "inandığını" değil, doğrulananı.
