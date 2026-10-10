# Apple kiti ve pen.dev kütüphanesi Viewportix tasarımını hızlandırır

Viewportix'in arayüzü için "kutudan çıkan" tek bir hazır kit yok; ama parçalar var ve doğru sırayla birleştirilince pen.dev'de işin büyük kısmı ilk haftada çıkar. Pencere iskeleti (toolbar, sidebar, inspector, alert, menü, materyaller, açık/koyu mod) için **Apple'ın ücretsiz, resmi macOS 26 ve macOS 27 Figma kitleri** tam kapsamlı ve Liquid Glass dönemine ait tek kaynak ([Figma: macOS 26](https://www.figma.com/community/file/1543337041090580818/macos-26), [Figma: macOS 27](https://www.figma.com/community/file/1651309434229735362/macos-27)); pen.dev `.fig` dosyalarını doğrudan içe aktarabildiği için bu kit tasarım sisteminin temeli olabilir ([pen.dev Import and Export](https://docs.pen.dev/core-concepts/import-and-export)). Buna karşılık sonsuz canvas'a özgü parçalar (zoom yüzdesi, "Sığdır", viewport kartı başlığı, lider vurgusu) hiçbir Figma kitinde hazır gelmiyor; bunlar Figma UI3, Sketch Copenhagen, Polypane 31 ve tldraw'un belgelenmiş davranışlarından elle türetilecek. Giriş ekranı için pen.dev'in kendi düzeni, Xcode'un Welcome penceresi ve Sketch'in belge penceresi üç olgun kalıp sunuyor; CodeEdit'in MIT lisanslı WelcomeWindow paketi de SwiftUI tarafında aynı kalıbı hazır veriyor ([GitHub: CodeEditApp/WelcomeWindow](https://github.com/CodeEditApp/WelcomeWindow)). pen.dev tarafında belgelenmiş mekanizma şu: Variables (Light/Dark temalı) + Components + Slots → `.lib.pen` kütüphanesi → her ekran dosyasına import → seçime dayalı kısa istemlerle iterasyon ([pen.dev: Build a design system](https://docs.pen.dev/core-concepts/build-a-design-system)). En büyük bilinen risk, pen.dev'in çok ekranlı tutarlılığı ve SwiftUI çıktısı olmaması; raporun ikinci yarısı bu iki riski kütüphane disiplini, SKILL.md ve `.pen` JSON'unu Claude Code'a vererek aşan adım adım bir plan sunuyor.

## Apple'ın macOS 26/27 kiti Liquid Glass dönemindeki tek tam kapsamlı kit

Ekim 2026 itibarıyla Apple'ın Design Resources sayfası macOS için yalnızca **macOS 27 UI Kit**'i listeliyor (Figma ve Sketch), yanında SF Symbols 27, Icon Composer ve SF Pro/SF Mono fontları var ([Apple Design Resources](https://developer.apple.com/design/resources/)). Kitin tanımı tam olarak Viewportix'in ihtiyaç listesini okuyor: "sidebar, toolbar, tables, buttons, menus, pointers... full dark mode and window state support; views and system components including windows, alerts, popovers, sheets, and dialogs" ([Figma Community: macOS 27](https://www.figma.com/community/file/1651309434229735362/macos-27)); sayfa metadata'sında **12.987 kullanım ve 646 beğeni** görünüyor ve son güncelleme 24 Temmuz 2026. macOS 26 kiti hâlâ Figma Community'de ve aynı bileşen listesiyle, aynı tarihte güncellenmiş durumda ([Figma Community: macOS 26](https://www.figma.com/community/file/1543337041090580818/macos-26)). Sketch tarafındaki macOS Tahoe 26 kütüphanesi ise bileşen bazında daha ayrıntılı listelenmiş: segmented control, search field, popup/pull-down button, slider, stepper, toggle, tooltip, scrollbar, disclosure button ve pencere/menü/dialog şablonları ([9to5Mac](https://9to5mac.com/2025/06/10/apple-updates-design-resources-for-ios-26-ipados-26-and-macos-tahoe-26/)). İki kitin de içermediği iki şey var ve bunlar Viewportix'in kalbi: **"inspector" ve "canvas" bileşeni yok**; inspector'ı kitin sidebar/table/form kontrollerinden kurmak, canvas'ı ise düz içerik katmanı olarak çizmek gerekiyor.

Topluluk kitleri bu boşluğu doldurmuyor. macOS 26'ya gerçekten güncel olanlar dar kapsamlı: Liquid Glass efekt dosyaları ([Figma: macOS 26 Liquid Glass Effect](https://www.figma.com/community/file/1514239434132644410/macos-26-liquid-glass-effect)), bir Liquid Glass UI plugin'i ([Figma plugin](https://www.figma.com/community/plugin/1514769156504171663/liquid-glass-ui)), macOS 26 imleç seti ([Figma: Apple macOS 26 Cursors](https://www.figma.com/community/file/1517119747499682321/apple-macos-26-cursors)) ve Liquid Glass'a güncellenmiş uygulama ikonu şablonu ([Figma: macOS icon template](https://www.figma.com/community/file/930870327989917713/macos-icon-template-updated-for-macos-26-liquid-glass)). Geniş kapsamlı topluluk sistemleri (Apple macOS 12 Design System, alexkaessner'in Sketch kiti) Monterey/Big Sur dönemine ait; "Apple macOS 26 Library" adlı dosya kendi açıklamasına göre iOS 26 kitinden türetilmiş, yani adı yanıltıcı ([Figma: Apple macOS 26 Library](https://www.figma.com/community/file/1514327883026186935/apple-macos-26-library)). Sonuç: pencere iskeleti için Apple kiti + imleç ve ikon şablonları yeterli; başka bir tam kit aramaya gerek yok.

HIG'in Liquid Glass rehberi tasarımı doğrudan şekillendiren birkaç kural veriyor. Toolbar ve sidebar "Liquid Glass katmanında içeriğin üstünde yüzer"; içerik sidebar'ın altına uzanmalı ve glass **içerik katmanında kullanılmamalı** ([HIG Materials](https://developer.apple.com/design/human-interface-guidelines/materials), [HIG Sidebars](https://developer.apple.com/design/human-interface-guidelines/sidebars)). Toolbar'da en fazla üç grup, 15 karakterden kısa başlık, kenarlıksız sistem sembolleri ve tek bir `.prominent` birincil eylem; özel toolbar arka planları sistem efektini bozduğu için önerilmiyor ([HIG Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars)). Inspector "seçili öğenin ayrıntılarını gösterir, seçim değişince otomatik güncellenir" ve split view'ın trailing bölmesinde durur; sliders/steppers gibi basit kontroller tercih edilir ([HIG Panels](https://developer.apple.com/design/human-interface-guidelines/panels)). Keynote'un yerleşimi (slide navigator | canvas | inspector) HIG'de split view örneği olarak anılıyor ve ince (1 pt) ayırıcı öneriliyor ([HIG Split Views](https://developer.apple.com/design/human-interface-guidelines/split-views)). Viewportix için bunun anlamı: canvas opak ve standart materyal, sidebar ve toolbar glass, viewport kartları glass değil. HIG sayısal sidebar genişliği veya toolbar yüksekliği vermiyor; bu değerler Apple kitinden ölçülerek değişkene dönüştürülmeli.

## Canvas chrome için hazır kit yok, ama davranış referansları tutarlı

Sonsuz canvas araçlarının arayüz parçalarını (zoom widget'ı, "fit" düğmeleri, minimap, cetvel) paketleyen bir Figma Community dosyası bulunamadı; en yakın kaynaklar Figma'nın kendi UI3 arayüzü ve Sketch'in Tahoe için yeniden tasarlanan Copenhagen sürümü. Figma UI3'ün hikâyesi Viewportix için bir uyarı taşıyor: ekip önce canvas üstünde yüzen paneller yayınladı, sonra "insanları yavaşlattığı için" sabit, yerleşik ve yeniden boyutlandırılabilir panellere geri döndü; yalnızca alt toolbar yüzen kaldı ([Figma blog: UI3](https://www.figma.com/blog/our-approach-to-designing-ui3/)). Sketch Copenhagen (19 Kasım 2025) da Tahoe'nin yüzen varsayılanlarına karşı **sabit sidebar'ları** tercih etti, araç/katmana göre değişen bağlamsal bir toolbar ekledi ve Liquid Glass'ı yalnızca toolbar, minimap ve canvas altı bildirimlerde kullandı ([Sketch blog: Copenhagen](https://www.sketch.com/blog/a-tour-of-copenhagen/)). Native bir canvas uygulamasının bu ikisi gibi "sidebar sabit, glass yalnızca kontrol katmanında" demesi hem HIG'e hem pratiğe uyuyor.

Zoom ve pan konvansiyonları sekiz uygulamada aynı modele yakınsıyor: `⌘+`/`⌘−` kademeli zoom, `⌘0` %100, "tümünü sığdır" ve "seçimi sığdır" yan yana iki tuşta (Sketch'te `⌘1`/`⌘2`, Figma ve Excalidraw'da `⇧1`/`⇧2`, Miro'da `⌥1`/`⌥2`), Space + sürükleme ile pan, pinch ile zoom ([Sketch Docs: The Canvas](https://www.sketch.com/docs/canvas/), [Figma Help: Zoom](https://help.figma.com/hc/en-us/articles/360041065034-Adjust-your-zoom-and-view-options), [Miro Shortcuts](https://miro.com/shortcuts/)). Apple'ın kendi canvas uygulaması Freeform zoom düğmelerini sol alt köşeye koyuyor ve View menüsünde "Zoom to Fit Content" / "Zoom to Selection" sunuyor ([Apple Support: Freeform](https://support.apple.com/guide/freeform/frfm000074a4e/mac)); Framer ise zoom menüsünü toolbar'ın sağında tutuyor ve her kademe zoom'u ikiye katlıyor ([Framer Help](https://www.framer.com/help/articles/how-to-use-the-canvas/)). tldraw'un varsayılan kademeleri **`[0.1, 0.25, 0.5, 1, 2, 4, 8]`** ve wheel davranışı trackpad'de pan, fare tekerinde zoom olarak ayrışıyor ([tldraw Docs: Camera](https://tldraw.dev/sdk-features/camera)). DESIGN.md'deki toolbar ("Sığdır 100%") bu konvansiyonun sağ üst varyantı; tasarımda zoom yüzdesini tıklanabilir bir menü (sığdır, seçimi sığdır, %50/100/200) olarak çizmek bu araçların tamamıyla uyumlu.

Canlı web içeriği olan kartlarda etkileşim ayrımı için en net belgelenmiş model tldraw'un embed'leri: tek tık kartı seçer, çift tık veya Enter "düzenleme moduna" alır ve ancak o zaman pointer olayları iframe'e geçer; Escape veya dışarı tıklama çıkar; kilitli kartlar bile etkinleştirilebilir ([tldraw Docs: Embed shape](https://tldraw.dev/sdk-features/embed-shape)). Eylül 2026'da düzeltilen bir regresyon aynı anda birden çok embed'in pointer alması durumunda seçimin bozulduğunu gösteriyor ([tldraw PR #10467](https://github.com/tldraw/tldraw/pull/10467)). Viewportix'in hareket tablosu (imleç viewport üstündeyken iki parmak kaydırma sayfayı kaydırır) bundan daha agresif bir "her zaman canlı" modelini seçiyor; bu, tasarımda kartın **hover (lider) durumu ile seçili durumunun** görsel olarak net ayrılmasını zorunlu kılıyor. Native tarafta `p1rallels/infinite` projesinin deneyimi de tasarımı etkiler: WKWebView'lar pinch sırasında donduruluyor ve yalnızca görsel olarak ölçekleniyor; hit-testing kayması ve IME penceresi konumu açık riskler ([GitHub: p1rallels/infinite](https://github.com/p1rallels/infinite)). Düşük zoom'da snapshot'a geçme fikri (PLAN.md yedek planı) tasarımda "canlı/snapshot" rozetine karşılık gelmeli.

## Rakipler viewport kartı ve senkron için kalıp veriyor, lider göstergesi için vermiyor

Polypane 31 (29 Eylül 2026) ve Responsively 2.0 (Eylül 2026) haftalar arayla serbest canvas yerleşimi ekledi; artık satır düzeni tek başına yetersiz, canvas + odak modu beklenen çift ([Polypane 31 blog](https://polypane.app/blog/polypane-31-canvas-layout-elements-panel-improvements-and-chromium-155/), [Responsively v2.0.0-beta.0](https://github.com/responsively-org/responsively-app-releases/releases/tag/v2.0.0-beta.0)). Polypane'in Canvas düzeni Viewportix'in hedeflediği etkileşimlerin neredeyse aynısı: serbest konum ve boyut, sürüklerken hizalama, ⌘ + teker veya pinch ile zoom, `⇧⌘0` ile tümünü görünüme sığdırma, boş alana çift tık ile pane ekleme, ⌘ + sürükleme ile dikdörtgen çizerek pane oluşturma ve sağ altta etkileşimli minimap ([Polypane Layouts](https://polypane.app/docs/layouts/)). Polypane'in pane başlığı en zengin örnek: **ad/preset, düzenlenebilir W×H, araç ikonları satırı**; kaldır/sırala/çoğalt/odakla/döndür gibi yapısal eylemler yalnızca hover'da görünüyor, 31 sürümüyle başlığa CPU/bellek rozeti de eklendi ([Polypane: Intro to panes](https://polypane.app/docs/intro-to-panes/)). Viewportix'in kart başlığı (cihaz adı, boyut, motor ve sürüm, kapatma) bu kalıbın sade hali; "yıkıcı eylemler hover'da" kuralı doğrudan alınmalı.

Senkron her araçta varsayılan olarak açık ve adres çubuğunda tek bir düğmeyle kapatılıyor; Polypane sağ tık menüsünde hangi olay türlerinin senkronlanacağını seçtiriyor ve pane bazında navigasyon senkronunu kapatabiliyor ([Polypane: Synced interactions](https://polypane.app/docs/synced-interactions/)). Önemli bulgu: **hiçbir rakibin belgesi "lider" (süren) pane'i görsel olarak işaretlemiyor**; lider, imlecin altındaki pane olarak örtük kalıyor. DESIGN.md'nin "lider göstergesi" ve "senkron kaçtı" uyarısı bu yüzden kopyalanacak bir kalıp değil, Viewportix'in kendine ait tasarım kararı; pen.dev'de bu iki durumu ayrı varyant olarak üretmek gerekecek. Kullanıcı eleştirileri de yön veriyor: Electron ağırlığı ve M1'de yavaşlık ([Responsively Issue #621](https://github.com/responsively-org/responsively-app/issues/621)), abonelik yorgunluğu ([HN 43451700](https://news.ycombinator.com/item?id=43451700)) ve Safari 17'nin tek tık cihaz ikonlarını kaldırmasına duyulan tepki ([Apple Developer Forums 738775](https://developer.apple.com/forums/thread/738775)). Bu kategoride native tek örnek Solis (WebKit, 50 viewport'a kadar çizip yerleştirme) ve son görünür sürümü 2021 civarı ([solisapp.com](https://solisapp.com/)); yani "native + gerçek WebKit + hızlı preset'ler" konumu boş.

Giriş ekranı için iki olgun Mac kalıbı var. Xcode'un Welcome penceresi solda 2–3 büyük başlangıç eylemi, sağda son projeler listesi ([Kodeco: Tour of Xcode](https://www.kodeco.com/ios/paths/foundational-tools-ios/43817071-introduction-to-xcode/01-getting-to-know-xcode/04)); Sketch'in Workspace penceresi ise solda kaynak sidebar'ı (All Documents, Recent, Drafts, Projects, Templates), ortada arama ve **ızgara/liste geçişi** olan küçük resim alanı, son sidebar seçimini uygulama yeniden açıldığında hatırlıyor ve ⌘O ile yeniden çağrılıyor ([Sketch Docs: Creating, opening & viewing documents](https://www.sketch.com/docs/getting-started/creating-opening-and-viewing-documents/)). DESIGN.md'nin pen.dev düzeni (sol sidebar: Son/Taslaklar/Şablonlar; merkezde URL kutusu ve şablon çipleri; altta ızgara/liste + arama) tam olarak Sketch kalıbının üstüne pen.dev'in merkezi istem kutusunu bindiriyor; bu melez için her iki referansın ekran görüntüsünü pen.dev'e context olarak vermek yeterli. HIG tarafında macOS için "welcome window" diye bir sayfa yok; yalnızca New/Open/Open Recent komutları ve bir Add (+) düğmesi şart koşuluyor ([HIG File Management](https://developer.apple.com/design/human-interface-guidelines/file-management)). SwiftUI tarafında CodeEdit'in WelcomeWindow paketi son belgeler listesi, yeni/aç düğmeleri, sürükle-bırak ve NSDocument desteğiyle MIT lisanslı hazır bir uygulama; Viewportix'in `.viewportix` + NSDocument kararıyla birebir örtüşüyor ([GitHub: CodeEditApp/WelcomeWindow](https://github.com/CodeEditApp/WelcomeWindow)).

## pen.dev'in gerçek yetenekleri: kütüphane, skill ve import var; masaüstü şablonu ve SwiftUI yok

pen.dev (Ocak 2026'da Pencil olarak çıktı, Ağustos 2026'da yeniden adlandırıldı) HTML üreten bir araç değil; Figma benzeri vektör nesne ağacını açık JSON `.pen` dosyasında tutan ve ajanın doğrudan düzenlediği bir masaüstü canvas ([The .pen Format](https://docs.pen.dev/for-developers/the-pen-format), [pen.dev](https://www.pen.dev/)). Bu, macOS uygulaması tasarlayan biri için önemli: hiçbir şey web idiyomlarını artboard'a zorlamıyor. Fiyatlandırma sayfasına göre ürün "planlar çıkana kadar ücretsiz"; Free planda ayda 5 "agent day", Pro **$16/kullanıcı/ay** sınırsız agent day ve 3 paralel ajan, Ultra $48 ([pen.dev pricing](https://www.pen.dev/pricing)). Claude kullanımı ayrı faturalanıyor; "Free bir iş modeli değil" uyarısı yerinde ([flowstep.ai](https://flowstep.ai/blog/pencil-dev-pricing/)).

Tasarım sistemi mekanizması belgelenmiş ve Viewportix için yeterli: Light/Dark temalı Variables (renk, sayı, string), token'lara bağlı Components, içine ne konabileceğini sınırlayan **Slots**, Libraries panelinden `.lib.pen` olarak dışa aktarma ve tüketici dosyalara import; kaynak değişiklikleri bağlı belgelerdeki tüm instance'lara yansıyor ([Build a design system](https://docs.pen.dev/core-concepts/build-a-design-system), [Design Libraries](https://docs.pen.dev/core-concepts/design-libraries)). İçe aktarma tarafında `.fig` dosyaları toolbar'dan veya File menüsünden alınıyor, tek tek Figma katmanları kopyala-yapıştır ile geliyor (görseller hariç), SVG'ler düzenlenebilir katmana dönüşüyor, PNG/JPEG görsel katmanı oluyor; yerleşik ikon kütüphaneleri Material Symbols, Lucide, Feather ve Phosphor ([Import and Export](https://docs.pen.dev/core-concepts/import-and-export)). **SF Symbols yerleşik değil**; SF Symbols uygulamasından SVG olarak dışa aktarıp özel ikon olarak eklemek gerekiyor.

İstem tarafında resmi öneri net: "değiştirmek istediğin katmanları seç, sonra değişikliği tarif et"; seçim otomatik olarak composer'a context düşüyor; görsel/dosya ekleyebiliyorsun; `/` ile SKILL.md tabanlı skill'ler; 1–6 paralel ajan "Split Work" (farklı parçalar) ya da "Side by Side" (aynı işin alternatifleri); "Let it cook" ile Layout (stili korur) veya Style (görsel işlemi değiştirir) varyantları ([AI agents and Skills](https://docs.pen.dev/core-concepts/ai-agents)). Resmi istem galerisinin devam kalıpları ("Use the selected design as the base design, that's my current app. Design a new page...", "Look at the selected design. Change it to the light mode.") çok ekranlı tutarlılığın ana aracı ([pen.dev/prompts](https://www.pen.dev/prompts)). Üçüncü taraf deneyimi iki şeyi vurguluyor: tasarım sistemini baştan belirtmek çıktı tutarlılığını "temelden" artırıyor ve token tüketimini düşürüyor ([atalupadhyay, Şubat 2026](https://atalupadhyay.wordpress.com/2026/02/25/pencil-dev-claude-code-workflow-from-design-to-production-code-in-minutes/)); etiket değiştirme veya hizalama gibi küçük işleri elle yapmak ücretsizken istemle yapmak token yakıyor ([uxmagic.ai](https://uxmagic.ai/blog/pencil-dev-review)).

Sınırlar da net. Kod hedefleri yalnızca web (React, Next.js, Vue, Svelte, HTML/CSS; Tailwind/CSS Modules); belgeler SwiftUI'den söz etmiyor ([Design ↔ Code](https://docs.pen.dev/design-and-code/design-to-code)). Yerleşik dışa aktarma PNG/JPEG/WEBP/PDF (1x/2x/3x, çoklu seçim ZIP) ve HTML+Tailwind/CSS; Figma'ya dönüş üçüncü taraf plugin'lerle oluyor ([Figma plugin: pen.dev to Figma](https://www.figma.com/community/plugin/1598907730561478304/pen-dev-to-figma)). Eleştirmenler "tek ekran odağı, ekranlar arası akış tutarlılığı yok", tasarım-kod senkronunun manuel olduğunu, undo/redo'nun sınırlı olduğunu ve Claude ile hızlı token tüketimini raporluyor ([uxmagic.ai](https://uxmagic.ai/blog/pencil-dev-review), [The Rundown AI](https://www.therundown.ai/tools/pencil)). Resmi istem galerisi tamamen web/mobil odaklı; **masaüstü uygulama şablonu veya macOS HIG kütüphanesi hiçbir kaynakta doğrulanamadı** ([pen.dev/prompts](https://www.pen.dev/prompts)). Giriş ekranındaki "Design Systems" bölümü, "Recreate a screenshot" çipi ve model listesi de belgelenmemiş; bunlar uygulama içinde doğrulanacak.

---

## Adım adım plan: Viewportix'i pen.dev'de tasarlamak

Plan, DESIGN.md'deki bekleyen karar sırasını izliyor (1. proje penceresi düzeni, 2. viewport kartı, 3. Liquid Glass dili, 4. giriş ekranı, 5. cihaz seçici, 6. lider / senkron kaçtı, 7. geliştirici paneli, 8. ikon). Giriş ekranı dördüncü sırada; çünkü kart bileşeni ve toolbar kütüphaneye girmeden giriş ekranı tutarlı çıkmaz. İstem şablonları İngilizce verildi: pen.dev'in ajanı ve referans aldığı kütüphane adları İngilizce, bu yüzden daha tutarlı sonuç veriyor; Türkçe istem de çalışır, ama "toolbar", "sidebar", "inspector" gibi terimleri İngilizce bırakmak gerekir.

### Adım 0 — Kurulum ve ilk doğrulamalar (yarım gün)

1. pen.dev macOS (Apple Silicon) sürümünü indir; Settings → Agents'ta Claude modelini ve reasoning effort'u seç ([AI Integration](https://docs.pen.dev/getting-started/ai-integration), [downloads](https://www.pen.dev/downloads)). Claude Code'u da kullanacaksan MCP'yi aynı ayardan aç ve `npm install -g @pen.dev/cli` kur.
2. Projede `design/` klasörü aç ve `.pen` dosyalarını orada tut; Git'e gireceği için `.viewportix` kararıyla aynı mantık ([pen.dev](https://www.pen.dev/)).
3. Uygulama içinde doğrula ve sonucu DESIGN.md'ye işle (araştırmada boşluk kalan noktalar):
   - Giriş ekranındaki **Design Systems** bölümünde Apple/macOS benzeri hazır bir sistem var mı? Varsa 1. adımda kendi kütüphaneni ona yama olarak kur.
   - **"Recreate a screenshot"** çipinin ne yaptığı (görseli composer context'e ekleyip vektöre çevirmesi bekleniyor; doğrulanmadı). Finder'ın bir ekran görüntüsüyle dene; çıktı düzenlenebilir frame ise toolbar/sidebar için kısa yol budur.
   - Libraries panelindeki "default libraries" listesi; Shadcn/Lunarus iddiası ikincil kaynaktan ([uxmagic.ai](https://uxmagic.ai/blog/pencil-dev-review)).
   - Model listesinde hangi Claude modelleri var; Claude 4.6'nın en iyi tasarım sonucunu verdiği raporlanıyor ([wakib.ai](https://www.wakib.ai/en/articles/pencil-rebrands-to-pendev-lets-6-ai-agents-design-together-20260814)).
   - Otomatik kaydetme ve undo durumu (ilkbahar 2026 eleştirileri güncel mi).

### Adım 1 — Kaynakları içe aktar (yarım gün)

1. Figma'da Apple'ın **macOS 26** kitini çoğalt (shipped macOS 26 görünümüne birebir uymak için 26; ileriye dönük görünüm istersen 27) ([Figma: macOS 26](https://www.figma.com/community/file/1543337041090580818/macos-26)). Figma'dan `.fig` olarak indir, pen.dev'de toolbar'daki Rectangle altındaki chevron → **Import Figma** ([Import and Export](https://docs.pen.dev/core-concepts/import-and-export)).
2. Tüm kiti değil, yalnızca gereken sayfaları al: window chrome (traffic lights, title bar, unified toolbar), sidebar rows, segmented control, search field, popup button, toggle, slider, alert/sheet, materials, system colors, text styles. Kit büyükse Figma'da bu bileşenleri ayrı bir dosyaya kopyalayıp onu dışa aktar.
3. **Doğrula:** import sonrası Figma değişkenleri (renk/tema), component property'leri ve Liquid Glass blur/efektleri korunmuş mu? Belgelenmemiş; korunmadıysa glass'ı 2. adımda pen.dev'in kendi effect'leriyle yeniden kuracaksın.
4. SF Symbols 27 uygulamasından kullanılacak sembolleri SVG dışa aktar (sidebar.leading, plus, arrow.clockwise, chevron.left/right, iphone, ipad, desktopcomputer, link, exclamationmark.triangle, arrow.triangle.2.circlepath) ve pen.dev'e özel ikon olarak ekle ([Apple Design Resources](https://developer.apple.com/design/resources/)). Taslak aşamasında Lucide eşdeğerlerini kullanmak kabul edilebilir, ama handoff'ta SF Symbols adı yazılmalı.
5. Referans görselleri bir `references/` klasörüne koy: Finder ve Keynote (Tahoe) pencereleri, Sketch Copenhagen ekran görüntüsü, Polypane Canvas düzeni (`https://polypane.app/static/canvas-866d3e97423b547bb068c21c4aed25d2.png`) ve pane başlığı hover hali (`https://polypane.app/static/paneheaderhovered-b748898e94942c0b5ecb82d6fc0f12ce.png`), pen.dev'in kendi giriş ekranı, Xcode Welcome, Sketch Workspace penceresi. Bunlar istemlere "Add image or file" ile girecek ([AI agents and Skills](https://docs.pen.dev/core-concepts/ai-agents)).

### Adım 2 — `viewportix.lib.pen` tasarım sistemini kur (1 gün)

Yeni bir `.pen` dosyasında önce değişkenleri, sonra bileşenleri kur; en sonda Libraries sekmesinden "Turn this file into a library" (geri alınamaz) ([Design Libraries](https://docs.pen.dev/core-concepts/design-libraries)).

**Değişkenler (Light/Dark temalı).** HIG sayısal değer vermediği için başlangıç değerlerini Apple kitinden ölçerek doğrula:

| Grup | Değişken | Not |
|---|---|---|
| Renk | `surface/window`, `surface/sidebar`, `surface/canvas`, `ink/primary`, `ink/secondary`, `accent`, `status/warning`, `status/leader` | Light/Dark override'ları kitin system colors sayfasından |
| Boyut | `toolbar/height`, `sidebar/width`, `sidebar/row-height`, `inspector/width`, `card/header-height`, `card/radius`, `divider` (1) | Divider 1 pt HIG'den ([Split Views](https://developer.apple.com/design/human-interface-guidelines/split-views)) |
| Tipografi | `font/body`, `font/caption`, `font/title`, `font/mono` | SF Pro / SF Mono; kitin text styles'ından |
| Aralık | `space/2,4,8,12,16,24` | |

**Bileşenler (her biri Light/Dark'ta çalışır).** Her bileşenin adı gerçek SwiftUI karşılığını taşısın, handoff bu adlarla konuşacak:

- `Window/Chrome` — traffic lights + unified toolbar alanı (Slot: `ToolbarItems`), sidebar bölmesi (Slot: `SidebarContent`), içerik bölmesi (Slot: `Content`), opsiyonel inspector bölmesi.
- `Toolbar/Button`, `Toolbar/SegmentedControl`, `Toolbar/URLField` (sol: güvenlik/motor rozeti; sağ: yenile), `Toolbar/ZoomMenu` ("100%" + chevron; menü: Sığdır ⌘1, Seçimi sığdır ⌘2, %50/100/200, Gerçek boyut ⌘0).
- `Sidebar/Row` (ikon, etiket, trailing rozet; durumlar: default, hover, selected, editing), `Sidebar/SectionHeader`, `Sidebar/AddRow` ("+ Ekle").
- `Viewport/Card` — başlık çubuğu + içerik alanı. Başlık: cihaz adı, "W×H", motor rozeti ("WebKit 26"); hover'da kapat/döndür/senkron. Varyantlar: `default`, `leader`, `selected`, `syncMissed`, `snapshot` (düşük zoom), `loading`.
- `Canvas/Background` (opak, standart materyal, ince nokta ızgarası opsiyonel), `Canvas/Minimap` (M3+, Polypane'den).
- `Home/ProjectCard` (küçük resim 16:10, ad, "2 sa. önce", bağlam menüsü), `Home/TemplateChip`, `Home/URLBox`.
- `Device/PickerPopover` (cihaz listesi: telefon/tablet/masaüstü grupları, arama, özel boyut).

Slots'u özellikle `ToolbarItems` ve `SidebarContent` için kullan; ajanın toolbar'a web düğmesi sokmasını engelliyor ([Build a design system](https://docs.pen.dev/core-concepts/build-a-design-system)).

**Kütüphaneyi kurduran istem (boş dosyada, Apple kit frame'leri seçiliyken):**

```
You are building a design library for a native macOS 26 (Liquid Glass) app called Viewportix.
Use ONLY the selected Apple macOS 26 kit frames as the visual source of truth. Do not invent web-style buttons.
1) Create variables with Light and Dark themes: surface/window, surface/sidebar, surface/canvas, ink/primary, ink/secondary, accent, status/warning, status/leader; number variables toolbar/height, sidebar/width, sidebar/row-height, inspector/width, card/radius, divider=1; font variables using SF Pro (body 13, caption 11, title 15) and SF Mono 11.
2) Create components bound to those variables: Window/Chrome (with slots ToolbarItems, SidebarContent, Content), Toolbar/Button, Toolbar/SegmentedControl, Toolbar/URLField, Toolbar/ZoomMenu, Sidebar/Row (states default/hover/selected/editing), Sidebar/SectionHeader, Sidebar/AddRow.
3) Use flex layout everywhere. Sidebar and toolbar are Liquid Glass (regular material); the Content area is opaque standard material — never glass.
4) Name every layer exactly as listed. Put all components on one page called "Library".
```

### Adım 3 — SKILL.md yaz ve her isteme bağla (1 saat)

`design/skills/viewportix-macos/SKILL.md` oluştur ve composer'da `/` → "Add SKILL.md file…" ile ekle; klasör adı menüdeki skill adı olur ([AI agents and Skills](https://docs.pen.dev/core-concepts/ai-agents)). İçeriği, ajanın her istemde uyacağı kurallar:

```
# viewportix-macos
Viewportix is a native macOS 26 app (SwiftUI/AppKit, Liquid Glass). Rules for every design task:
- Always reuse components and variables from viewportix.lib.pen. Never draw a new button, field or row if the library has one.
- Window anatomy: traffic lights top-left; unified toolbar integrated with the title bar; sidebar (leading, glass) | canvas (opaque content layer) | optional inspector (trailing, glass). Thin 1pt dividers.
- Toolbar: max 3 groups; leading = sidebar toggle + back/forward/reload; center = URL field; trailing = "+ Device", Zoom menu, Sync toggle. Borderless SF Symbols, no tinted backgrounds, one prominent action max.
- Sidebar: project pages list (Ana sayfa, Ürün, Sepet, Ödeme), selected row uses accent, "+ Ekle" row at bottom, section header "SAYFALAR".
- Canvas: viewports are Viewport/Card instances; cards are never glass. Default auto-layout is one row, left-aligned, 24px gap, 100% zoom.
- Viewport/Card header shows: device name, "W×H", engine badge "WebKit 26". Hover reveals close / rotate / sync-off. States: leader (soft accent ring + 1px brighter header), selected, syncMissed (small warning glyph + tooltip "Element bu viewport'ta bulunamadı"), snapshot (grey "Snapshot" pill), loading.
- Developer tools are hidden by default; never add a diff panel unless asked.
- Turkish UI copy; keep product names as-is. Light and Dark themes for every screen.
- Frame sizes: project window 1440×900; home window 1040×700.
```

### Adım 4 — Ekranları şu sırayla tasarla (3–4 gün)

Her ekran ayrı sayfa, tek `viewportix.pen` dosyası; dosya `viewportix.lib.pen`'i import eder. Bu, "tek ekran odağı" eleştirisine karşı kütüphane disiplinini zorlar ([uxmagic.ai](https://uxmagic.ai/blog/pencil-dev-review)).

**4.1 Proje penceresi (karar 1 + 3).** Boş 1440×900 frame'de, SKILL aktif, Finder/Keynote ve Polypane Canvas görselleri ekli:

```
/viewportix-macos
Design the main project window of Viewportix at 1440×900, Light theme, using the Window/Chrome component.
Sidebar (open by default, 220 wide): section "SAYFALAR" with rows Ana sayfa, Ürün (selected, with a dot badge), Sepet, Ödeme, then "+ Ekle".
Toolbar: ‹ › ⟳, URL field showing https://marka.com/urun with an engine badge, then "+ Cihaz", Zoom menu "100%", Sync toggle (on).
Canvas: three Viewport/Card instances in one row: "iPhone 16 · 393×852 · WebKit 26", "iPad · 820×1180 · WebKit 26", "Masaüstü · 1440×900 · WebKit 26". Fill their content with a neutral e-commerce product page placeholder (image, title, price, add-to-cart).
No inspector in this version. Developer tools hidden.
Then create a Dark theme copy next to it.
```

Ardından iki alternatifi "Side by Side" paralel ajanla üret: (a) sidebar kapalı + kompakt toolbar, (b) sağda inspector'lı sürüm. Karar 1'i bu üç frame'e bakıp ver.

**4.2 Viewport kartı ve durumları (karar 2 + 6).** Kütüphanedeki `Viewport/Card`'ı seç:

```
Look at the selected Viewport/Card component. Create a state sheet on a new page "Viewport states":
default, leader (pointer is over this card: soft accent ring, header slightly brighter), selected (2px accent outline, resize handles), syncMissed (small warning glyph after the engine badge, tooltip "Element bu viewport'ta bulunamadı"), snapshot (grey pill "Snapshot" in header, content slightly desaturated), loading (thin progress line under header).
Show each state at 393×852 and at 50% canvas zoom. Also show the hover header with close / rotate / sync-off icons revealed.
Explore two header densities: single line (name · size · engine) and two lines (name; size · engine).
```

Cihaz çerçevesi sorusu için "Let it cook → Style, 3 varyant" ile çerçeveli/çerçevesiz/yalnızca köşe yarıçaplı üç seçenek üret ([AI agents and Skills](https://docs.pen.dev/core-concepts/ai-agents)). Öneri: MVP'de çerçeve yok (PLAN.md kapsam dışı), kart yalnızca başlık + içerik.

**4.3 Sidebar (karar 1'in parçası).** Proje penceresindeki sidebar frame'ini seç:

```
Look at the selected sidebar. Design its interaction states: row hover, row rename (inline text field), drag-to-reorder (lifted row with shadow and insertion line), "Bu sayfayı ekle" button that appears when the current URL is not in the list, and an empty state "Henüz sayfa yok". Keep it a macOS source-list style sidebar with Liquid Glass; content under it must extend beneath the sidebar edge.
```

**4.4 Giriş ekranı (karar 4).** pen.dev'in kendi giriş ekranı, Xcode Welcome ve Sketch Workspace görselleri ekli; 1040×700 frame:

```
/viewportix-macos
Design the Home window of Viewportix (1040×700). Layout like pen.dev's home screen, but the central AI prompt box becomes a URL box.
Left sidebar (glass): "Son", "Taslaklar", then section "ŞABLONLAR" with "Mobil odaklı", "Tam matris", "Motor karşılaştırma".
Top-right: "Aç" and "+ Yeni" buttons. Center: large URL box with placeholder "URL yapıştır…" and an "Aç →" button; below it three template chips.
Section "SON PROJELER" with grid/list toggle and a search field; a grid of Home/ProjectCard: "Marka A · 2 sa. önce", "Marka B · dün", "Untitled · 36 dk. önce" (draft style). Thumbnails are canvas snapshots.
Also produce: list view variant, empty state (no projects yet), and a context menu on a card: Yeniden adlandır / Finder'da göster / Kaldır. Light and Dark.
```

**4.5 Cihaz seçici ve viewport ekleme (karar 5).** Toolbar'daki "+ Cihaz" düğmesini seç:

```
Look at the selected "+ Cihaz" button. Design the popover it opens: search field on top, groups Telefon / Tablet / Masaüstü with device rows (name, W×H, SF symbol), a "Özel boyut…" row at the bottom with W and H steppers, and an engine picker (WebKit only for now, Chromium and Firefox greyed with "yakında"). Show the state right after adding: the new card appears at the end of the row and the canvas animates to fit (⌘1).
```

**4.6 Geliştirici paneli yeri (karar 7, M5+ için yalnızca iskelet).** Alt panel ve sağ panel olarak iki frame; içerik: diff listesi ("Buton Safari'de 12px aşağıda") ve senkron olay kaydı. Proxyman/TablePlus görsellerini referans ver. Bu ekrana şimdi derinlik harcama.

**4.7 Uygulama ikonu (karar 8).** pen.dev'de değil, Icon Composer'da yap; Liquid Glass katmanlı ikon için Apple'ın aracı bu ([Apple Design Resources](https://developer.apple.com/design/resources/)). pen.dev'de yalnızca 2–3 kavram eskizi üretip Icon Composer'a taşı.

### Adım 5 — İterasyon disiplini

1. **Seç, sonra iste.** Tüm canvas yerine ilgili frame'i (toolbar, sidebar, tek kart) seçip kısa istem ver; hem tutarlılık hem token açısından resmi öneri bu ([AI agents and Skills](https://docs.pen.dev/core-concepts/ai-agents)).
2. **Devam kalıbını kullan.** Yeni ekrana geçerken her zaman "Use the selected design as the base design, that's my current app. Design the X now." ([pen.dev/prompts](https://www.pen.dev/prompts)). Tema geçişi için "Look at the selected design. Change it to the dark mode. Create a new design for it."
3. **Küçük düzeltmeleri elle yap.** Etiket, hizalama, 4 px'lik kaydırma istemle değil Inspector'dan; token yakmıyor ([uxmagic.ai](https://uxmagic.ai/blog/pencil-dev-review)).
4. **Varyant için "Let it cook".** Yerleşim alternatifleri için Layout modu (stil sabit), görsel dil için Style modu; 2–3 varyantla sınırla.
5. **Queue ve Steering.** Çalışan ajana art arda kısa düzeltmeler kuyruğa atılabiliyor; uzun bir istem yerine beş kısa istem.
6. **Prompt blocks.** Kararı verilmiş istemleri canvas'a yapışkan not olarak koy; takım arkadaşının neyin neden değiştiğini görmesini sağlar ([designwithai.substack.com](https://designwithai.substack.com/p/exploring-pencildev-walkthrough-and-impressions)).
7. **Her gün sonunda kütüphaneyi güncelle.** Ekranlarda doğan yeni bileşeni (örn. `Viewport/SyncBadge`) `viewportix.lib.pen`'e taşı; kaynak değişince instance'lar belgeler yeniden açıldığında güncellenir ([Design Libraries](https://docs.pen.dev/core-concepts/design-libraries)).
8. **Snapshot/version al.** Her karar noktasında pen.dev'in snapshot/versions özelliğiyle sürüm işaretle; undo sınırlı raporlanıyor ([The Rundown AI](https://www.therundown.ai/tools/pencil)). `.pen` zaten Git'te; commit mesajına karar numarasını yaz.

### Adım 6 — Dışa aktarma ve SwiftUI geliştiricisine teslim

SwiftUI hedefi olmadığı için teslim paketi beş parçadan oluşur:

1. **Görsel referans.** Her ekran ve her kart durumu için 2x PNG; çoklu seçim ZIP olarak çıkar ([Import and Export](https://docs.pen.dev/core-concepts/import-and-export)). Dosya adları `window-project-light@2x.png`, `card-state-leader@2x.png` gibi; `docs/design/` altına.
2. **Ölçü kaynağı.** Aynı frame'lerin HTML+CSS dışa aktarımı; geliştirici kesin padding, radius, font boyutu ve renkleri buradan okur. HTML'i uygulamak için değil, değer tablosu olarak kullan.
3. **Token dosyası.** İstem: "Write all viewportix.lib.pen variables as a Swift file: an enum `DesignTokens` with static `Color`, `CGFloat` and `Font` values, Light and Dark via `Color(light:dark:)`." Resmi örnek CSS içindir ("Update globals.css with these pen.dev variables") ([Design ↔ Code](https://docs.pen.dev/design-and-code/design-to-code)); Swift çıktısı aynı mekanizmanın denenmemiş uzantısı, çıktıyı elle kontrol et.
4. **`.pen` JSON + Claude Code.** `.pen` belgelenmiş bir nesne ağacı olduğu için ([The .pen Format](https://docs.pen.dev/for-developers/the-pen-format)) Claude Code, pen.dev MCP'si veya CLI üzerinden dosyayı okuyup SwiftUI görünümlerine çevirebilir; resmi özellik değil, ajan işi. Önerilen istem (Claude Code'da): "Read design/viewportix.pen via the pen.dev MCP. For the frame 'Project Window', produce SwiftUI: `NavigationSplitView` with sidebar, `.toolbar` items matching the ToolbarItems slot, and a `ViewportCard` view with a `ViewportCardState` enum (default, leader, selected, syncMissed, snapshot, loading). Use DesignTokens for every value. Use `.glassEffect` only on sidebar/toolbar, never on the canvas." Geliştiricinin bu çıktıyı PLAN.md'deki `ViewportixKit` mimarisine uydurması gerekir; birebir yapıştırma beklenmemeli.
5. **İsteğe bağlı Figma kopyası.** Geliştirici Dev Mode ölçüm istiyorsa "pen.dev to Figma" veya PenFig plugin'leriyle `.pen`'i Figma'ya al ([Figma plugin](https://www.figma.com/community/plugin/1598907730561478304/pen-dev-to-figma), [PenFig](https://www.figma.com/community/plugin/1643726402305223297/penfig-pencil-dev-pen-to-figma-importer)). Üçüncü taraf oldukları için önce tek bir temsilî frame'le (iç içe component + Light/Dark) fidelity testi yap.

Paylaşım için pen.dev share linki yeterli; geliştirici yorumları orada bırakır (comments Free planda var) ([pen.dev pricing](https://www.pen.dev/pricing)). Teslim notunda SF Symbols adlarını (Lucide yer tutucuları değil), sistem kontrollerini (NSToolbar, source list, popover) ve HIG kurallarını (toolbar ≤ 3 grup, glass yalnızca kontrol katmanı) açıkça yaz; geliştirici `.pen`'deki her şeyi özel çizim sanmasın.

### Doğrulanamayan noktalar ve uygulama içinde nasıl test edilir

| Boşluk | Neden önemli | Nasıl doğrulanır |
|---|---|---|
| Giriş ekranı "Design Systems" bölümünün içeriği | Hazır macOS sistemi varsa Adım 2 kısalır | Boş projede bölümü aç, listeyi ekran görüntüsüyle DESIGN.md'ye ekle |
| "Recreate a screenshot" davranışı | Finder/Keynote görüntüsünden düzenlenebilir chrome çıkarabilir | Tek bir Finder penceresiyle dene; çıktı frame mi görsel mi bak |
| `.fig` import'unda değişken, component property ve glass efektlerinin korunması | Apple kitinin değeri buna bağlı | Kitten tek bir sidebar + toolbar frame'i import et; Variables panelini kontrol et |
| "Default libraries" adları | Shadcn/Lunarus iddiası ikincil kaynak | Libraries sekmesini aç |
| SVG dışa aktarma | Belgede yalnızca raster/PDF/HTML var | Bir ikon katmanında sağ tık menüsüne bak |
| Otomatik kaydetme ve undo derinliği | İlkbahar 2026 eleştirileri güncel olmayabilir | 20 adım geri al; dosyayı kaydetmeden kapat |
| Free planın "5 agent day" sınırının şu an uygulanıp uygulanmadığı | Haftalık iterasyon bütçesi | Settings → Billing; planlar çıkmadan ücretsiz olmalı |
| Swift token dışa aktarımı | Resmi örnek yalnızca CSS | Adım 6.3 istemini dene, çıktıyı derle |

## Sonuç

Araştırmanın asıl bulgusu şu: Viewportix'in arayüzünün yüzde yetmişi (pencere, toolbar, sidebar, popover, alert, materyaller, iki tema) Apple'ın kendi kitinde hazır ve pen.dev bu kiti `.fig` olarak alıp kütüphaneye çevirebiliyor; geriye kalan yüzde otuz (viewport kartı ve altı durumu, zoom menüsü, lider/senkron göstergeleri, giriş ekranının melez düzeni) hiçbir yerde hazır değil ve zaten ürünün farkını oluşturan parça bu. Rakip belgelerinin lider pane'i görsel olarak işaretlememesi, "senkron kaçtı" uyarısının ise hiçbir üründe bulunmaması, bu iki durumun tasarımını kopyalanacak bir kalıp değil, Viewportix'in özgün katkısı olarak ele almayı gerektiriyor.

pen.dev'in bilinen zayıflıkları (ekranlar arası tutarlılık, SwiftUI çıktısı yok, manuel senkron) bu projede yapısal engel değil; kütüphane + SKILL.md disiplini ve `.pen` JSON'unun Claude Code'a verilmesi, aracın tasarlandığı web akışının dışında bile işi taşıyor. Asıl pratik risk zaman değil, `.fig` import'unun Apple kitinin değişkenlerini ve glass efektlerini ne kadar koruduğu; bu tek deney ilk yarım saatte yapılmalı, çünkü sonucu kütüphanenin elle mi yoksa import'la mı kurulacağını belirliyor.
