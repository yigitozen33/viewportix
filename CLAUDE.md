# Viewportix

> Kullanıcıyla Türkçe konuş. Kod, değişken adları ve commit mesajları İngilizce olsun.

Tasarımcılar ve front-end geliştiriciler için native macOS uygulaması: bir siteyi birden fazla cihaz boyutunda, **gerçek tarayıcı motorlarında** (WebKit, Chromium, Gecko) yan yana gösterir; scroll, tıklama, form, hover ve navigasyon senkrondur. Rakipler (Responsively, Polypane, Sizzy) Electron + Chromium. Slogan: **"Every width. Every engine."**

- Mimari, yol haritası, spike sonuçları: [PLAN.md](PLAN.md)
- Ekranlar ve tasarım kararları: [DESIGN.md](DESIGN.md)

## Oturum başında oku

- Kod oturumu: kendi durumun [docs/HANDOFF.md](docs/HANDOFF.md) (+ son günlük `docs/oturumlar/`), karşı taraf `design/HANDOFF.md` (+ `design/notlar/`)
- Tasarım oturumu: kendi durumun `design/HANDOFF.md`, karşı taraf `docs/HANDOFF.md` ve `docs/tasarim-istekleri.md`

## Kararlar

- Yalnızca macOS 26+; Swift + SwiftUI, canvas ve web görünümleri AppKit
- Arayüz tamamen özel (toolbar ve sidebar dahil); pencere standart, sistem davranışları (menü, kısayol, klavye, VoiceOver) korunur; kendi yüzeylerimizde Liquid Glass yok
- Viewport'lar serbest canvas'ta (zoom + pan); proje = `.viewportix` dosyası
- WebKit `WKWebView` (canlı), Chromium CDP (canlı), Firefox WebDriver BiDi (snapshot)
- Senkron motordan bağımsız tek `sync-agent.js`; yalnızca lider viewport olay yayınlar
- Görsel farklar DOM diff ile; AI entegrasyonu MCP sunucusu olarak (MVP sonrası)
- App Store dışı, önce şirket içi; GPL'li bağımlılık yok
- Arayüz tasarımını kullanıcı yapar; görsel kararları ona sor

## Çalışma kuralları

- Motorlara yalnızca `EngineSession` üzerinden eriş; mantık `Packages/ViewportixKit`'te, uygulama hedefi yalnızca arayüz
- Riskli teknik sorular önce `Spikes/` altında denenir
- "Gerçek motor" de, "gerçek cihaz" deme: macOS WebKit'i iOS Safari değildir
- Mimari kararlar PLAN.md'ye, ekran kararları DESIGN.md'ye; bu dosya kısa kalır, ayrıntı HANDOFF ve günlüklerde
- Paralel oturumlar aynı dosyaya yazmaz. Tasarım: yalnızca `DESIGN.md` ve `design/`. Kod: geri kalan her şey (`docs/` dahil)
- Kod oturumu arayüze dokunan her değişikliği aynı commit'te `docs/tasarim-istekleri.md`'ye ekler (yalnızca eklenir, kullanıcıya sormadan); `docs/HANDOFF.md`'yi güncel tutar (üzerine yazılır); oturum sonunda `docs/oturumlar/YYYY-MM-DD.md`'ye karar, denenen/reddedilen, kanıt ve eklenen tasarım isteklerini yazar (yalnızca eklenir)
- Notlara inanılanı değil kanıtı yaz (commit, dosya yolu, test çıktısı); eski karar silinmez, "superseded" yazılır

## Geliştirme

- Xcode projesi `project.yml`'den üretilir, repoda tutulmaz: `xcodegen generate`
- Paket testleri: `swift test --package-path Packages/ViewportixKit`
- Uygulama: `xcodebuild -project Viewportix.xcodeproj -scheme Viewportix -derivedDataPath .build/xcode -allowProvisioningUpdates build`
- İmza: varsayılan ad-hoc; geliştirici ekibi repoya girmeyen `Config/Signing.local.xcconfig`'te (`Config/App.xcconfig`)
- Performans: `Scripts/perf.sh [url]`; test sayfaları `Packages/ViewportixKit/Tests/Fixtures/`
- `.pen` dosyalarına yalnızca pen.dev MCP araçlarıyla eriş
