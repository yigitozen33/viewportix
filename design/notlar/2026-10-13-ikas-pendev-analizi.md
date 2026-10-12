# ikas-pendev skill'i Viewportix aktarımına uyar mı? (2026-10-13)

Kaynak: `~/orca/ikas-pendev-skill` (SKILL.md 105 satır, references/ 9 dosya ~1.600 satır, 5 Python + 1 JS script ~5.500 satır), çıktılar `ismail-theme/docs/pendev`, `gizem-theme/docs/pendev`. Salt okuma; skill kullanılmadı.

## Bulgu
Skill ters yönde çalışır: referans → pen.dev'de tasarım → "port paketi"; kod yazmaz. Bize yarayan kısım sözleşme + manifest biçimi.

## Omurga
1. Adlandırma sözleşmesi: kök frame = kod birimi, katman = sınıf, metadata = rol (yaratılırken yazılır).
2. Token tablosu: 41 değişken, `mode`/`device` eksenleri, `[ölçüldü]/[tahmini]`.
3. Bileşen envanteri: katman ağacı + `{prop}`/`{data}` işaretleri + durumlar + prop tablosu.
4. Port manifest JSON + MD; canvas dökümü ↔ plan diff'i → açık sorular; 16 CHK salt-okunur kontrol (`CHK|id|PASS|n`).
Aşama kapıları (lint OK / kullanıcı onayı / CHK), append-only build log.

## ikas'a özgü (alınmaz, ~%70)
Prop tipleri, tema global'leri, section şablonları, veri sözlüğü, masaüstü/mobil parite, CSS/AnimeJS, Google Fonts kuralları, analyze_site.py, plan üretimi/lint.

## Bizde var / eksik
Var: ad → SwiftUI tablosu (§6), token dosyaları, durum listesi, etkileşim tabloları, HANDOFF + günlük.
Eksik: makinece okunur manifest; canvas ↔ belge tutarlılık kontrolü; etkileşim satırlarında id; CHK kontrolleri.

## Öneri (hafif sürüm, ~1 oturum)
1. `design/handoff/manifest.json`: pen.dev `Get`/`GetVariables` dökümü (bileşen: ad, nodeId, SwiftUI adı, durumlar, kullanıldığı frame'ler; ekran: ad, nodeId, PNG, bileşenler; token'lar).
2. Etkileşim satırlarına id (`PW-12`, `HOME-03`), tablo ekran başına bölünür.
3. CHK snippet'i: token dışı değer, instance olmayan chrome, tabloda satırı olmayan bileşen, PNG'si eski frame, kullanılmayan bileşen.
4. `design/handoff/README.md`: üç cümlelik sözleşme.
Alınmayacak: metadata yazma, plan/lint, parite, script altyapısı.
