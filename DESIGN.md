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
- **Sağ üst:** "Aç…" (dosya seçici), "+ Yeni" (boş proje, varsayılan şablonla) ve ikon-only ⚙ (Ayarlar). Giriş ekranında ray yok; ⚙ ya da ⌘, ayarlar panelini sağdan, üst satırın altından açar (⚙ görünür kalır ve basılı hal alır; arka plan hafif kararır; "Bu proje" bölümü gizli). Frame: `Home Window · Ayarlar paneli`.
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
| URL kutusuna yapıştır / yaz | "Aç →" hep sarı (boşken tık alana odaklanır); geçersizse mercan kenar + altında açıklama | 100 ms |
| ⏎ veya "Aç →" | Seçili şablonla proje penceresi açılır, giriş penceresi kapanır | Pencere geçişi 200 ms |
| Çipe tık | Çip seçilir (tek seçim); sarı kenar | 100 ms |
| Karta tık / ⏎ | Proje açılır | 200 ms |
| Kart hover | Kart kenarı `line/strong` olur, ⋯ belirir (⋯ yalnız hover ve sağ tıkta görünür) | 100 ms |
| Sağ tık / ⋯ | Bağlam menüsü imleçte; kart gök kenar alır | 120 ms fade + 4 px |
| Yeniden adlandır | Ad satırı yerinde metin alanına dönüşür; ⏎ kaydeder, Esc iptal | Anlık |
| Kaldır › | Alt menü: Listeden kaldır / Çöp Sepeti'ne taşı; taslakta "Taslağı sil…" + onay | Alt menü 120 ms; kart 150 ms daralır, ızgara 250 ms yeniden dizilir |
| ⊞ / ☰ | Izgara ↔ liste; tercih hatırlanır | 200 ms crossfade |
| Arama alanına yaz | Kartlar ad ve URL'de süzülür (taslaklar dahil); sonuç yoksa "“…” ile eşleşen proje yok" + Aramayı temizle | Süzme anlık; kartlar 150 ms fade |
| Esc (aramada) | Arama temizlenir, tüm projeler döner | 150 ms |
| Dosyası bulunamayan karta tık / Bul… | Dosya seçici; seçilen yer listeye yazılır, kart normale döner | — |
| Açılamayan proje | Sistem uyarısı (NSAlert): bozuk → Son taslağı aç / Finder'da Göster / Vazgeç; yeni sürüm → Güncellemeleri Denetle / Vazgeç (`home-file-errors@2x.png`) | Sistem |
| Arama | Ad ve URL'de süzer, eşleşme yoksa "Sonuç yok" | Anlık |
| "Son" / "Taslaklar" | Liste süzülür; seçim uygulama yeniden açılınca hatırlanır | 150 ms |
| ⌘O | "Aç…" dosya seçici | Sistem |
| ⚙ / ⌘, | Ayarlar paneli sağdan, üst satırın altından kayar; ⚙ basılı; tekrar ⚙, ✕ ya da Esc kapatır | 200 ms |
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
│ + Ekle   │       [ 🔗 ][ ⤢ ][ %100 ▴▾ ][ 📷 ]         │
└──────────┴───────────────────────────────────────────────────────┘
```

Üst çubuk yok. Üç kontrol yüzeyi, her biri tek iş yapar:

- **Sidebar (240, varsayılan açık):** üstte traffic lights, URL alanı ve geri/ileri/yenile; altında "SAYFALAR" listesi. **URL alanı odaklanınca** altında "SON" menüsü, URL kutusuyla aynı genişlik ve sol hizada, 4 px altında (canvas'a taşmaz): son 5 URL (favicon; adres ortadan kısaltılır; altında ne zaman; ↑↓ ⏎ ile seçilir, yazdıkça süzülür), altta "Geçmişi temizle" ve "Bu sayfayı listeye ekle: ⌘D" ipucu; geçmiş uygulamaya aittir, proje dosyasına girmez. **Sayfa listesi durumları** (`sidebar-states@2x.png`): hover'da satır zemini + sağda kalem ve ⋯; yeniden adlandırma yerinde metin alanı (gök kenar; ⏎ kaydet, Esc iptal); sürükle-bırak'ta satır kalkar (gölge, hafif eğim), hedefte gök ekleme çizgisi; açık URL listede yoksa en altta sarı kenarlı "Bu sayfayı ekle · /yol · ⌘D" satırı; boş durum "Henüz sayfa yok · Açık sayfayı ⌘D ile ekle."; "+ Ekle" her zaman en altta. Kapanınca ışıklar, sidebar düğmesi, nav ve URL canvas'ın üst solunda tek bir yüzen kapsüle taşınır (aynı sırayla), canvas tam genişliği alır.
- **Cihaz sekmeleri (canvas üstünde yüzen şerit):** açık viewport'lar sırayla; her sekme kartla aynı durumu taşır (lider gök çerçeve, senkron kaçtı mercan üçgen, yükleniyor dönen ikon, snapshot resim ikonu). Sığmayınca şerit kayar (kenarda solma + ok); sağda "+N" çipi gizli cihazların en ciddi durumunu gösterir (hata > lider > yükleniyor > normal: hata mercan kenar + üçgen, lider gök kenar + göz, yükleniyor dönen ikon, normal düz) ve menü açar ("GİZLİ CİHAZLAR"): her gizli cihaz için ad, boyut · motor · durum metni, odakla ve kapat düğmeleri. Etkileşimler aşağıdaki tabloda. Sekme adı asla kısaltılmaz, durum ikonu asla gizlenmez. Sonda "+ Cihaz".
- **Alt yüzen çubuk (ikon-only):** Senkron (sarı zincir; kapalıyken gri kırık zincir), Sığdır, zoom kontrolü (`Toolbar/ZoomControl`: yüzde metni + sağında dikey mini stepper ▲▼; yüzdeye tık → menü, ▲▼ kademeli zoom, yüzde yatay sürükle → sürekli zoom), ekran görüntüsü. Her ikonun hover'ında koyu tooltip: ad + kısayol. Bildirim kapsülü bu çubuğun üstüne çıkar; menü veya tooltip açıkken gösterilmez.
- **Ekran görüntüsü (alt çubuktaki kamera):** basınca hemen çekmez, çubuğun üstünde küçük bir seçici açılır: başlık "EKRAN GÖRÜNTÜSÜ · 3 VIEWPORT"; **Görünen alan** (her viewport'un şu an ekrandaki kısmı, ⌥⌘S) ve **Tam sayfa** (her viewport'un sayfanın tamamı, ⌃⌥⌘S); altta tek satır ayar özeti (panoya kopyala, ölçek, klasör → Ayarlar). Kısayollar seçiciyi atlar, doğrudan çeker. **Kart kamerası** aynı seçiciyi yalnız o viewport için açar ("EKRAN GÖRÜNTÜSÜ · iPhone 16": Görünen alan / Tam sayfa). Kart sağ tık menüsünde ekran görüntüsü seçeneği yok. Her yakalamadan sonra kapsül.
- **Zoom menüsü (çubuğun üstüne açılır):** Sığdır ⌘1, Seçimi sığdır ⌘2 · %25 / %50 / %100 / %200 (geçerli olan işaretli; yüzde Türkçe yazımla önde: "%100", sistem yerel ayarına göre) · Gerçek boyut ⌘0, Yakınlaştır ⌘+, Uzaklaştır ⌘−.
- **Viewport kartı:** kompakt tek satır başlık: cihaz adı, boyut, sağda motor ikonu ve kamera düğmesi. Motor yalnızca ikon; hover'da tooltip "WebKit 26 · macOS 26". Sığmazsa gizlenme sırası: önce boyut, sonra ad ortadan kısaltılır; motor ikonu ve kamera asla gizlenmez. Sekmeler motor göstermez; aynı cihaz iki motorda açılırsa sekme adı "iPad · Chromium" olur. Hover'da kapat / döndür / senkrondan çıkar kartın üstünde yüzen şeritte. Durumlar §4'te.
- **Canvas boş durumu** (`window-project-canvas-empty@2x.png`): projede viewport yokken ortada soluk üç hayalet kart çerçevesi, "Henüz viewport yok", "Bir cihaz ekle ya da şablon seç.", sarı "+ Cihaz ekle" ve yanında metin bağlantıları Mobil odaklı · Tam matris · Motor karşılaştırma, altta ⌥⌘N. Cihaz şeridinde yalnız "+ Cihaz" kalır.
- **Sayfa satırı sağ tık menüsü** (`sidebar-page-context-menu@2x.png`): Aç ⏎ · Yeniden adlandır (çift tık) · URL'yi kopyala ⇧⌘C · — · Yukarı taşı ⌥⌘↑ · Aşağı taşı ⌥⌘↓ · — · Kaldır ⌫ (mercan). İpucu: sayfanın URL'si.
- **Bildirim kapsülü halleri** (`toast-states@2x.png`): İlerleme (dönen ikon, "Ekran görüntüsü alınıyor… 2 / 3", eylem yok) → Başarı ("Kaydedildi ve kopyalandı · Finder'da Göster", 5 sn) · Kısmi hata (mercan kenar + üçgen, "Masaüstü yakalanamadı · Yeniden dene") · Hata ("Kaydedilemedi: disk dolu · Ayrıntılar"); hatalar kullanıcı kapatana kadar kalır.
- **Kart başlığı sağ tık menüsü:** Döndür ⌥⌘R · Boyutu düzenle… · Senkrondan çıkar (kapalıysa "Senkrona kat") · — · Motor › (M4'e kadar pasif, "WebKit 26") · — · Kaldır ⌫ (mercan). Sayfa alanında WebKit'in kendi menüsü kalır.
- **Boyutu düzenle:** kart başlığının altından açılan popover: Ad, Genişlik ⇄ Yükseklik (ortadaki düğme değiştirir), sınır ipucu "200–3840 × 200–4320 px" (dışındaysa alan mercan kenar, Kaydet pasif), İptal / Kaydet (sarı). Yeni kart için cihaz seçicinin "Özel boyut" satırı aynı sınırları kullanır.
- **Senkron kapalı viewport:** başlıkta boyutun yanında gri ‖ işareti (ipucu "Bu viewport için senkron kapalı"), içerik değişmez; hover şeridindeki ilk düğme kırık zincirden zincire döner ("Senkrona kat"). Projeye kaydedilir. Frame: `Card Actions`.
- **Lider göstergesi:** imlecin üstünde olduğu viewport gök çerçeve ve parlak başlıkla vurgulanır; sekmesi de aynı renkte.
- **"Senkron kaçtı" göstergesi:** başlıkta mercan üçgen, kartın altında "Element bu viewport'ta bulunamadı" notu; sekmede de üçgen.
- Inspector şimdilik yok; gelince seçeneklere bakılır. Geliştirici paneli §3.4.
- **Cihaz seçici (`Device/Picker`, "+ Cihaz" altına açılan popover, 660):** canvas görünür kalır. Üstte arama ("Cihaz ara ya da 1024×768 yaz": boyut yazınca doğrudan eklenir) ve motor seçici (WebKit; Chromium ve Firefox soluk "yakında"). Altında "SON" satırı: son kullanılan üç cihaz çip olarak. Gövde üç sütun: TELEFON / TABLET / MASAÜSTÜ, başlıkta cihaz sayısı; her sütun kendi sabit yükseklikli penceresinde (≈6 satır) bağımsız kayar, altta solma ve ince kaydırma çubuğu; liste uzamaz. Satır: ikon, ad, boyut, "+" (canvas'ta varsa gök tik). Altta "Özel boyut" W/H + sarı "Ekle"; sağda "Cihazları yönet… ↗" (Ayarlar › Cihazlar, §3.3). Frame: `Project Window · Cihaz seçici`. Reddedilen: tam ekran sheet (canvas kararır, küçük iş için ağır), tek sütun popover (uzun liste).

**Etkileşim tablosu (kod için sözleşme):**

| Tetikleyici | Etki | Hareket |
|---|---|---|
| Sekmeye tık | Canvas o karta kayar, kart `selected` olur | Canvas pan 250 ms ease-out; şerit gerekirse sekmeyi görünüre kaydırır |
| Sekmedeki ✕ | Viewport kapanır; sağdakiler sola kayar | Sekme 150 ms daralıp kaybolur; canvas yeniden dizilir 250 ms |
| "+N" çipine tık | Gizli cihaz menüsü açılır | 120 ms fade + 4 px yukarıdan |
| Menü satırına tık | Şerit o sekmeye kayar, sekme `selected`, canvas karta kayar, menü kapanır | Şerit kaydırma 250 ms; canvas pan 250 ms |
| Menü satırı odakla düğmesi | Canvas karta kayar ve kart `selected`; menü **açık kalır** | Canvas pan 250 ms |
| Menü satırı ✕ | Viewport kapanır, satır menüden düşer, N azalır | Satır 150 ms daralır |
| İmleç kartın üstünde | Kart `leader`; sekmesi gök çerçeve; hover şeridi belirir; kart seçiliyse krem halka yerinde kalır | 100 ms |
| Karta tık (boş alana değil) / sekmeye tık | Kart `selected`: dışta krem halka; önceki seçim kalkar; Esc ya da canvas boşluğuna tık seçimi kaldırır | 100 ms |
| Motor ikonu hover | Tooltip: motor adı + sürüm, altında işletim sistemi | 400 ms gecikme, 100 ms fade |
| Alt çubuk ikon hover | Tooltip (ad + kısayol) | 400 ms gecikme, 100 ms fade |
| Senkron düğmesi | Senkron aç/kapa; sarı ↔ gri, zincir ↔ kırık zincir | 150 ms |
| Zoom yüzdesine tık | Zoom menüsü çubuğun üstüne açılır | 120 ms fade + 4 px |
| Zoom ▲ / ▼ | Kademeli zoom (25, 50, 100, 200, 400); basılı tutunca tekrar | 150 ms ease-out |
| Zoom yüzdesini yatay sürükle | Sürekli zoom, 1 px = %1; ⇧ ile kademe atlar; imleç ↔ | Anlık |
| URL alanına odak | Altında SON menüsü (son 5 URL); yazdıkça süzülür; ⏎ seçileni açar | 120 ms fade + 4 px |
| Sidebar satırı hover | Zemin + kalem/⋯ belirir | 100 ms |
| Çift tık / kalem | Yerinde yeniden adlandırma; ⏎ kaydet, Esc iptal | Anlık |
| Satırı sürükle | Satır kalkar, hedefte gök çizgi; bırakınca sıralanır ve proje kaydedilir | 150 ms kalkış, 200 ms yerleşme |
| ⌘D | Açık URL sayfa listesine eklenir; "Bu sayfayı ekle" satırı kaybolur | 150 ms |
| Alt çubuk kamerası | Seçici: Görünen alan / Tam sayfa (tüm viewport'lar); seçince çeker, kapsül ilerleme gösterir | 120 ms fade + 4 px |
| Kart kamerası | Aynı seçici yalnız o viewport için, başlığın altında | 120 ms fade + 4 px |
| ⌥⌘S / ⌃⌥⌘S | Seçiciyi atlar: tüm viewport'ların görünen alanı / tam sayfası | — |
| Sidebar düğmesi / ⌃⌘S | Sidebar kapanır; ışıklar + nav + URL üst sol kapsüle taşınır | Sidebar 200 ms genişlik; kapsül 150 ms fade |
| "+ Cihaz" / ⌥⌘N | Cihaz seçici popover açılır, arama odaklı | 120 ms fade + 4 px |
| Seçicide satıra tık | Cihaz canvas sonuna eklenir, sekme belirir, tik gelir; popover **açık kalır**; canvas ⌘1 ile sığdırılır | Kart 200 ms belirir; canvas 250 ms |
| Seçicide ekli satıra tık | Canvas o karta kayar (çıkarmaz) | 250 ms |
| Aramaya "W×H" yaz + ⏎ | Özel boyut eklenir | — |
| Esc / dışarı tık | Popover kapanır | 100 ms |
| Kart başlığına sağ tık | Kart menüsü imleçte | 120 ms fade |
| Boyutu düzenle… | Popover başlığın altından; Kaydet → kart yeni boyuta animasyonla geçer, canvas yeniden dizilir | Popover 120 ms; kart 200 ms |
| Senkrondan çıkar / Senkrona kat | Kart ‖ işareti alır / bırakır; o viewport olay almaz | 150 ms |
| Kart başlığını sürükle | Kart gölgeyle kalkar, hover şeridi gizlenir; yakın kenar/üst/alt hizalarında gök çizgi, eşit aralıkta gök rozet (px); bırakınca konum projeye kaydedilir | Kalkış 120 ms; yapışma 6 px eşik; bırakma 150 ms |
| Sürüklerken ⌥ | Hizalama ve yapışma kapanır | Anlık |
| Viewport › Kartları Diz | Kartlar otomatik dizilime (tek sıra; gruplar açıksa grup içinde) döner | 250 ms |
| Görünüm › Grupla › Cihaz türü / Motor | Canvas'ta grup alanları + başlık; şeritte gruplar arası ayırıcı; Yok → tek sıra | 250 ms yeniden dizilim |
| Grup başlığı oku | Grup katlanır: alan başlık çipine iner, kartlar gizlenir, sağdakiler sola kayar; şeritte grubun sekmeleri tek çipe ("Telefon 2 ›") toplanır; tekrar tık açar (`window-project-groups-collapsed@2x.png`) | 200 ms |
| Şeritteki katlı grup çipine tık | Grup açılır, canvas gruba kayar | 200 ms + pan 250 ms |
| Hata kartında Yeniden dene / Şimdi dene | Yalnız o viewport yeniden yüklenir; ⌘R hepsi | Hata alanı yükleme çizgisine döner |
| `localhost` kapalı | 2 sn'de bir otomatik dener; sunucu açılınca sayfa kendiliğinden yüklenir | — |
| Sertifika › Bu oturumda güven | O ana makine uygulama kapanana kadar güvenilir sayılır; tüm viewport'lar yeniden yüklenir | — |
| Hata kapsülü › Hepsini dene | Hatalı tüm viewport'lar yeniden yüklenir | Kapsül 150 ms kaybolur |
| Sidebar sağ kenarı hover | İmleç ↔, kenar 2 px gök | 100 ms |
| Sidebar kenarını sürükle | Genişlik 200–360 arası değişir, yanında genişlik etiketi; bırakınca kaydedilir; 200 altı kapatmaz | Anlık |
| Tab / ⇧Tab | Odak sırası: sidebar başlığı → sayfa listesi → şerit → kartlar → alt çubuk → ray; odaktaki öğede 2 px gök halka (yalnız klavyede) | Halka 100 ms fade |

Kapat, döndür, senkrondan çıkar ve ekran görüntüsü eylemleri menü çubuğunda da bulunur (hover'a gizlenenler klavye ve menüden ulaşılabilir kalır).


### 3.2.1 Menü çubuğu ve kısayollar

Tek kaynak bu tablo; diğer bölümlerdeki kısayollar buna uyar. macOS standartları korunur (⌘N yeni belge, ⌘S kaydet, ⌃⌘S sidebar, ⌘L adres, ⌘, ayarlar). Her toolbar, ray ve kart eylemi menüde de bulunur. Frame: `Shortcut Map · Menü çubuğu` (00 bölümü).

| Menü | Madde → kısayol |
|---|---|
| Viewportix | Hakkında · Ayarlar… ⌘, · Gizle ⌘H · Çıkış ⌘Q |
| Dosya | Yeni Proje ⌘N · Aç… ⌘O · Son Kullanılanlar › · Kapat ⌘W · Kaydet ⌘S · Çoğalt ⇧⌘S · Yeniden Adlandır… · Giriş Ekranı ⇧⌘0 · Ekran Görüntüsü Al ⌥⌘S · Tam Sayfa Ekran Görüntüsü ⌃⌥⌘S |
| Görünüm | Sidebar'ı Gizle ⌃⌘S · Rayı Gizle ⌥⌘0 · Yakınlaştır ⌘+ · Uzaklaştır ⌘− · Gerçek Boyut ⌘0 · Sığdır ⌘1 · Seçimi Sığdır ⌘2 · Farklar ⌥⌘1 · Senkron Kaydı ⌥⌘2 · Grupla › Yok · Cihaz Türü · Motor · Arka Plandaki Medyayı Duraklat · Tam Ekran ⌃⌘F |
| Gezinme | Geri ⌘[ · İleri ⌘] · Yenile ⌘R · Adres Çubuğu ⌘L · Bu Sayfayı Listeye Ekle ⌘D · Sonraki Sayfa ⇧⌘] · Önceki Sayfa ⇧⌘[ |
| Viewport | Cihaz Ekle… ⌥⌘N · Kartları Diz · Döndür ⌥⌘R · Boyutu Düzenle… · Senkrondan Çıkar · Kaldır ⌫ · Senkron Açık ⇧⌘L · Sonraki Viewport ⌃⇥ · Önceki Viewport ⌃⇧⇥ · Seçimi Kaldır Esc |

Bağlama özel (odak panelde/listede): Farklar J/K, A Kabul, I Yoksay, T Takip et, ⏎ Göster · Senkron ↑↓, ⏎ göster, R yeniden dene · Sayfa listesi ⏎ aç, çift tık yeniden adlandır, ⌫ kaldır, ⌥⌘↑/↓ taşı · Popover ↑↓ ⏎, Esc · Zoom yüzdesi yatay sürükle. Giriş ekranında ⌘D kartı çoğaltır (Finder gibi; proje penceresinde sayfa ekler).

Grupla ve Kartları Diz kısayolsuz (⌥⌘D sistemin Dock kısayolu, kullanılmaz). Düzeltilen çakışmalar: ⌘S (seçili viewport ekran görüntüsü → kaldırıldı, Kaydet'e ait), ⇧⌘S (sidebar ve tüm ekran görüntüsü → sidebar ⌃⌘S, ekran görüntüsü ⌥⌘S), ⌘N ("+ Cihaz" → ⌥⌘N), ⌥⌘↑/↓ (sayfa geçişi → ⇧⌘]/[ ).

### 3.3 Sağ ray ve Ayarlar paneli

Proje penceresinin sağ kenarında 44 px **ray** (varsayılan açık; alttaki düğmeyle gizlenir, tercih hatırlanır; gizliyken sağ kenarda üstte 24×56 **tutamaç** kalır — ray ikonu, Farklar bulgusu varken mercan nokta; tık ya da ⌥⌘0 rayı geri getirir, hover "Rayı göster ⌥⌘0"; `window-project-rail-hidden@2x.png`; ⌘, ve kısayollar gizliyken de paneli açar): ⚙ Ayarlar, Cihazlar, MCP, Hesap; ayırıcı; Farklar, Senkron (M5); altta daralt. Rayın ikonuna tıklayınca ilgili panel açılır. **Varsayım (kullanımda doğrulanacak):** Ayarlar / Cihazlar / MCP / Hesap panelleri canvas'ın **üstüne kayar** (340 px, gölgeli, canvas yerinden oynamaz); Farklar ve Senkron panelleri canvas'ı **iter** (320 px, uzun süre açık kalır). Ayarlar panelinin başlığında yalnızca ✕; Farklar ve Senkron panellerinde ayrıca "pencereye çıkar" (⧉, ikinci ekrana almak için). ⌘, ayarları açar. Giriş ekranında ray yok; ⚙ düğmesi ve ⌘, aynı paneli açar (§3.1). Ayrı ayarlar penceresi yok.

**Ayarlar paneli içeriği** (`window-project-settings-panel@2x.png`: ray + üstüne kayan panel): üstte sekme çipleri Genel · Cihazlar · MCP · Hesap, arama; GÖRÜNÜM (Dil; Tema satırı açık temayla birlikte gelir, şimdilik çizimde ve uygulamada yok), PROJE (Varsayılan şablon; Senkron açık başlasın; Taslakları sakla), EKRAN GÖRÜNTÜSÜ (Klasör; Panoya da kopyala; Ölçek 1× / 2×); PROJE altında ayrıca "Arka plandaki viewport'larda medyayı duraklat" (**varsayılan açık**: ses ve video yalnızca imlecin üstündeki viewport'ta oynar, diğerleri durur ve sessizdir; Görünüm menüsünde de, tikli; canvas'ta düğmesi yok), **BU PROJE** (Cihazlar (n) → Cihazlar sekmesi; Motor). Sekme içerikleri:
- **Cihazlar** (`window-project-settings-devices@2x.png`, C1 iki satırlı liste): cihaz yönetimi; "Cihazları yönet…" buraya açılır. Üstte arama ("Cihaz ara"), sayaç "23 cihaz · 2 özel", "İçe aktar…", sarı "+ Cihaz"; altında tür süzgeci Tümü · Telefon · Tablet · Masaüstü · Özel. Satır iki satır: tür ikonu, ad (özel cihazda "özel" rozeti), altında "393×852 · 3× · Telefon"; sağda "Seçicide" toggle'ı, hover'da ⋯ (Düzenle, Çoğalt, Sil — Sil yalnız özel). Seçicide kapalı = "+ Cihaz" menüsünde görünmez, açık projelerdeki kartlar kalır. Yerleşik cihazlar silinemez, gizlenir. Özel cihazlar uygulamayla saklanır. Elenen: C2 türe göre gruplu tek satır, C3 yerinde ayrıntı.
- **MCP** (M7; `window-project-settings-mcp@2x.png`): SUNUCU — gök nokta + "Çalışıyor", altında "stdio · 2 istemci · 14 araç", sağda Durdur (durmuşken gri nokta + Başlat); Taşıma segmenti stdio / HTTP; komut kutusu (mono, "viewportix mcp --stdio") + Kopyala. İZİNLER — Ekran görüntüsü alma, Gezinme ve tıklama, DOM diff okuma (açık), Proje dosyası yazma (varsayılan kapalı). BAĞLI İSTEMCİLER — ad, "son istek 2 sn önce", sağda "Bağlantıyı kes".
- **Hesap** (`window-project-settings-account@2x.png`): üstte baş harfli avatar, ad, e-posta, sağda "Çıkış yap". TAKIM (takım adı, kişi sayısı), LİSANS (Plan: "Dahili"; iş modeli sonra), GÜNCELLEME (sürüm + "Güncel", Denetle; Otomatik güncelle toggle'ı, varsayılan açık).
- Reddedilenler: klasik ayrı pencere tek başına (çok klasik), canlı önizlemeli pencere (K1), onboarding kartları (K3); ⌘, ayar paleti (K2) ileride eklenebilir, şimdilik yok.

**Etkileşim tablosu:**

| Tetikleyici | Etki | Hareket |
|---|---|---|
| Ray ikonu / ⌘, | Panel açılır; aynı ikona tekrar tık kapatır | Kayan panel 200 ms sağdan; iten panel 200 ms genişlik |
| Farklar/Senkron ⧉ | Aynı panel ayrı pencerede; panel kapanır | 200 ms |
| Ray daralt düğmesi | Ray gizlenir, canvas genişler, sağ kenarda tutamaç belirir; tercih uygulamaya kaydedilir | 200 ms; tutamaç 150 ms fade |
| Tutamaca tık / ⌥⌘0 | Ray geri gelir, tutamaç kaybolur | 200 ms |
| Tutamaç hover | Tooltip "Rayı göster ⌥⌘0" solunda | 400 ms gecikme, 100 ms fade |
| Toggle / segment / select | Anında uygulanır, kaydet yok | 150 ms |
| Tema (açık temayla, ileride) | Tüm pencereler anında | 200 ms crossfade |
| Cihazlar › Seçicide toggle | Cihaz seçicide gizlenir/görünür | Anlık |
| Cihazlar › ⋯ › Sil | Özel cihaz silinir; açık kartlar kalır | Satır 150 ms daralır |
| MCP › Durdur / Başlat | Sunucu durur/başlar | 150 ms |

### 3.4 Geliştirici paneli (M5+): Farklar ve Senkron

Sağ raydan açılır, canvas'ı iter (320 px). Tasarım ilkesi: **sakin ama teknik** — iki seviye (özet satır → tek açılım), sakin durumda renk sıfır, tek renk = tek anlam (mercan = dikkat), sayılar sağa hizalı tabular, çizgi yerine boşluk, ikon yerine kelime, rozet yerine nokta, filtre tek menüden, kutlama yok. Frame'ler: `Dev Panel · Farklar (sakin)`, `· Senkron (sakin)`, `· Fark yok (sakin)`; dışa aktarımlar `devpanel-*-calm@2x.png`. Yoğun "pro" sürüm arşivde (`devpanel-*-pro@2x.png`), kullanımda eksik çıkarsa oradan parça alınır.

**Farklar:** başlık "Farklar", sağda tek menü `iPad ↔ iPhone 16 ▾` (baseline = lider viewport; karşılaştırılan seçilir) ve ⋯ (mod: Yan yana / Üst üste / Yanıp sönme; rapor; yoksayılanlar). Sütunlar ELEMAN / FARK. Satır: seçici, özellik (soluk), sağda fark (+12 px, 500 → 600). Yalnız dikkat isteyen satırda mercan nokta ve mercan değer. Satıra tık → açılır: "284 → 296 px · iPhone 16'da aynı fark · baseline: iPad" ve kelime düğmeler **Kabul** (sarı; baseline güncellenir) · Yoksay (seçici bazlı, projeye kaydedilir) · Takip et · Göster (canvas'ta eleman ince gök kutu + "+12 px" etiketi). Alt satır: mod · "1 / 3 incelendi" · Rapor. Sıfır durumu: "Fark yok" + "3 viewport, 142 eleman karşılaştırıldı · az önce". Aynı fark birden çok viewport'taysa tek satır, açıklamada belirtilir, tek karar.

**Senkron:** başlık "Senkron", sağda `Canlı ▾` (Canlı / Duraklatıldı) ve ⋯. Sütunlar OLAY / VIEWPORT. Satır: zaman (soluk), olay + argüman, sağda "3 / 3". Kaçıran satırda yalnız sayı mercan ("2 / 3"); açılınca "Masaüstü kaçırdı: .add-to-cart bulunamadı" ve **Yeniden dene** · Göster (canvas'ta beklenen konum mercan kutu + "bulunamadı"). Yukarı kaydırınca takip durur, altta "2 yeni olay ↓". Alt satır: Tasarımcı / Geliştirici kapsamı (geliştirici ağ ve konsolu da görür) · Duraklat · Temizle · Dışa aktar (JSON).

**Etkileşim tablosu:**

| Tetikleyici | Etki | Hareket |
|---|---|---|
| Satıra tık | Açılır (tek seviye); diğeri kapanır; canvas'ta eleman vurgulanır | 150 ms |
| J / K | Sonraki / önceki fark | 150 ms; canvas gerekirse kaydırır |
| Kabul (A) | Baseline güncellenir, satır listeden düşer, "incelendi" artar | 150 ms |
| Yoksay (I) | Seçici yoksayılanlara girer; ⋯ › Yoksayılanlar'dan geri alınır | 150 ms |
| Takip et (T) | Satır kalır, soluk işaret; sonraki karşılaştırmada yeniden ölçülür | Anlık |
| Yeniden dene | Olay yalnızca kaçıran viewport'ta tekrar çalışır; sayı güncellenir | Anlık |
| Yeni fark bulundu (panel kapalı) | Raydaki Farklar ikonunda mercan nokta | 150 ms |
| "2 yeni olay ↓" | Dibe kaydırır, takip yeniden başlar | 200 ms |

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
| Kart durumu `selected` (S3, çift halka): kartın dışında 3 px boşlukla 1.5 px krem halka (`ink/primary`); kartın kendi çizgisi değişmez. Lider ile bağımsız: içteki çizgi "lider mi?" (gök 2 px), dıştaki halka "seçili mi?" sorusunu yanıtlar; ikisi aynı anda görünebilir. Seçili kart imleç gidince kalır; sekmeye tık, "+N"/cihaz seçicide ekli satıra tık ve Farklar › Göster seçer; ⌘S, ⌘2, kapat/döndür kısayollarının hedefidir. S0 (2 px krem) lider ile çakıştığı için, S1 tutamaç ve S2 boyut etiketi ek öğe gerektirdiği için reddedildi | 2026-10-10 |
| Kısayol haritası tek tablo (§3.2.1): macOS standartları korunur, çakışmalar düzeltildi; zoom yüzdesi Türkçe yazımla "%100"; kart sağ tık menüsü, boyut düzenleme popover'ı ve "senkron kapalı" durumu (gri ‖); medya duraklatma Ayarlar › Proje | 2026-10-10 |
| Canvas boş durumu, sayfa satırı sağ tık menüsü, kapsülün ilerleme/kısmi hata/hata halleri (hata kalıcı, başarı 5 sn) | 2026-10-10 |
| Ekran görüntüsü: hem alt çubuk hem kart kamerası önce sorar (Görünen alan / Tam sayfa); "Seçili viewport" ve "Canvas'ı olduğu gibi" maddeleri kalktı (kart kamerası seçili viewport'un yerini aldı); kart sağ tık menüsünde ekran görüntüsü yok | 2026-10-10 |
| ~~Toolbar iki satır (üstte nav+URL+senkron, altta cihaz sekmeleri + zoom)~~ — yerini aldı, aşağıya bak | 2026-10-10 |
| Proje penceresi düzeni (B2): üst çubuk yok; URL ve nav sidebar'ın tepesinde; cihaz sekmeleri canvas üstünde yüzen şerit; senkron/sığdır/zoom/ekran görüntüsü alt yüzen çubukta; sidebar varsayılan açık (220), kapanınca ışıklar+nav+URL üst sol kapsüle taşınır; inspector sonra. Gerekçe: araştırmada zoom/sığdır hiçbir canvas aracında üst çubukta değil; yüzen paneller (Figma UI3, Sketch) geri alındı, yalnızca alt araç çubuğu kaldı; cihaz sekmeleri çoklu önizlemede canvas'ı tekrarlar, bu yüzden durum taşıyarak değer kazanır | 2026-10-10 |
| Cihaz sekmeleri durum taşır (lider/senkron kaçtı/yükleniyor/snapshot); taşmada kaydırılabilir şerit + "+N" durum çipi + gizli cihaz menüsü; ad kısaltılmaz. İkon-only sekmeler reddedildi (hata hangi cihazda, tek bakışta okunmalı) | 2026-10-10 |
| Alt çubuk ikon-only, tooltip koyu zeminli (ad + kısayol); zoom menüsü ve gizli cihaz menüsü çizildiği gibi; menüde "sidebar'da göster" yok, satırda seç (sekmeye kaydır + canvas'ta seç), odakla ve kapat var; davranışlar §3.2 etkileşim tablosunda | 2026-10-10 |
| Kart başlığında motor yalnızca ikon, sürüm hover tooltip'te; dar kartta gizlenme sırası boyut → ad kısaltma, motor ve kamera hep görünür. Tam ad/kısa kod rozetleri reddedildi (230 px'te uzun cihaz adıyla taşıyor). Motor ikonları özel SVG olacak (Lucide'de Chromium yok; logolar marka hakkı nedeniyle birebir kullanılmaz) | 2026-10-10 |
| Motor glifleri çizildi (`Engine Glyphs`, `engine-glyphs@2x.png`): WebKit pusula (halka + dört uçlu yıldız), Chromium üç parçalı halka + merkez disk, Firefox alev; 16×16 ızgara, 2 px band, path olarak kartta kullanılıyor | 2026-10-10 |
| Zoom kontrolü Z2: yüzde + dikey mini stepper (macOS stepper); bölünmüş stepper, hover'da açılan ve scrubber reddedildi. Yüzde ayrıca sürüklenebilir | 2026-10-10 |
| Giriş ekranı: başlık metni yok; şablon çipleri URL kutusunun altında kalır, sidebar'daki ŞABLONLAR bölümü M3'e ertelendi (MVP sidebar: Son, Taslaklar); kart küçük resmi canvas'ın son hali + ad yanında favicon; liste/boş durum/bağlam menüsü çizildiği gibi | 2026-10-10 |
| "Kaldır" iki aşamalı alt menü (Listeden kaldır / Çöp Sepeti'ne taşı); "+ Yeni" gri kalır (tek vurgu) | 2026-10-10 |
| Cihaz seçici: "+ Cihaz" altında 660 px popover, üç sütun (grup başına bağımsız kaydırma, sayı), SON çipleri, aramada boyut yazma, Özel boyut, "Cihazları yönet…" M3; sheet ve tek sütun reddedildi | 2026-10-10 |
| ~~Ayarlar ayrı pencere (880×680, sol sekmeler)~~ — kaldırıldı: ayarlar yalnızca sağ panel; giriş ekranında da aynı panel kayar | 2026-10-10 |
| Sağ ray (44 px) + paneller: ayarlar üstüne kayar, Farklar/Senkron iter (varsayım, kullanımda doğrulanacak); ayarlar içeriği Genel/Cihazlar/MCP/Hesap; K1/K2/K3 kreatif ayar konseptleri reddedildi, K2 paleti ileride | 2026-10-10 |
| Ray: proje penceresinde varsayılan açık, daraltılabilir, tercih hatırlanır (M5'te Farklar ikonundaki mercan nokta görünür kalsın). Giriş ekranında ray yok: sağ üstte ⚙ + ⌘, ayarlar panelini açar. Hep açık ray (B) ve otomatik gizlenen ray reddedildi | 2026-10-10 |
| Geliştirici paneli sakin tasarım: iki seviye, tek renk = dikkat, tabular sayılar, kelime düğmeler; baseline = lider, Kabul/Yoksay/Takip et; senkron satırında "n / n" ve kaçıranın adı açılımda | 2026-10-10 |
| Açık tema MVP dışı, ileride: token'lar `mode: light` değerleriyle hazır (hardal `#E6C800` vurgu; aynı sarı açık zeminde okunmuyor), `Project Window · Açık` ve `Home Window · Açık` frame'leri referans; uygulama şimdilik yalnızca koyu | 2026-10-10 |
| URL alanında son 5 geçmiş menüsü (uygulamaya ait, projeye girmez); sidebar durumları (hover, yerinde yeniden adlandırma, sürükle-bırak, "Bu sayfayı ekle" ⌘D, boş durum); ekran görüntüsü menüsü içeriği | 2026-10-10 |
| Uygulama ikonu: B6 "Vx monogram" — koyu zemin (#161412), sarı köşe bracket'leri (#FFF36B, 30 px uzunluk, 14 px kalınlık, 44 px kenar boşluğu @220), ortada krem "Vx" (#FAF8F5, kalın, sıkı letter-spacing). Eskiz `App Icon · B variants`, `app-icon-B-variants@2x.png`; üretim Icon Composer'da 1024 px, üç katman (zemin / bracket'ler / Vx). Elenenler: A üç genişlik, C V harfi, B1–B5 | 2026-10-10 |
| Yazı tipi: uygulamada sistem yazı tipi SF Pro (arayüz) + SF Mono (sayılar, seçiciler, ölçüler); pen.dev yalnızca Google Fonts çizdiği için tasarım dosyasında vekil Inter + JetBrains Mono. Marka fontu (Geist, IBM Plex, DM Sans, Manrope) karşılaştırıldı, reddedildi: native his ve Dinamik Tür korunur, kimliği palet + ikon + kart dili taşır | 2026-10-10 |
| Pencere chrome'u bileşen oldu: `Sidebar/Header`, `Window/CollapsedHeader`, `Window/DeviceStrip` (sekmeler slot), `Window/BottomBar`, `Window/Rail`; tüm proje penceresi frame'leri bunların instance'ı. Ray artık her proje penceresi frame'inde (varsayılan açık kararına uyum); şerit ve alt çubuk canvas'a göre ortalı; anatomi ve durumlar `Chrome Spec` (05) | 2026-10-10 |
| Medya duraklatma varsayılan **açık** (önceki "varsayılan kapalı" superseded): ses/video yalnızca imlecin üstündeki viewport'ta; canvas'ta düğmesi yok, yalnız Görünüm menüsü ve Ayarlar › Genel › PROJE | 2026-10-10 |
| Ayarlar › Cihazlar = C1 iki satırlı liste (tür süzgeci, Seçicide toggle, hover ⋯); MCP ve Hesap sekmeleri taslak gibi kesinleşti; üç sekme ayrı frame (`Project Window · Ayarlar › Cihazlar / MCP / Hesap`). Elenen: C2 gruplu tek satır, C3 yerinde ayrıntı | 2026-10-11 |
| Ray gizliyken sağ kenarda tutamaç (R2): ray ikonu + Farklar bulgusunda mercan nokta, tık / ⌥⌘0 geri getirir; frame `Project Window · Ray gizli`. Elenen: R1 hiçbir şey, R3 alt çubukta "Farklar n" çipi | 2026-10-11 |
| Sidebar 240 px (önceki "220" superseded; çizimler zaten 240) | 2026-10-11 |
| Boş URL alanı ipucu: "Adres yaz ya da yapıştır" (globe ikonu) | 2026-10-11 |
| Sayfa yüklenemedi halleri (`Card Load Errors`): hata kartın içinde, başlık + sekmede mercan üçgen; ağ / sertifika ("Bu oturumda güven", yalnız o ana makine) / `localhost` kapalı (2 sn'de bir otomatik dener) / adres bulunamadı; altta mono hata kodu; hepsi hatadaysa kapsül "Hepsini dene"; sitenin 404/500 sayfası olduğu gibi | 2026-10-11 |
| Kartı elle sürükleme: başlıktan tutulur, gölgeyle kalkar, hover şeridi gizli; gök hizalama çizgileri + eşit aralık rozetleri; ⌥ hizalamayı kapatır; konum projeye; Viewport › Kartları Diz otomatiğe döner | 2026-10-11 |
| Gruplama: Görünüm › Grupla (Yok / Cihaz türü / Motor); canvas'ta grup alanı (çizgi, köşe 16, hafif zemin) + katlanır başlık "TELEFON 2"; şeritte gruplar arası ince ayırıcı | 2026-10-11 |
| Sidebar yalnızca sayfalar (V1): cihaz listesi ve gruplar şeritte ve canvas'ta; PLAN.md M3 "Sidebar'da viewport listesi ve gruplar" maddesi şeride taşınır (PLAN'ı kod oturumu günceller). Elenen: V2 sidebar'da CİHAZLAR bölümü, V3 Sayfalar/Cihazlar sekmesi | 2026-10-11 |
| Klavye odak halkası gök (`status/leader`), 2 px, 2 px dışarıda, yalnız klavyede (F1). Elenen: F2 krem (seçim halkasıyla karışır) | 2026-10-11 |
| Sidebar genişlik tutamacı (6 px, hover/sürükleme 2 px gök kenar + genişlik etiketi, sınır 200–360, varsayılan 240, 200 altı kapatmaz); giriş ekranında aramada sonuç yok ("“…” ile eşleşen proje yok", Aramayı temizle Esc) | 2026-10-11 |
| Katlanmış grup: alan başlık çipine iner, şeritte "Telefon 2 ›" çipi; motora göre gruplama: grup başlığında motor glifi, sekme adı "iPhone 16 · Chromium" (M4) | 2026-10-13 |
| Proje dosyası sorunları: dosyası bulunamayan kart soluk + mercan "Dosya bulunamadı" + Bul…; açılamayan proje sistem uyarısı (bozuk → Son taslağı aç / Finder'da Göster / Vazgeç; yeni sürüm → Güncellemeleri Denetle / Vazgeç) | 2026-10-13 |
| VoiceOver etiket tablosu (§6) ve küçük ayrıntılar a–i (§5 madde 20: en küçük pencere 1024×640, tam ekranda 16 px üst boşluk, ray tooltip'leri, kısaltma kuralları, tek kapsül + Geri al, bağlantı bırakma, "senkron kurulamıyor" ‖, grup menüsü); j çoklu seçim MVP dışı. Kart başlığındaki ‖ işareti korunur (kırık zincir önerisi reddedildi) | 2026-10-13 |
| Token'la aynı değerdeki ham değerler token'a bağlanır (SnapshotPill, ProjectCard MiniHeader, tooltip/menü/popover yazı boyutları), boş dolgular (`#00000000`) kaldırılır; görünüm değişmez. Bilinçli ham kalanlar: kart içi örnek sayfa renkleri, trafik ışıkları, gölge ve solma renkleri (aktarım paketi aşama 3 bulgusu) | 2026-10-13 |
| Tooltip bileşen olur: `Window/Tooltip` → `ChromeTooltip` (gövde + ok; ad + kısayol); elle çizilmiş 8 tooltip instance'a çevrilir | 2026-10-13 |
| Tooltip ile hedef arası her yerde 8 px (ok ucundan); alt çubuk tooltip'indeki 6 px düzeltildi (Chrome Spec notu esas) | 2026-10-13 |
| Giriş bileşen durumları çizildi (`Home States`, `home-states@2x.png`): URL kutusu boş / dolu / geçersiz (mercan kenar + altında "Bu bir web adresi değil · örnek: marka.com"); "Aç →" **hep sarı** (U2; boşken tık alana odaklanır; §3.1'deki "etkinleşir" superseded). Elenen: U1 boşken gri | 2026-10-13 |
| Proje kartı hover kenarı yeni token `line/strong` (koyu `#4F4945`, açık `#C7C0B4`; H2). Elenen: H1 `ink/secondary` (seçim gibi görünüyor) | 2026-10-13 |
| Proje kartında ⋯ yalnız hover ve sağ tıkta görünür (ana kopyada gizli; bağlam menüsü ekranlarında açık). Önceki çizimlerde her kartta görünüyordu (superseded) | 2026-10-13 |
| İkonlar uygulamada SF Symbols (eşleme `design/handoff/icons.md`). Karşılığı olmayanlar: kırık zincir için özel sembol `link.slash` (`link`'ten türetilir; senkron kapalı, Senkrondan çıkar, adres hatalı); Farklar `square.split.2x1`, Senkron kaydı `waveform.path.ecg`, Döndür `rectangle.portrait.rotate`, Taslaklar `square.and.pencil`, localhost kapalı `server.rack`. Elenen: renkle anlatılan gri `link`; `arrow.left.and.right.square` + `list.bullet.rectangle`; Lucide'e en yakınlar (`arrow.counterclockwise` Geri al ile karışır) | 2026-10-13 |
| Cihaz seçicinin motor sütununda da kart başlığındaki motor glifleri (`Engine Glyphs`) kullanılır; Lucide yer tutucuları (pusula, kesikli halka, alev) kaldırıldı | 2026-10-13 |
| Token'a eşit ham değer kuralı ekranlara da uygulandı (138 yazı boyutu, 13 renk, 19 boş dolgu); grup alanı zemini yeni token `surface/group` (koyu `#FFFFFF05`, açık `#0000000A`); "Drag hint" zemini `surface/tooltip`'e bağlandı (`#0E0D0C` → `#0B0A09`). Elenen: grup zemini ham kalsın | 2026-10-13 |
| Belgeleme panoları (`Design System · Tokens`, `Shortcut Map`, `Engine Glyphs`, `App Icon · B variants`) ve keşif `Selected Options` CHK-1 (token dışı değer) dışında; arayüz frame'leri için kural sıkı | 2026-10-13 |

## 5. Bekleyen tasarım kararları

Öncelik sırasıyla, kullanıcıdan:

1. ~~Proje penceresi düzeni~~ — verildi (bkz. §4). Kalan: inspector (sonra)
2. ~~Viewport kartı: başlık içeriği, cihaz çerçevesi, selected~~ — verildi (bkz. §4)
3. ~~Genel görsel dil~~ — verildi (koyu canvas ve palet, bkz. §4). Açık tema ileriye bırakıldı (§4)
4. ~~Giriş ekranının görsel tasarımı~~ — verildi (bkz. §3.1, §4)
5. ~~Cihaz seçici ve viewport ekleme akışı~~ — verildi (bkz. §3.2)
6. ~~Lider ve "senkron kaçtı" göstergeleri~~ — verildi (`Viewport/Card` durumları ve sekme durumları, §3.2, §4)
7. ~~Geliştirici panelinin yeri~~ — verildi (sağ ray, §3.3–3.4)
8. ~~Uygulama ikonu~~ — verildi: B6 Vx monogram (bkz. §4); üretim Icon Composer'da
9. ~~Kart başlığındaki kamera düğmesi~~ — verildi (§3.2 kart başlığı)
10. ~~Ekran görüntüsü menüsü~~ — verildi (§3.2 alt çubuk)
11. ~~Bildirim kapsülü~~ — verildi (`Window/Toast`, §3.2)

12. ~~Sayfa yüklenemedi halleri~~ — verildi (2026-10-11, §4) (`Card Load Errors`, `card-load-errors@2x.png`): hata kartın içinde sayfanın yerinde; başlıkta ve sekmede mercan üçgen. Ağ hatası (Yeniden dene; ⌘R hepsi), Sertifika (Geri dön · Bu oturumda güven — yalnız o ana makine, uygulama kapanana kadar), `localhost` kapalı (2 sn'de bir kendiliğinden dener + Şimdi dene), Adres bulunamadı (Adresi düzenle → ⌘L). Altta küçük mono hata kodu. Hepsi aynı hatadaysa kapsül "Sayfa n viewport'ta açılamadı · Hepsini dene". Sitenin kendi 404/500 sayfası olduğu gibi görünür.
13. ~~Kartı elle sürükleme~~ — verildi (2026-10-11, §4) (`Project Window · Kart sürükleniyor`, `window-project-dragging@2x.png`): kart başlığından tutulur (sayfa alanı web içeriğidir); kart gölgeyle kalkar, hover şeridi gizlenir; gök hizalama çizgileri (üst/alt/kenar) ve eşit aralık rozetleri; ⌥ basılıyken hizalama kapalı. Konum projeye kaydedilir; Viewport menüsünde "Kartları Diz" otomatik dizilime döndürür.
14. ~~Gruplama~~ — verildi (2026-10-11, §4) (`Project Window · Gruplar (cihaz türü)`, `window-project-groups@2x.png`): Görünüm › Grupla: Yok / Cihaz türü / Motor. Canvas'ta grup alanı (ince çizgi, köşe 16, çok hafif zemin) ve başlık "TELEFON 2" + katla oku; şeritte gruplar arasında ince ayırıcı.
15. ~~Sidebar'da cihaz listesi~~ — verildi: V1 (2026-10-11, §4). Seçenekler arşivde (`Archive · Sidebar · Cihaz listesi seçenekleri`, `sidebar-device-list-options@2x.png`).
16. ~~Küçük durumlar~~ — verildi (2026-10-11, §4; `Misc States`, `misc-states@2x.png`): sidebar genişlik tutamacı (6 px görünmez, hover/sürüklemede 2 px gök kenar + genişlik etiketi, sınır 200–360, bırakınca kaydedilir, 200 altı kapatmaz); klavye odak halkası 2 px, yalnız klavyede — renk gök (F1; F2 krem reddedildi); giriş ekranında aramada sonuç yok ("“…” ile eşleşen proje yok", "Aramayı temizle Esc").

17. ~~Katlanmış grup ve motora göre gruplama~~ — verildi (2026-10-13, §4): `Project Window · Gruplar · katlanmış` (`window-project-groups-collapsed@2x.png`), `Project Window · Gruplar (motor, M4)` (`window-project-groups-engine@2x.png`; grup başlığında motor glifi, sekmede "iPhone 16 · Chromium").
18. ~~Proje dosyası sorunları~~ — verildi (2026-10-13, §4) (`Home File Errors`, `home-file-errors@2x.png`): dosyası bulunamayan kart (soluk küçük resim, mercan "Dosya bulunamadı", Bul…), açılamayan proje için sistem uyarısı metinleri.
19. ~~VoiceOver etiketleri~~ — verildi (2026-10-13; §6 "Erişilebilirlik etiketleri").
20. ~~Küçük ayrıntılar~~ — verildi (2026-10-13, §4; j MVP dışı) (`misc-states-2@2x.png`; a ve b için `window-project-min-size@2x.png`, `window-project-fullscreen@2x.png`):
    - a. Pencere en küçük boyutu **1024 × 640**; o boyutta sidebar + iki kart + ray sığar, üçüncü kart canvas'ta kaydırılır (frame `Project Window · En küçük boyut`).
    - b. Tam ekranda trafik ışıkları yok: sidebar'ın üstündeki 48 px satır **16 px**'e iner; pencere köşeleri düz (`Project Window · Tam ekran`).
    - c. Ray tooltip'leri öğenin solunda, 8 px boşlukla: Ayarlar ⌘, · Cihazlar · MCP · Hesap · Farklar ⌥⌘1 ("Farklar · 3 bulgu") · Senkron Kaydı ⌥⌘2 · Rayı Gizle ⌥⌘0; 400 ms.
    - d. Kısaltma: URL alanında alan adı korunur, yol ortadan kısalır ("marka.com/…/keten-gomlek"); sayfa satırı ve sekme (en çok 140 px) sondan "…", hover'da tam ad tooltip'te.
    - e. Aynı anda tek kapsül; yenisi eskisinin yerine geçer (150 ms crossfade); hata kapsülü başarı kapsülüyle ezilmez, başarı hata kapanana kadar bekler.
    - f. Kart kapatınca kapsül "iPad kapatıldı · Geri al" (5 sn; ⌘Z de geri alır; süre dolunca kesinleşir).
    - g. Pencereye bağlantı sürükle-bırak: canvas 2 px gök iç kenar + ortada "Bu adresi aç · marka.com/kampanya" kapsülü; bırakınca adres tüm viewport'larda açılır (listeye eklenmez, ⌘D ekler).
    - h. Sayfada senkron kurulamazsa (CSP, sandbox, about:blank, PDF): başlıkta gri ‖ + tooltip "Bu sayfada senkron çalışmıyor"; hover şeridinde zincir pasif; kapsül yalnız ilk seferde ("Neden?" açıklama).
    - i. Grup başlığında hover'da ⋯ (sağ tık da açar): Katla · Grubu sığdır · — · Gruptakileri kapat (mercan).
    - j. Çoklu seçim (⇧ tık; birlikte sürükle, ⌫ hepsini kapat, ⌘2 seçimi sığdır; "2 seçili" etiketi) — **MVP dışı**, çizim ileride için.

## 6. Tasarım sistemi (`design/viewportix.pen`)

**Renk** (koyu; her token'ın `mode: light` değeri de tanımlı, açık tema ileride): `canvas`, `surface/bar`, `surface/card`, `surface/header`, `surface/header-leader`, `surface/pill`, `surface/tooltip`, `line`, `line/strong` (hover kenarı), `surface/group` (grup alanı zemini, %2 beyaz), `ink/primary`, `ink/secondary`, `accent`, `accent/ink`, `status/leader`, `status/warning`, `status/warning-bg`.
**Köşe:** `radius/window` 16, `radius/bar` 14, `radius/card` 12, `radius/control` 8, `radius/badge` 6. **Aralık:** `space/1..8` = 4, 8, 12, 16, 24, 32. **Motor glifleri:** `Engine Glyphs` frame'inde üç `path` (viewBox 0 0 16 16, evenodd, fill `ink/secondary`; seçili/lider halde `status/leader`). **Yazı:** `font/ui` = Inter (vekil; uygulamada SF Pro), `font/mono` = JetBrains Mono (vekil; uygulamada SF Mono), `font/title` 15, `font/body` 13, `font/label` 12, `font/caption` 11, `font/micro` 10. **Çizgi:** `stroke/hairline` 1, `stroke/focus` 2. **Boyut (yalnızca referans; pen.dev width/height'ta değişken çözmüyor, değerler sayı yazılır):** `size/sidebar` 240, `size/bar-height` 48, `size/card-header` 36, `size/icon` 16, `size/icon-sm` 14, `size/rail` 44, `size/panel-overlay` 340, `size/panel-docked` 320. (2026-10-10 düzeltme: sidebar 220 ve iten panel 300 yazıyordu; çizimler 240 / 320, token'lar çizime eşitlendi; 240 kullanıcı kararıyla kesin, 2026-10-11.)

**Dosya düzeni (`design/viewportix.pen`):** üstte `00 · TASARIM SİSTEMİ` (`Design System · Tokens` panosu: renk, yazı, aralık/köşe/çizgi, bileşen → SwiftUI tablosu) ve `00b · BİLEŞENLER` (ana kopyalar); altında `01 · Giriş ekranı`, `02 · Proje penceresi`, `03 · Menüler ve durumlar`, `04 · Geliştirici paneli`, `05 · Bileşen durumları`, `06 · İkon ve glifler`. Keşifler `Archive ·` önekiyle solda, açık tema `Future ·` önekiyle arşivin altında.

**Koda aktarım:** `design/tokens/` — `viewportix.tokens.json` (W3C Design Tokens; koyu değer + `viewportix.light`), `DesignTokens.swift` (SwiftUI taslağı; `swiftc -typecheck` temiz), `README.md`. Kod oturumu buradan kopyalar.

| pen.dev bileşeni | SwiftUI | Durumlar |
|---|---|---|
| `Viewport/Card` | `ViewportCard` | `ViewportCardState`: default, leader, selected, syncMissed, snapshot, loading (selected lider ile birlikte, ayrı halka) |
| `Viewport/HoverStrip` | `ViewportHoverStrip` | yalnız hover |
| `Window/Toast` | `ToastCapsule` | menü/tooltip açıkken gizli |
| `Sidebar/Row` | `SidebarRow` | default, hover, selected, editing, dragging |
| `Toolbar/Button` | `ChromeButton` | ikon + etiket, ikon-only + tooltip |
| `Toolbar/DeviceTab` | `DeviceTab` | normal, leader, syncMissed, loading, snapshot |
| `Toolbar/ZoomControl` | `ZoomControl` | yüzde + ▲▼ |
| `Home/ProjectCard` | `ProjectCard` | normal, hover (`line/strong` + ⋯), draft, sağ tık hedefi (gök kenar + ⋯), dosya bulunamadı |
| `Home/TemplateChip` | `TemplateChip` | normal, selected |
| `Home/URLBox` | `URLBox` | empty, filled, invalid (Aç hep sarı) |
| `Device/Picker` | `DevicePicker` | popover |
| `Window/BottomBar` | `BottomBar` | syncOn, syncOff; düğme hover / basılı / menü açık; tooltip (400 ms) |
| `Window/DeviceStrip` | `DeviceStrip` | sekmeler (slot), boş (yalnız "+ Cihaz"), taşma (‹ › + "+N" çipi) |
| `Sidebar/Header` | `SidebarHeader` | URL dolu, odak (+ Son 5 menüsü), boş |
| `Window/CollapsedHeader` | `CollapsedSidebarHeader` | sidebar kapalıyken canvas sol üstünde (16, 16) |
| `Window/Rail` | `InspectorRail` | öğe: default, hover, active, badge; ray gizliyken `RailHandle` |
| `Window/RailHandle` | `RailHandle` | ray gizliyken sağ kenarda; badge (Farklar bulgusu), hover tooltip |
| `Window/Tooltip` | `ChromeTooltip` | ok aşağıda (varsayılan) / ok yok (yan tooltip); kısayol isteğe bağlı; hedefe 8 px, 400 ms gecikme |

**Pencere chrome'u** (`Chrome Spec` frame'i, 05 bölümü; `chrome-spec@2x.png`): her parçanın ölçüsü, token'ları ve durumları orada. Yerleşim: `DeviceStrip` canvas'ın üstünde ortada, üstten 16 px; `BottomBar` altta ortada, alttan 31 px; `CollapsedSidebarHeader` canvas sol üstünde 16, 16; `InspectorRail` pencerenin sağ kenarında, canvas'tan sonra. Ortalama canvas'a göredir (sidebar, ray ve iten panel çıkarıldıktan sonra kalan alan); bu parçalara bağlı menüler (zoom, ekran görüntüsü, "+N", cihaz seçici, tooltip) tetikleyicisine hizalı açılır ve onunla birlikte kayar.

**Erişilebilirlik etiketleri (VoiceOver, 2026-10-13 onaylandı):** ikon-only her denetimin etiketi Türkçe; durum "değer" olarak okunur.

| Denetim | Etiket | Değer / ipucu |
|---|---|---|
| Alt çubuk senkron | Senkron | Açık / Kapalı · ⇧⌘L |
| Sığdır | Sığdır | ⌘1 |
| Zoom kontrolü | Yakınlaştırma | "%100"; ayarlanabilir (↑↓ kademe) |
| Kamera (alt çubuk / kart) | Ekran görüntüsü al | Tüm viewport'lar / bu viewport |
| Sekme | `<cihaz adı>` | boyut; lider / senkron kaçtı / yükleniyor / senkron kapalı |
| Sekmedeki ✕ | `<cihaz>`ı kapat | — |
| "+N" çipi | `<n>` gizli cihaz | menüyü açar |
| "+ Cihaz" | Cihaz ekle | ⌥⌘N |
| Kart motor glifi | Motor | "WebKit 26 · macOS 26" |
| Hover şeridi | Senkrondan çıkar / Senkrona kat · Döndür · Kapat | — |
| Grup başlığı | `<grup>` grubu | `<n>` cihaz; açık / katlı |
| Ray öğeleri | Ayarlar · Cihazlar · MCP · Hesap · Farklar · Senkron kaydı · Rayı gizle | Farklar: "`<n>` bulgu" |
| Ray tutamacı | Rayı göster | ⌥⌘0; bulgu varsa "`<n>` fark" |
| Sidebar nav | Geri · İleri · Yenile | pasifse "kullanılamaz" |
| URL alanı | Adres | ⌘L |
| Sidebar düğmesi (kapsülde) | Kenar çubuğunu göster | ⌃⌘S |
| Giriş: ⚙ · ⊞ · ☰ · ⋯ | Ayarlar · Izgara görünümü · Liste görünümü · Diğer eylemler | seçili görünüm "seçili" |

**Bileşen kuralı:** Yeni ekranlar yalnızca bu token ve bileşenlerle kurulur; eksik bir parça gerekirse önce bileşen olarak eklenir.

## 7. Referanslar

- **Rakipler:** Polypane, Responsively, Safari Responsive Design Mode
- **Giriş ekranı:** pen.dev, Xcode Welcome penceresi, Sketch belge seçici
- **Canvas:** Figma, Xcode Previews
- **Native geliştirici araçları:** Proxyman, TablePlus, Tower
- **Diff:** Kaleidoscope, DevTools element overlay'i
- **Kurallar:** Apple Human Interface Guidelines
