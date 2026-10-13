# İkon eşleme (Lucide → SF Symbols)

Üretilir: `build_icons.py` (eşleme elle, script'teki `MAP`); kaynak `icons-dump.json` (`dump-icons.js`, 2026-10-13). Arşiv dışı tüm görünür ikon düğümleri, instance içleri dahil.

Tür: **1:1** aynı anlam ve şekil · **yakın** aynı anlam, şekil biraz farklı · **öneri** birebir karşılık yok, öneri (onaylandı, DESIGN.md §4 2026-10-13) · **özel** Assets'e özel sembol gerekir · **sistem** sembol değil, AppKit çizer.

**Boyut:** SF Symbol puntosu = tasarımdaki Lucide kutusu × 0.875, ağırlık regular (16 → 14 pt, 14 → 12,25, 10 → 8,75); aynı puntoda SF Symbols Lucide'den iri görünür. Karşılaştırma `skeleton/icon-size-options@2x.png`, karar DESIGN.md §4 (2026-10-13).

SF adları macOS 26'da `NSImage(systemSymbolName:)` ile doğrulandı (`python3 build_icons.py --verify`).

| Nerede | Lucide | SF Symbol | Tür | Not | Kaynak (bileşen · ekran) |
|---|---|---|---|---|---|
| Senkron kapalı (alt çubuk), Senkrondan çıkar (hover şeridi), adres hatalı | `link-2-off` | link.slash (özel) | özel | SF'de yok; `link`'ten türetilmiş özel sembol (`.symbolset`). Pen'de de eğik çizgili zincir (DESIGN.md §4). | `Viewport/HoverStrip`, Dev Panel ×3, Project Window ×21, 2 durum frame'i |
| Ray › Senkron kaydı | `activity` | `waveform.path.ecg` | öneri | Alternatif `list.bullet.rectangle`. | `Window/Rail`, Dev Panel ×3, Project Window ×21, 2 durum frame'i |
| Giriş sidebar › Taslaklar | `file-pen` | `square.and.pencil` | öneri | Alternatif `doc.badge.ellipsis`. | Home Window ×6 |
| Ray › Farklar | `git-compare` | `square.split.2x1` | öneri | Yan yana karşılaştırma; alternatif `arrow.left.and.right.square`. | `Window/Rail`, Dev Panel ×3, Home Window ×6, Project Window ×21, 2 durum frame'i |
| Hover şeridi › Döndür | `rotate-ccw` | `rectangle.portrait.rotate` | öneri | `arrow.counterclockwise` Geri al ile karışır; cihaz döndürme sembolü daha açık. | `Viewport/HoverStrip`, Dev Panel ×3, Project Window ×21, 1 durum frame'i |
| Kart yükleme hatası › localhost kapalı | `server-off` | `server.rack` | öneri | SF'de kapalı sunucu yok. | 1 durum frame'i |
| Ekran görüntüsü seçici › Tam sayfa | `file-down` | `arrow.down.document` | yakın |  | Project Window ×1, 1 durum frame'i |
| Giriş › Aç… düğmesi | `folder-open` | `folder` | yakın | SF'de açık klasör yok. | Home Window ×6 |
| Alt çubuk › senkron açık | `link-2` | `link` | yakın | SF'de tek zincir şekli var; `link` ile aynı sembol. | `Window/BottomBar`, Dev Panel ×3, Project Window ×22, 1 durum frame'i |
| Kaldır › Listeden kaldır | `list-x` | `text.badge.xmark` | yakın |  | Home Window ×1 |
| Ray › Rayı gizle | `panel-right-close` | `sidebar.right` | yakın | SF'de aç/kapa ayrımı yok; aynı sembol. | `Window/Rail`, Dev Panel ×3, Project Window ×21, 2 durum frame'i |
| Ray tutamacı › Rayı göster | `panel-right-open` | `sidebar.right` | yakın | SF'de aç/kapa ayrımı yok; aynı sembol. | `Window/RailHandle`, Project Window ×1, 1 durum frame'i |
| Aramada sonuç yok | `search-x` | `magnifyingglass` | yakın | SF'de çarpılı büyüteç yok. | 1 durum frame'i |
| Boyut popover'ı › en ↔ boy | `arrow-left-right` | `arrow.left.arrow.right` | 1:1 |  | 1 durum frame'i |
| URL kutusu › Aç → | `arrow-right` | `arrow.right` | 1:1 |  | `Home/URLBox`, Home Window ×6, 2 durum frame'i |
| Cihaz seçici › Cihazları yönet… | `arrow-up-right` | `arrow.up.right` | 1:1 |  | `Device/Picker`, Project Window ×1 |
| Kart başlığı kamerası, alt çubuk ekran görüntüsü | `camera` | `camera` | 1:1 |  | `Viewport/Card`, `Window/BottomBar`, Dev Panel ×3, Project Window ×22, 7 durum frame'i |
| Kapsül başarı, cihaz seçicide eklendi | `check` | `checkmark` | 1:1 |  | `Device/Picker`, `Window/Toast`, Project Window ×9, 1 durum frame'i |
| Menü okları, zoom ▼, "+N" çipi | `chevron-down` | `chevron.down` | 1:1 | Zoom ▲▼ küçük (10 pt) çizilir. | `Toolbar/ZoomControl`, `Window/BottomBar`, Dev Panel ×3, Home Window ×1, Project Window ×22, 3 durum frame'i |
| Sidebar nav › Geri | `chevron-left` | `chevron.left` | 1:1 |  | `Sidebar/Header`, `Window/CollapsedHeader`, Dev Panel ×3, Project Window ×22, 2 durum frame'i |
| Nav › İleri, şerit kaydırma ›, alt menü oku | `chevron-right` | `chevron.right` | 1:1 | Alt menü okunu NSMenu kendisi çizer. | `Sidebar/Header`, `Window/CollapsedHeader`, Dev Panel ×3, Home Window ×2, Project Window ×22, 2 durum frame'i |
| Zoom ▲ | `chevron-up` | `chevron.up` | 1:1 |  | `Toolbar/ZoomControl`, `Window/BottomBar`, Dev Panel ×3, Project Window ×22, 1 durum frame'i |
| Bağlam menüsü › Çoğalt, MCP komutu kopyala | `copy` | `doc.on.doc` | 1:1 |  | Home Window ×2, Project Window ×1 |
| Sidebar sayfa ikonu (örnek: Ödeme) | `credit-card` | `creditcard` | 1:1 | Örnek veri; sayfa ikonu türüne göre seçilir. | Dev Panel ×3, Project Window ×20, 2 durum frame'i |
| ⋯ düğmeleri (kart, satır, panel) | `ellipsis` | `ellipsis` | 1:1 |  | Dev Panel ×3, Home Window ×3, Project Window ×1, 4 durum frame'i |
| Gizli cihaz menüsü › satır durumu | `eye` | `eye` | 1:1 |  | 1 durum frame'i |
| Sidebar/Row varsayılan sayfa ikonu | `file-text` | `doc.text` | 1:1 |  | `Sidebar/Row`, 2 durum frame'i |
| Bağlam menüsü › Finder'da göster | `folder` | `folder` | 1:1 |  | Home Window ×2 |
| URL alanı boşken ipucu | `globe` | `globe` | 1:1 |  | 1 durum frame'i |
| Giriş sidebar › Son | `history` | `clock.arrow.circlepath` | 1:1 |  | Home Window ×6 |
| Sidebar sayfa ikonu (örnek: Ana sayfa) | `house` | `house` | 1:1 | Örnek veri. | Dev Panel ×3, Project Window ×20, 2 durum frame'i |
| Sekme / kart durumu snapshot | `image` | `photo` | 1:1 |  | Project Window ×2, 2 durum frame'i |
| Kapsül bilgi (senkron kurulamıyor) | `info` | `info.circle` | 1:1 |  | 1 durum frame'i |
| Cihaz türü dizüstü | `laptop` | `laptopcomputer` | 1:1 |  | `Device/Picker`, Project Window ×2, 1 durum frame'i |
| Giriş › ızgara görünümü | `layout-grid` | `square.grid.2x2` | 1:1 |  | Home Window ×6, 1 durum frame'i |
| URL kutusu, hover şeridi › Senkrona kat | `link` | `link` | 1:1 |  | `Home/URLBox`, Home Window ×6, 3 durum frame'i |
| Giriş › liste görünümü | `list` | `list.bullet` | 1:1 |  | Home Window ×6, 1 durum frame'i |
| URL alanı › güvenli bağlantı | `lock` | `lock` | 1:1 |  | `Sidebar/Header`, `Window/CollapsedHeader`, Dev Panel ×3, Project Window ×22, 3 durum frame'i |
| Alt çubuk › Sığdır | `maximize-2` | `arrow.up.left.and.arrow.down.right` | 1:1 |  | `Window/BottomBar`, Dev Panel ×3, Project Window ×22, 1 durum frame'i |
| Cihaz türü masaüstü | `monitor` | `display` | 1:1 |  | `Device/Picker`, Project Window ×3, 1 durum frame'i |
| Sidebar sayfa ikonu (örnek: Ürün) | `package` | `shippingbox` | 1:1 | Örnek veri. | Dev Panel ×3, Project Window ×20, 2 durum frame'i |
| Kenar çubuğu düğmesi (kapsülde) | `panel-left` | `sidebar.left` | 1:1 |  | `Window/CollapsedHeader`, Project Window ×2, 1 durum frame'i |
| Kart başlığı › senkron kapalı ‖ | `pause` | `pause` | 1:1 |  | 2 durum frame'i |
| Yeniden adlandır | `pencil` | `pencil` | 1:1 |  | Home Window ×2, 1 durum frame'i |
| Ray › MCP | `plug` | `powerplug.portrait` | 1:1 | Dikey fiş, Lucide ile aynı yön (DESIGN.md §4). | `Window/Rail`, Dev Panel ×3, Home Window ×1, Project Window ×21, 2 durum frame'i |
| + Cihaz, + Ekle, + Yeni | `plus` | `plus` | 1:1 |  | `Device/Picker`, `Toolbar/Button`, `Window/DeviceStrip`, Dev Panel ×3, Home Window ×6, Project Window ×22, 4 durum frame'i |
| Sidebar nav › Yenile | `rotate-cw` | `arrow.clockwise` | 1:1 |  | `Sidebar/Header`, `Window/CollapsedHeader`, Dev Panel ×3, Project Window ×22, 2 durum frame'i |
| Cihaz seçici › Özel boyut | `ruler` | `ruler` | 1:1 |  | `Device/Picker`, Project Window ×2 |
| Ekran görüntüsü › Görünen alan; menü › odakla | `scan` | `viewfinder` | 1:1 |  | Project Window ×2, 2 durum frame'i |
| Arama alanları | `search` | `magnifyingglass` | 1:1 |  | `Device/Picker`, Home Window ×6, Project Window ×5, 1 durum frame'i |
| Ray / giriş › Ayarlar | `settings` | `gearshape` | 1:1 |  | `Window/Rail`, Dev Panel ×3, Home Window ×6, Project Window ×21, 2 durum frame'i |
| Kart yükleme hatası › sertifika | `shield-alert` | `exclamationmark.shield` | 1:1 |  | 1 durum frame'i |
| Sidebar sayfa ikonu (örnek: Sepet) | `shopping-cart` | `cart` | 1:1 | Örnek veri. | Dev Panel ×3, Project Window ×20, 2 durum frame'i |
| Cihaz türü telefon, şablon çipi, ray › Cihazlar | `smartphone` | `iphone` | 1:1 |  | `Device/Picker`, `Home/TemplateChip`, `Window/Rail`, Dev Panel ×3, Home Window ×6, Project Window ×21, 3 durum frame'i |
| Cihaz türü tablet | `tablet` | `ipad` | 1:1 |  | `Device/Picker`, Project Window ×2 |
| Kaldır › Çöp Sepeti'ne taşı | `trash-2` | `trash` | 1:1 |  | Home Window ×2 |
| Uyarı: senkron kaçtı, hata, "+N" durumu | `triangle-alert` | `exclamationmark.triangle` | 1:1 |  | `Viewport/Card`, `Window/DeviceStrip`, Dev Panel ×3, Project Window ×21, 9 durum frame'i |
| Ray › Hesap | `user` | `person` | 1:1 |  | `Window/Rail`, Dev Panel ×3, Home Window ×1, Project Window ×21, 2 durum frame'i |
| Kart yükleme hatası › ağ | `wifi-off` | `wifi.slash` | 1:1 |  | 1 durum frame'i |
| Kapat (sekme, kart, menü satırı, panel) | `x` | `xmark` | 1:1 |  | `Toolbar/DeviceTab`, `Viewport/HoverStrip`, `Window/DeviceStrip`, Dev Panel ×3, Home Window ×1, Project Window ×21, 6 durum frame'i |
| Kart sürüklenirken imleç | `hand-grab` | NSCursor.closedHand | sistem | Sembol değil, imleç. | Project Window ×1 |
| Yükleniyor (kart, sekme, kapsül) | `loader-circle` | ProgressView | sistem | `ProgressView().controlSize(.small)`; sembol değil. | Project Window ×2, 5 durum frame'i |
| Bağlantı bırakma örneğinde imleç | `mouse-pointer-2` | NSCursor.arrow | sistem | Sembol değil, imleç. | 1 durum frame'i |
| Sidebar genişlik tutamacı imleci | `move-horizontal` | NSCursor.resizeLeftRight | sistem | Sembol değil, imleç. | 1 durum frame'i |

## Özel semboller (Assets'e eklenecek)

- `link.slash`: `link` şablonundan türetilen `.symbolset` (eğik çizgi sol üst → sağ alt, kalınlık = glif çizgisi, iki yanda boşluk; `bell.slash` / `wifi.slash` gibi). Oranlar `skeleton/link-slash@2x.png` panosunda; şablon SF Symbols uygulamasından dışa aktarılınca tasarım oturumu eğik çizgiyi ekler ve `actool` ile doğrular. O zamana kadar iskelet `LinkSlashSymbol` (kodda bileşim) ile çizer. DESIGN.md §4, 2026-10-13.
- Motor glifleri `engine.webkit`, `engine.chromium`, `engine.firefox`: pen.dev `Engine Glyphs` frame'i (16×16 ızgara, 2 px band); geometri `specs/ViewportCard.json` › Header › Engine ve `specs/DevicePicker.json` › EngIcon (`viewBox` 0 0 16 16). Kart başlığı ve cihaz seçici aynı glifi kullanır.

## Açık sorular

- (yok)
