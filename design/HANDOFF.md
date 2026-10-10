# Tasarım oturumu — güncel durum

> Bu dosya **üzerine yazılır**; yalnızca tasarım oturumu yazar. Tarihçe: `notlar/`. Kod oturumu salt okur.
> Son güncelleme: 2026-10-10

## Şu an neredeyiz

- pen.dev MCP bağlantısı çalışıyor. Açık dosya şimdilik `~/Desktop/viewportix.pen` (boş, 800×600 tek frame). `design/` altına taşınmadı.
- Karar: Figma / Apple kit aktarımı **yok**. `viewportix.lib.pen` pen.dev'de elle kurulacak (DESIGN.md §4, 2026-10-10).
- Henüz değişken, bileşen veya ekran yok.

## Sıradaki iş

1. `.pen` dosyalarını `design/viewportix.lib.pen` ve `design/viewportix.pen` olarak repoya taşı (kullanıcı pen.dev'de yeniden açacak).
2. Referans: Apple HIG sayfaları ve kullanıcının vereceği Finder/Keynote ekran görüntüleri.
3. Değişkenler (Light/Dark): `surface/*`, `ink/*`, `accent`, `status/*`, boyutlar, aralıklar.
4. `Window/Chrome`, sonra `Viewport/Card` ve altı durumu (default, leader, selected, syncMissed, snapshot, loading).
5. Kod oturumundan gelen yeni öğeler tasarıma girecek (DESIGN.md §5, madde 9–11): kart başlığında kamera düğmesi (`Viewport/Card` hover/başlık satırı), toolbar'da ekran görüntüsü menüsü, pencere altında bildirim kapsülü ("Kaydedildi ve kopyalandı · Finder'da Göster").
6. Her görsel karar kullanıcıya sorulur, DESIGN.md §4'e tarihiyle işlenir.

## Açık sorular (kullanıcıya)

- `.pen` dosyalarının taşınması ve referans kaynağı (HIG sayfaları mı, ekran görüntüsü mü).
- Başlangıç: değişkenlerle mi, kaba proje penceresiyle mi.

## Oturum başında oku

- `docs/tasarim-istekleri.md` (kod oturumunun tasarıma bıraktığı istekler): son işlenen girdiden sonrakileri DESIGN.md §5'e işle ve aşağıya "son işlenen" yaz.
- Son işlenen: yok (dosya henüz oluşturulmadı)

## Kurallar

- Yazma alanı: yalnızca `DESIGN.md` ve `design/`. Kod oturumunun işleri için `design/KOD-OTURUMU-ISLERI.md`.
- `.pen` dosyalarına yalnızca pen.dev MCP ile eriş.
- Notlara kanıt yaz (dosya yolu, commit, ekran görüntüsü); modelin "inandığını" değil, doğrulananı.
