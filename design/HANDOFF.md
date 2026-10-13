# Tasarım oturumu — güncel durum

> Bu dosya **üzerine yazılır**; yalnızca tasarım oturumu yazar. Tarihçe: `notlar/`. Kod oturumu salt okur.
> Son güncelleme: 2026-10-13

## Kod oturumu için: nereden başla

Tasarım M3 uygulamasına hazır. Okuma sırası:

1. `design/KOD-OTURUMU-ISLERI.md` — sana düşen işler; **§12 uygulama sırası**, sonra **§13 yeni haller**.
2. `DESIGN.md` §3 (ekranlar + etkileşim tabloları), §4 (kararlar), §6 (token'lar, bileşen → SwiftUI tablosu, pencere chrome'u yerleşimi).
3. `design/tokens/` — `DesignTokens.swift` (kopyala, elle düzenleme), `viewportix.tokens.json`.
4. `design/exports/*.png` — her frame'in 2x görüntüsü. Ölçü ve durumlar: `chrome-spec@2x.png`, `card-states@2x.png`, `tab-states-overflow-menu@2x.png`, `sidebar-states@2x.png`, `toast-states@2x.png`, `card-actions@2x.png`, `design-system-tokens@2x.png`.
5. `design/viewportix.pen` yalnızca pen.dev MCP ile; ana kopyalar 00b bölümünde.

Dışa aktarım adları: `window-project-*` (proje penceresi halleri), `window-home-*` (giriş), `devpanel-*-calm` (M5 paneller), `settings-*`, `layout-*`, `*-options` ve `*-pro` dosyaları **arşiv/keşif** (uygulama için değil).

## Şu an neredeyiz

- Ekranlar: giriş (liste, ızgara, boş, bağlam menüsü, kaldır alt menüsü, ayarlar paneli), proje penceresi (ana, sidebar kapalı, 8 cihaz, +N menüsü, zoom menüsü, ikon çubuklar + tooltip, motor tooltip, cihaz seçici, ekran görüntüsü seçici, URL son 5, canvas boş, ray gizli), ayarlar paneli (Genel, Cihazlar, MCP, Hesap), geliştirici paneli (Farklar, Senkron, Fark yok).
- Bileşenler (00b): `Viewport/Card`, `Viewport/HoverStrip`, `Window/Toast`, `Sidebar/Row`, `Toolbar/Button`, `Toolbar/DeviceTab`, `Toolbar/ZoomControl`, `Home/ProjectCard`, `Home/TemplateChip`, `Home/URLBox`, `Device/Picker`, chrome: `Sidebar/Header`, `Window/CollapsedHeader`, `Window/DeviceStrip`, `Window/BottomBar`, `Window/Rail`, `Window/RailHandle`, `Window/Tooltip` (2026-10-13). Tüm pencere frame'leri instance kullanır.
- Token'lar: renk (koyu; açık değerler ileride), köşe, aralık, yazı, çizgi, boyut (sidebar 240, ray 44, panel 340 / 320).
- Son kararlar (2026-10-11): Cihazlar sekmesi iki satırlı liste, ray gizliyken tutamaç, sidebar 240, boş URL ipucu, medya duraklatma varsayılan açık (10-10).

## Açık tasarım işleri

Yok (2026-10-13). MVP ve M3 kapsamı çizildi, onaylandı ve koda aktarıldı (`KOD-OTURUMU-ISLERI.md` §12 iskelet, §13 yeni haller).

**Kilometre taşıyla gelecekler:** lisans/takım akışı (iş modeli), MCP istemci onayı (M7), güncelleme bildirimi (dağıtım), Farklar paneli yükleniyor/boş halleri (M5), Chromium canlı / Firefox snapshot kart halleri (M4/M6).
**İleride:** Icon Composer (B6), açık tema, inspector, tam yükseklik modu, çoklu seçim. **Kullanıcıda:** `viewportix.lib.pen` dönüşümü.

## Sürmekte olan iş: aktarım paketi

Plan ve ilerleme: `design/handoff/PLAN.md` ([[PLAN]]). Aşama 0–2 bitti; 3 (bileşen spec'leri) kod oturumunun `BottomBar` denemesini bekliyor (`KOD-OTURUMU-ISLERI.md` §14); 5 (ikon eşleme), 4 (CHK, hepsi PASS), 7 (etkileşim id'leri, 80 satır) ve 6 (örnek sayfa) bitti; 8 (parite) kod oturumunun ilk ekranını, 3'ün kabulü `BottomBar` denemesini, 9 (iskelet denemesi; typecheck temiz, ölçüler tutuyor) kod oturumunun değerlendirmesini bekliyor. İkon boyutu kararı verildi (SF = Lucide × 0.875). Bekleyen: `link.slash` asset'i — kullanıcı SF Symbols uygulamasından `link` şablonunu dışa aktarınca tasarım oturumu eğik çizgiyi ekler. Birden çok oturuma yayılır; yeni oturum önce o dosyayı okur ve ilk tamamlanmamış aşamadan devam eder.

## Oturum başında oku

- `docs/HANDOFF.md` ve `docs/tasarim-istekleri.md`: son işlenenden sonraki girdileri işle.
- `design/handoff/PLAN.md`: aktarım paketi ilerlemesi.
- Son işlenen: "Görünüm menüsünde Arka Plandaki Viewport'larda Medyayı Duraklat" (2026-10-10), 12 girdi.

## Kurallar

- Yazma alanı: yalnızca `DESIGN.md` ve `design/`. Kod oturumunun işleri `design/KOD-OTURUMU-ISLERI.md`.
- `.pen` dosyalarına yalnızca pen.dev MCP ile eriş.
- Notlara kanıt yaz (dosya yolu, commit, ekran görüntüsü).
