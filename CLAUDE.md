# Viewportix

> Kullanıcıyla Türkçe konuş. Kod, değişken adları ve commit mesajları İngilizce olsun.

## Ne yapıyoruz

Responsively App'in bir alternatifi: tasarımcılar ve front-end geliştiriciler için **native bir macOS uygulaması**.

Bir web sitesini birden fazla cihaz boyutunda yan yana gösterir; scroll, tıklama ve navigasyon tüm cihazlarda senkrondur.

Asıl farkı: Responsively, Polypane ve Sizzy'nin hepsi Electron + Chromium, yani "iPhone" görünümleri aslında Chrome. Viewportix sayfayı **gerçek tarayıcı motorlarında** (Safari/WebKit, Chrome, Firefox) gösterir ve aralarındaki görsel farkları işaretler.

Slogan: **"Every width. Every engine."**

Ayrıntılı mimari, klasör yapısı ve yol haritası: [PLAN.md](PLAN.md)
Ekranlar, akışlar ve tasarım kararları: [DESIGN.md](DESIGN.md)

## Kararlar

- Yalnızca macOS 26+; eski sürümler ve Windows ileride talep olursa
- Swift + SwiftUI (gerektiğinde AppKit)
- Hedef kitle hem tasarımcı hem geliştirici: varsayılan arayüz sade, geliştirici araçları ayrı panelde
- Viewport'lar serbest canvas üzerinde (zoom + pan); hareket kuralları spike ile doğrulanacak, olmazsa ızgara
- Proje = `.viewportix` dosyası (bir markanın tüm kurulumu); taslaklar otomatik saklanır; giriş ekranı pen.dev düzeninde
- Safari için WKWebView (canlı), Chrome için CDP (screencast ile canlı), Firefox için WebDriver BiDi (snapshot modu)
- Senkron element tabanlı ve motordan bağımsız: tek `sync-agent.js`, yalnızca lider viewport olay yayınlar
- Görsel farklar DOM tabanlı diff ile bulunur, piksel diff ile değil
- AI entegrasyonu MCP sunucusu olarak (Blender modeli), MVP sonrası
- iOS Simulator MVP dışı
- App Store dışı dağıtım, önce şirket içi; iş modeli sonra. GPL'li bağımlılık kullanma
- Arayüz tasarımını kullanıcı yapar; görsel kararları ona sor

## Çalışma kuralları

- Motorlara yalnızca `EngineSession` protokolü üzerinden eriş; canvas ve senkron kodu motora özgü tip görmemeli
- Mantık `Packages/ViewportixKit` içinde, uygulama hedefi yalnızca arayüz
- Riskli teknik sorular önce `Spikes/` altında atılabilir denemeyle cevaplanır
- "Gerçek motor" de, "gerçek cihaz" deme: macOS WebKit'i iOS Safari değildir
- Mimari ve yol haritası kararları PLAN.md'ye, ekran ve akış kararları DESIGN.md'ye; bu dosya yalnızca özet
- Kararlar netleştikçe bu dosyaları güncelle

## Geliştirme

- Xcode projesi `project.yml`'den üretilir, repoda tutulmaz: `xcodegen generate`
- Paket testleri: `swift test --package-path Packages/ViewportixKit`
- Uygulama derleme: `xcodebuild -project Viewportix.xcodeproj -scheme Viewportix -derivedDataPath .build/xcode build`
- Test sayfaları: `Packages/ViewportixKit/Tests/Fixtures/`
- `.pen` tasarım dosyalarına yalnızca pen.dev MCP araçlarıyla eriş

## Şu anki durum

M0 iskeleti hazır (Xcode 27, Swift 6.4). Sıradaki adım M1: spike'lar (S1 canvas hareketleri, S2 WebPage vs WKWebView, S3 çapa tabanlı scroll).

## İlk hedef (MVP)

Canvas üzerinde yan yana birkaç cihazda (WebKit) aynı siteyi açan, scroll, tıklama ve navigasyonu senkron tutan uygulama. Kapsam ve kabul ölçütleri PLAN.md, M2.
