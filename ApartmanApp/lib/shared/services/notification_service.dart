import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

/// Arka planda gelen FCM mesajlarını işleyen top-level handler (Firebase zorunluluğu)
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM Background] ${message.notification?.title}');
}

/// Flutter Local Notifications için Android kanalı
const _androidChannel = AndroidNotificationChannel(
  'apartman_channel',
  'Apartman Bildirimleri',
  description: 'Apartman yönetim uygulaması bildirimleri',
  importance: Importance.high,
);

class NotificationService {
  final ApiService _api;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<String>? _tokenRefreshSub;
  int? _currentUserId;

  NotificationService(this._api);

  /// Bildirime tıklanınca emit edilen route stream'i.
  /// main.dart bu stream'i dinleyip GoRouter ile yönlendirme yapar.
  final _navController = StreamController<String>.broadcast();
  Stream<String> get navigationStream => _navController.stream;

  /// Ön planda yeni bildirim geldiğinde emit eder (badge yenilemek için).
  final _refreshController = StreamController<void>.broadcast();
  Stream<void> get onRefresh => _refreshController.stream;

  // ────────────────────────────────────────────────
  // Başlatma
  // ────────────────────────────────────────────────

  Future<void> initialize() async {
    await _setupLocalNotifications();

    // İzin iste (Android 13+ ve iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] Bildirim izni reddedildi.');
      return;
    }

    // Arka plan handler (top-level function zorunlu)
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    // Ön planda çalışırken gelen mesaj → yerel bildirim göster
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Arka plandayken bildirimi tıkladı → yönlendir
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // Token al ve yenilenince backend ile tekrar senkronize et
    final token = await _messaging.getToken();
    debugPrint('[FCM Token] $token');
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _messaging.onTokenRefresh.listen((token) async {
      debugPrint('[FCM Token Refresh] $token');

      final currentUserId = _currentUserId;
      if (currentUserId == null) return;

      try {
        await _api.dio.put(
          '/api/kullanici/$currentUserId/fcm-token',
          data: {'token': token},
        );
        debugPrint('[FCM] Yenilenen token backend\'e gönderildi.');
      } catch (e) {
        debugPrint('[FCM] Yenilenen token gönderilemedi: $e');
      }
    });
  }

  // ────────────────────────────────────────────────
  // Local Notifications kurulumu
  // ────────────────────────────────────────────────

  Future<void> _setupLocalNotifications() async {
    // Android kanalını oluştur
    await _localPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        // Ön planda gösterilen yerel bildirime tıklandı
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _navController.add(payload);
          _refreshController.add(null);
        }
      },
    );
  }

  // ────────────────────────────────────────────────
  // Mesaj işleyiciler
  // ────────────────────────────────────────────────

  /// Uygulama açıkken FCM mesajı geldi → yerel bildirim göster
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM Foreground] ${message.notification?.title}');
    final notification = message.notification;
    if (notification == null) return;

    final route = routeFromMessage(message);

    _localPlugin.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: route,
    );

    // Badge count yenilensin
    _refreshController.add(null);
  }

  /// Arka planda bildirimi tıkladı → route yayınla
  void _handleMessageTap(RemoteMessage message) {
    debugPrint('[FCM Tap] ${message.data}');
    _navController.add(routeFromMessage(message));
    _refreshController.add(null);
  }

  // ────────────────────────────────────────────────
  // Yardımcılar
  // ────────────────────────────────────────────────

  /// Bildirim tipine göre hedef route döndürür.
  String routeFromMessage(RemoteMessage message) {
    final tip = message.data['tip'] as String?;
    return switch (tip) {
      'YeniAriza' || 'ArizaDurum' => '/ana-sayfa/arizalar',
      'Duyuru' || 'DaireMesaj' || 'BlokMesaj' => '/ana-sayfa/bildirimler',
      _ => '/ana-sayfa/bildirimler',
    };
  }

  /// Uygulama kapalıyken bildirimi tıklayıp açıldıysa mesajı döndürür.
  Future<RemoteMessage?> getInitialMessage() => _messaging.getInitialMessage();

  Future<String?> getToken() => _messaging.getToken();

  /// Login/otomatik giriş sonrası FCM token'ı backend'e gönder.
  /// ApiService'in auth token'ı set edilmiş olmalı.
  Future<void> sendTokenToServer(int kullaniciId) async {
    _currentUserId = kullaniciId;
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await _api.dio.put(
        '/api/kullanici/$kullaniciId/fcm-token',
        data: {'token': token},
      );
      debugPrint(
        '[FCM] Token backend\'e gönderildi: ${token.substring(0, 20)}...',
      );
    } catch (e) {
      debugPrint('[FCM] Token gönderilemedi: $e');
    }
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
    _navController.close();
    _refreshController.close();
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final api = ref.read(apiServiceProvider);
  final service = NotificationService(api);
  ref.onDispose(service.dispose);
  return service;
});
