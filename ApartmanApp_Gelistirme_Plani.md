# ApartmanApp Arıza ve Bildirim Sistemi Spesifikasyon Belgesi

Bu belge, **ApartmanApp** projesinin arıza takip ve bildirim mekanizmalarının işleyişini, kullanıcı rollerini ve "Blok Bazlı Canlı Takip" özelliğinin teknik akışını tanımlar.

---

## 1. Bildirim ve Arıza Yönetim Matrisi

Sistemdeki temel etkileşimler ve tetikleyici mekanizmalar aşağıdaki tabloda özetlenmiştir:

| Olay | Tetikleyici (Actor) | Alıcı (Recipient) | Bildirim Kanalı | Açıklama |
| :--- | :--- | :--- | :--- | :--- |
| **Yeni Arıza Kaydı** | Sakin | Yönetici | Push Bildirim | Sakin arızayı açtığında yöneticiye anlık uyarı gider. |
| **Arıza Yayını** | Sistem | Aynı Blok Sakinleri | Uygulama İçi (Badge) | Arıza listesinde ilgili bloğun yanında "!" işareti belirir. |
| **Durum Güncelleme** | Yönetici | Sahibi + Takipçiler | Push + In-app | "Usta atandı" veya "Parça bekleniyor" gibi durum değişimleri. |
| **Arıza Reddedildi** | Yönetici | Arıza Sahibi | Push Bildirim | Red nedeni (Örn: "Kullanıcı hatası") belirtilmesi zorunludur. |
| **Arıza Tamamlandı** | Yönetici | Sahibi + Takipçiler | Push Bildirim | Sorun çözüldüğünde tüm ilgili taraflara bilgi verilir. |
| **Genel Duyuru** | Yönetici | Tüm Sakinler | Push + Liste Üstü | Önemli duyurular (Su kesintisi vb.) en üstte sabitlenir. |
| **Daireye Özel Mesaj**| Yönetici | Sadece Hedef Daire | Push (Gizli) | Sadece ilgili daire sakinlerine özel (Borç, uyarı vb.). |

---

## 2. Gelişmiş "Blok Bazlı Takip" Mekanizması

Bu özellik, aynı blokta yaşayan kişilerin ortak sorunlardan haberdar olmasını ve mükerrer kayıtların önlenmesini sağlar.

### İşleyiş Akışı:
1.  **Arıza Görünürlüğü:** Bir sakin arıza talebi açtığında, bu talep sadece yöneticinin paneline değil, aynı zamanda uygulamanın "Blok Arızaları" sekmesine düşer.
2.  **Etkileşim Simgesi:** Arıza başlığının yanında bir **bildirim (çan/ünlem)** simgesi bulunur.
3.  **Abone Olma (Subscribing):** O bloğun diğer sakinleri bu simgeye bastığında, arıza sahibiyle aynı haklara sahip olur (bildirim alma açısından).
4.  **Kolektif Takip:** Yönetici bir güncelleme yaptığında (Örn: "Asansör kartı sipariş edildi"), sistemi takip eden tüm blok sakinleri aynı anda bildirim alır.

---



## 3. Kullanıcı Deneyimi (UX) Notları

* **Gereksiz Bildirimi Önleme:** Sakin, sadece "Takip Et" butonuna bastığı arızalar için anlık push bildirim almalıdır. Takip etmediği arızaları sadece listeye girdiğinde görmelidir.
* **Şeffaflık:** Arıza detay sayfasında "Bu sorunu [X] komşunuz daha takip ediyor" gibi bir ibare topluluk bilincini artırır.

