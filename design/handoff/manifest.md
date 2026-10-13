# Manifest (üretilir, elle düzenlenmez)

Kaynak: `design/viewportix.pen`, döküm 2026-10-13. Sözleşme: `README.md`.

## Bileşenler

| pen.dev | SwiftUI | nodeId | Boyut | Durumlar | Kullanıldığı frame sayısı |
|---|---|---|---|---|---|
| `Viewport/Card` | `ViewportCard` | `Ngw0t` | 230×296 | `ViewportCardState`: default, leader, selected, syncMissed, snapshot, loading (selected lider ile birlikte, ayrı halka) | 30 |
| `Viewport/HoverStrip` | `ViewportHoverStrip` | `TgJMN` | 88×28 | yalnız hover | 25 |
| `Window/Toast` | `ToastCapsule` | `t3Hr4` | 306×36 | menü/tooltip açıkken gizli | 10 |
| `Sidebar/Row` | `SidebarRow` | `UCIzS` | 196×30 | default, hover, selected, editing, dragging | 33 |
| `Toolbar/Button` | `ChromeButton` | `w629d9` | 73×27 | ikon + etiket, ikon-only + tooltip | 8 |
| `Toolbar/DeviceTab` | `DeviceTab` | `FpUpU` | 95×27 | normal, leader, syncMissed, loading, snapshot | 4 |
| `Toolbar/ZoomControl` | `ZoomControl` | `sSUik` | 72×33 | yüzde + ▲▼ | 0 |
| `Home/ProjectCard` | `ProjectCard` | `sACvk` | 236×195 | normal, hover (`line/strong` + ⋯), draft, sağ tık hedefi (gök kenar + ⋯), dosya bulunamadı | 6 |
| `Home/TemplateChip` | `TemplateChip` | `k9seN` | 115×31 | normal, selected | 7 |
| `Home/URLBox` | `URLBox` | `m9eWrA` | 560×47 | empty, filled, invalid (Aç hep sarı) | 7 |
| `Device/Picker` | `DevicePicker` | `G9E6ET` | 660×345 | popover | 1 |
| `Sidebar/Header` | `SidebarHeader` | `tzWBu` | 216×110 | URL dolu, odak (+ Son 5 menüsü), boş | 25 |
| `Window/BottomBar` | `BottomBar` | `I3EMY` | 210×49 | syncOn, syncOff; düğme hover / basılı / menü açık; tooltip (400 ms) | 26 |
| `Window/DeviceStrip` | `DeviceStrip` | `Z3xtg` | 370×35 | sekmeler (slot), boş (yalnız "+ Cihaz"), taşma (‹ › + "+N" çipi) | 26 |
| `Window/Rail` | `InspectorRail` | `O8YpHG` | 44×900 | öğe: default, hover, active, badge; ray gizliyken `RailHandle` | 26 |
| `Window/CollapsedHeader` | `CollapsedSidebarHeader` | `P0uqV` | 396×38 | sidebar kapalıyken canvas sol üstünde (16, 16) | 3 |
| `Window/RailHandle` | `RailHandle` | `vDAMf` | 24×56 | ray gizliyken sağ kenarda; badge (Farklar bulgusu), hover tooltip | 2 |
| `Window/Tooltip` | `ChromeTooltip` | `boSko` | 78×33 | ok aşağıda (varsayılan) / ok yok (yan tooltip); kısayol isteğe bağlı; hedefe 8 px, 400 ms gecikme | 5 |

## Ekranlar

| Frame | Bölüm | nodeId | Boyut | PNG | Bileşenler | Etkileşim (DESIGN.md §3) |
|---|---|---|---|---|---|---|
| Project Window | 02 · Proje penceresi | `vFVfv` | 1440×900 | `window-project-dark@2x.png` | Sidebar/Header, Sidebar/Row, Viewport/Card, Viewport/HoverStrip, Window/BottomBar, Window/DeviceStrip, Window/Rail, Window/Toast | PW-01…PW-05, STRIP-01…STRIP-12, CARD-01…CARD-12, SIDEBAR-01…SIDEBAR-08, BAR-01…BAR-07, RAIL-01…RAIL-05 |
| Project Window · Sidebar kapalı | 02 · Proje penceresi | `mle8a` | 1440×900 | `window-project-sidebar-collapsed@2x.png` | Viewport/Card, Viewport/HoverStrip, Window/BottomBar, Window/CollapsedHeader, Window/DeviceStrip, Window/Rail, Window/Toast | PW-01…PW-05, STRIP-01…STRIP-12, CARD-01…CARD-12, SIDEBAR-01…SIDEBAR-08, BAR-01…BAR-07, RAIL-01…RAIL-05 |
| Project Window · 8 cihaz | 02 · Proje penceresi | `SRvkj` | 1440×900 | `window-project-many-devices@2x.png` | Sidebar/Header, Sidebar/Row, Viewport/Card, Viewport/HoverStrip, Window/BottomBar, Window/DeviceStrip, Window/Rail, Window/Toast | PW-01…PW-05, STRIP-01…STRIP-12, CARD-01…CARD-12, SIDEBAR-01…SIDEBAR-08, BAR-01…BAR-07, RAIL-01…RAIL-05 |
| Project Window · 8 cihaz · menü açık | 03 · Menüler ve durumlar | `S9oTqZ` | 1440×900 | `window-project-overflow-menu-open@2x.png` | Sidebar/Header, Sidebar/Row, Viewport/Card, Viewport/HoverStrip, Window/BottomBar, Window/DeviceStrip, Window/Rail, Window/Toast | PW-01…PW-05, STRIP-01…STRIP-12, CARD-01…CARD-12, SIDEBAR-01…SIDEBAR-08, BAR-01…BAR-07, RAIL-01…RAIL-05 |
| Project Window · Zoom menüsü açık | 03 · Menüler ve durumlar | `Gcdye` | 1440×900 | `window-project-zoom-menu-open@2x.png` | Sidebar/Header, Sidebar/Row, Viewport/Card, Viewport/HoverStrip, Window/BottomBar, Window/DeviceStrip, Window/Rail | PW-01…PW-05, STRIP-01…STRIP-12, CARD-01…CARD-12, SIDEBAR-01…SIDEBAR-08, BAR-01…BAR-07, RAIL-01…RAIL-05 |
| Project Window · İkon çubuklar + tooltip | 03 · Menüler ve durumlar | `ZgWIQ` | 1440×900 | `window-project-icon-bars-tooltip@2x.png` | Viewport/Card, Viewport/HoverStrip, Window/BottomBar, Window/CollapsedHeader, Window/DeviceStrip, Window/Rail, Window/Tooltip | PW-01…PW-05, STRIP-01…STRIP-12, CARD-01…CARD-12, SIDEBAR-01…SIDEBAR-08, BAR-01…BAR-07, RAIL-01…RAIL-05 |
| Project Window · Motor tooltip | 03 · Menüler ve durumlar | `k1UnJv` | 1440×900 | `window-project-engine-tooltip@2x.png` | Sidebar/Header, Sidebar/Row, Viewport/Card, Viewport/HoverStrip, Window/BottomBar, Window/DeviceStrip, Window/Rail, Window/Tooltip | PW-01…PW-05, STRIP-01…STRIP-12, CARD-01…CARD-12, SIDEBAR-01…SIDEBAR-08, BAR-01…BAR-07, RAIL-01…RAIL-05 |
| Home Window | 01 · Giriş ekranı | `j633o` | 1040×700 | `window-home-dark@2x.png` | Home/ProjectCard, Home/TemplateChip, Home/URLBox, Sidebar/Row, Toolbar/Button | HOME-01…HOME-18 |
| Home Window · Liste | 01 · Giriş ekranı | `SkRUV` | 1040×700 | `window-home-list@2x.png` | Home/TemplateChip, Home/URLBox, Sidebar/Row, Toolbar/Button | HOME-01…HOME-18 |
| Home Window · Boş durum | 01 · Giriş ekranı | `E8Inyr` | 1040×700 | `window-home-empty@2x.png` | Home/TemplateChip, Home/URLBox, Sidebar/Row, Toolbar/Button | HOME-01…HOME-18 |
| Home Window · Bağlam menüsü | 01 · Giriş ekranı | `E7EP1n` | 1040×700 | `window-home-context-menu@2x.png` | Home/ProjectCard, Home/TemplateChip, Home/URLBox, Sidebar/Row, Toolbar/Button | HOME-01…HOME-18 |
| Home Window · Kaldır alt menüsü | 01 · Giriş ekranı | `QzPin` | 1040×700 | `window-home-remove-submenu@2x.png` | Home/ProjectCard, Home/TemplateChip, Home/URLBox, Sidebar/Row, Toolbar/Button | HOME-01…HOME-18 |
| Project Window · Cihaz seçici (birleşik) | 03 · Menüler ve durumlar | `IMusa` | 1440×900 | `window-project-device-picker@2x.png` | Device/Picker, Sidebar/Header, Sidebar/Row, Viewport/Card, Viewport/HoverStrip, Window/BottomBar, Window/DeviceStrip, Window/Rail | PW-01…PW-05, STRIP-01…STRIP-12, CARD-01…CARD-12, SIDEBAR-01…SIDEBAR-08, BAR-01…BAR-07, RAIL-01…RAIL-05 |
| Dev Panel · Farklar (sakin) | 04 · Geliştirici paneli | `Dr4hZ` | 1440×900 | `devpanel-diff-calm@2x.png` | Sidebar/Header, Sidebar/Row, Viewport/Card, Viewport/HoverStrip, Window/BottomBar, Window/DeviceStrip, Window/Rail | DEV-01…DEV-08, RAIL-01…RAIL-05 |
| Dev Panel · Senkron (sakin) | 04 · Geliştirici paneli | `VsnVs` | 1440×900 | `devpanel-synclog-calm@2x.png` | Sidebar/Header, Sidebar/Row, Viewport/Card, Viewport/HoverStrip, Window/BottomBar, Window/DeviceStrip, Window/Rail | DEV-01…DEV-08, RAIL-01…RAIL-05 |
| Dev Panel · Fark yok (sakin) | 04 · Geliştirici paneli | `lfJ3a` | 1440×900 | `devpanel-diff-zero-calm@2x.png` | Sidebar/Header, Sidebar/Row, Viewport/Card, Viewport/HoverStrip, Window/BottomBar, Window/DeviceStrip, Window/Rail | DEV-01…DEV-08, RAIL-01…RAIL-05 |
| Project Window · URL son 5 | 02 · Proje penceresi | `qm0vz` | 1440×900 | `window-project-url-recent@2x.png` | Sidebar/Header, Sidebar/Row, Viewport/Card, Viewport/HoverStrip, Window/BottomBar, Window/DeviceStrip, Window/Rail | PW-01…PW-05, STRIP-01…STRIP-12, CARD-01…CARD-12, SIDEBAR-01…SIDEBAR-08, BAR-01…BAR-07, RAIL-01…RAIL-05 |
| Project Window · Ekran görüntüsü menüsü | 03 · Menüler ve durumlar | `X5k7c` | 1440×900 | `window-project-screenshot-menu@2x.png` | Sidebar/Header, Sidebar/Row, Viewport/Card, Viewport/HoverStrip, Window/BottomBar, Window/DeviceStrip, Window/Rail | PW-01…PW-05, STRIP-01…STRIP-12, CARD-01…CARD-12, SIDEBAR-01…SIDEBAR-08, BAR-01…BAR-07, RAIL-01…RAIL-05 |
| Project Window · Ayarlar paneli | 02 · Proje penceresi | `T6iQ4` | 1440×900 | `window-project-settings-panel@2x.png` | Sidebar/Header, Sidebar/Row, Viewport/Card, Viewport/HoverStrip, Window/BottomBar, Window/DeviceStrip, Window/Rail | PW-01…PW-05, STRIP-01…STRIP-12, CARD-01…CARD-12, SIDEBAR-01…SIDEBAR-08, BAR-01…BAR-07, RAIL-01…RAIL-05, SETTINGS-01…SETTINGS-05 |
| Home Window · Ayarlar paneli | 01 · Giriş ekranı | `kp8Ek` | 1040×700 | `window-home-settings-panel@2x.png` | Home/ProjectCard, Home/TemplateChip, Home/URLBox, Sidebar/Row, Toolbar/Button | HOME-01…HOME-18, SETTINGS-01…SETTINGS-05 |
| Project Window · Canvas boş | 02 · Proje penceresi | `amtWl` | 1440×900 | `window-project-canvas-empty@2x.png` | Sidebar/Header, Sidebar/Row, Window/BottomBar, Window/DeviceStrip, Window/Rail | PW-01…PW-05, STRIP-01…STRIP-12, CARD-01…CARD-12, SIDEBAR-01…SIDEBAR-08, BAR-01…BAR-07, RAIL-01…RAIL-05 |
| Project Window · Ayarlar › Cihazlar | 02 · Proje penceresi | `dMDOK` | 1440×900 | `window-project-settings-devices@2x.png` | Sidebar/Header, Sidebar/Row, Viewport/Card, Viewport/HoverStrip, Window/BottomBar, Window/DeviceStrip, Window/Rail | PW-01…PW-05, STRIP-01…STRIP-12, CARD-01…CARD-12, SIDEBAR-01…SIDEBAR-08, BAR-01…BAR-07, RAIL-01…RAIL-05, SETTINGS-01…SETTINGS-05 |
| Project Window · Ayarlar › MCP | 02 · Proje penceresi | `R0VEg` | 1440×900 | `window-project-settings-mcp@2x.png` | Sidebar/Header, Sidebar/Row, Viewport/Card, Viewport/HoverStrip, Window/BottomBar, Window/DeviceStrip, Window/Rail | PW-01…PW-05, STRIP-01…STRIP-12, CARD-01…CARD-12, SIDEBAR-01…SIDEBAR-08, BAR-01…BAR-07, RAIL-01…RAIL-05, SETTINGS-01…SETTINGS-05 |
| Project Window · Ayarlar › Hesap | 02 · Proje penceresi | `P8hJd5` | 1440×900 | `window-project-settings-account@2x.png` | Sidebar/Header, Sidebar/Row, Viewport/Card, Viewport/HoverStrip, Window/BottomBar, Window/DeviceStrip, Window/Rail | PW-01…PW-05, STRIP-01…STRIP-12, CARD-01…CARD-12, SIDEBAR-01…SIDEBAR-08, BAR-01…BAR-07, RAIL-01…RAIL-05, SETTINGS-01…SETTINGS-05 |
| Project Window · Ray gizli | 02 · Proje penceresi | `O7JgxK` | 1440×900 | `window-project-rail-hidden@2x.png` | Sidebar/Header, Sidebar/Row, Viewport/Card, Viewport/HoverStrip, Window/BottomBar, Window/DeviceStrip, Window/RailHandle, Window/Toast | PW-01…PW-05, STRIP-01…STRIP-12, CARD-01…CARD-12, SIDEBAR-01…SIDEBAR-08, BAR-01…BAR-07, RAIL-01…RAIL-05 |
| Project Window · Kart sürükleniyor | 03 · Menüler ve durumlar | `q6obk` | 1440×900 | `window-project-dragging@2x.png` | Sidebar/Header, Sidebar/Row, Viewport/Card, Viewport/HoverStrip, Window/BottomBar, Window/DeviceStrip, Window/Rail | PW-01…PW-05, STRIP-01…STRIP-12, CARD-01…CARD-12, SIDEBAR-01…SIDEBAR-08, BAR-01…BAR-07, RAIL-01…RAIL-05 |
| Project Window · Gruplar (cihaz türü) | 03 · Menüler ve durumlar | `N1dkY` | 1440×900 | `window-project-groups@2x.png` | Sidebar/Header, Sidebar/Row, Viewport/Card, Viewport/HoverStrip, Window/BottomBar, Window/DeviceStrip, Window/Rail | PW-01…PW-05, STRIP-01…STRIP-12, CARD-01…CARD-12, SIDEBAR-01…SIDEBAR-08, BAR-01…BAR-07, RAIL-01…RAIL-05 |
| Project Window · Gruplar · katlanmış | 03 · Menüler ve durumlar | `B1aeP` | 1440×900 | `window-project-groups-collapsed@2x.png` | Sidebar/Header, Sidebar/Row, Viewport/Card, Viewport/HoverStrip, Window/BottomBar, Window/DeviceStrip, Window/Rail | PW-01…PW-05, STRIP-01…STRIP-12, CARD-01…CARD-12, SIDEBAR-01…SIDEBAR-08, BAR-01…BAR-07, RAIL-01…RAIL-05 |
| Project Window · Gruplar (motor, M4) | 03 · Menüler ve durumlar | `SlUcW` | 1440×900 | `window-project-groups-engine@2x.png` | Sidebar/Header, Sidebar/Row, Viewport/Card, Viewport/HoverStrip, Window/BottomBar, Window/DeviceStrip, Window/Rail | PW-01…PW-05, STRIP-01…STRIP-12, CARD-01…CARD-12, SIDEBAR-01…SIDEBAR-08, BAR-01…BAR-07, RAIL-01…RAIL-05 |
| Project Window · En küçük boyut (1024×640) | 02 · Proje penceresi | `hJrjk` | 1024×640 | `window-project-min-size@2x.png` | Sidebar/Header, Sidebar/Row, Viewport/Card, Viewport/HoverStrip, Window/BottomBar, Window/DeviceStrip, Window/Rail, Window/Toast | PW-01…PW-05, STRIP-01…STRIP-12, CARD-01…CARD-12, SIDEBAR-01…SIDEBAR-08, BAR-01…BAR-07, RAIL-01…RAIL-05 |
| Project Window · Tam ekran | 02 · Proje penceresi | `IVxFw` | 1440×900 | `window-project-fullscreen@2x.png` | Sidebar/Header, Sidebar/Row, Viewport/Card, Viewport/HoverStrip, Window/BottomBar, Window/DeviceStrip, Window/Rail, Window/Toast | PW-01…PW-05, STRIP-01…STRIP-12, CARD-01…CARD-12, SIDEBAR-01…SIDEBAR-08, BAR-01…BAR-07, RAIL-01…RAIL-05 |

## Durum ve spec frame'leri

| Frame | Bölüm | nodeId | PNG | Bileşenler |
|---|---|---|---|---|
| Viewport States | 05 · Bileşen durumları | `U1DEv` | `card-states@2x.png` | Viewport/Card |
| Tab States & Overflow Menu | 05 · Bileşen durumları | `pDYzq` | `tab-states-overflow-menu@2x.png` | Toolbar/Button, Toolbar/DeviceTab |
| Engine Tooltip | 05 · Bileşen durumları | `L9rkJ` | `card-engine-tooltip@2x.png` | Viewport/Card, Window/Tooltip |
| Engine Glyphs | 06 · İkon ve glifler | `M1DiUr` | `engine-glyphs@2x.png` |  |
| Sidebar States | 05 · Bileşen durumları | `p48xxG` | `sidebar-states@2x.png` | Sidebar/Row |
| App Icon · B variants | 06 · İkon ve glifler | `XsCo1` | `app-icon-B-variants@2x.png` |  |
| Selected Options | 05 · Bileşen durumları | `ioLB2` | `card-selected-options@2x.png` | Viewport/Card |
| Design System · Tokens | 00 · Tasarım sistemi | `JD8Q1` | `design-system-tokens@2x.png` |  |
| Card Actions | 05 · Bileşen durumları | `Cld0z` | `card-actions@2x.png` | Viewport/Card, Viewport/HoverStrip |
| Toast States | 05 · Bileşen durumları | `NzMCp` | `toast-states@2x.png` | Window/Toast |
| Sidebar · Sayfa sağ tık menüsü | 05 · Bileşen durumları | `xY8o9` | `sidebar-page-context-menu@2x.png` | Sidebar/Row |
| Shortcut Map · Menü çubuğu | 00 · Tasarım sistemi | `mV0xH` | `shortcut-map@2x.png` |  |
| Chrome Spec | 05 · Bileşen durumları | `JGcRx` | `chrome-spec@2x.png` | Sidebar/Header, Window/BottomBar, Window/CollapsedHeader, Window/DeviceStrip, Window/Rail, Window/RailHandle, Window/Tooltip |
| Card Load Errors | 05 · Bileşen durumları | `s3Atj` | `card-load-errors@2x.png` | Toolbar/DeviceTab, Viewport/Card, Window/Toast |
| Misc States | 05 · Bileşen durumları | `g5nQ0p` | `misc-states@2x.png` | Sidebar/Row, Toolbar/Button, Toolbar/DeviceTab |
| Home File Errors | 05 · Bileşen durumları | `BQurR` | `home-file-errors@2x.png` | Home/ProjectCard |
| Misc States 2 | 05 · Bileşen durumları | `hTxn0` | `misc-states-2@2x.png` | Sidebar/Header, Sidebar/Row, Toolbar/DeviceTab, Viewport/Card, Window/Rail, Window/Toast, Window/Tooltip |
| Home States | 05 · Bileşen durumları | `Q2jiv` | `home-states@2x.png` | Home/ProjectCard, Home/TemplateChip, Home/URLBox |

## Açık sorular

- yok
