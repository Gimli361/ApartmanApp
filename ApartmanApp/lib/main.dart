import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'core/strings.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/bildirim/presentation/providers/bildirim_provider.dart';
import 'shared/services/notification_service.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await initializeDateFormatting('tr');

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('[Firebase] Başlatma hatası: $e');
    FlutterNativeSplash.remove();
    runApp(_FirebaseErrorApp(message: e.toString()));
    return;
  }

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[Flutter Error] ${details.exceptionAsString()}');
  };

  runApp(const ProviderScope(child: ApartmanApp()));
}

class _FirebaseErrorApp extends StatelessWidget {
  final String message;
  const _FirebaseErrorApp({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Uygulama başlatılamadı.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Firebase yapılandırma hatası:\n$message',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ApartmanApp extends ConsumerStatefulWidget {
  const ApartmanApp({super.key});

  @override
  ConsumerState<ApartmanApp> createState() => _ApartmanAppState();
}

class _ApartmanAppState extends ConsumerState<ApartmanApp> {
  StreamSubscription<String>? _navSub;
  StreamSubscription<void>? _refreshSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final notifService = ref.read(notificationServiceProvider);
    await notifService.initialize();

    // Bildirime tıklanınca yönlendir + bildirimleri yenile
    _navSub = notifService.navigationStream.listen(_handleNotificationNav);

    // Ön planda bildirim gelince sadece badge'i yenile
    _refreshSub = notifService.onRefresh.listen((_) {
      if (ref.read(authProvider).isLoggedIn) {
        ref.read(bildirimProvider.notifier).load();
      }
    });

    FlutterNativeSplash.remove();

    // Uygulama tamamen kapalıyken bildirime tıklayıp açıldıysa
    final initialMessage = await notifService.getInitialMessage();
    if (initialMessage != null && mounted) {
      _handleNotificationNav(notifService.routeFromMessage(initialMessage));
    }
  }

  void _handleNotificationNav(String route) {
    if (!mounted) return;
    if (!ref.read(authProvider).isLoggedIn) return;

    ref.read(bildirimProvider.notifier).load();
    ref.read(routerProvider).go(route);
  }

  @override
  void dispose() {
    _navSub?.cancel();
    _refreshSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
      builder: (context, child) => _AppErrorBoundary(child: child!),
    );
  }
}

class _AppErrorBoundary extends StatelessWidget {
  final Widget child;
  const _AppErrorBoundary({required this.child});

  @override
  Widget build(BuildContext context) {
    ErrorWidget.builder = (details) {
      return Material(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Beklenmeyen bir hata oluştu.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  details.exceptionAsString(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    };
    return child;
  }
}
