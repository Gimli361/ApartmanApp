# ApartmanApp — CLAUDE.md

## Proje özeti
Flutter ile geliştirilmiş apartman yönetim uygulaması.
İki kullanıcı tipi: Sakin (mobil) ve Yönetici (mobil + web).

## Mimari
- Frontend: Flutter (Dart) — sakin ve yönetici mobil
- Backend: Node.js REST API (ayrı repo)
- Veritabanı: PostgreSQL
- State management: Riverpod
- Navigasyon: go_router
- HTTP: dio
- Local storage: flutter_secure_storage
- Push bildirim: firebase_messaging

## Klasör yapısı
lib/
  core/           → sabitler, tema, yardımcı fonksiyonlar
  features/       → özellik bazlı modüller (auth, ariza, aidat, bildirim, oylama)
    auth/
      data/       → repository, API çağrıları
      domain/     → model sınıfları
      presentation/ → ekranlar, widget'lar, provider'lar
  shared/         → ortak widget'lar, servisler

## Kodlama kuralları
- Dart null-safety zorunlu, late kullanımından kaçın
- Her feature kendi provider'ını yönetir, global state minimum
- Widget'lar 80 satırı geçerse alt widget'lara böl
- Tüm renkler AppTheme üzerinden gelir, hardcode renk yok
- String'ler AppStrings sabitine taşınır (lokalizasyon hazırlığı)
- API hataları Result<T, AppError> pattern ile ele alınır

## Komutlar
flutter pub get          # bağımlılık yükle
flutter run              # emülatörde çalıştır
flutter test             # testleri çalıştır
flutter build apk        # Android build
dart analyze             # statik analiz
dart format lib/         # kod formatla

## Önemli kurallar
- Commit'e API key, token veya şifre kesinlikle girme
- Her yeni özelliği önce domain (model) → data (repo) → presentation sırasıyla kur
- firebase_options.dart dosyasını .gitignore'a ekle
- Bildirim izinleri her platformda (iOS + Android) ayrıca istenmeli

## Bilinen kısıtlar
- iOS push bildirimi için APNs sertifikası gerekli, simulatörde test edilemez
- Web desteği şu an hedefte yok