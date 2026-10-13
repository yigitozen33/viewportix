# Bileşen spec'leri (üretilir, elle düzenlenmez)

Kaynak: `design/viewportix.pen`, döküm 2026-10-13. Üretim: `dump-specs.js` → `save_dump.py` → `build_specs.py`.

Her `<SwiftName>.json`: `tree` ana kopyanın katman ağacı (layout: eksen + `HStack`/`VStack`, gap, padding [üst, sağ, alt, sol], hizalama; boyut `w`/`h` = sayı (sabit) · `fill` · `fit`, `px` çözülmüş ölçü), `tokens` pen adı → `DesignTokens` üyesi, `states` durum frame'lerinden okunan override'lar (`samples[].overrides[].node` ana kopyadaki katman yolu; `companions` o durum için yanına çizilen parçalar), `extra` bileşene ait ama ayrı çizilmiş parçalar, `onScreens` ekran frame'lerinde görülen farklı görünümler (veri ve boyut farkı sayılmaz; çizili bir duruma eşitse `sameAsState`), `rawValues` token dışı renk/yazı değerleri, `rawNumbers` token dışı ölçüler (eşit token varsa `sameAsToken`).

Değerler pen.dev'deki gibi: `$surface/card` token, `#2D2926` ya da `6` ham değer. `hidden: true` ana kopyada gizli, bir durumda görünür olan katman.

| pen.dev | SwiftUI | Boyut | Durum | Ham renk/yazı | Ham ölçü |
|---|---|---|---|---|---|
| `Viewport/Card` | [`ViewportCard`](ViewportCard.json) | 230×296 | 18 | 53 | 137 |
| `Viewport/HoverStrip` | [`ViewportHoverStrip`](ViewportHoverStrip.json) | 88×28 | 1 | 0 | 4 |
| `Window/Toast` | [`ToastCapsule`](ToastCapsule.json) | 306×36 | 7 | 2 | 9 |
| `Sidebar/Row` | [`SidebarRow`](SidebarRow.json) | 196×30 | 8 | 4 | 28 |
| `Toolbar/Button` | [`ChromeButton`](ChromeButton.json) | 73×27 | 2 | 0 | 8 |
| `Toolbar/DeviceTab` | [`DeviceTab`](DeviceTab.json) | 95×27 | 8 | 2 | 11 |
| `Toolbar/ZoomControl` | [`ZoomControl`](ZoomControl.json) | 72×33 | 0 | 0 | 10 |
| `Home/ProjectCard` | [`ProjectCard`](ProjectCard.json) | 236×195 | 2 | 16 | 19 |
| `Home/TemplateChip` | [`TemplateChip`](TemplateChip.json) | 115×31 | 0 | 0 | 0 |
| `Home/URLBox` | [`URLBox`](URLBox.json) | 560×47 | 0 | 0 | 0 |
| `Device/Picker` | [`DevicePicker`](DevicePicker.json) | 660×345 | 0 | 7 | 115 |
| `Sidebar/Header` | [`SidebarHeader`](SidebarHeader.json) | 216×110 | 4 | 4 | 14 |
| `Window/BottomBar` | [`BottomBar`](BottomBar.json) | 210×49 | 4 | 2 | 16 |
| `Window/DeviceStrip` | [`DeviceStrip`](DeviceStrip.json) | 370×35 | 4 | 15 | 65 |
| `Window/Rail` | [`InspectorRail`](InspectorRail.json) | 44×900 | 5 | 8 | 14 |
| `Window/CollapsedHeader` | [`CollapsedSidebarHeader`](CollapsedSidebarHeader.json) | 396×38 | 1 | 4 | 10 |
| `Window/RailHandle` | [`RailHandle`](RailHandle.json) | 24×56 | 1 | 2 | 10 |

## Durum kapsamı

§6 tablosundaki durumlar ile durum frame'lerinde çizili olanlar yan yana. "Ekranda adsız" = ekran frame'lerinde görülen ama çizili bir duruma eşlenemeyen görünüm sayısı (`onScreens[].sameAsState: null`).

| SwiftUI | §6 durumları | Çizili durumlar | Ekranda adsız |
|---|---|---|---|
| `ViewportCard` | `ViewportCardState`: default, leader, selected, syncMissed, snapshot, loading (selected lider ile birlikte, ayrı halka) | default, leader, selected, selected + leader, syncMissed, snapshot, loading, Engine Tooltip, Senkron kapalı, Senkron kapalı · hover, Başlıkta sağ tık, Boyutu düzenle (popover), Kart kamerası, Ağ hatası, Sertifika, localhost kapalı, Adres hatalı, senkron kurulamıyor (‖) | 3 |
| `ViewportHoverStrip` | yalnız hover | Senkron kapalı · hover | 1 |
| `ToastCapsule` | menü/tooltip açıkken gizli | İlerleme, Başarı, Kısmi hata, Hata, hepsi aynı hatada, tek kapsül kuralı · Geri al, senkron kurulamıyor · kapsül | 1 |
| `SidebarRow` | default, hover, selected, editing, dragging | Hover, selected (açık sayfa), + Ekle satırı, Sürükle-bırak, Bu sayfayı ekle, Sidebar · Sayfa sağ tık menüsü, klavye odağı (focus ring), Sayfa satırı + tooltip | 1 |
| `ChromeButton` | ikon + etiket, ikon-only + tooltip | + Cihaz (şeritte), klavye odağı (focus ring) | 2 |
| `DeviceTab` | normal, leader, syncMissed, loading, snapshot | normal, loading, syncMissed, leader, snapshot, yükleme hatası (sekmede), klavye odağı (focus ring), Sekme (en çok 140 px) | 0 |
| `ZoomControl` | yüzde + ▲▼ | — | 0 |
| `ProjectCard` | normal, hover, draft | Normal, Dosya bulunamadı (taşındı / silindi) | 4 |
| `TemplateChip` | normal, selected | — | 1 |
| `URLBox` | empty, filled, invalid | — | 0 |
| `DevicePicker` | popover | — | 0 |
| `SidebarHeader` | URL dolu, odak (+ Son 5 menüsü), boş | Dolu, Odak, Boş, URL alanı (216) | 1 |
| `BottomBar` | syncOn, syncOff; düğme hover / basılı / menü açık; tooltip (400 ms) | Senkron açık, Senkron kapalı, Hover + tooltip, Menü açık (zoom) | 1 |
| `DeviceStrip` | sekmeler (slot), boş (yalnız "+ Cihaz"), taşma (‹ › + "+N" çipi) | 3 cihaz, Boş, gruplu, Taşma (8 cihaz) | 1 |
| `InspectorRail` | öğe: default, hover, active, badge; ray gizliyken `RailHandle` | Varsayılan, Rozet, Hover (Cihazlar), Aktif (Farklar açık), tooltip (ray öğesi) | 6 |
| `CollapsedSidebarHeader` | sidebar kapalıyken canvas sol üstünde (16, 16) | Sidebar kapalı · CollapsedHeader | 0 |
| `RailHandle` | ray gizliyken sağ kenarda; badge (Farklar bulgusu), hover tooltip | Gizli · tutamaç | 0 |

## Token dışı renk ve yazı değerleri

CHK-1 ile aynı kural (aşama 4). `sameAsToken` dolu olanlar token'a bağlanabilir; boş olanlar bilinçli ham değer mi, karar gerekir.

| Bileşen | Değer | Özellik | Eşit token | Adet | İlk katman |
|---|---|---|---|---|---|
| `ViewportCard` | `#FAF8F5` | `fill` | — | 1 | Viewport/Card › Page |
| `ViewportCard` | `#E6E1DA` | `fill` | — | 1 | Viewport/Card › Page › Image |
| `ViewportCard` | `#1D1B19` | `fill` | — | 1 | Viewport/Card › Page › Product |
| `ViewportCard` | `#6E6760` | `fill` | — | 1 | Viewport/Card › Page › Price |
| `ViewportCard` | `#161412` | `fill` | `canvas` | 1 | Viewport/Card › Page › SnapshotPill |
| `ViewportCard` | `#F4EFE9` | `fill` | `ink/primary` | 1 | Viewport/Card › Page › SnapshotPill › SnapshotText |
| `ViewportCard` | `#BDB8B1` | `fill` | — | 1 | Viewport/Card [snapshot] › Viewport/Card › Page |
| `ViewportCard` | `12` | `fontSize` | `font/label` | 13 | Viewport/Card [Engine Tooltip] › Tooltip › Tooltip Body › TipText |
| `ViewportCard` | `11` | `fontSize` | `font/caption` | 13 | Viewport/Card [Engine Tooltip] › Tooltip › Tooltip Body › TipSub |
| `ViewportCard` | `#00000066` | `effect.color` | — | 3 | Viewport/Card [Başlıkta sağ tık] › Card Context Menu |
| `ViewportCard` | `10` | `fontSize` | `font/micro` | 12 | Viewport/Card [Boyutu düzenle (popover)] › Size Popover › Field Ad › FL |
| `ViewportCard` | `13` | `fontSize` | `font/body` | 4 | Viewport/Card [Ağ hatası] › Error › text |
| `ViewportCard` | `#000000AA` | `effect.color` | — | 1 | Viewport/Card (ekranda) |
| `ToastCapsule` | `12` | `fontSize` | `font/label` | 1 | Window/Toast [senkron kurulamıyor · kapsül] › Tooltip › Tooltip Body › TipText |
| `ToastCapsule` | `11` | `fontSize` | `font/caption` | 1 | Window/Toast [senkron kurulamıyor · kapsül] › Tooltip › Tooltip Body › TipKey |
| `SidebarRow` | `#00000080` | `effect.color` | — | 1 | Sidebar/Row [Sürükle-bırak] |
| `SidebarRow` | `10` | `fontSize` | `font/micro` | 1 | Sidebar/Row [Sidebar · Sayfa sağ tık menüsü] › Section SAYFALAR › Title |
| `SidebarRow` | `12` | `fontSize` | `font/label` | 1 | Sidebar/Row [Sayfa satırı + tooltip] › Tooltip › Tooltip Body › TipText |
| `SidebarRow` | `11` | `fontSize` | `font/caption` | 1 | Sidebar/Row [Sayfa satırı + tooltip] › Tooltip › Tooltip Body › TipKey |
| `DeviceTab` | `12` | `fontSize` | `font/label` | 1 | Toolbar/DeviceTab [Sekme (en çok 140 px)] › Tooltip › Tooltip Body › TipText |
| `DeviceTab` | `11` | `fontSize` | `font/caption` | 1 | Toolbar/DeviceTab [Sekme (en çok 140 px)] › Tooltip › Tooltip Body › TipKey |
| `ProjectCard` | `#FAF8F5` | `fill` | — | 4 | Home/ProjectCard › Thumb › MiniCard |
| `ProjectCard` | `#2D2926` | `fill` | `surface/header` | 4 | Home/ProjectCard › Thumb › MiniCard › MiniHeader |
| `ProjectCard` | `#E6E1DA` | `fill` | — | 4 | Home/ProjectCard › Thumb › MiniCard › MiniImg |
| `ProjectCard` | `#C8553D` | `fill` | — | 1 | Home/ProjectCard (ekranda) › Home/ProjectCard › Body › Text › NameRow › Favicon |
| `ProjectCard` | `#8A7968` | `fill` | — | 1 | Home/ProjectCard (ekranda) › Home/ProjectCard › Body › Text › NameRow › Favicon |
| `ProjectCard` | `#3D7FC8` | `fill` | — | 2 | Home/ProjectCard (ekranda) › Home/ProjectCard › Body › Text › NameRow › Favicon |
| `DevicePicker` | `#00000080` | `effect.color` | — | 1 | Device/Picker |
| `DevicePicker` | `#2D292600` | `fill.colors.color` | — | 3 | Device/Picker › Body › Group TELEFON › Scroll Window › Fade |
| `DevicePicker` | `#2D2926` | `fill.colors.color` | `surface/header` | 3 | Device/Picker › Body › Group TELEFON › Scroll Window › Fade |
| `SidebarHeader` | `#FF5F57` | `fill` | — | 1 | Sidebar/Header › Traffic Lights › Light |
| `SidebarHeader` | `#FEBC2E` | `fill` | — | 1 | Sidebar/Header › Traffic Lights › Light |
| `SidebarHeader` | `#28C840` | `fill` | — | 1 | Sidebar/Header › Traffic Lights › Light |
| `SidebarHeader` | `13` | `fontSize` | `font/body` | 1 | Sidebar/Header › URL Field › UrlText |
| `BottomBar` | `12` | `fontSize` | `font/label` | 1 | Window/BottomBar [Hover + tooltip] › Tooltip offset › Tooltip › Tooltip Body › TipText |
| `BottomBar` | `11` | `fontSize` | `font/caption` | 1 | Window/BottomBar [Hover + tooltip] › Tooltip offset › Tooltip › Tooltip Body › TipKey |
| `DeviceStrip` | `#2D292600` | `fill.colors.color` | — | 1 | Window/DeviceStrip [Taşma (8 cihaz)] › Tabs › Scroll Window › Fade |
| `DeviceStrip` | `#2D2926` | `fill.colors.color` | `surface/header` | 1 | Window/DeviceStrip [Taşma (8 cihaz)] › Tabs › Scroll Window › Fade |
| `DeviceStrip` | `12` | `fontSize` | `font/label` | 9 | Window/DeviceStrip [Taşma (8 cihaz)] › Tabs › Overflow Chip › MoreText |
| `DeviceStrip` | `10` | `fontSize` | `font/micro` | 1 | Window/DeviceStrip › Overflow Menu › Menu Header › HeaderText |
| `DeviceStrip` | `11` | `fontSize` | `font/caption` | 3 | Window/DeviceStrip › Overflow Menu › Menu Row Laptop › Text › Meta |
| `InspectorRail` | `#00000000` | `fill` | — | 4 | Window/Rail › Rail Diff |
| `InspectorRail` | `12` | `fontSize` | `font/label` | 2 | Window/Rail [tooltip (ray öğesi)] › Tooltip › Tooltip Body › TipText |
| `InspectorRail` | `11` | `fontSize` | `font/caption` | 2 | Window/Rail [tooltip (ray öğesi)] › Tooltip › Tooltip Body › TipKey |
| `CollapsedSidebarHeader` | `#FF5F57` | `fill` | — | 1 | Window/CollapsedHeader › Traffic Lights › Light |
| `CollapsedSidebarHeader` | `#FEBC2E` | `fill` | — | 1 | Window/CollapsedHeader › Traffic Lights › Light |
| `CollapsedSidebarHeader` | `#28C840` | `fill` | — | 1 | Window/CollapsedHeader › Traffic Lights › Light |
| `CollapsedSidebarHeader` | `13` | `fontSize` | `font/body` | 1 | Window/CollapsedHeader › URL Field › UrlText |
| `RailHandle` | `12` | `fontSize` | `font/label` | 1 | Window/RailHandle [Gizli · tutamaç] › Tooltip › Tooltip Body › TipText |
| `RailHandle` | `11` | `fontSize` | `font/caption` | 1 | Window/RailHandle [Gizli · tutamaç] › Tooltip › Tooltip Body › TipKey |

## Açık sorular

- (yok)
