# Viewportix — UI/UX

> Son güncelleme: 2026-10-06 · Görsel tasarım kullanıcıya ait; bu dosya ekranları, akışları ve verilen kararları kaydeder.

## 1. İlkeler

- **Sade varsayılan.** Tasarımcı uygulamayı açıp URL yapıştırınca sonucu görmeli. Geliştirici araçları (diff paneli, selector bilgisi, motor ayrıntıları) isteyince açılır.
- **Motoru gizleme.** Her viewport hangi motorda ve hangi sürümde çalıştığını gösterir. "Gerçek motor" iddiasının güvenilirliği buna bağlı.
- **Figma alışkanlıkları.** Canvas hareketleri (pinch zoom, Space + sürükleme, "Sığdır") Figma ile aynı; yeniden öğrenme yok.
- **Kendi arayüzümüz, sistem davranışları.** Toolbar, sidebar, canvas, kartlar, göstergeler, kapsül, giriş ekranı ve cihaz seçici bizim tasarımımız; macOS sürümleri arasında aynı görünür, tam kontrol bizde. Pencere standart kalır (şeffaf başlık çubuğu, traffic lights, taşıma, tam ekran). Sistemden ödünç aldığımız: menü çubuğu ve kısayollar, klavye gezinmesi, VoiceOver etiketleri, Apple'ın dokunma hedefi ve boşluk ölçüleri (token olarak).

## 2. Bilgi mimarisi

```
Uygulama
├── Giriş ekranı (Home)        projeler, taslaklar, şablonlar
└── Proje penceresi            canvas + toolbar + paneller
    ├── Toolbar                URL, navigasyon, cihaz ekle, zoom, senkron
    ├── Canvas                 viewport kartları
    ├── Sidebar                sayfa listesi (M2); viewport listesi, gruplar (M3)
    └── Geliştirici paneli     diff sonuçları, senkron kaydı (M5+)
```

### Proje

Kullanıcının kaydettiği birim. Bir markanın (mağazanın) tüm kurulumunu taşır, böylece her açılışta yeniden kurmak gerekmez.

İçerik: sayfa listesi (ana sayfa, ürün, sepet...), cihaz seti, motor seçimi, canvas yerleşimi ve zoom, gruplar, küçük resim.

**Dosya tabanlı:** her proje bir `.viewportix` dosyası (JSON tabanlı paket). Gerekçe: şirket içinde paylaşılabilir (Slack, repo), macOS'un aç/kaydet, otomatik kaydetme ve "Son kullanılanlar" davranışı hazır gelir.

**Taslaklar:** Kaydedilmeden kapatılan projeler kaybolmaz; uygulama "Untitled" taslak olarak saklar ve giriş ekranında gösterir.

**Şablon:** URL'siz proje. Cihaz ve motor setini tanımlar ("Mobil odaklı", "Tam matris", "Motor karşılaştırma"). Kullanıcı kendi şablonunu kaydedebilir.

## 3. Ekranlar

### 3.1 Giriş ekranı

```
┌──────────┬───────────────────────────────────────────────────────┐
│ ● ● ●    │                                      [Aç…]  [+ Yeni]  │
│ Son      │                                                       │
│ Taslaklar│   ┌──────────────────────────────────────────────┐    │
│          │   │ 🔗 URL yapıştır…                      [Aç →] │    │
│          │   └──────────────────────────────────────────────┘    │
│          │   (▣ Mobil odaklı) ( Tam matris ) ( Motor karşılaş. ) │
│          │                                                       │
│          │  SON PROJELER                     [ara]      [⊞][☰]   │
│          │  ┌────────┐ ┌────────┐ ┌────────┐                     │
│          │  │ canvas │ │ canvas │ │ canvas │                     │
│          │  ├────────┤ ├────────┤ ├────────┤                     │
│          │  │▪Marka A│ │▪Marka B│ │▪Untitled  Taslak│            │
│          │  │2 sa.·3c│ │Dün ·5c │ │36 dk.·2c│                    │
│          │  └────────┘ └────────┘ └────────┘                     │
└──────────┴───────────────────────────────────────────────────────┘
```

1040×700, proje penceresiyle aynı palet ve bileşenler. Başlık metni yok; kutu kendini anlatır.

- **Sidebar (200):** ışıklar, "Son" (varsayılan seçili), "Taslaklar". "ŞABLONLAR" bölümü M3'te şablon yönetimiyle gelir; MVP'de şablon seçimi çiplerde.
- **Sağ üst:** "Aç…" (dosya seçici) ve "+ Yeni" (boş proje, varsayılan şablonla).
- **URL kutusu (`Home/URLBox`):** zincir ikonu, "URL yapıştır…", sağda sarı "Aç →". Yapıştırınca otomatik olarak https tamamlanır, geçersiz URL'de kutu mercan kenar alır ve altında kısa açıklama çıkar.
- **Şablon çipleri (`Home/TemplateChip`):** Mobil odaklı (varsayılan), Tam matris, Motor karşılaştırma. Seçili çip sarı kenar + parlak zemin. URL + seçili şablon → proje penceresi.
- **Son projeler:** "SON PROJELER" başlığı, arama alanı, ızgara/liste anahtarı. Kart (`Home/ProjectCard`): üstte canvas'ın son halinin küçük resmi (otomatik üretilen `thumbnail.png`), altta favicon + ad, meta satırı "2 sa. önce · 3 cihaz", sağda ⋯. Taslaklarda ad satırının yanında "Taslak" rozeti. Liste görünümü: Ad (favicon + ad + rozet), Cihazlar, Sayfalar, Düzenlendi, ⋯.
- **Boş durum:** soluk üç hayalet kart, "Henüz proje yok", "Yukarıya bir URL yapıştır ya da bir .viewportix dosyası aç."
- **Bağlam menüsü (sağ tık veya ⋯):** Aç ↩ · Yeniden adlandır ⏎ · Çoğalt ⌘D · — · Finder'da göster ⌘⇧R · Dosya yolunu kopyala · — · Kaldır › (mercan). "Kaldır" alt menü açar: **Listeden kaldır** ⌫ ("Dosya diskte kalır") ve **Çöp Sepeti'ne taşı** ⌘⌫ ("Finder'dan geri alınabilir"); açıklama satırları sayesinde ayrıca onay penceresi yok. Taslakta alt menü yok: "Taslağı sil…" tek seçenek, onay ister. Frame: `Home Window · Kaldır alt menüsü`.
- **"+ Yeni" gri kalır:** ekranda tek sarı vurgu "Aç →"; iki sarı düğme yarışır.
- Frame'ler: `Home Window`, `· Liste`, `· Boş durum`, `· Bağlam menüsü`. Dışa aktarımlar `design/exports/window-home-*.png`.

**Etkileşim tablosu:**

| Tetikleyici | Etki | Hareket |
|---|---|---|
| URL kutusuna yapıştır / yaz | "Aç →" etkinleşir; geçersizse mercan kenar + açıklama | 100 ms |
| ⏎ veya "Aç →" | Seçili şablonla proje penceresi açılır, giriş penceresi kapanır | Pencere geçişi 200 ms |
| Çipe tık | Çip seçilir (tek seçim); sarı kenar | 100 ms |
| Karta tık / ⏎ | Proje açılır | 200 ms |
| Kart hover | Kart kenarı `line`'dan bir ton parlar, ⋯ belirir | 100 ms |
| Sağ tık / ⋯ | Bağlam menüsü imleçte; kart gök kenar alır | 120 ms fade + 4 px |
| Yeniden adlandır | Ad satırı yerinde metin alanına dönüşür; ⏎ kaydeder, Esc iptal | Anlık |
| Kaldır › | Alt menü: Listeden kaldır / Çöp Sepeti'ne taşı; taslakta "Taslağı sil…" + onay | Alt menü 120 ms; kart 150 ms daralır, ızgara 250 ms yeniden dizilir |
| ⊞ / ☰ | Izgara ↔ liste; tercih hatırlanır | 200 ms crossfade |
| Arama | Ad ve URL'de süzer, eşleşme yoksa "Sonuç yok" | Anlık |
| "Son" / "Taslaklar" | Liste süzülür; seçim uygulama yeniden açılınca hatırlanır | 150 ms |
| ⌘O | "Aç…" dosya seçici | Sistem |
| Pencereye .viewportix sürükle | Dosya açılır; pencere kenarı gök çerçeve | 100 ms |

### 3.2 Proje penceresi

```
┌──────────┬───────────────────────────────────────────────────────┐
│ ● ● ●    │           [iPhone 16 ×][iPad ×][Masaüstü ⚠ ×][+ Cihaz] │
│ 🔒 URL   │                                                       │
│ ‹ › ⟳    │  ┌ iPhone 16 · 393×852 · WebKit ┐ ┌ iPad ┐ ┌ Masa ⚠ ┐ │
│ SAYFALAR │  │                              │ │      │ │        │ │
│ Ana sayfa│  │                              │ │      │ │        │ │
│ Ürün   ● │  └──────────────────────────────┘ └──────┘ └────────┘ │
│ Sepet    │                                                       │
│ Ödeme    │              ( ✓ Kaydedildi · Finder'da Göster )      │
│ + Ekle   │       [ Senkron açık ][ Sığdır ][ 100% ][ 📷 ]         │
└──────────┴───────────────────────────────────────────────────────┘
```

Üst çubuk yok. Üç kontrol yüzeyi, her biri tek iş yapar:

- **Sidebar (220, varsayılan açık):** üstte traffic lights, URL alanı ve geri/ileri/yenile; altında "SAYFALAR" listesi (tıklayınca tüm viewport'lar o sayfaya gider; ekleme, kaldırma, yeniden adlandırma, sürükleyerek sıralama; "+ Ekle"). Kapanınca ışıklar, sidebar düğmesi, nav ve URL canvas'ın üst solunda tek bir yüzen kapsüle taşınır (aynı sırayla), canvas tam genişliği alır.
- **Cihaz sekmeleri (canvas üstünde yüzen şerit):** açık viewport'lar sırayla; her sekme kartla aynı durumu taşır (lider gök çerçeve, senkron kaçtı mercan üçgen, yükleniyor dönen ikon, snapshot resim ikonu). Sığmayınca şerit kayar (kenarda solma + ok); sağda "+N" çipi gizli cihazların en ciddi durumunu gösterir (hata > lider > yükleniyor > normal) ve menü açar ("GİZLİ CİHAZLAR"): her gizli cihaz için ad, boyut · motor · durum metni, odakla ve kapat düğmeleri. Etkileşimler aşağıdaki tabloda. Sekme adı asla kısaltılmaz, durum ikonu asla gizlenmez. Sonda "+ Cihaz".
- **Alt yüzen çubuk (ikon-only):** Senkron (sarı zincir; kapalıyken gri kırık zincir), Sığdır, zoom kontrolü (`Toolbar/ZoomControl`: yüzde metni + sağında dikey mini stepper ▲▼; yüzdeye tık → menü, ▲▼ kademeli zoom, yüzde yatay sürükle → sürekli zoom), ekran görüntüsü. Her ikonun hover'ında koyu tooltip: ad + kısayol. Bildirim kapsülü bu çubuğun üstüne çıkar; menü veya tooltip açıkken gösterilmez.
- **Zoom menüsü (çubuğun üstüne açılır):** Sığdır ⌘1, Seçimi sığdır ⌘2 · 50% / 100% / 200% (geçerli olan işaretli) · Gerçek boyut ⌘0, Yakınlaştır ⌘+, Uzaklaştır ⌘−.
- **Viewport kartı:** kompakt tek satır başlık: cihaz adı, boyut, sağda motor ikonu ve kamera düğmesi. Motor yalnızca ikon; hover'da tooltip "WebKit 26 · macOS 26". Sığmazsa gizlenme sırası: önce boyut, sonra ad ortadan kısaltılır; motor ikonu ve kamera asla gizlenmez. Sekmeler motor göstermez; aynı cihaz iki motorda açılırsa sekme adı "iPad · Chromium" olur. Hover'da kapat / döndür / senkrondan çıkar kartın üstünde yüzen şeritte. Durumlar §4'te.
- **Lider göstergesi:** imlecin üstünde olduğu viewport gök çerçeve ve parlak başlıkla vurgulanır; sekmesi de aynı renkte.
- **"Senkron kaçtı" göstergesi:** başlıkta mercan üçgen, kartın altında "Element bu viewport'ta bulunamadı" notu; sekmede de üçgen.
- Inspector şimdilik yok; gelince seçeneklere bakılır. Geliştirici paneli §3.3.
- **Cihaz seçici (`Device/Picker`, "+ Cihaz" altına açılan popover, 660):** canvas görünür kalır. Üstte arama ("Cihaz ara ya da 1024×768 yaz": boyut yazınca doğrudan eklenir) ve motor seçici (WebKit; Chromium ve Firefox soluk "yakında"). Altında "SON" satırı: son kullanılan üç cihaz çip olarak. Gövde üç sütun: TELEFON / TABLET / MASAÜSTÜ, başlıkta cihaz sayısı; her sütun kendi sabit yükseklikli penceresinde (≈6 satır) bağımsız kayar, altta solma ve ince kaydırma çubuğu; liste uzamaz. Satır: ikon, ad, boyut, "+" (canvas'ta varsa gök tik). Altta "Özel boyut" W/H + sarı "Ekle"; sağda "Cihazları yönet… ↗" (M3, ayrı pencere). Frame: `Project Window · Cihaz seçici`. Reddedilen: tam ekran sheet (canvas kararır, küçük iş için ağır), tek sütun popover (uzun liste).

**Etkileşim tablosu (kod için sözleşme):**

| Tetikleyici | Etki | Hareket |
|---|---|---|
| Sekmeye tık | Canvas o karta kayar, kart `selected` olur | Canvas pan 250 ms ease-out; şerit gerekirse sekmeyi görünüre kaydırır |
| Sekmedeki ✕ | Viewport kapanır; sağdakiler sola kayar | Sekme 150 ms daralıp kaybolur; canvas yeniden dizilir 250 ms |
| "+N" çipine tık | Gizli cihaz menüsü açılır | 120 ms fade + 4 px yukarıdan |
| Menü satırına tık | Şerit o sekmeye kayar, sekme `selected`, canvas karta kayar, menü kapanır | Şerit kaydırma 250 ms; canvas pan 250 ms |
| Menü satırı odakla düğmesi | Canvas karta kayar ve kart `selected`; menü **açık kalır** | Canvas pan 250 ms |
| Menü satırı ✕ | Viewport kapanır, satır menüden düşer, N azalır | Satır 150 ms daralır |
| İmleç kartın üstünde | Kart `leader`; sekmesi gök çerçeve; hover şeridi belirir | 100 ms |
| Motor ikonu hover | Tooltip: motor adı + sürüm, altında işletim sistemi | 400 ms gecikme, 100 ms fade |
| Alt çubuk ikon hover | Tooltip (ad + kısayol) | 400 ms gecikme, 100 ms fade |
| Senkron düğmesi | Senkron aç/kapa; sarı ↔ gri, zincir ↔ kırık zincir | 150 ms |
| Zoom yüzdesine tık | Zoom menüsü çubuğun üstüne açılır | 120 ms fade + 4 px |
| Zoom ▲ / ▼ | Kademeli zoom (25, 50, 100, 200, 400); basılı tutunca tekrar | 150 ms ease-out |
| Zoom yüzdesini yatay sürükle | Sürekli zoom, 1 px = %1; ⇧ ile kademe atlar; imleç ↔ | Anlık |
| Sidebar düğmesi / ⌘⇧S | Sidebar kapanır; ışıklar + nav + URL üst sol kapsüle taşınır | Sidebar 200 ms genişlik; kapsül 150 ms fade |
| "+ Cihaz" / ⌘N | Cihaz seçici popover açılır, arama odaklı | 120 ms fade + 4 px |
| Seçicide satıra tık | Cihaz canvas sonuna eklenir, sekme belirir, tik gelir; popover **açık kalır**; canvas ⌘1 ile sığdırılır | Kart 200 ms belirir; canvas 250 ms |
| Seçicide ekli satıra tık | Canvas o karta kayar (çıkarmaz) | 250 ms |
| Aramaya "W×H" yaz + ⏎ | Özel boyut eklenir | — |
| Esc / dışarı tık | Popover kapanır | 100 ms |

Kapat, döndür, senkrondan çıkar ve ekran görüntüsü eylemleri menü çubuğunda da bulunur (hover'a gizlenenler klavye ve menüden ulaşılabilir kalır).


### 3.3 Geliştirici paneli (M5+)

Alt veya sağ panel. Motor diff listesi ("Buton Safari'de 12px aşağıda"), tıklayınca ilgili elementi overlay ile vurgular. Senkron olay kaydı.

## 4. Verilen tasarım kararları

| Karar | Tarih |
|---|---|
| Viewport'lar serbest canvas'ta, Figma hareket kuralları | 2026-10-06 |
| Proje = dosya (`.viewportix`), taslaklar otomatik saklanır | 2026-10-06 |
| Giriş ekranı pen.dev düzeninde, URL kutusu merkezde | 2026-10-06 |
| Geliştirici araçları varsayılan gizli | 2026-10-06 |
| Proje birden fazla sayfa tutar; sayfa listesi sidebar'da, MVP'de | 2026-10-06 |
| Figma / Apple UI kit aktarımı kullanılmaz; kütüphane pen.dev'de elle kurulur | 2026-10-10 |
| Obsidian vault = repo kökü; hafıza için oturum başına `HANDOFF.md` + tarihli günlük (`design/notlar/`) | 2026-10-10 |
| Arayüz tamamen bizim (A): toolbar, sidebar dahil; pencere standart (şeffaf başlık çubuğu), sistem davranışları (kısayol, klavye, VoiceOver, tam ekran) korunur; Apple metrikleri token olarak uyarlanır; her macOS sürümünde aynı görünüm; kendi yüzeylerimizde Liquid Glass yok | 2026-10-10 |
| Koyu canvas; renk paleti: vurgu sarı `#FFF36B`, lider gök `#8EC9E6`, uyarı yumuşak mercan `#FF8F85`; zemin sıcak siyah `#161412`. Sarı yalnızca eylem ve onay için (üstündeki yazı koyu `#141210`). Lider ve uyarı yalnızca renkle değil şekille de ayrışır (çerçeve + parlak başlık / üçgen ikon). Açık tema ayrıca çizilecek | 2026-10-10 |
| Viewport kartı: çerçevesiz (cihaz çerçevesi yok); kompakt tek satır başlık: ad, boyut, sağda motor ve kamera düğmesi (kamera başlıkta hep görünür, varsayım); hover'da kapat / döndür / senkrondan çıkar eylemleri kartın üstünde yüzen küçük bir şeritte (başlık değişmez, motor ve boyut her an görünür) | 2026-10-10 |
| Kart durumu `loading`: başlık altında 3 px açık krem ilerleme çizgisi + kamera yerine dönen yükleme ikonu (iskelet veya ortada kutu yok) | 2026-10-10 |
| ~~Toolbar iki satır (üstte nav+URL+senkron, altta cihaz sekmeleri + zoom)~~ — yerini aldı, aşağıya bak | 2026-10-10 |
| Proje penceresi düzeni (B2): üst çubuk yok; URL ve nav sidebar'ın tepesinde; cihaz sekmeleri canvas üstünde yüzen şerit; senkron/sığdır/zoom/ekran görüntüsü alt yüzen çubukta; sidebar varsayılan açık (220), kapanınca ışıklar+nav+URL üst sol kapsüle taşınır; inspector sonra. Gerekçe: araştırmada zoom/sığdır hiçbir canvas aracında üst çubukta değil; yüzen paneller (Figma UI3, Sketch) geri alındı, yalnızca alt araç çubuğu kaldı; cihaz sekmeleri çoklu önizlemede canvas'ı tekrarlar, bu yüzden durum taşıyarak değer kazanır | 2026-10-10 |
| Cihaz sekmeleri durum taşır (lider/senkron kaçtı/yükleniyor/snapshot); taşmada kaydırılabilir şerit + "+N" durum çipi + gizli cihaz menüsü; ad kısaltılmaz. İkon-only sekmeler reddedildi (hata hangi cihazda, tek bakışta okunmalı) | 2026-10-10 |
| Alt çubuk ikon-only, tooltip koyu zeminli (ad + kısayol); zoom menüsü ve gizli cihaz menüsü çizildiği gibi; menüde "sidebar'da göster" yok, satırda seç (sekmeye kaydır + canvas'ta seç), odakla ve kapat var; davranışlar §3.2 etkileşim tablosunda | 2026-10-10 |
| Kart başlığında motor yalnızca ikon, sürüm hover tooltip'te; dar kartta gizlenme sırası boyut → ad kısaltma, motor ve kamera hep görünür. Tam ad/kısa kod rozetleri reddedildi (230 px'te uzun cihaz adıyla taşıyor). Motor ikonları özel SVG olacak (Lucide'de Chromium yok; logolar marka hakkı nedeniyle birebir kullanılmaz) | 2026-10-10 |
| Zoom kontrolü Z2: yüzde + dikey mini stepper (macOS stepper); bölünmüş stepper, hover'da açılan ve scrubber reddedildi. Yüzde ayrıca sürüklenebilir | 2026-10-10 |
| Giriş ekranı: başlık metni yok; şablon çipleri URL kutusunun altında kalır, sidebar'daki ŞABLONLAR bölümü M3'e ertelendi (MVP sidebar: Son, Taslaklar); kart küçük resmi canvas'ın son hali + ad yanında favicon; liste/boş durum/bağlam menüsü çizildiği gibi | 2026-10-10 |
| "Kaldır" iki aşamalı alt menü (Listeden kaldır / Çöp Sepeti'ne taşı); "+ Yeni" gri kalır (tek vurgu) | 2026-10-10 |
| Cihaz seçici: "+ Cihaz" altında 660 px popover, üç sütun (grup başına bağımsız kaydırma, sayı), SON çipleri, aramada boyut yazma, Özel boyut, "Cihazları yönet…" M3; sheet ve tek sütun reddedildi | 2026-10-10 |

## 5. Bekleyen tasarım kararları

Öncelik sırasıyla, kullanıcıdan:

1. ~~Proje penceresi düzeni~~ — verildi (bkz. §4). Kalan: inspector (sonra)
2. ~~Viewport kartı: başlık içeriği, cihaz çerçevesi~~ — verildi (bkz. §4). Kalan: kamera düğmesinin yeri onayı, selected rengi
3. ~~Genel görsel dil~~ — verildi (koyu canvas ve palet, bkz. §4). Kalan: açık tema paleti, yüzey ve ink tonları
4. ~~Giriş ekranının görsel tasarımı~~ — verildi (bkz. §3.1, §4)
5. ~~Cihaz seçici ve viewport ekleme akışı~~ — verildi (bkz. §3.2)
6. Lider ve "senkron kaçtı" göstergeleri
7. Geliştirici panelinin yeri
8. Uygulama ikonu
9. Viewport kartı başlığındaki kamera (ekran görüntüsü) düğmesi. Kodda var, şimdilik sistem görünümünde (kod oturumundan, 2026-10-10)
10. Toolbar'daki ekran görüntüsü menüsü. Kodda var, şimdilik sistem görünümünde
11. Pencerenin altındaki bildirim kapsülü: "Kaydedildi ve kopyalandı · Finder'da Göster". Kodda var, şimdilik sistem görünümünde

## 6. Tasarım sistemi (`design/viewportix.pen`)

**Renk** (koyu; açık tema bekliyor): `canvas`, `surface/bar`, `surface/card`, `surface/header`, `surface/header-leader`, `surface/pill`, `surface/tooltip`, `line`, `ink/primary`, `ink/secondary`, `accent`, `accent/ink`, `status/leader`, `status/warning`, `status/warning-bg`.
**Köşe:** `radius/window` 16, `radius/bar` 14, `radius/card` 12, `radius/control` 8, `radius/badge` 6. **Aralık:** `space/1..8` = 4, 8, 12, 16, 24, 32. **Yazı:** `font/ui` (şimdilik Inter; hedef SF Pro), `font/title` 15, `font/body` 13, `font/label` 12, `font/caption` 11, `font/micro` 10. **Çizgi:** `stroke/hairline` 1, `stroke/focus` 2. **Boyut (yalnızca referans; pen.dev width/height'ta değişken çözmüyor, değerler sayı yazılır):** `size/sidebar` 220, `size/bar-height` 48, `size/card-header` 36, `size/icon` 16, `size/icon-sm` 14.

**Bileşenler:** `Viewport/Card` (6 durum), `Viewport/HoverStrip`, `Window/Toast`, `Sidebar/Row`, `Toolbar/Button`, `Toolbar/DeviceTab` (durum ikonlu), `Toolbar/ZoomControl`, `Home/ProjectCard`, `Home/TemplateChip`, `Home/URLBox`, `Device/Picker`. Yeni ekranlar yalnızca bu token ve bileşenlerle kurulur; eksik bir parça gerekirse önce bileşen olarak eklenir.

## 7. Referanslar

- **Rakipler:** Polypane, Responsively, Safari Responsive Design Mode
- **Giriş ekranı:** pen.dev, Xcode Welcome penceresi, Sketch belge seçici
- **Canvas:** Figma, Xcode Previews
- **Native geliştirici araçları:** Proxyman, TablePlus, Tower
- **Diff:** Kaleidoscope, DevTools element overlay'i
- **Kurallar:** Apple Human Interface Guidelines
