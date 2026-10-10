# S3 — Çapa tabanlı scroll senkronu

**Soru:** Farklı genişliklerde sayfa yükseklikleri farklıyken, bir viewport'ta scroll edince diğerlerinde aynı içeriği ekranda tutabiliyor muyuz? Basit yüzde eşlemesinden ne kadar iyi?

**Çıktı:** `Sources/sync-agent.js`, MVP'deki `SyncCore`'un ilk taslağı. M2'de `Packages/ViewportixKit/Sources/SyncCore/Resources/` altına taşınacak.

Atılabilir uygulama kodu; ajanın algoritması ürüne taşınır.

## Algoritma

1. **Okuma çizgisi:** Ekranın üstündeki sabit/sticky header'ların hemen altı (+8 px). Her viewport kendi çizgisini hesaplar, böylece farklı header yükseklikleri sorun olmaz.
2. **Lider yakalar:** Çizgideki elemanı (orta, sol, sağ noktalardan) ve atalarını aday olarak seçer; her aday için selector ve "çizgi elemanın yüzde kaçında" oranını gönderir. Ayrıca çizginin üstündeki en yakın başlığın **metnini** ve o bölümün içindeki oranı, son olarak da yüzde konumunu gönderir.
3. **Takipçi uygular**, sırayla:
   1. Kararlı selector'ler (`#id`, `data-testid`): aynı elemanın aynı noktası kendi okuma çizgisine.
   2. Başlık metni: aynı başlığı bulur, bölüm içinde aynı orana gider. Sayfa yapısı farklı olsa da başlıklar aynıysa tutar.
   3. Yapısal selector'ler (`nth-of-type` yolları): farklı DOM'da yanlış elemana gidebileceği için başlıktan sonra.
   4. Yüzde.
4. **Uçlar:** Lider en üstteyse veya en alttaysa takipçiler de oraya gider.
5. **Yankı koruması:** Uygulama yalnızca imlecin altındaki viewport'tan gelen olayları iletir. Takipçi kendi programatik scroll'u sırasında iki animasyon karesi boyunca olay göndermez.
6. **İzolasyon:** Ajan ayrı bir `WKContentWorld`'de çalışır. Sayfanın script'leri onu göremez veya bozamaz; DOM ortaktır.

## Ölçüm

Lider (telefon, sonra masaüstü) dört derinliğe (%15, %35, %55, %75) kaydırılır. Liderin okuduğu sütundaki içerik blokları (ekranın üst %40'ı, menü/header/kenar çubuğu hariç) not edilir. Her takipçi önce yüzdeyle, sonra çapayla senkronlanır; o blokların kaçının ekranda olduğu sayılır.

## Sonuçlar (2026-10-10)

| Sayfa | Çapa | Yüzde | Not |
|---|---|---|---|
| Fixture: uzun sayfa | 93% | 73% | |
| Fixture: sticky header | 100% | 79% | |
| Wikipedia makalesi | 79% | 28% | Telefon mobil arayüzü alıyor; bölümler kapalı. Başlık çapası 52% → 79% |
| MDN | 100% | 83% | |
| Apple ürün sayfası | 100% | 0% | |
| Stripe | 80% | 80% | |
| BBC News ana sayfa | ~60% | ~60% | Çok sütunlu ızgara; "aynı içerik" belirsiz |
| **Ortalama** | **87%** | **58%** | Hedef: çapa ≥ 80% ve yüzdeden iyi ✅ |

**Canlı akış:** Sayfa scroll'u → ajan mesajı → uygulama → takipçiler. 1 iletim, 0 yankı ✅. Koruma kapatılınca test 2 yankı yakalayıp başarısız oluyor; yani test gerçekten ölçüyor.

Gerçek siteler canlı içerik yüklediği için sonuçlar çalıştırmadan çalıştırmaya birkaç puan oynuyor.

## Bulgular

- **Aynı adres, farklı sayfa:** Mobil User-Agent bazı sitelerde (Wikipedia) bambaşka bir DOM getiriyor. Selector'e dayalı her senkron (tıklama dahil) bundan etkilenir. Başlık metni eşleştirmesi scroll için çözüyor; tıklama senkronu için de metin tabanlı yedek gerekecek.
- **Izgara sayfalar:** Haber ana sayfası gibi genişliğe göre yeniden dizilen ızgaralarda hiçbir yöntem "aynı yeri" garanti edemez. Kabul edilebilir sınır; bu sayfalarda "senkron kaçtı" göstergesi yerine sessiz yaklaşık davranış yeterli.
- **Kapsam dışı (planla uyumlu):** Sayfa içi scroll alanları (`overflow: auto` kutular), iframe içeriği.

## Çalıştırma

```sh
cd Spikes/S3-AnchorScroll && xcodegen generate && open S3AnchorScroll.xcodeproj   # ⌘R, sonra bir viewport'ta kaydır
Spikes/S3-AnchorScroll/run-selftest.sh                                          # otomatik ölçüm, ~3 dk
```

Self-test seçenekleri: `--only <sayfa adı parçası>`, `--verbose` (örnek bazında ayrıntı).
