# ApartmanApp Uygulama Planı

## Faz 1: API Altyapısı ✅ TAMAMLANDI

### Proje Yapısı
- [x] N-Tier mimari kuruldu (Core, Data, Business, API katmanları)
- [x] Solution dosyası oluşturuldu (`ApartmanApp.sln`)
- [x] Proje referansları ayarlandı (Core ← Data ← Business ← API)

### Paketler
- [x] EF Core 8.0.11 + Npgsql.EntityFrameworkCore.PostgreSQL 8.0.11
- [x] AutoMapper 14.0.0
- [x] FluentValidation 11.x
- [x] Swashbuckle (Swagger)

### Core Katmanı
- [x] `Kullanici` entity — Id, Ad, Soyad, Email, Rol, DaireNo
- [x] `Ariza` entity — Id, Baslik, Aciklama, Durum, Oncelik, BildirenId, Tarih
- [x] `KullaniciRol` enum — Admin, Sakin
- [x] `ArizaDurum` enum — Beklemede, Inceleniyor, Tamamlandi, Reddedildi
- [x] `ArizaOncelik` enum — Dusuk, Orta, Yuksek, Kritik
- [x] `Result<T>` wrapper — başarı/hata sarmalayıcısı

### Data Katmanı
- [x] `AppDbContext` yapılandırıldı
- [x] `KullaniciConfiguration` — unique email index, max length kuralları
- [x] `ArizaConfiguration` — FK kısıtlaması (DeleteBehavior.Restrict)
- [x] PostgreSQL bağlantısı: `Host=localhost;Port=5432;Database=postgres;Username=postgres`
- [x] `InitialCreate` migration oluşturuldu ve uygulandı
- [x] `Kullanicilar` ve `Arizalar` tabloları veritabanında oluşturuldu

### Business Katmanı
- [x] DTOs: `ArizaListDto`, `ArizaDetailDto`, `ArizaCreateDto`
- [x] DTOs: `KullaniciListDto`, `KullaniciCreateDto`
- [x] `ArizaCreateValidator` (FluentValidation)
- [x] `KullaniciCreateValidator` (FluentValidation)
- [x] `MappingProfile` (AutoMapper)
- [x] `IArizaService` / `ArizaService` — GetAll, GetById, Create, Delete
- [x] `IKullaniciService` / `KullaniciService` — GetAll, GetById, Create, Delete

### API Katmanı
- [x] `ArizaController` — GET /api/ariza, GET /api/ariza/{id}, POST /api/ariza, DELETE /api/ariza/{id}
- [x] `KullaniciController` — GET /api/kullanici, GET /api/kullanici/{id}, POST /api/kullanici, DELETE /api/kullanici/{id}
- [x] Swagger UI aktif (Development ortamında)
- [x] CORS yapılandırıldı
- [x] Enum'lar JSON'da string olarak serialize ediliyor

---

## Faz 2: Arıza Takip Modülü (Backend) ✅ TAMAMLANDI

### Arıza Durum Güncelleme
- [x] `ArizaDurumGuncelleDto` — Durum field'ı içeren PATCH body
- [x] `IArizaService.UpdateDurumAsync` + `ArizaService` implementasyonu
- [x] `PATCH /api/ariza/{id}/durum` endpoint'i eklendi

### File Upload (Local Storage)
- [x] `ArizaFoto` entity — Core katmanına eklendi
- [x] `ArizaFotoConfiguration` — Cascade delete, max length kuralları
- [x] `AppDbContext`'e `ArizaFotolar` DbSet eklendi
- [x] `AddArizaFoto` migration oluşturuldu (DB çevrimdışıydı — uygulanacak)
- [x] `ArizaFotoDto` — URL alanı dahil response DTO
- [x] `IFotoService` / `FotoService` — Upload (5MB limit, jpg/png/webp), GetByArizaId, Delete
- [x] `FotoController` — GET/POST/DELETE `/api/ariza/{arizaId}/foto`
- [x] `Business.csproj`'a `Microsoft.AspNetCore.App` framework referansı eklendi
- [x] `Program.cs` — IFotoService, IHttpContextAccessor, UseStaticFiles kaydedildi
- [ ] ⚠️ Migration uygulanacak: PostgreSQL açıkken `dotnet ef database update` çalıştır

## Faz 3: Flutter Mobil Giriş ✅ TAMAMLANDI

- [x] Flutter projesi zaten oluşturulmuştu (`ApartmanApp/`)
- [x] API entegrasyonu — `ApiService` Dio interceptor ile güncellendi, baseUrl `http://10.0.2.2:5255`
- [x] `UserModel` backend `KullaniciListDto`'ya uygun güncellendi (fromJson/toJson)
- [x] `AuthRepositoryImpl` — email ile kullanıcı bul, `flutter_secure_storage` ile sakla
- [x] `AuthNotifier` (Riverpod StateNotifier) — login, logout, uygulama başında oturum yükle
- [x] Login ekranı — email + şifre formu, validasyon, hata mesajı, loading göstergesi
- [x] `MainScaffold` — Material 3 `NavigationBar` ile 4 sekme (Arızalar, Aidatlar, Bildirimler, Oylamalar)
- [x] Router — `ShellRoute` + auth redirect, login ↔ ana-sayfa otomatik yönlendirme
- [x] `dart analyze` — 0 hata, 0 uyarı
- [ ] ⚠️ Not: Şu an login şifre doğrulaması yok (backend JWT auth Faz 5'te eklenecek)

## Faz 4: Mobil Arıza Takibi (HCI Odaklı) ✅ TAMAMLANDI

- [x] `ArizaModel` backend'e uygun güncellendi (id: int, oncelik, bildirenAdSoyad, tarih, fromJson)
- [x] `ArizaDurum` / `ArizaOncelik` enum — label, toApiString, fromString metodları
- [x] `ArizaRepository` abstract + `ArizaRepositoryImpl` — getArizalar, getById, create, updateDurum, delete, uploadFoto
- [x] `ArizaListNotifier` (Riverpod) — load, create, updateDurum, delete
- [x] `ArizaListScreen` — durum filtresi chips, pull-to-refresh, swipe-to-delete (sadece admin), FAB
- [x] `ArizaCreateScreen` — başlık/açıklama formu, öncelik chip seçimi, fotoğraf (kamera/galeri)
- [x] `ArizaDetailScreen` — detay görünümü, admin için durum güncelleme (ActionChip + PopupMenu)
- [x] Router — `/ana-sayfa/arizalar/yeni` ve `/ana-sayfa/arizalar/:id` route'ları eklendi
- [x] `image_picker` paketi eklendi
- [x] `dart analyze` — 0 hata, 0 uyarı

## Faz 5: Bildirim ve Cila ✅ TAMAMLANDI (Firebase config manuel gerekli — aşağıya bak)

- [x] `NotificationService` — FCM izin isteme, token alma, foreground/background/tap handler
- [x] `firebaseBackgroundHandler` — top-level Dart function (Firebase zorunluluğu)
- [x] `main.dart` — Firebase.initializeApp(), FlutterNativeSplash, FlutterError.onError
- [x] `_AppErrorBoundary` — tüm uygulamayı saran global hata widget'ı
- [x] `flutter_native_splash` config — mavi arka plan (#1976D2), assets/images/splash_logo.png
- [x] `flutter_launcher_icons` config — adaptive icon, assets/images/app_icon.png
- [x] Android `settings.gradle.kts` + `app/build.gradle.kts` — google-services plugin eklendi
- [x] `AndroidManifest.xml` — FCM kanal ID ve ikon meta-data eklendi
- [x] `AppTheme` — SnackBar floating, InputDecoration global border
- [x] `dart analyze` — 0 hata, 0 uyarı
- [x] `google-services.json` yerleştirildi, APK build başarılı ✅
- [x] `flutter_native_splash:create` ve `flutter_launcher_icons` çalıştırıldı ✅

---

## Faz 6: Backend JWT Kimlik Doğrulama ✅ TAMAMLANDI

- [x] `Kullanici` entity'sine `SifreHash` alanı eklendi
- [x] `BCrypt.Net-Next` paketi ile şifre hash'leme
- [x] `LoginDto`, `TokenResponseDto` DTO'ları eklendi
- [x] `POST /api/auth/login` endpoint'i — email+şifre doğrula, JWT token döndür
- [x] `IAuthService` / `AuthService` implementasyonu
- [x] `Microsoft.AspNetCore.Authentication.JwtBearer` paketi eklendi
- [x] JWT middleware `Program.cs`'e eklendi
- [x] Swagger'a Bearer JWT desteği eklendi
- [x] Flutter `AuthRepositoryImpl` — JWT token'ı `flutter_secure_storage`'a kaydediyor
- [x] `ApiService` — token ile `Authorization: Bearer` header'ı otomatik ekliyor, 401'de onUnauthorized callback
- [x] Token expire olunca login sayfasına yönlendiriyor (401 interceptor)
- [x] Migration: `AddSifreHash` oluşturuldu
- [ ] ⚠️ `dotnet ef database update` PostgreSQL açıkken çalıştırılacak
- [ ] ⚠️ Mevcut kullanıcıların şifreleri `POST /api/kullanici` ile yeniden oluşturulacak (SifreHash zorunlu)

---

## Faz 7: Eksik Mobil Ekranlar

### Bildirim Ekranı
- [ ] `BildirimModel` — id, baslik, icerik, okundu, tarih
- [ ] Backend `Bildirim` entity + migration (opsiyonel — FCM ile de yönetilebilir)
- [ ] `BildirimListScreen` — okundu/okunmadı badge, liste
- [ ] FCM `onMessageOpenedApp` → ilgili arıza detayına yönlendir

### Aidat Ekranı (Kapsam Dışı — İleride)
- [ ] `AidatModel` — tutar, ay, yıl, ödendi mi
- [ ] Backend `Aidat` entity + migration
- [ ] `AidatListScreen` — aylık ödeme durumu listesi
- [ ] Admin için aidat ekleme formu

### Oylama Ekranı (Kapsam Dışı — İleride)
- [ ] `OylamaModel` — başlık, seçenekler, bitiş tarihi
- [ ] `OylamaListScreen` — aktif/biten oylamalar
- [ ] Oy verme formu

---

## Faz 8: Test ve Yayına Hazırlık

### Test
- [ ] Fiziksel Android cihazda test — `constants.dart`'ta `baseUrl`'i LAN IP'ye çek
- [ ] FCM bildirimi testi — Firebase Console → Cloud Messaging → Send test message
- [ ] Fotoğraf yükleme uçtan uca testi
- [ ] Admin / Sakin rol ayrımı testi

### Android Yayın
- [ ] `android/app/build.gradle.kts` — release signing config
- [ ] `flutter build apk --release` veya `flutter build appbundle`
- [ ] Play Store için `key.jks` oluştur

### Küçük İyileştirmeler
- [ ] `ArizaListScreen` — boş liste için illüstrasyon/icon
- [ ] `ArizaCreateScreen` — birden fazla fotoğraf desteği
- [ ] Uygulama içi bildirim banner'ı (flutter_local_notifications)
- [ ] Logout butonu (ayarlar veya profil sayfası)
