# Hata kodları (VPX-NNNN)

Uyarıların altındaki mono satır (DESIGN.md §4 K8, HOME-13, PW-09): `VPX-0042 · JSON çözümlenemedi`. Seçilip kopyalanabilir; hata bildiriminde bu satır istenir. Kaynak: `Packages/ViewportixKit/Sources/ProjectModel/ErrorCode.swift` (bu liste onunla aynı tutulur; yeni kod eklenir, eskisi yeniden kullanılmaz).

| Kod | Neden | Nerede |
|---|---|---|
| **00xx dosya okuma** | | |
| VPX-0001 | Dosya bulunamadı | açılırken |
| VPX-0042 | JSON çözümlenemedi | `project.json` bozuk (HOME-13) |
| VPX-0043 | project.json eksik | paket var, içi eksik (HOME-13) |
| VPX-0044 | Dosya sürümü daha yeni | daha yeni Viewportix'le kaydedilmiş (HOME-13) |
| VPX-0050 | Okuma izni yok | |
| VPX-0099 | Dosya okunamadı | diğer okuma hataları |
| **01xx kaydetme** | | |
| VPX-0101 | Diskte yer yok | PW-09 |
| VPX-0102 | Yazma izni yok | PW-09 (Farklı Yere Kaydet…) |
| VPX-0103 | Aynı adlı dosya var | kaydet sayfası denetimi kaçırırsa |
| VPX-0110 | Taslak oluşturulamadı | Yeni / URL kutusu |
| VPX-0111 | Taslak silinemedi | HOME-08 |
| VPX-0120 | Kopya yazılamadı | Çoğalt (⇧⌘S) |
| VPX-0199 | Dosya yazılamadı | diğer yazma hataları |
| **02xx senkron** (M5 ile kullanılacak) | | |
| VPX-0201 | Senkron ajanı sayfaya giremedi | senkron kurulamıyor (‖ + "Neden?") |
| VPX-0202 | Senkron olayı ulaşmadı | |
| **03xx motorlar** | | |
| VPX-0301 | Web içeriği süreci kapandı | |
| VPX-0302 | Ekran görüntüsü alınamadı | |
