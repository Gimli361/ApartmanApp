import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';

/// Arka planda gelen mesajları işleyen top-level handler (Firebase zorunluluğu)
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM Background] ${message.notification?.title}');
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// İzin iste + FCM token al + handler'ları kur
  Future<void> initialize() async {
    // İzin iste (iOS + Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] Bildirim izni reddedildi.');
      return;
    }

    // Arka plan handler
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    // Ön plan mesajlar
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM Foreground] ${message.notification?.title}: '
          '${message.notification?.body}');
      // TODO: overlay bildirim göster (flutter_local_notifications ile)
    });

    // Bildirime tıklanınca uygulama açılıyorsa
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM Tap] ${message.data}');
      // TODO: ilgili route'a yönlendir
    });

    // Token al
    final token = await _messaging.getToken();
    debugPrint('[FCM Token] $token');

    // Token yenilenince
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('[FCM Token Refresh] $newToken');
    });
  }

  Future<String?> getToken() => _messaging.getToken();

  Future<void> sendTokenToServer(int kullaniciId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      final dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
      await dio.put(
        '/api/kullanici/$kullaniciId/fcm-token',
        data: {'token': token},
      );
      debugPrint('[FCM] Token backend\'e gönderildi.');
    } catch (e) {
      debugPrint('[FCM] Token gönderilemedi: $e');
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);
