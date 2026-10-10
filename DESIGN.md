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
│ SAYFALAR │ ‹ › ⟳   https://marka.com/urun   + Cihaz  Sığdır 100% │
│ Ana sayfa├───────────────────────────────────────────────────────┤
│ Ürün   ● │                                                       │
│ Sepet    │  ┌ iPhone 16 · WebKit 26 ┐ ┌ iPad · WebKit ┐ ┌ Masa ┐ │
│ Ödeme    │  │                       │ │               │ │      │ │
│          │  │                       │ │               │ │      │ │
│ + Ekle   │  └───────────────────────┘ └───────────────┘ └──────┘ │
│          │                                                       │
└──────────┴───────────────────────────────────────────────────────┘
```

- **Sidebar:** projenin sayfa listesi. Tıklayınca tüm viewport'lar o sayfaya gider. Ekleme, kaldırma, yeniden adlandırma, sürükleyerek sıralama. "Bu sayfayı ekle" ile o an açık URL listeye girer. Gizlenebilir. M3'te viewport listesi ve gruplar da buraya gelir.
- **Toolbar:** geri/ileri/yenile, URL alanı, cihaz ekle, "Sığdır", zoom yüzdesi, senkron açık/kapalı.
- **Viewport kartı:** başlıkta cihaz adı, boyut, motor ve sürüm; kapatma; (M3) döndürme, senkrondan çıkarma, motor değiştirme.
- **Lider göstergesi:** imlecin üstünde olduğu viewport hafifçe vurgulanır.
- **"Senkron kaçtı" göstergesi:** tıklanan element bu viewport'ta bulunamadıysa başlıkta küçük bir uyarı.

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

## 5. Bekleyen tasarım kararları

Öncelik sırasıyla, kullanıcıdan:

1. Proje penceresi düzeni: sidebar varsayılan açık mı, inspector var mı
2. Viewport kartı: başlık içeriği, cihaz çerçevesi olacak mı
3. Genel görsel dil (his, vurgu ve lider renkleri)
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
