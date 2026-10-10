# S4 — Sentetik fare olayıyla CSS `:hover`

**Soru:** Hover senkronunda takipçi `WKWebView`'a yerel bir `mouseMoved` olayı gönderirsek, gerçek imleç başka bir viewport'tayken CSS `:hover` uygulanır mı?

**Sonuç (2026-10-10): Hayır.** Aktif ve key pencerede, iki web görünümü yan yana, imleç uzakta:

| Teslim yolu | `:hover` |
|---|---|
| `webView.mouseMoved(with:)` | ❌ |
| `window.sendEvent(_:)` | ❌ |
| `NSApp.sendEvent(_:)` | ❌ |
| `mouseEntered` + `mouseMoved` | ❌ |

WebKit hover durumunu sentetik yerel olaylardan güncellemiyor; muhtemelen gerçek imleç konumuna bakıyor.

**Karar:** Hover senkronu ajan içinde taklit ediliyor: `:hover` kuralları `[data-viewportix-hover]` öznitelik seçicisine kopyalanıyor, hedefe ve atalarına öznitelik konuyor, `pointerenter/mouseenter/over` olayları gönderiliyor. Ayrıntı: PLAN.md 3.3, `sync-agent.js`.

Çalıştırma: `xcodegen generate && open S4HoverProbe.xcodeproj` (⌘R); sonuçlar konsola yazılır.
