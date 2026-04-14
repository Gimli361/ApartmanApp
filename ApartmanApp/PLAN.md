Flutter ile ApartmanApp uygulamasını başlatıyoruz.

Önce projeyi oluştur:
flutter create --org com.apartmanapp --project-name apartman_app .

Sonra pubspec.yaml'a şu bağımlılıkları ekle ve `flutter pub get` çalıştır:

dependencies:
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  go_router: ^13.2.0
  dio: ^5.4.3
  flutter_secure_storage: ^9.0.0
  firebase_core: ^3.3.0
  firebase_messaging: ^15.0.3
  cached_network_image: ^3.3.1
  intl: ^0.19.0

dev_dependencies:
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.9
  flutter_lints: ^4.0.0

Ardından CLAUDE.md dosyasındaki klasör yapısını oluştur:
lib/core/, lib/features/auth/, lib/features/ariza/,
lib/features/aidat/, lib/features/bildirim/, lib/features/oylama/,
lib/shared/

Her klasörde placeholder .dart dosyaları oluştur.
Sonra bana ne geliştirmek istediğimi sor.