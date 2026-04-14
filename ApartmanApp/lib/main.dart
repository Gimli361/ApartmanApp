import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'core/strings.dart';
import 'shared/services/notification_service.dart';

void main() async {
  // Splash ekranı Flutter hazır olana kadar tut
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Türkçe tarih formatı için locale verisi yükle
  await initializeDateFormatting('tr');

  // Firebase başlat
  await Firebase.initializeApp();

  // Flutter framework hatalarını yakala
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[Flutter Error] ${details.exceptionAsString()}');
  };

  runApp(
    const ProviderScope(
      child: ApartmanApp(),
    ),
  );
}

class ApartmanApp extends ConsumerStatefulWidget {
  const ApartmanApp({super.key});

  @override
  ConsumerState<ApartmanApp> createState() => _ApartmanAppState();
}

class _ApartmanAppState extends ConsumerState<ApartmanApp> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Bildirim izinlerini kur
    await ref.read(notificationServiceProvider).initialize();
    // Splash ekranı kaldır
    FlutterNativeSplash.remove();
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

/// Tüm route'ların üstünde global hata yakalayıcı
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
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
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
