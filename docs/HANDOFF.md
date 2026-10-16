# Kod oturumu — güncel durum

> Bu dosya **üzerine yazılır**; yalnızca kod oturumu yazar. Tarihçe: `docs/oturumlar/`. Tasarım oturumu salt okur.
> Son güncelleme: 2026-10-16

## Şu an neredeyiz

- M0, M1 tamam; M2 (MVP) çalışıyor; M3 arayüz uygulaması başladı. Ayrıntı: PLAN.md §6.
- Özel arayüzde biten: **alt çubuk** (`BottomBar`, `ZoomControl`, `ChromeButton`; BAR-01…07), **tooltip** (`ChromeTooltip`), **giriş ekranı** (HOME-01…06, 08…12, 15, 16, 18; HOME-13 kısmen; HOME-07 ve HOME-17 yok). Kod: `Viewportix/Chrome/`, `Viewportix/Home/`.
- Proje penceresinin geri kalanı hâlâ sistem görünümünde (toolbar'da nav + adres + Cihaz Ekle; sidebar `List`; kart AppKit yer tutucu).
- Token'lar paket hedefi `DesignSystem`'de (`DesignTokens.swift`, `design/tokens/`'tan birebir kopya). Özel semboller (`link.slash`, `engine.*`) `Assets.xcassets`'te. İkonlar `ChromeSymbol` ile (kutu × 0.875, regular).
- Testler: 53 paket testi geçiyor (`swift test --package-path Packages/ViewportixKit`); uygulama derleniyor.
- Görüntü almak: `Scripts/snapshots.sh [klasör]` (DEBUG `--snapshots`, ekran dışı pencere, @2x, sRGB). Xcode önizlemesi bu makinede imza yüzünden derlenmiyor ("No Accounts"). Girdiler `Viewportix/Debug/PreviewSnapshots.swift`.

## Sıradaki iş

1. Tasarım oturumunun yanıtları: "spec: BottomBar" (12 madde), "iskelet" (aşama 9 ⛔ önerisi), giriş ekranı farkları, parite turu (`design/handoff/PARITY.md`).
2. `KOD-OTURUMU-ISLERI.md` §12 sırası: adım 2 pencere çerçevesi (şeffaf başlık, sidebar 240 + canvas + ray), 3 `SidebarHeader` / `SidebarRow`, 4'ün kalanı `DeviceStrip` + `ToastCapsule`, 5 `ViewportCard`.
3. Elle test: alt çubukta zoom menüsü konumu, ▲▼ basılı tutma, yüzde sürükleme (⇧ kademe), ekran görüntüsü seçicisi; giriş ekranında sağ tık menüsü, Bul…, sürükle-bırak.

## Açık sorular

- Elle testler bekliyor: S1 kontrol listesi, uygulamada kaydırma/tıklama senkronu, lider vurgusu, boyut sheet'i, yukarıdaki yeni etkileşimler (`orca computer` ile sürmek odak sorunu yüzünden çalışmamıştı).
- Şablon içerikleri (Mobil odaklı / Tam matris / Motor karşılaştırma) koddaki varsayılan; tasarım onayı bekliyor.
- Hover taklidi CORS'suz başka alan adı stil dosyalarında çalışmıyor; gerçek sitelerde ne kadar sık olduğu ölçülmedi.
- Dağıtım için Apple Developer Program (şirket hesabı) gerekecek.

## Tasarım oturumunun istekleri (`design/KOD-OTURUMU-ISLERI.md`) — durum

İşaretler burada tutuluyor; kod oturumu `design/` altına yazmaz.

- §1, §4, §5: 2026-10-10 durumunda (✅; SessionStart hook ⏸).
- §7 Token teslimi: `DesignTokens.swift` paket hedefi `DesignSystem`'de ✅ (2026-10-16, ddb295e). Görünüm adları §6 tablosuyla aynı (`BottomBar`, `ZoomControl`, `ChromeButton`, `ChromeTooltip`, `URLBox`, `TemplateChip`, `ProjectCard`) ✅. Motor glifleri artık sembol (§14 son madde) ✅.
- §8: zoom yüzdesi Türkçe yazım ✅ (sistem yerel ayarı); ekran görüntüsü önce seçici (alt çubuk) ✅; kalanlar kart/sidebar ile.
- §12: adım 1 ✅; adım 4'ten `BottomBar` ✅; adım 8 (giriş ekranı) ✅ (⚙ paneli ve yeniden adlandırma hariç).
- §13: giriş ekranı (sonuç yok, dosyası bulunamayan kart, NSAlert) ✅.
- §14: deneme (`BottomBar` PNG'siz) ✅ fe93bfd · `ChromeTooltip` ✅ 53365f3 · `lineStrong` ✅ · giriş durumları ✅ · SF Symbols + boyut kuralı ✅ · `surfaceGroup` + alfa ✅ (kopyalandı; kullanan grup alanı henüz yok) · kabul = etkileşim id'leri (commit'lerde anılıyor) ✅ · örnek sayfa fixture ✅ · iskelet değerlendirmesi ✅ ae79e90 · `link.slash` ve motor sembolleri Assets'te ✅.
- Aşama 8 parite: ilk tur başladı (giriş ekranı, 560d9ef); tasarımın karşılaştırması bekleniyor.
- Uygulama ikonu (`design/logo/Viewportix.icon`) alınmadı: logo kararı açık (kullanıcı, 2026-10-16).

## Tasarım tarafından son okunan

- `design/HANDOFF.md`, 2026-10-16 sürümü (6d09af8): aktarım paketi aşama 3 ve 9 kod oturumunu bekliyordu; logo dili ve ikon paketi eklendi.
