/// Uygulama sabitleri
class AppConstants {
  AppConstants._();

  static const String appName = 'ApartmanApp';

  /// API base URL — build/run sırasında --dart-define ile override edilir.
  /// Örnek (Android emülatör):
  ///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5255
  /// Örnek (fiziksel cihaz):
  ///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:5255
  /// Örnek (production):
  ///   flutter build apk --dart-define=API_BASE_URL=https://api.apartmann.com
  ///
  /// Tanımlanmazsa Android emülatör default'una düşer.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5255',
  );

  /// Çıktıda mevcut ortamı görmek için kullanılabilir.
  static bool get isProduction =>
      !baseUrl.contains('10.0.2.2') &&
      !baseUrl.contains('localhost') &&
      !baseUrl.contains('192.168.');

  static const String storageKeyUser = 'current_user';
  static const String storageKeyToken = 'auth_token';
  static const String storageKeyRefreshToken = 'refresh_token';
}
