import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../features/auth/domain/user_model.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/bildirim/presentation/providers/bildirim_provider.dart';

class MainScaffold extends ConsumerStatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  static const _baseTabs = [
    _TabItem(icon: Icons.build_outlined, label: AppStrings.arizalar, path: '/ana-sayfa/arizalar'),
    _TabItem(icon: Icons.payment_outlined, label: AppStrings.aidatlar, path: '/ana-sayfa/aidatlar'),
    _TabItem(icon: Icons.notifications_outlined, label: AppStrings.bildirimler, path: '/ana-sayfa/bildirimler'),
    _TabItem(icon: Icons.how_to_vote_outlined, label: AppStrings.oylamalar, path: '/ana-sayfa/oylamalar'),
  ];

  static const _adminTabs = [
    _TabItem(icon: Icons.apartment_outlined, label: 'Bina', path: '/ana-sayfa/bina'),
    _TabItem(icon: Icons.people_outline, label: 'Üyeler', path: '/ana-sayfa/kullanicilar'),
  ];

  List<_TabItem> _tabs(UserRole? rol) {
    if (rol == UserRole.admin) return [..._baseTabs, ..._adminTabs];
    return _baseTabs;
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(bildirimProvider.notifier).load());
  }

  int _currentIndex(BuildContext context, List<_TabItem> tabs) {
    final location = GoRouterState.of(context).uri.path;
    final index = tabs.indexWhere((t) => location.startsWith(t.path));
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final tabs = _tabs(user?.rol);
    final currentIndex = _currentIndex(context, tabs);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tabs[currentIndex].label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          PopupMenuButton<_MenuAction>(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
              child: Text(
                user?.adSoyad.isNotEmpty == true
                    ? user!.adSoyad[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            onSelected: (action) async {
              if (action == _MenuAction.profil) {
                context.push('/profil');
                return;
              }
              if (action == _MenuAction.logout) {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Çıkış Yap'),
                    content: const Text('Hesabınızdan çıkmak istediğinize emin misiniz?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('İptal'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Çıkış Yap'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await ref.read(authProvider.notifier).logout();
                }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.adSoyad ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (user?.daireNo.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Daire ${user!.daireNo}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: _MenuAction.profil,
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 18),
                    SizedBox(width: 10),
                    Text('Profilim'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: _MenuAction.logout,
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 18),
                    SizedBox(width: 10),
                    Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => context.go(tabs[i].path),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.build_outlined),
            label: AppStrings.arizalar,
          ),
          const NavigationDestination(
            icon: Icon(Icons.payment_outlined),
            label: AppStrings.aidatlar,
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: ref.watch(bildirimProvider).unreadCount > 0,
              label: Text('${ref.watch(bildirimProvider).unreadCount}'),
              child: const Icon(Icons.notifications_outlined),
            ),
            label: AppStrings.bildirimler,
          ),
          const NavigationDestination(
            icon: Icon(Icons.how_to_vote_outlined),
            label: AppStrings.oylamalar,
          ),
          if (user?.rol == UserRole.admin) ...[
            const NavigationDestination(
              icon: Icon(Icons.apartment_outlined),
              label: 'Bina',
            ),
            const NavigationDestination(
              icon: Icon(Icons.people_outline),
              label: 'Üyeler',
            ),
          ],
        ],
      ),
    );
  }
}

enum _MenuAction { profil, logout }

class _TabItem {
  final IconData icon;
  final String label;
  final String path;

  const _TabItem({
    required this.icon,
    required this.label,
    required this.path,
  });
}
