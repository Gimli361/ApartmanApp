/// Uygulama sabitleri
class AppConstants {
  AppConstants._();

  static const String appName = 'ApartmanApp';

  // Android emulator: 10.0.2.2 → host makinenin localhost'u
  // Fiziksel cihaz: bilgisayarın LAN IP'si (ör. 192.168.1.x)
  static const String baseUrl = 'http://10.0.2.2:5255';

  static const String storageKeyUser = 'current_user';
  static const String storageKeyToken = 'auth_token';
}
