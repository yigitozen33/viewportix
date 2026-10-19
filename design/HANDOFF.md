# Tasarım oturumu — güncel durum

> Bu dosya **üzerine yazılır**; yalnızca tasarım oturumu yazar. Tarihçe: `notlar/`. Kod oturumu salt okur.
> Son güncelleme: 2026-10-19 (M4 sonrası)

## Kod oturumu için: nereden başla

Tasarım M3 uygulamasına hazır. Okuma sırası:

1. `design/KOD-OTURUMU-ISLERI.md` — sana düşen işler; **§12 uygulama sırası**, sonra **§13 yeni haller**, **§15 eylem düğmeleri, hareket dili, uygulama içi AI, kaydetme ve uyarılar (2026-10-19)**, **§16 M4 sonrası: onboarding, motorlar, Chromium kart halleri, `<select>`, sayfa uyarıları, başlıkta motor adı**.
2. `DESIGN.md` §3 (ekranlar + etkileşim tabloları), §4 (kararlar), §6 (token'lar, bileşen → SwiftUI tablosu, pencere chrome'u yerleşimi).
3. `design/tokens/` — `DesignTokens.swift` (kopyala, elle düzenleme), `viewportix.tokens.json`.
4. `design/exports/*.png` — her frame'in 2x görüntüsü. Ölçü ve durumlar: `chrome-spec@2x.png`, `card-states@2x.png`, `tab-states-overflow-menu@2x.png`, `sidebar-states@2x.png`, `toast-states@2x.png`, `card-actions@2x.png`, `design-system-tokens@2x.png`.
5. `design/viewportix.pen` yalnızca pen.dev MCP ile; ana kopyalar 00b bölümünde.

Dışa aktarım adları: `window-project-*` (proje penceresi halleri), `window-home-*` (giriş), `devpanel-*-calm` (M5 paneller), `devpanel-*-ai-*` ve `window-project-agent*` (uygulama içi AI), `motion-spec` (hareket değerleri), `dialogs-save-alerts` (kaydetme penceresi ve uyarılar), `test-ai-*` ve `test-save-alerts` (**keşif, uygulama için değil**; silinecek), `settings-*`, `layout-*`, `*-options` ve `*-pro` dosyaları **arşiv/keşif** (uygulama için değil).

## Şu an neredeyiz

- Ekranlar: giriş (liste, ızgara, boş, bağlam menüsü, kaldır alt menüsü, ayarlar paneli), proje penceresi (ana, sidebar kapalı, 8 cihaz, +N menüsü, zoom menüsü, ikon çubuklar + tooltip, motor tooltip, cihaz seçici, ekran görüntüsü seçici, URL son 5, canvas boş, ray gizli), ayarlar paneli (Genel, Cihazlar, MCP, Hesap), geliştirici paneli (Farklar, Senkron, Fark yok).
- Bileşenler (00b): `Viewport/Card`, `Viewport/HoverStrip`, `Window/Toast`, `Sidebar/Row`, `Toolbar/Button`, `Toolbar/DeviceTab`, `Toolbar/ZoomControl`, `Home/ProjectCard`, `Home/TemplateChip`, `Home/URLBox`, `Device/Picker`, chrome: `Sidebar/Header`, `Window/CollapsedHeader`, `Window/DeviceStrip`, `Window/BottomBar`, `Window/Rail`, `Window/RailHandle`, `Window/Tooltip` (2026-10-13). Tüm pencere frame'leri instance kullanır.
- Token'lar: renk (koyu; açık değerler ileride), köşe, aralık, yazı, çizgi, boyut (sidebar 240, ray 44, panel 340 / 320).
- Son kararlar (2026-10-11): Cihazlar sekmesi iki satırlı liste, ray gizliyken tutamaç, sidebar 240, boş URL ipucu, medya duraklatma varsayılan açık (10-10).
- **Uygulama içi AI (2026-10-18 / 19, DESIGN.md §3.4 + §4):** A satır içi teşhis önce, B Ajanlar paneli MCP ile. Hareket dili K1 sarı · K2 üç viewport (`AI/Glyph`, 720 ms) · K3 bitince 2 sn sonra katlanır; K4 eylem düğmeleri kelime + kısayol (`Action/Primary`, `Action/Secondary`; eski "kelime düğmeler" superseded, Farklar / Senkron panelleri güncellendi, eylem satırı açılımın tam genişliğinde); K5 hareket önerileri (klavye canlanmaz, DEV-02 J / K anında; 40 ms kademe; bildirim yığını; tek eğri cubic-bezier(.23, 1, .32, 1)); K6 izin isteği üç satırlı liste. Temiz panolar 04 sırasında (`Dev Panel · Senkron · AI düşünüyor / seni bekliyor / sonuç`, `Dev Panel · Farklar · AI açıkla`, `Project Window · Ajanlar paneli`, `Project Window · Ajan sürüyor`) ve 05'te `Motion Spec`. Yeni kısayollar: Teşhis et D, Açıkla E, Farklara ekle ⌘⏎, Kapat esc, Durdur ⌘., izin 1 / 2 / 3 — çakışma görürsen `docs/tasarim-istekleri.md`'ye yaz. **Kaydetme ve uyarılar (2026-10-19):** K7 S2 bizim kaydet sayfası (aynı gün S1'den değişti); K8 karma: önce sorma (geri al, yerinde durum), dosya işleri NSAlert (+ hata kodu satırı), MCP onayı ve ajanlı çıkış bizim sayfa. HOME-08 taslak silme onayı kalktı; yeni PW-06…09. Temiz pano `Dialogs · Kaydet ve uyarılar` (05 sonu). Oynayan hâli `design/prototypes/animasyon-lab.html` (artifact https://claude.ai/artifact/AtcD2CbesE2taUdEqFKYHU; Nexus paketi yerelde `design/prototypes/vendor/`, git dışı). Mimari (MCP, model çağrısı, araç katmanı) kod oturumunun, PLAN.md'ye.

## Açık tasarım işleri

- **M4 sonrası (2026-10-19, `07 · MOTORLAR (M4)` sırası, y 8100):** `Project Window · Ayarlar › Motorlar`, `Onboarding · Motorlar` (K9 A, K10 uygulama indirir), `Card · Motor halleri` (Chrome bulunamadı ailesi; K12 a başlıkta gri motor adı; `Viewport/Card` › `EngineName`), `Select Menu · Chromium`, `Page Dialogs · alert confirm prompt` (K11 canvas altında kapsül + az sorma), `Setup Reminder · Kuruluma devam et` + iki pencere karesi (onboarding menüden değil, eksik kurulum oldukça şerit / sidebar kartıyla açılır; Flowventory mantığı). Kod işleri `KOD-OTURUMU-ISLERI.md` §16. **Kaynak paneli (2026-10-19):** `Resource Monitor · Kaynaklar` — alt çubuğun sağ kenarında çentik, tıkta Morph ile yüzen panel, kartlarda yük şeridi; kod işleri §17. Kod oturumunun yazdığı iki kare (`Action/Secondary · Haller`, `Kod kararları · 2026-10-19`) exports-map'e ve CHK'ye alındı; `Viewport/Card` değişince 42 PNG yeniden dışa aktarıldı.
- `Test · AI ·` ve `Test · Kaydet ve uyarılar` panoları (y 11800): kullanıcı temiz panolarla karşılaştıracak, sonra silinecek. Kanvastaki canlı önizlemeler (`browser` düğümleri, C ve D) `file://` yolları; başka makinede boş.
- Logo: `icon.json` koyu görünüm dolgusu (`extended-gray 0`) bilinçli mi, kullanıcıya soruldu.

Yok (2026-10-13). MVP ve M3 kapsamı çizildi, onaylandı ve koda aktarıldı (`KOD-OTURUMU-ISLERI.md` §12 iskelet, §13 yeni haller).

**Kilometre taşıyla gelecekler:** lisans/takım akışı (iş modeli), MCP istemci onayı (M7), güncelleme bildirimi (dağıtım), Farklar paneli yükleniyor/boş halleri (M5), Chromium canlı / Firefox snapshot kart halleri (M4/M6).
**İleride:** açık tema, inspector, tam yükseklik modu, çoklu seçim. **Kullanıcıda:** `viewportix.lib.pen` dönüşümü.

**Logo (2026-10-16):** `design/logo-dili.md` + `design/logo/` (betik, `Viewportix.icon` paketi, düz `.icns`, README logoları; `bash design/logo/make-logo.sh`). Kod oturumu: `.icon`'u Xcode asset kataloğuna al, README'ye `out/README-picture.html` parçasını ekle.

## Sürmekte olan iş: aktarım paketi

Plan ve ilerleme: `design/handoff/PLAN.md` ([[PLAN]]). Aşama 0–2 bitti; 3 (bileşen spec'leri) kod oturumunun `BottomBar` denemesini bekliyor (`KOD-OTURUMU-ISLERI.md` §14); 5 (ikon eşleme), 4 (CHK, hepsi PASS), 7 (etkileşim id'leri, 80 satır) ve 6 (örnek sayfa) bitti; 8 (parite) kod oturumunun ilk ekranını, 3'ün kabulü `BottomBar` denemesini, 9 (iskelet denemesi; typecheck temiz, ölçüler tutuyor) kod oturumunun değerlendirmesini bekliyor. İkon boyutu kararı verildi (SF = Lucide × 0.875). Özel semboller hazır: `link.slash` ve motor glifleri (`design/handoff/symbols/`, actool ile doğrulandı). Birden çok oturuma yayılır; yeni oturum önce o dosyayı okur ve ilk tamamlanmamış aşamadan devam eder.

## Oturum başında oku

- `docs/HANDOFF.md` ve `docs/tasarim-istekleri.md`: son işlenenden sonraki girdileri işle.
- `design/handoff/PLAN.md`: aktarım paketi ilerlemesi.
- Son işlenen: "Görünüm menüsünde Arka Plandaki Viewport'larda Medyayı Duraklat" (2026-10-10), 12 girdi.

## Kurallar

- Yazma alanı: yalnızca `DESIGN.md` ve `design/`. Kod oturumunun işleri `design/KOD-OTURUMU-ISLERI.md`.
- `.pen` dosyalarına yalnızca pen.dev MCP ile eriş.
- Notlara kanıt yaz (dosya yolu, commit, ekran görüntüsü).
