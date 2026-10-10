# Tasarım oturumu — güncel durum

> Bu dosya **üzerine yazılır**; yalnızca tasarım oturumu yazar. Tarihçe: `notlar/`. Kod oturumu salt okur.
> Son güncelleme: 2026-10-11

## Kod oturumu için: nereden başla

Tasarım M3 uygulamasına hazır. Okuma sırası:

1. `design/KOD-OTURUMU-ISLERI.md` — sana düşen işler; **§12 uygulama sırası**.
2. `DESIGN.md` §3 (ekranlar + etkileşim tabloları), §4 (kararlar), §6 (token'lar, bileşen → SwiftUI tablosu, pencere chrome'u yerleşimi).
3. `design/tokens/` — `DesignTokens.swift` (kopyala, elle düzenleme), `viewportix.tokens.json`.
4. `design/exports/*.png` — her frame'in 2x görüntüsü. Ölçü ve durumlar: `chrome-spec@2x.png`, `card-states@2x.png`, `tab-states-overflow-menu@2x.png`, `sidebar-states@2x.png`, `toast-states@2x.png`, `card-actions@2x.png`, `design-system-tokens@2x.png`.
5. `design/viewportix.pen` yalnızca pen.dev MCP ile; ana kopyalar 00b bölümünde.

Dışa aktarım adları: `window-project-*` (proje penceresi halleri), `window-home-*` (giriş), `devpanel-*-calm` (M5 paneller), `settings-*`, `layout-*`, `*-options` ve `*-pro` dosyaları **arşiv/keşif** (uygulama için değil).

## Şu an neredeyiz

- Ekranlar: giriş (liste, ızgara, boş, bağlam menüsü, kaldır alt menüsü, ayarlar paneli), proje penceresi (ana, sidebar kapalı, 8 cihaz, +N menüsü, zoom menüsü, ikon çubuklar + tooltip, motor tooltip, cihaz seçici, ekran görüntüsü seçici, URL son 5, canvas boş, ray gizli), ayarlar paneli (Genel, Cihazlar, MCP, Hesap), geliştirici paneli (Farklar, Senkron, Fark yok).
- Bileşenler (00b): `Viewport/Card`, `Viewport/HoverStrip`, `Window/Toast`, `Sidebar/Row`, `Toolbar/Button`, `Toolbar/DeviceTab`, `Toolbar/ZoomControl`, `Home/ProjectCard`, `Home/TemplateChip`, `Home/URLBox`, `Device/Picker`, chrome: `Sidebar/Header`, `Window/CollapsedHeader`, `Window/DeviceStrip`, `Window/BottomBar`, `Window/Rail`, `Window/RailHandle`. Tüm pencere frame'leri instance kullanır.
- Token'lar: renk (koyu; açık değerler ileride), köşe, aralık, yazı, çizgi, boyut (sidebar 240, ray 44, panel 340 / 320).
- Son kararlar (2026-10-11): Cihazlar sekmesi iki satırlı liste, ray gizliyken tutamaç, sidebar 240, boş URL ipucu, medya duraklatma varsayılan açık (10-10).

## Açık tasarım işleri (M3'ün beklediği, sırayla)

2026-10-11: dördü de çizildi, kullanıcı onayı bekliyor (DESIGN.md §5 madde 12–16). Kod oturumu bunlara onaydan önce başlamasın.


1. Viewport kartında **sayfa yüklenemedi** halleri (ağ, sertifika, `localhost` kapalı).
2. **Kartı elle sürükleme** (sürükleme hali, hizalama çizgileri) ve **gruplama** (motor / cihaz türü, canvas'ta grup başlığı).
3. PLAN.md M3 "Sidebar'da viewport listesi ve gruplar": şerit mi, sidebar'da bölüm mü — kullanıcı kararı.
4. Sidebar genişlik tutamacı (hover, sürükleme, sınırlar), klavye odak halkası, giriş ekranında "aramada sonuç yok".

**İleride:** Icon Composer (B6), açık tema, inspector, tam yükseklik modu, M4/M6 motor seçici. **Kullanıcıda:** `viewportix.lib.pen` dönüşümü; pen.dev'de ⌘S ile kaydetme (diskteki `.pen` ilk commit'ten beri değişmedi).

## Oturum başında oku

- `docs/HANDOFF.md` ve `docs/tasarim-istekleri.md`: son işlenenden sonraki girdileri işle.
- Son işlenen: "Görünüm menüsünde Arka Plandaki Viewport'larda Medyayı Duraklat" (2026-10-10), 12 girdi.

## Kurallar

- Yazma alanı: yalnızca `DESIGN.md` ve `design/`. Kod oturumunun işleri `design/KOD-OTURUMU-ISLERI.md`.
- `.pen` dosyalarına yalnızca pen.dev MCP ile eriş.
- Notlara kanıt yaz (dosya yolu, commit, ekran görüntüsü).
