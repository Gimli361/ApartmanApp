import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/strings.dart';
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
    _TabItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: AppStrings.anaSayfa,
      path: '/ana-sayfa',
    ),
    _TabItem(
      icon: Icons.payment_outlined,
      activeIcon: Icons.payment,
      label: AppStrings.finans,
      path: '/ana-sayfa/aidatlar',
    ),
    _TabItem(
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications,
      label: AppStrings.duyurular,
      path: '/ana-sayfa/bildirimler',
    ),
    _TabItem(
      icon: Icons.handyman_outlined,
      activeIcon: Icons.handyman,
      label: AppStrings.talepler,
      path: '/ana-sayfa/arizalar',
    ),
    _TabItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: AppStrings.profil,
      path: '/profil',
    ),
  ];

  List<_TabItem> _tabs(UserRole? rol) {
    // Prompt gereği bottom-nav 5 sekme sabit.
    // Admin ekranlarına erişim AppBar menüsünden sağlanır.
    return _baseTabs;
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(bildirimProvider.notifier).load());
  }

  int _currentIndex(BuildContext context, List<_TabItem> tabs) {
    final location = GoRouterState.of(context).uri.path;
    // En uzun eşleşen path seçilsin (örn. "/ana-sayfa/arizalar" yanlışlıkla
    // "/ana-sayfa" sekmesini seçmesin).
    int bestIndex = 0;
    int bestLen = -1;
    for (var i = 0; i < tabs.length; i++) {
      final p = tabs[i].path;
      final matches = location == p || location.startsWith('$p/');
      if (matches && p.length > bestLen) {
        bestLen = p.length;
        bestIndex = i;
      }
    }
    return bestLen < 0 ? 0 : bestIndex;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final tabs = _tabs(user?.rol);
    final currentIndex = _currentIndex(context, tabs);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: _buildAppBar(context, cs, isDark, user, tabs, currentIndex),
      body: widget.child,
      bottomNavigationBar: _buildBottomNav(
        context,
        cs,
        isDark,
        tabs,
        currentIndex,
        ref.watch(bildirimProvider).unreadCount,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ColorScheme cs,
    bool isDark,
    dynamic user,
    List<_TabItem> tabs,
    int currentIndex,
  ) {
    return AppBar(
      title: Text(
        AppStrings.appName,
        style: GoogleFonts.inter(
          color: cs.primary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: IconButton(
          icon: Icon(Icons.menu, color: cs.primary),
          onPressed: () {},
        ),
      ),
      actions: [
        _buildProfileButton(context, cs, isDark, user),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildProfileButton(
    BuildContext context,
    ColorScheme cs,
    bool isDark,
    dynamic user,
  ) {
    return PopupMenuButton<_MenuAction>(
      offset: const Offset(0, 48),
      icon: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? cs.surfaceContainerHigh
              : cs.surfaceContainerLow,
          border: Border.all(
            color: cs.primary.withOpacity(isDark ? 0.3 : 0.15),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            user?.adSoyad?.isNotEmpty == true
                ? user!.adSoyad[0].toUpperCase()
                : '?',
            style: GoogleFonts.inter(
              color: cs.primary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
      onSelected: (action) async {
        if (action == _MenuAction.profil) {
          context.push('/profil');
          return;
        }
        if (action == _MenuAction.bina) {
          context.push('/ana-sayfa/bina');
          return;
        }
        if (action == _MenuAction.uyeler) {
          context.push('/ana-sayfa/kullanicilar');
          return;
        }
        if (action == _MenuAction.logout) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Çıkış Yap'),
              content: const Text(
                  'Hesabınızdan çıkmak istediğinize emin misiniz?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('İptal'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.error,
                    minimumSize: const Size(80, 40),
                  ),
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
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user?.email ?? '',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                ),
              ),
              if (user?.daireNo?.isNotEmpty == true) ...[
                const SizedBox(height: 2),
                Text(
                  'Daire ${user!.daireNo}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _MenuAction.profil,
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 18, color: cs.onSurface),
              const SizedBox(width: 10),
              Text('Profilim',
                  style: GoogleFonts.inter(color: cs.onSurface)),
            ],
          ),
        ),
        if (user?.rol == UserRole.admin) ...[
          const PopupMenuDivider(),
          PopupMenuItem(
            value: _MenuAction.bina,
            child: Row(
              children: [
                Icon(Icons.apartment_outlined, size: 18, color: cs.onSurface),
                const SizedBox(width: 10),
                Text('Bina Yönetimi',
                    style: GoogleFonts.inter(color: cs.onSurface)),
              ],
            ),
          ),
          PopupMenuItem(
            value: _MenuAction.uyeler,
            child: Row(
              children: [
                Icon(Icons.people_outline, size: 18, color: cs.onSurface),
                const SizedBox(width: 10),
                Text('Üyeler',
                    style: GoogleFonts.inter(color: cs.onSurface)),
              ],
            ),
          ),
        ],
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _MenuAction.logout,
          child: Row(
            children: [
              Icon(Icons.logout, color: cs.error, size: 18),
              const SizedBox(width: 10),
              Text('Çıkış Yap',
                  style: GoogleFonts.inter(color: cs.error)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(
    BuildContext context,
    ColorScheme cs,
    bool isDark,
    List<_TabItem> tabs,
    int currentIndex,
    int unreadCount,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerLowest : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFE8E8E8),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(tabs.length, (i) {
              final tab = tabs[i];
              final isSelected = currentIndex == i;
              final isBildirim = tab.path == '/ana-sayfa/bildirimler';

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.go(tab.path),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 6),
                    decoration: isSelected
                        ? BoxDecoration(
                            color: cs.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cs.primary.withOpacity(0.2),
                              width: 1,
                            ),
                          )
                        : null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // İcon + Badge
                        isBildirim && unreadCount > 0
                            ? Badge(
                                label: Text(
                                  '$unreadCount',
                                  style: const TextStyle(fontSize: 10),
                                ),
                                child: Icon(
                                  isSelected ? tab.activeIcon : tab.icon,
                                  size: 22,
                                  color: isSelected
                                      ? cs.primary
                                      : (isDark
                                          ? cs.outline
                                          : Colors.grey[400]),
                                ),
                              )
                            : Icon(
                                isSelected ? tab.activeIcon : tab.icon,
                                size: 22,
                                color: isSelected
                                    ? cs.primary
                                    : (isDark
                                        ? cs.outline
                                        : Colors.grey[400]),
                              ),
                        const SizedBox(height: 4),
                        Text(
                          tab.label,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? cs.primary
                                : (isDark
                                    ? cs.outline
                                    : Colors.grey[400]),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

enum _MenuAction { profil, bina, uyeler, logout }

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;

  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
}
