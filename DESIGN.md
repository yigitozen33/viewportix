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

Referans: pen.dev'in giriş ekranı. AI istem kutusunun yerini URL kutusu alır.

```
┌──────────┬───────────────────────────────────────────────────────┐
│ Son      │  Giriş                              [Aç]  [+ Yeni]    │
│ Taslaklar│                                                       │
│          │   ┌─────────────────────────────────────────────┐     │
│ ŞABLONLAR│   │ URL yapıştır…                        [Aç →] │     │
│ Mobil    │   └─────────────────────────────────────────────┘     │
│ Tam matr.│   ( Mobil odaklı ) ( Tam matris ) ( Motor karşılaş. ) │
│ Motor k. │                                                       │
│          │  SON PROJELER                          [⊞] [☰]  ara   │
│          │  ┌────────┐ ┌────────┐ ┌────────┐                     │
│          │  │ küçük  │ │ küçük  │ │ küçük  │                     │
│          │  │ resim  │ │ resim  │ │ resim  │                     │
│          │  ├────────┤ ├────────┤ ├────────┤                     │
│          │  │ Marka A│ │ Marka B│ │Untitled│                     │
│          │  │ 2 sa.  │ │ dün    │ │ 36 dk. │                     │
│          │  └────────┘ └────────┘ └────────┘                     │
└──────────┴───────────────────────────────────────────────────────┘
```

- URL kutusu + seçili şablon → yeni proje penceresi açılır.
- Kartlar: küçük resim, proje adı, son düzenleme zamanı, bağlam menüsü (yeniden adlandır, Finder'da göster, kaldır).
- Izgara ve liste görünümü, arama.
- Küçük resim canvas'ın son halinden otomatik üretilir.
- Kapsam: temel hali M2, küçük resimli ve şablonlu hali M3.

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
- **Cihaz sekmeleri (canvas üstünde yüzen şerit):** açık viewport'lar sırayla; her sekme kartla aynı durumu taşır (lider gök çerçeve, senkron kaçtı mercan üçgen, yükleniyor dönen ikon, snapshot resim ikonu). Sığmayınca şerit kayar (kenarda solma + ok); sağda "+N" çipi gizli cihazların en ciddi durumunu gösterir (hata > lider > yükleniyor > normal) ve menü açar: her gizli cihaz için ad, boyut · motor · durum metni, odakla düğmesi; altta "Tümünü sidebar'da göster". Sekme adı asla kısaltılmaz, durum ikonu asla gizlenmez. Sonda "+ Cihaz".
- **Alt yüzen çubuk:** Senkron açık/kapalı (sarı), Sığdır, zoom yüzdesi (menü), ekran görüntüsü menüsü. Bildirim kapsülü bu çubuğun üstüne çıkar.
- **Viewport kartı:** kompakt tek satır başlık: cihaz adı, boyut, sağda motor ve kamera düğmesi. Hover'da kapat / döndür / senkrondan çıkar kartın üstünde yüzen şeritte. Durumlar §4'te.
- **Lider göstergesi:** imlecin üstünde olduğu viewport gök çerçeve ve parlak başlıkla vurgulanır; sekmesi de aynı renkte.
- **"Senkron kaçtı" göstergesi:** başlıkta mercan üçgen, kartın altında "Element bu viewport'ta bulunamadı" notu; sekmede de üçgen.
- Inspector şimdilik yok; gelince seçeneklere bakılır. Geliştirici paneli §3.3.

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

## 5. Bekleyen tasarım kararları

Öncelik sırasıyla, kullanıcıdan:

1. ~~Proje penceresi düzeni~~ — verildi (bkz. §4). Kalan: inspector (sonra)
2. ~~Viewport kartı: başlık içeriği, cihaz çerçevesi~~ — verildi (bkz. §4). Kalan: kamera düğmesinin yeri onayı, selected rengi
3. ~~Genel görsel dil~~ — verildi (koyu canvas ve palet, bkz. §4). Kalan: açık tema paleti, yüzey ve ink tonları
4. Giriş ekranının görsel tasarımı
5. Cihaz seçici ve viewport ekleme akışı
6. Lider ve "senkron kaçtı" göstergeleri
7. Geliştirici panelinin yeri
8. Uygulama ikonu
9. Viewport kartı başlığındaki kamera (ekran görüntüsü) düğmesi. Kodda var, şimdilik sistem görünümünde (kod oturumundan, 2026-10-10)
10. Toolbar'daki ekran görüntüsü menüsü. Kodda var, şimdilik sistem görünümünde
11. Pencerenin altındaki bildirim kapsülü: "Kaydedildi ve kopyalandı · Finder'da Göster". Kodda var, şimdilik sistem görünümünde

## 6. Referanslar

- **Rakipler:** Polypane, Responsively, Safari Responsive Design Mode
- **Giriş ekranı:** pen.dev, Xcode Welcome penceresi, Sketch belge seçici
- **Canvas:** Figma, Xcode Previews
- **Native geliştirici araçları:** Proxyman, TablePlus, Tower
- **Diff:** Kaleidoscope, DevTools element overlay'i
- **Kurallar:** Apple Human Interface Guidelines
