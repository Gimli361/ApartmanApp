import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/profil_screen.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/ariza/presentation/ariza_list_screen.dart';
import '../features/ariza/presentation/ariza_create_screen.dart';
import '../features/ariza/presentation/ariza_detail_screen.dart';
import '../features/aidat/presentation/aidat_list_screen.dart';
import '../features/aidat/presentation/aidat_create_screen.dart';
import '../features/bildirim/presentation/bildirim_list_screen.dart';
import '../features/oylama/presentation/oylama_list_screen.dart';
import '../features/oylama/presentation/oylama_detail_screen.dart';
import '../features/oylama/presentation/oylama_create_screen.dart';
import '../features/kullanici/presentation/kullanici_list_screen.dart';
import '../features/bina/presentation/bina_yonetim_screen.dart';
import '../shared/widgets/main_scaffold.dart';

/// Auth state değişince GoRouter'ı yeniden değerlendir
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    _isLoggedIn = ref.read(authProvider).isLoggedIn;
    ref.listen(authProvider, (_, next) {
      _isLoggedIn = next.isLoggedIn;
      notifyListeners();
    });
  }

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;
}

final _routerNotifierProvider = ChangeNotifierProvider<_RouterNotifier>(
  (ref) => _RouterNotifier(ref),
);

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_routerNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final isLoggedIn = notifier.isLoggedIn;
      final onLogin = state.matchedLocation == '/login';

      if (!isLoggedIn && !onLogin) return '/login';
      if (isLoggedIn && onLogin) return '/ana-sayfa';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/ana-sayfa',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/ana-sayfa/arizalar',
            builder: (context, state) => const ArizaListScreen(),
            routes: [
              GoRoute(
                path: 'yeni',
                builder: (context, state) => const ArizaCreateScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return ArizaDetailScreen(arizaId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/ana-sayfa/aidatlar',
            builder: (context, state) => const AidatListScreen(),
            routes: [
              GoRoute(
                path: 'yeni',
                builder: (context, state) => const AidatCreateScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/ana-sayfa/bildirimler',
            builder: (context, state) => const BildirimListScreen(),
          ),
          GoRoute(
            path: '/ana-sayfa/oylamalar',
            builder: (context, state) => const OylamaListScreen(),
            routes: [
              GoRoute(
                path: 'yeni',
                builder: (context, state) => const OylamaCreateScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return OylamaDetailScreen(oylamaId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/ana-sayfa/kullanicilar',
            builder: (context, state) => const KullaniciListScreen(),
          ),
          GoRoute(
            path: '/ana-sayfa/bina',
            builder: (context, state) => const BinaYonetimScreen(),
          ),
          GoRoute(
            path: '/profil',
            builder: (context, state) => const ProfilScreen(),
          ),
        ],
      ),
    ],
  );
});
