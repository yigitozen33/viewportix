# Bileşen spec'leri (üretilir, elle düzenlenmez)

Kaynak: `design/viewportix.pen`, döküm 2026-10-13. Üretim: `dump-specs.js` → `save_dump.py` → `build_specs.py`.

Her `<SwiftName>.json`: `tree` ana kopyanın katman ağacı (layout: eksen + `HStack`/`VStack`, gap, padding [üst, sağ, alt, sol], hizalama; boyut `w`/`h` = sayı (sabit) · `fill` · `fit`, `px` çözülmüş ölçü), `tokens` pen adı → `DesignTokens` üyesi, `states` durum frame'lerinden okunan override'lar (`samples[].overrides[].node` ana kopyadaki katman yolu; `companions` o durum için yanına çizilen parçalar), `extra` bileşene ait ama ayrı çizilmiş parçalar, `onScreens` ekran frame'lerinde görülen farklı görünümler (veri ve boyut farkı sayılmaz; çizili bir duruma eşitse `sameAsState`), `rawValues` token dışı renk/yazı değerleri, `rawNumbers` token dışı ölçüler (eşit token varsa `sameAsToken`).

Değerler pen.dev'deki gibi: `$surface/card` token, `#2D2926` ya da `6` ham değer. `hidden: true` ana kopyada gizli, bir durumda görünür olan katman.

| pen.dev | SwiftUI | Boyut | Durum | Ham renk/yazı | Ham ölçü |
|---|---|---|---|---|---|
| `Viewport/Card` | [`ViewportCard`](ViewportCard.json) | 230×296 | 18 | 9 | 132 |
| `Viewport/HoverStrip` | [`ViewportHoverStrip`](ViewportHoverStrip.json) | 88×28 | 1 | 0 | 4 |
| `Window/Toast` | [`ToastCapsule`](ToastCapsule.json) | 306×36 | 7 | 0 | 4 |
| `Sidebar/Row` | [`SidebarRow`](SidebarRow.json) | 196×30 | 8 | 1 | 23 |
| `Toolbar/Button` | [`ChromeButton`](ChromeButton.json) | 73×27 | 2 | 0 | 8 |
| `Toolbar/DeviceTab` | [`DeviceTab`](DeviceTab.json) | 95×27 | 8 | 0 | 6 |
| `Toolbar/ZoomControl` | [`ZoomControl`](ZoomControl.json) | 72×33 | 0 | 0 | 10 |
| `Home/ProjectCard` | [`ProjectCard`](ProjectCard.json) | 236×195 | 6 | 12 | 19 |
| `Home/TemplateChip` | [`TemplateChip`](TemplateChip.json) | 115×31 | 2 | 0 | 0 |
| `Home/URLBox` | [`URLBox`](URLBox.json) | 560×47 | 3 | 0 | 0 |
| `Device/Picker` | [`DevicePicker`](DevicePicker.json) | 660×345 | 0 | 7 | 115 |
| `Sidebar/Header` | [`SidebarHeader`](SidebarHeader.json) | 216×110 | 4 | 3 | 14 |
| `Window/BottomBar` | [`BottomBar`](BottomBar.json) | 210×49 | 4 | 0 | 11 |
| `Window/DeviceStrip` | [`DeviceStrip`](DeviceStrip.json) | 370×35 | 4 | 2 | 65 |
| `Window/Rail` | [`InspectorRail`](InspectorRail.json) | 44×900 | 5 | 0 | 4 |
| `Window/CollapsedHeader` | [`CollapsedSidebarHeader`](CollapsedSidebarHeader.json) | 396×38 | 1 | 3 | 10 |
| `Window/RailHandle` | [`RailHandle`](RailHandle.json) | 24×56 | 1 | 0 | 5 |
| `Window/Tooltip` | [`ChromeTooltip`](ChromeTooltip.json) | 78×33 | 7 | 0 | 2 |

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
| `ProjectCard` | normal, hover (`line/strong` + ⋯), draft, sağ tık hedefi (gök kenar + ⋯), dosya bulunamadı | Normal, Dosya bulunamadı (taşındı / silindi), Normal · ⋯ gizli, Hover · kenar line/strong, ⋯ belirir, Taslak · rozet, ⋯ gizli, Sağ tık hedefi · gök kenar, ⋯ görünür | 4 |
| `TemplateChip` | normal, selected | Normal, Seçili · sarı kenar + parlak zemin | 0 |
| `URLBox` | empty, filled, invalid (Aç hep sarı) | Boş · Aç hep sarı (boşken tık alana odaklanır), Dolu · yapıştırınca https tamamlanır, Geçersiz · mercan kenar + açıklama | 0 |
| `DevicePicker` | popover | — | 0 |
| `SidebarHeader` | URL dolu, odak (+ Son 5 menüsü), boş | Dolu, Odak, Boş, URL alanı (216) | 1 |
| `BottomBar` | syncOn, syncOff; düğme hover / basılı / menü açık; tooltip (400 ms) | Senkron açık, Senkron kapalı, Hover + tooltip, Menü açık (zoom) | 1 |
| `DeviceStrip` | sekmeler (slot), boş (yalnız "+ Cihaz"), taşma (‹ › + "+N" çipi) | 3 cihaz, Boş, gruplu, Taşma (8 cihaz) | 1 |
| `InspectorRail` | öğe: default, hover, active, badge; ray gizliyken `RailHandle` | Varsayılan, Rozet, Hover (Cihazlar), Aktif (Farklar açık), tooltip (ray öğesi) | 6 |
| `CollapsedSidebarHeader` | sidebar kapalıyken canvas sol üstünde (16, 16) | Sidebar kapalı · CollapsedHeader | 0 |
| `RailHandle` | ray gizliyken sağ kenarda; badge (Farklar bulgusu), hover tooltip | Gizli · tutamaç | 0 |
| `ChromeTooltip` | ok aşağıda (varsayılan) / ok yok (yan tooltip); kısayol isteğe bağlı; hedefe 8 px, 400 ms gecikme | Engine Tooltip, Hover + tooltip, Gizli · tutamaç, tooltip (ray öğesi), Sayfa satırı + tooltip, Sekme (en çok 140 px), senkron kurulamıyor (‖) | 0 |

## Token dışı renk ve yazı değerleri

CHK-1 ile aynı kural (aşama 4). `sameAsToken` dolu olanlar token'a bağlanabilir; boş olanlar bilinçli ham değer mi, karar gerekir.

| Bileşen | Değer | Özellik | Eşit token | Adet | İlk katman |
|---|---|---|---|---|---|
| `ViewportCard` | `#FAF8F5` | `fill` | — | 1 | Viewport/Card › Page |
| `ViewportCard` | `#E6E1DA` | `fill` | — | 1 | Viewport/Card › Page › Image |
| `ViewportCard` | `#1D1B19` | `fill` | — | 1 | Viewport/Card › Page › Product |
| `ViewportCard` | `#6E6760` | `fill` | — | 1 | Viewport/Card › Page › Price |
| `ViewportCard` | `#BDB8B1` | `fill` | — | 1 | Viewport/Card [snapshot] › Viewport/Card › Page |
| `ViewportCard` | `#00000066` | `effect.color` | — | 3 | Viewport/Card [Başlıkta sağ tık] › Card Context Menu |
| `ViewportCard` | `#000000AA` | `effect.color` | — | 1 | Viewport/Card (ekranda) |
| `SidebarRow` | `#00000080` | `effect.color` | — | 1 | Sidebar/Row [Sürükle-bırak] |
| `ProjectCard` | `#FAF8F5` | `fill` | — | 4 | Home/ProjectCard › Thumb › MiniCard |
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
| `DeviceStrip` | `#2D292600` | `fill.colors.color` | — | 1 | Window/DeviceStrip [Taşma (8 cihaz)] › Tabs › Scroll Window › Fade |
| `DeviceStrip` | `#2D2926` | `fill.colors.color` | `surface/header` | 1 | Window/DeviceStrip [Taşma (8 cihaz)] › Tabs › Scroll Window › Fade |
| `CollapsedSidebarHeader` | `#FF5F57` | `fill` | — | 1 | Window/CollapsedHeader › Traffic Lights › Light |
| `CollapsedSidebarHeader` | `#FEBC2E` | `fill` | — | 1 | Window/CollapsedHeader › Traffic Lights › Light |
| `CollapsedSidebarHeader` | `#28C840` | `fill` | — | 1 | Window/CollapsedHeader › Traffic Lights › Light |

## Açık sorular

- (yok)
