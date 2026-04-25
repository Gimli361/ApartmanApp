# ApartmanApp — Backend Eksikler & Geliştirme Planı

_Son güncelleme: 2026-04-12_

---

## Mevcut Durum

### Tamamlananlar ✅

**Backend (ApartmanAPI):**
- Kullanici CRUD (`GET`, `POST`, `DELETE`)
- Ariza CRUD (`GET`, `POST`, `PATCH durum`, `DELETE`)
- Ariza Foto upload/listeleme/silme (`/api/ariza/{id}/foto`)
- `FcmToken` alanı `Kullanicilar` tablosuna eklendi (migration: `AddFcmToken`)
- `PUT /api/kullanici/{id}/fcm-token` endpoint'i eklendi
- `ArizaListDto`'ya `Aciklama`, `BildirenId`, `BildirenDaireNo` alanları eklendi
- JWT olmadan geçici email eşleşmeli giriş

**Flutter (ApartmanApp):**
- Login, Logout (onay dialog'lu)
- Arıza listesi (filtre, refresh, swipe-to-delete)
- Arıza detayı (fotoğraf galerisi + tam ekran görüntüleyici)
- Arıza bildirme (foto seçimi kamera/galeri, upload hata bildirimi)
- MainScaffold: AppBar + kullanıcı avatar menüsü (ad, email, daire, logout)
- Aidat / Bildirim / Oylama: "Yakında" placeholder ekranları
- FCM token login sonrası backend'e gönderiliyor
- Riverpod router hatası düzeltildi (`ref.read` → `notifier.isLoggedIn`)
- `ArizaModel.fromJson` enum string parse düzeltildi (`JsonStringEnumConverter` uyumu)
- `UserModel.fromJson` `adSoyad` + int rol parse düzeltildi

---

## Yapılacaklar

### ✅ 1. JWT Authentication — TAMAMLANDI

**Yapılanlar:**
- [x] `Kullanici` entity'e `SifreHash` alanı eklendi + `AddSifreHash` migration oluşturuldu
- [x] BCrypt ile şifre hashleme (`BCrypt.Net-Next` paketi) — kayıt + doğrulama
- [x] `POST /api/auth/login` → email + şifre al, JWT token döndür
- [x] `IAuthService` / `AuthService` implementasyonu
- [x] `Program.cs`'e JWT middleware eklendi (`AddAuthentication`, `AddJwtBearer`)
- [x] Swagger'a Bearer JWT desteği eklendi
- [x] Flutter `auth_repository_impl.dart` → `/api/auth/login` endpoint'ine geçti
- [x] Token `SecureStorage`'a kaydedildi, her istekte `Authorization: Bearer` header'ı ekleniyor
- [x] Uygulama başlangıcında token yükleniyor, 401 gelince otomatik logout
- [x] `appsettings.json`'a JWT konfigürasyonu eklendi
- [ ] ⚠️ Migration uygulanacak: PostgreSQL açıkken `dotnet ef database update` çalıştır
- [ ] Kayıtlı kullanıcıların şifreleri güncellenmeli (mevcut kayıtlar SifreHash=boş)

---

### ✅ 2. Firebase Admin SDK & Push Bildirim — TAMAMLANDI

- [x] `FirebaseAdmin` NuGet paketi eklendi
- [x] `Bildirim` entity + migration `AddBildirim` (DB kaydı)
- [x] `IFcmService` / `FcmService` — tek token'a FCM gönderim
- [x] `IBildirimService` / `BildirimService` — 4 senaryo:
  - Arıza durumu değişince → arızayı bildirene push + DB kaydı
  - Yeni arıza → tüm adminlere push + DB kaydı
  - Yönetici → tüm sakinlere duyuru (`POST /api/bildirim/duyuru`)
  - Yönetici → belirli daireye mesaj (`POST /api/bildirim/daire`)
- [x] `BildirimController` — GET, okundu PATCH, duyuru POST, daire POST
- [x] Flutter `BildirimModel` fromJson eklendi
- [x] Flutter `BildirimRepositoryImpl` — API entegrasyonu
- [x] Flutter `BildirimListScreen` — gerçek liste, okundu/okunmadı badge
- [x] `MainScaffold` — bildirim sekmesinde okunmamış sayı badge'i
- [x] `UserModel.fromJson` — rol string parse düzeltildi

---

### ✅ 3. Aidat Modülü — TAMAMLANDI

- [x] `OdemeDurumu` enum (Beklemede/Odendi/Gecikti)
- [x] `Aidat` entity + `AidatConfiguration`
- [x] `AddAidat` migration oluşturuldu ve uygulandı
- [x] `AidatListDto`, `AidatCreateDto`, `AidatOdemeDurumGuncelleDto`
- [x] `IAidatService` + `AidatService` implementasyonu
- [x] AutoMapper profili güncellendi
- [x] `AidatController`: GET all (admin), GET by kullanici, GET by id, POST (admin), PATCH odemeDurumu (admin), DELETE (admin)
- [x] Flutter: `AidatModel.fromJson`, `AidatRepository`, `AidatRepositoryImpl`, `AidatProvider`, `AidatListScreen` (admin/sakin farklı görünüm)
- [x] Flutter: `AidatCreateScreen` — admin sakin seçip aidat oluşturabilir (FAB ile açılır)

#### ✅ 3a. Otomatik Aidat — TAMAMLANDI

- [x] `OtomatikAidat` entity: `KullaniciId`, `Tutar`, `AktifMi`, `SonUretimAy`, `SonUretimYil`
- [x] `OtomatikAidatConfiguration` — `KullaniciId` üzerinde unique index (her sakin için tek konfigürasyon)
- [x] `AddOtomatikAidat` migration oluşturuldu ve uygulandı
- [x] `OtomatikAidatDto`, `OtomatikAidatUpsertDto`, `OtomatikAidatTutarGuncelleDto`
- [x] `IOtomatikAidatService` / `OtomatikAidatService`:
  - `GetAllAsync` — tüm konfigürasyonlar
  - `UpsertAsync` — oluştur veya güncelle (aynı sakin için)
  - `ToggleAktifAsync` — aktif/pasif geçiş
  - `UpdateTutarAsync` — tutar güncelle
  - `DeleteAsync` — sil
  - `UretAylikAidatlarAsync(ay, yil)` — aktif kayıtlar için eksik aidatları oluşturur, tekrar oluşturmaz
- [x] `OtomatikAidatController`: GET, POST (upsert), PATCH toggle, PATCH tutar, DELETE, POST uret
- [x] `AidatUretimBackgroundService` — uygulama başında + her gece 02:00'de `UretAylikAidatlarAsync` çalıştırır
- [x] Flutter: `OtomatikAidatModel`, `OtomatikAidatNotifier/Provider`
- [x] Flutter: `AidatListScreen` 2 sekmeli — **Aidatlar** + **Otomatik**
  - Otomatik sekmesi: toggle (aç/kapa), kalem ikon (tutar düzenle), "Bu Ayı Oluştur" butonu
- [x] Flutter: `AidatCreateScreen`'e "Her ay otomatik yenile" toggle'ı eklendi

---

### ✅ 4. Kullanıcı Yönetimi Eksiklikleri — TAMAMLANDI

- [x] `PUT /api/kullanici/{id}` → kullanıcı güncelleme (kendi veya admin)
- [x] `PATCH /api/kullanici/{id}/sifre` → şifre güncelleme
- [x] `GET /api/kullanici/me` → oturumdaki kullanıcının bilgileri
- [x] Flutter: `ProfilScreen` (Ad/Soyad/DaireNo güncelleme + şifre değiştirme sekmeleri)
- [x] MainScaffold popup menüye "Profilim" eklendi

---

### ✅ 5. Arıza Foto — wwwroot Sorunu — TAMAMLANDI

- [x] `Program.cs`'te uygulama başlarken `wwwroot/uploads` klasörü otomatik oluşturuluyor

---

### ✅ 6. Oylama Modülü — TAMAMLANDI

- [x] Entity'ler: `Oylama`, `OylamaSecenek`, `OylamaOyu`
- [x] Configurations: `OylamaConfiguration`, `OylamaSecenekConfiguration`, `OylamaOyuConfiguration`
- [x] `AddOylama` migration oluşturuldu (DB açıkken API başlayınca otomatik uygulanır)
- [x] DTO'lar: `OylamaListDto`, `OylamaDetailDto`, `OylamaCreateDto`, `OyVerDto`
- [x] `IOylamaService` / `OylamaService` — GetAll, GetById, Create, OyVer, OyGeriAl, Delete, ToggleAktif
- [x] `OylamaController` — 7 endpoint, JWT korumalı, Create/Toggle/Delete admin-only
- [x] Unique constraint: bir kullanıcı aynı oylamaya sadece bir kez oy verebilir
- [x] Flutter: `OylamaModel`, `OylamaDetailModel`, `OylamaSecenekModel` (fromJson ile)
- [x] Flutter: `OylamaRepository` abstract + `OylamaRepositoryImpl`
- [x] Flutter: `oylamaListProvider`, `oylamaDetailProvider.family`
- [x] Flutter: `OylamaListScreen` (liste, kart, toggle/sil admin aksiyonları)
- [x] Flutter: `OylamaDetailScreen` (seçenekler, oy ver, oy geri al, progress bar)
- [x] Flutter: `OylamaCreateScreen` (admin, dinamik seçenek listesi, date picker)
- [x] Router: `/ana-sayfa/oylamalar/yeni` ve `/ana-sayfa/oylamalar/:id` route'ları eklendi
- [x] Web: `OylamaModels`, `OylamalarController`, `Index.cshtml`, `Detay.cshtml` eklendi
- [x] Web: Sidebar'a Oylamalar linki eklendi

---

## Geliştirme Sırası

1. JWT Auth
2. Firebase Admin SDK (push bildirim)
3. wwwroot fix
4. Aidat modülü
5. Kullanıcı yönetimi & profil ekranı
6. Oylama modülü
