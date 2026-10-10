# Kod oturumunun yapması gerekenler

> Tasarım oturumu CLAUDE.md, `.gitignore`, `docs/` veya kod dosyalarına dokunamaz. Aşağıdakileri kod oturumu yapar. Bitenleri `[x]` yap ve tarihle.
> Yazan: tasarım oturumu, 2026-10-10

## 1. Hafıza yapısı (Obsidian ile paralel çalışma)

- [ ] `.gitignore`'a ekle: `.obsidian/` ve `.trash/` (vault repo kökü olacak).
- [ ] `docs/HANDOFF.md` oluştur: kod oturumunun güncel durumu. **Üzerine yazılır**; yalnızca kod oturumu yazar. İçerik: şu an neredeyiz, sıradaki iş, açık sorular.
- [ ] `docs/oturumlar/` oluştur; her oturum sonunda `YYYY-MM-DD.md` ekle (yalnızca eklenir): karar, denenen/reddedilen, kanıt (commit, dosya yolu, test çıktısı).
- [ ] CLAUDE.md "Paralel oturumlar" kuralını güncelle: oturum başında kendi `HANDOFF.md`'ni ve karşı tarafınkini oku; tasarım tarafı `design/HANDOFF.md` + `design/notlar/`, kod tarafı `docs/HANDOFF.md` + `docs/oturumlar/`.
- [ ] CLAUDE.md'yi kısa tut; ayrıntı HANDOFF ve günlüklerde kalsın.
- [ ] İsteğe bağlı, sonra: SessionStart hook'u ile ilgili `HANDOFF.md`'yi bağlama ekle (çıktıyı küçük tut). Önce elle işe yaradığını gör.

Kurallar (araştırmadan): iki oturum aynı dosyaya yazmaz; notlara modelin inandığını değil kanıtı yaz; kesinleşen karar DESIGN.md/PLAN.md'ye taşınır, günlükte "işlendi" işaretlenir; eski karar silinmez, "superseded" yazılır.

## 2. Tasarımı uygulamak için (şimdilik beklemede)

- Tasarım henüz yok. Bileşen adları (`Window/Chrome`, `Viewport/Card`, `ViewportCardState`) ve durumlar hazır olunca `DESIGN.md` + `design/*.pen` + `design/exports/` üzerinden gelecek.
- O zamana kadar arayüz koduna tasarım kaynaklı değişiklik yapma.

## 3. Bilmen gerekenler

- CLAUDE.md'ye göre tasarım oturumu yalnızca `DESIGN.md` ve `design/`'i commit'ler. Kod oturumundaki commit edilmemiş Swift değişikliklerine dokunulmadı.
- Figma kullanılmıyor; tasarım kütüphanesi pen.dev'de elle kuruluyor (DESIGN.md §4).
