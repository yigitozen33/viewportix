# Aktarım paketi (tasarım → kod)

Sözleşme, üç cümle:

1. **pen.dev kök frame adı → SwiftUI View adı.** Eşleme DESIGN.md §6 tablosu ve `manifest.json` › `components[].swiftName`. Bileşenin durumları `states[]`; ölçüleri `specs/<SwiftName>.json`.
2. **`Project Window · <hal>` / `Home Window · <hal>` frame'i → ekranın bir durumu.** Hangi bileşenleri kullandığı ve PNG'si `manifest.json` › `screens[]`; davranışı DESIGN.md §3 etkileşim tablolarındaki id'li satırlar.
3. **pen.dev değişken adı → `DesignTokens` üyesi.** `color/ink/primary` → `DesignTokens.Color.inkPrimary`; zincir `design/tokens/` (pen → `viewportix.tokens.json` → `DesignTokens.swift`), elle düzenlenmez.

| Dosya | Ne | Nasıl yenilenir |
|---|---|---|
| `PLAN.md` | Aşamalar, ilerleme, oturum raporları | Her oturumda elle |
| `manifest.json` / `manifest.md` | Bileşen · ekran · PNG · nodeId dökümü + açık sorular | `dump-manifest.js` pen.dev `execute` içinde → çıktı `canvas-dump.json`'a → `python3 build_manifest.py` (açık soru varsa exit 1) |
| `exports-map.json` | Frame adı → PNG adı | Yeni frame dışa aktarılınca elle |
| `specs/*.json` + `specs/README.md` | Bileşen başına ölçülü katman ağacı, durum override'ları, ekranlardaki görünümler, token dışı değerler, durum kapsamı | `dump-specs.js` ve `dump-instances.js` pen.dev `execute` içinde → çıktıyı `python3 save_dump.py <çıktı> specs-dump.json` / `instances-dump.json` (hash denetimli) → `python3 build_specs.py` (açık soru varsa exit 1) |
| `checks.js` → `CHECKS.md` | Tutarlılık kontrolleri | Her tasarım değişikliğinden sonra |
| `icons.md` | Lucide → SF Symbols (+ özel semboller) | `dump-icons.js` → `save_dump.py <çıktı> icons-dump.json` → `python3 build_icons.py --verify`; yeni ikonda `build_icons.py` › `MAP`'e satır ekle |
| `PARITY.md` | Kod önizlemesi ↔ tasarım farkları | Parite turlarında |
| `../tokens/` | Token zinciri | `export-variables.js` → `pen-variables.json`; `gen_swift.py` |

Kurallar: `.pen` yalnızca pen.dev MCP ile okunur; bu klasörü yalnızca tasarım oturumu yazar; kod oturumu kopyalar, sorularını `docs/tasarim-istekleri.md`'ye yazar.
