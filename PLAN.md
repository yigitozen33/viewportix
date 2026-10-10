# Viewportix — Plan

> Son güncelleme: 2026-10-06 · Durum: planlama tamamlandı, kodlama başlamadı

## 1. Vizyon

Tasarımcılar ve front-end geliştiriciler için native bir macOS uygulaması. Bir web sitesini birden fazla cihaz boyutunda, **gerçek tarayıcı motorlarında** (WebKit, Chromium, Gecko) yan yana gösterir; scroll, tıklama ve navigasyonu senkron tutar; motorlar arasındaki görsel farkları işaretler.

Slogan: **"Every width. Every engine."**

**Rakiplerden farkı:** Responsively, Polypane ve Sizzy Electron + Chromium tabanlıdır; "iPhone" görünümleri aslında Chrome'dur. Viewportix sayfayı her motorun kendisinde render eder.

**Dürüstlük sınırı:** "Gerçek motor" diyoruz, "gerçek cihaz" demiyoruz. macOS'taki WebKit, iOS Safari ile aynı motordur ama aynı ortam değildir (bkz. [5.4](#54-cihaz-emülasyonunun-sınırları)).

## 2. Kararlar

| Konu | Karar | Not |
|---|---|---|
| Platform | Yalnızca macOS 26+ | Şirkette herkes son sürümde. Eski sürümler ve Windows talep olursa |
| Dil / UI | Swift + SwiftUI, gerektiğinde AppKit | Canvas ve webview barındırma büyük ihtimalle AppKit |
| Hedef kitle | Tasarımcı ve geliştirici birlikte | Varsayılan arayüz sade; geliştirici araçları ayrı panelde |
| Yerleşim | Serbest canvas (zoom + pan) | MVP'de sade hali; hareket kuralları spike ile doğrulanacak, olmazsa ızgara |
| WebKit | WKWebView, canlı | MVP'nin tek motoru |
| Chromium | CDP, screencast ile canlı | Akıcılık spike ile doğrulanacak |
| Firefox | WebDriver BiDi, snapshot modu | Canlı etkileşim o aşamada araştırılacak |
| Senkron | Element tabanlı, motordan bağımsız protokol | Koordinat veya piksel tekrarı yok |
| Fark tespiti | DOM tabanlı diff | Piksel diff motorlar arasında çalışmaz |
| AI | MCP sunucusu (Blender modeli) | Kullanıcı kendi Claude Code / Claude Desktop'ından bağlanır. MVP sonrası |
| iOS Simulator | MVP dışı | Sonra: yalnızca "Simulator'da aç" butonu |
| Dağıtım | App Store dışı, önce şirket içi | Developer ID + notarization. İş modeli sonra |
| Lisans hijyeni | GPL'li bağımlılık yok | Açık kaynak / ücretli seçeneği açık kalsın |
| Arayüz tasarımı | Kullanıcı yapar | Görsel kararlar ona sorulur |

## 3. Mimari

### 3.1 Genel bakış

```
┌──────────────────────────────────────────────────────────┐
│ App (SwiftUI)        toolbar · URL çubuğu · paneller      │
├──────────────────────────────────────────────────────────┤
│ Canvas (AppKit)      zoom/pan · dizilim · viewport kartı  │
├──────────────────────────────────────────────────────────┤
│ Workspace            viewport listesi · lider · durum     │
├───────────────────────┬──────────────────────────────────┤
│ SyncCoordinator       │ DeviceCatalog                    │
│ olay yayını           │ cihaz preset'leri                │
├───────────────────────┴──────────────────────────────────┤
│ EngineSession protokolü                                  │
├──────────────┬──────────────────┬────────────────────────┤
│ WebKitEngine │ ChromiumEngine   │ FirefoxEngine          │
│ WKWebView    │ CDP (sonra)      │ BiDi (sonra)           │
└──────────────┴──────────────────┴────────────────────────┘
        ▲ her sayfaya aynı sync-agent.js enjekte edilir
```

Temel ilke: **Canvas, senkron ve ileride MCP, motorları yalnızca `EngineSession` üzerinden tanır.** Yeni motor eklemek bu protokolü uygulamak demektir.

### 3.2 Motor soyutlaması

```swift
enum EngineKind { case webKit, chromium, firefox }

struct EngineCapabilities {
    var isLive: Bool            // false ise snapshot modu (Firefox)
    var canEmulateDPR: Bool
    var canEmulateTouch: Bool
}

@MainActor
protocol EngineSession: AnyObject {
    var id: ViewportID { get }
    var kind: EngineKind { get }
    var engineVersion: String { get }              // "WebKit · Safari 26.1"
    var currentURL: URL? { get }
    var view: NSView { get }                       // canvas'a yerleşen canlı görünüm
    var eventHandler: ((EngineEvent) -> Void)? { get set }  // etkileşim, URL, başlık, yükleme

    func load(_ url: URL)
    func reload()
    func goBack()
    func goForward()
    func resize(to size: ViewportSize)
    func apply(_ event: SyncEvent) async -> ApplyResult    // .applied(yöntem) / .missed / .failed
}
```

M2'de uygulanan hali (`EngineCore/EngineSession.swift`). Ajan yükleri (`scroll` çapası, `click` hedefi) Swift tarafında opak `JSONValue`'dur; yalnızca ajan yorumlar. Görüntüleme motorla birlikte değişir: WebKit bir `NSView` verir, Chromium ve Firefox bir görüntü akışı (frame) verecek; o zaman `view` bir `ViewportSurface` enum'una (`.view(NSView)` / `.frames(...)`) dönüşecek. `screenshot` ve `capabilities` ihtiyaç doğunca (M3 screenshot, M4 Chromium) eklenecek.

Bu arayüz ileride MCP araçlarına birebir karşılık gelir: `navigate`, `click`, `scroll`, `read_dom`, `screenshot`, `list_viewports`, `get_engine_diff`.

### 3.3 Senkron protokolü

**Lider modeli.** Kullanıcının o an etkileşimde olduğu viewport (imlecin üstünde olduğu) liderdir. Yalnızca lider olay yayınlar, diğerleri yalnızca uygular. Bu, viewport'ların birbirini sonsuz döngüyle tetiklemesini kökten engeller. Ek güvence olarak her olay kaynak kimliği taşır ve uygulanan olaylar sırasında agent kendi dinleyicilerini susturur.

**Olaylar.**

| Olay | Taşıdığı veri | Uygulama |
|---|---|---|
| `scroll` | çapa elementin selector'ü, element içi oran, yedek olarak sayfa yüzdesi | Çapa elemente git, oranı uygula |
| `click` | hedef selector | Aynı elementi bul ve tıkla |
| `navigate` | URL, tür (yükleme / pushState / geri / ileri) | Aynı URL'e git |
| `input` (MVP sonrası) | selector, değer | Değeri yaz, `input` olayını tetikle |
| `hover` (MVP sonrası) | selector | Hover durumunu yansıt |

**Scroll.** Farklı genişliklerde sayfa yüksekliği farklı olduğundan piksel veya yüzde ile eşleme kayar. Agent, lider viewport'un okuma çizgisindeki (sabit header'ların hemen altı) elementi ve atalarını çapa adayı olarak seçer ve "çizgi bu elementin %30'unda" bilgisini gönderir; yanına en yakın başlığın metnini ve bölüm içi oranı, son olarak da sayfa yüzdesini ekler. Takipçi sırayla dener: kararlı selector (`#id`, `data-testid`) → başlık metni → yapısal selector → yüzde. Her viewport kendi okuma çizgisini kullanır. Olaylar `requestAnimationFrame` ile seyreltilir. S3 ölçümü: 7 sayfada çapa %87, yüzde %58.

**İzolasyon.** Agent sayfa script'lerinden ayrı bir `WKContentWorld`'de çalışır; DOM ortak, global değişkenler ayrı. Sayfa agent'ı bozamaz, agent sayfanın global'lerine karışmaz.

**Farklı DOM.** Mobil User-Agent bazı sitelerde aynı adreste farklı bir sayfa getirir (S3: Wikipedia). Selector'e dayalı her olay bundan etkilenir; scroll için başlık metni yedeği var, tıklama için metin tabanlı yedek M2'de eklenecek.

**Tıklama.** Agent tıklanan element için kararlı bir selector üretir. Öncelik sırası: benzersiz `id` → `data-testid` ve benzeri → `nth-of-type` içeren yapısal yol. Hedef viewport'ta element yoksa veya görünmüyorsa (ör. masaüstünde olmayan hamburger menü) tıklama atlanır ve o viewport'ta küçük bir "senkron kaçtı" göstergesi çıkar.

**Navigasyon.** Tam sayfa yüklemeleri motorun navigasyon delegesinden, SPA geçişleri agent'ın sardığı `pushState` / `replaceState` / `popstate` üzerinden yakalanır. Bağlantı tıklamaları iki kez işlenmesin diye kural: tıklama olayı yayınlanır, ardından gelen navigasyon yalnızca hedef viewport farklı bir URL'de kalmışsa uygulanır.

**Agent.** Tek bir `sync-agent.js` dosyası, derleme adımı yok, tüm motorlarda aynı. Yalnızca köprü değişir:

| Motor | Enjeksiyon | Sayfa → uygulama | Uygulama → sayfa |
|---|---|---|---|
| WebKit | `WKUserScript` (document start) | `webkit.messageHandlers` | `evaluateJavaScript` |
| Chromium | `Page.addScriptToEvaluateOnNewDocument` | `Runtime.addBinding` | `Runtime.evaluate` |
| Firefox | `script.addPreloadScript` | BiDi channel | `script.callFunction` |

**MVP'de kapsam dışı:** sayfa içi iç içe scroll alanları, iframe içi senkron, klavye olayları.

### 3.4 Canvas

Viewport'lar zoom ve pan yapılabilen bir canvas üzerinde durur.

**Hareket kuralları.**

| Hareket | İmleç viewport üstünde | İmleç boşlukta |
|---|---|---|
| İki parmak kaydırma | Sayfayı kaydırır | Canvas'ı kaydırır |
| Pinch / Cmd + scroll | Canvas'ı zoom'lar | Canvas'ı zoom'lar |
| Space + sürükleme | Canvas'ı kaydırır | Canvas'ı kaydırır |

**Teknik yaklaşım (spike ile doğrulanacak).** İlk aday: `NSScrollView` + `magnification`, document view içinde gerçek `WKWebView`'lar. AppKit ölçeklemeyi ve olay koordinatlarının dönüşümünü kendisi halleder, scroll olayı da imlecin altındaki view'a gider. Risk: pinch ve Cmd + scroll'un webview tarafından yutulması ve küçük ölçekte render kalitesi. Yedek plan: belli bir zoom eşiğinin altında canlı view yerine snapshot göstermek; o da olmazsa ızgara yerleşimi.

**MVP'de:** otomatik dizilim (tek sıra), zoom, pan, "Sığdır". **Sonra:** elle sürükleme, gruplama (motora / cihaz tipine göre), tam yükseklik modu.

### 3.5 Proje modeli

Kullanıcının kaydettiği birim **proje**dir: bir markanın tüm kurulumu (URL, cihaz seti, motorlar, canvas yerleşimi, zoom, gruplar, küçük resim). Her açılışta yeniden kurmak gerekmez.

- **Dosya tabanlı:** her proje bir `.viewportix` paketi (`project.json` + `thumbnail.png`). Şirket içinde paylaşılabilir; macOS'un aç/kaydet, otomatik kaydetme ve "Son kullanılanlar" davranışı hazır gelir.
- **Uygulama:** `NSDocument` tabanlı belge mimarisi. Taslaklar (kaydedilmemiş "Untitled" projeler) sistemin otomatik kaydetme mekanizmasıyla saklanır, giriş ekranında listelenir.
- **Şablon:** URL'siz proje; cihaz ve motor setini tanımlar. Birkaç yerleşik şablon + kullanıcı şablonları.
- **Giriş ekranı:** son projeler, taslaklar ve şablonlar; ayrıntı DESIGN.md.
- **Sayfa listesi:** proje birden fazla sayfa (ana sayfa, ürün, sepet...) tutar; canvas bir anda tek sayfayı gösterir, sidebar'dan geçilir. Yeni bir URL'e gidince sayfa listesine eklemek kullanıcının tek tıkla yaptığı bir işlemdir, otomatik değildir.

### 3.6 Oturum ve veri

- Tüm WebKit viewport'ları aynı `WKWebsiteDataStore`'u paylaşır: bir viewport'ta giriş yapınca hepsi giriş yapmış olur.
- Chromium ve Firefox kendi çerez depolarını kullanır. Motorlar arası oturum paylaşımı açık sorudur (bkz. [8](#8-açık-sorular)).
- Oturum verisi projeye değil uygulamaya aittir; proje dosyası çerez veya şifre içermez.

### 3.7 Uygulama yapılandırması

- App Sandbox **kapalı** (Chrome ve Firefox process'lerini başlatmak için gerekli), Hardened Runtime **açık** (notarization için).
- Yerel geliştirme sunucuları (`http://localhost`) için App Transport Security istisnası.
- Geçersiz sertifikalı staging siteleri için kullanıcı onaylı istisna (MVP sonrası).

## 4. Klasör yapısı

```
viewportix/
├── CLAUDE.md
├── PLAN.md
├── project.yml                      XcodeGen tanımı; Viewportix.xcodeproj buradan üretilir, repoda değil
├── docs/research/                   araştırma notları ve raporlar
├── Viewportix/                      uygulama hedefi (ince katman)
│   ├── App/                         giriş noktası, pencere, menü komutları
│   ├── Home/                        giriş ekranı: son projeler, taslaklar, şablonlar
│   ├── Document/                    NSDocument, .viewportix okuma/yazma
│   ├── Canvas/                      zoom/pan, dizilim, viewport kartı
│   ├── Toolbar/                     URL çubuğu, navigasyon, cihaz seçici
│   ├── Panels/                      geliştirici paneli (sonra)
│   └── Resources/                   Assets
├── Packages/ViewportixKit/          yerel Swift paketi (mantık, test edilebilir)
│   ├── Sources/
│   │   ├── EngineCore/              EngineSession, olay tipleri, JSONValue
│   │   ├── WebKitEngine/            WKWebView uygulaması
│   │   ├── SyncCore/                SyncCoordinator, lider takibi
│   │   │   └── Resources/sync-agent.js
│   │   ├── DeviceCatalog/           cihaz preset'leri
│   │   └── ProjectModel/            proje ve şablon modeli, JSON kodlama
│   └── Tests/
│       ├── SyncCoreTests/
│       └── Fixtures/                test HTML sayfaları
└── Spikes/                          atılabilir deneme projeleri
```

Sonradan eklenecek modüller: `ChromiumEngine`, `FirefoxEngine`, `DiffCore`, `MCPServer`.

Mantığın ayrı pakette durmasının sebebi: Xcode açmadan `swift test` ile test edilebilmesi ve uygulama hedefinin yalnızca arayüz içermesi.

## 5. Teknik notlar ve riskler

### 5.1 Spike'lar

Spike, bir riski en kısa yoldan cevaplayan atılabilir denemedir. Kod `Spikes/` altında kalır, ürüne taşınmaz.

| # | Soru | Başarı ölçütü | Olmazsa |
|---|---|---|---|
| S1 | Ölçeklenmiş canvas'ta canlı WKWebView'lar hareket kurallarına uyuyor mu? | Kaydırma doğru hedefe gidiyor, pinch her zaman canvas'ı zoom'luyor, tıklama koordinatları her zoom'da doğru, 5 viewport'ta akıcı | Snapshot'lı zoom, o da olmazsa ızgara |
| S2 | SwiftUI `WebView`/`WebPage` senkron için yeterli mi? | User script, mesaj köprüsü, navigasyon olayları ve paylaşılan veri deposu destekleniyor | `WKWebView` + AppKit (beklenen sonuç) |
| S3 | Çapa tabanlı scroll gerçek sitelerde tutuyor mu? | 5 farklı sitede 3 genişlik arasında aynı içerik görünür kalıyor | Çapa seçim kurallarını iyileştir, yüzdeye düş |
| S4 | CDP screencast canlı hissettiriyor mu? (Chromium aşaması) | Kabul edilebilir FPS ve giriş gecikmesi, retina netliği | CEF gömme veya Chromium'u da snapshot moduna alma |
| S5 | BiDi ile snapshot yenileme ne kadar hızlı? (Firefox aşaması) | Scroll sonrası fark edilir beklemeden güncelleme | Yalnızca istek üzerine snapshot |

### 5.2 Chromium (CDP)

- Kullanıcının kurulu Chrome'u (veya Chromium tabanlı başka bir tarayıcı) bulunur, geçici profil ve headless modda başlatılır, CDP ile bağlanılır.
- Görüntü `Page.startScreencast`, giriş `Input.dispatchMouseEvent` / `dispatchKeyEvent`, boyut ve DPR `Emulation.setDeviceMetricsOverride`.
- Chromium burada WebKit'ten güçlü: DPR, dokunma ve mobil viewport emülasyonu tam.
- Chrome kurulu değilse viewport "Chrome bulunamadı" durumunu gösterir. Tarayıcı indirme özelliği kapsam dışı.

### 5.3 Firefox (WebDriver BiDi)

- Kurulu Firefox `--remote-debugging-port` ile başlatılır, BiDi WebSocket'ine bağlanılır.
- BiDi'de sürekli görüntü akışı yoktur; `browsingContext.captureScreenshot` ile tek tek görüntü alınır. Bu yüzden viewport bir fotoğraf gösterir, senkron olayları arka planda uygulanır ve fotoğraf yenilenir. Viewport'un içine doğrudan tıklanamaz.
- Canlıya yakın deneyim (sık aralıklı snapshot) S5 ile ölçülür.

### 5.4 Cihaz emülasyonunun sınırları

macOS WKWebView'da bir "iPhone" viewport'u şunları **yapar**: doğru CSS genişliği ve yüksekliği, mobil User-Agent, gerçek WebKit layout ve CSS desteği.

Şunları **yapmaz**: `<meta viewport>` işlemesi iOS'taki gibi değildir, devicePixelRatio ekranınkidir (3 değil), `hover` / `pointer` media query'leri masaüstü değerini döner, dokunma olayları yoktur, iOS'a özgü araç çubuğu ve güvenli alan davranışları yoktur.

App Store dışında dağıttığımız için private API ile DPR gibi değerleri zorlamak mümkün olabilir; MVP sonrası araştırılır. Arayüz bu sınırı gizlememeli: viewport başlığında motor ve sürüm görünür ("WebKit 26.x").

### 5.5 Risk tablosu

| Risk | Etki | Önlem |
|---|---|---|
| Canvas hareketleri WebKit'te temiz çalışmaz | Yerleşim kararı değişir | S1 ilk iş; yedek plan hazır |
| Çok sayıda WKWebView bellek ve CPU tüketir | Yavaşlama | Görünmeyen viewport'ları duraklat, üst sınır koy |
| Selector'ler dinamik sitelerde tutmaz | Tıklama senkronu kaçar | Kademeli selector stratejisi, "senkron kaçtı" göstergesi |
| CDP screencast yeterince akıcı olmaz | Chromium canlı olamaz | S4; CEF veya snapshot modu |
| Motorlar arası oturum paylaşılamaz | Girişli sayfalar her motorda ayrı giriş ister | Açık soru; çerez aktarımı araştırılacak |
| Private API'ler macOS güncellemesinde kırılır | Emülasyon özellikleri bozulur | Private API kullanımını tek dosyada topla, yokluğunda zarifçe devre dışı kal |

## 6. Yol haritası

### M0 — Kurulum

- [x] Xcode kurulumu (Xcode 27.0, Swift 6.4; hedef macOS 26 değişmedi)
- [x] Xcode MCP sunucusu (`xcrun mcpbridge`; build, önizleme render, test)
- [x] pen.dev MCP bağlantısı (tasarım tarafı; Figma yerine pen.dev kullanılıyor)
- [x] Proje iskeleti: XcodeGen ile uygulama hedefi + `ViewportixKit` paketi (EngineCore, DeviceCatalog, ProjectModel), boş pencere açılıyor
- [x] Test fixture sayfaları (uzun sayfa, SPA, form, sabit header)

### M1 — Spike'lar

- [ ] S1: canvas hareketleri — otomatik kısım geçti (tıklama %100/%50/%30'da 15/15, sapma 0,9 px; sayfa scroll'u, boşlukta pan, ⌘ + scroll zoom). Pinch, sızıntı, momentum ve performans elle kontrol bekliyor: `Spikes/S1-CanvasGestures/README.md`
- [x] S2: `WebPage` mi `WKWebView` mi — **`WKWebView`**, deneme gerekmedi: canvas AppKit `NSScrollView` (S1) ve her viewport'un gerçek bir `NSView` olması gerekiyor; `WebPage` görünümü dışarı vermiyor, sızıntı koruması için `scrollWheel` yakalanamıyor
- [x] S3: çapa tabanlı scroll — 7 sayfada çapa %87, yüzde %58; canlı akışta yankı yok. Başlık metni yedeği eklendi. Ayrıntı: `Spikes/S3-AnchorScroll/README.md`
- [ ] Sonuçları bu dosyaya işle, gerekiyorsa kararları güncelle

### M2 — MVP (yalnızca WebKit)

**Durum (2026-10-10):** Motor katmanı, senkron koordinatörü, ajan (scroll + tıklama), proje dosyası, giriş ekranı, sayfa listesi, toolbar ve canvas uygulamada çalışıyor; 23 paket testi geçiyor (8 tanesi gerçek WKWebView ile). Arayüz etkileşimleri (hover ile lider seçimi, gerçek trackpad) elle test bekliyor; S1 kontrol listesiyle birlikte yapılacak.

**Kapsam**

- URL çubuğu, geri / ileri / yenile
- Canvas üzerinde 3–5 viewport, otomatik dizilim, zoom, pan, "Sığdır"
- Cihaz preset'leri (birkaç telefon, tablet, masaüstü); viewport ekleme ve kaldırma
- Scroll, tıklama ve navigasyon senkronu (SPA dahil)
- Viewport başlığı: cihaz adı, boyut, motor sürümü
- Paylaşılan oturum (bir kez giriş, her viewport'ta geçerli)
- Proje dosyası: yeni, aç, kaydet, otomatik kaydetme, taslaklar
- Sayfa listesi: sidebar'da projenin sayfaları, ekleme/kaldırma/yeniden adlandırma, tıklayınca canvas o sayfaya geçer
- Basit giriş ekranı: URL kutusu, son projeler listesi (küçük resimsiz)

**Kapsam dışı**

Cihaz çerçeveleri, screenshot, form girişi senkronu, gruplama, elle sürükleme, şablonlar, diğer motorlar, diff, MCP.

**Kabul ölçütleri**

- Gerçek bir sitede bir viewport'ta scroll edince diğerlerinde aynı içerik görünür.
- Bir viewport'ta menü bağlantısına tıklayınca hepsi aynı sayfaya gider; SPA'da da çalışır.
- Viewport'lar birbirini tetikleyip titremez.
- Canvas hareket kuralları tablosundaki her satır beklendiği gibi çalışır.
- `localhost` üzerindeki geliştirme sunucusu açılır.

### M3 — Şirket içi sürüm

- [ ] Arayüz tasarımının uygulanması (tasarım kullanıcıdan)
- [ ] Giriş ekranının tam hali: küçük resimler, şablonlar, ızgara/liste, arama
- [ ] Sidebar'da viewport listesi ve gruplar
- [ ] Form girişi ve hover senkronu
- [ ] Screenshot (tek viewport ve tümü)
- [ ] Özel cihaz boyutu, viewport döndürme
- [ ] Elle sürükleme ve gruplama
- [ ] Senkronu viewport bazında açıp kapama
- [ ] Developer ID imzası + notarization, şirket içi dağıtım

### M4 — Chromium

- [ ] S4 spike
- [ ] `ChromiumEngine`: Chrome bulma, başlatma, CDP bağlantısı, screencast, giriş iletimi
- [ ] sync-agent'ın CDP köprüsü
- [ ] Viewport eklerken motor seçimi

### M5 — Motor diff'i

- [ ] Aynı genişlikte iki motorda element kutularını selector ile eşleştirme
- [ ] Eşik üstü farkları overlay ile işaretleme
- [ ] Fark listesi paneli ("Safari'de 12px aşağıda")

### M6 — Firefox

- [ ] S5 spike
- [ ] `FirefoxEngine`: snapshot modu
- [ ] Diff'e Firefox'u dahil etme

### M7 — MCP sunucusu

- [ ] `EngineSession` üzerinden araçlar: `list_viewports`, `navigate`, `click`, `scroll`, `read_dom`, `screenshot`, `get_engine_diff`
- [ ] Claude Code ve Claude Desktop için kurulum yönergesi
- [ ] Varsayılan kapalı, ayarlardan açılır

### Sonrası (sırasız)

- Tam yükseklik modu
- "iOS Simulator'da aç" butonu (yalnızca Xcode kuruluysa görünür)
- Private API ile DPR / dokunma emülasyonu
- Otomatik güncelleme (Sparkle)
- Uygulama içi AI paneli (API anahtarıyla)
- Eski macOS sürümleri, Windows
- İş modeli kararı

## 7. Tasarım

Ekranlar, akışlar, verilen ve bekleyen tasarım kararları [DESIGN.md](DESIGN.md) dosyasında. MVP, tasarım beklenmeden sistem varsayılanı görünümle geliştirilir; tasarım M3'te uygulanır.

## 8. Açık sorular

- Motorlar arası oturum: WebKit'te yapılan giriş Chromium ve Firefox'a aktarılabilir mi?
- Sekme desteği olacak mı, yoksa her proje ayrı pencere mi?
- Şirketin Apple Developer hesabı var mı? (imza ve notarization için)
- Tasarım Figma'da mı yapılacak?
