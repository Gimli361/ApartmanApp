import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../domain/ariza_model.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/auth/domain/user_model.dart';
import 'ariza_helpers.dart';
import 'providers/ariza_provider.dart';

/// Sakin için basit iki seçenekli filtre
enum _SakinFiltresi { tumu, acik, gecmis }

class ArizaListScreen extends ConsumerStatefulWidget {
  const ArizaListScreen({super.key});

  @override
  ConsumerState<ArizaListScreen> createState() => _ArizaListScreenState();
}

class _ArizaListScreenState extends ConsumerState<ArizaListScreen>
    with SingleTickerProviderStateMixin {
  // Admin filtreleri
  ArizaDurum? _adminDurumFilter;
  bool _takipFiltresi = false;
  String? _blokFilter;
  late TabController _tabController;
  int _currentTab = 0;

  // Sakin filtresi
  _SakinFiltresi _sakinFilter = _SakinFiltresi.tumu;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _currentTab) {
        setState(() => _currentTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _load() => ref.read(arizaListProvider.notifier).load();

  @override
  Widget build(BuildContext context) {
    final arizaState = ref.watch(arizaListProvider);
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.rol == UserRole.admin;
    final userId = user?.id ?? 0;
    final blokNo = user?.blokNo;

    if (isAdmin) {
      return _buildAdminView(context, arizaState, userId);
    } else {
      return _buildSakinView(context, arizaState, userId, blokNo);
    }
  }

  // ── Admin görünümü ────────────────────────────────────────────────────────

  Widget _buildAdminView(
    BuildContext context,
    ArizaListState arizaState,
    int userId,
  ) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bloklar = arizaState.arizalar
        .map((a) => a.blokNo)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();

    final arizalar = arizaState.arizalar.where((a) {
      if (_adminDurumFilter != null && a.durum != _adminDurumFilter) {
        return false;
      }
      if (_takipFiltresi && !a.kullaniciTakipEdiyor) return false;
      if (_blokFilter != null && a.blokNo != _blokFilter) return false;
      return true;
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          // Blok filtre çipleri
          if (bloklar.isNotEmpty)
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _FilterChip(
                    label: 'Tüm Bloklar',
                    selected: _blokFilter == null,
                    onTap: () => setState(() => _blokFilter = null),
                  ),
                  ...bloklar.map((b) => _FilterChip(
                        label: '$b Blok',
                        selected: _blokFilter == b,
                        color: cs.secondary,
                        icon: Icons.apartment,
                        onTap: () => setState(
                            () => _blokFilter = _blokFilter == b ? null : b),
                      )),
                ],
              ),
            ),

          // Durum filtre çipleri
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _FilterChip(
                  label: 'Tümü',
                  selected: _adminDurumFilter == null && !_takipFiltresi,
                  onTap: () => setState(() {
                    _adminDurumFilter = null;
                    _takipFiltresi = false;
                  }),
                ),
                ...ArizaDurum.values.map((d) => _FilterChip(
                      label: d.label,
                      selected: _adminDurumFilter == d,
                      color: durumColor(d),
                      onTap: () => setState(() =>
                          _adminDurumFilter =
                              _adminDurumFilter == d ? null : d),
                    )),
              ],
            ),
          ),

          Divider(height: 1, color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8E8E8)),

          Expanded(
            child: _ArizaListView(
              arizaState: arizaState,
              arizalar: arizalar,
              isAdmin: true,
              userId: userId,
              onDelete: _confirmDelete,
              onRefresh: _load,
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildMiniRefreshFab(cs, isDark),
          const SizedBox(width: 12),
          _buildAddFab(context, cs, isDark),
        ],
      ),
    );
  }

  // ── Sakin görünümü ────────────────────────────────────────────────────────

  Widget _buildSakinView(
    BuildContext context,
    ArizaListState arizaState,
    int userId,
    String? blokNo,
  ) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final listeTemel = arizaState.arizalar.where((a) {
      final ayniBlok = blokNo != null && a.blokNo == blokNo;
      final ortakAlan = a.blokNo == null || a.blokNo!.isEmpty;
      return ayniBlok || ortakAlan;
    }).toList();

    final arizalar = listeTemel.where((a) {
      switch (_sakinFilter) {
        case _SakinFiltresi.acik:
          return a.durum == ArizaDurum.beklemede ||
              a.durum == ArizaDurum.inceleniyor;
        case _SakinFiltresi.gecmis:
          return a.durum == ArizaDurum.tamamlandi ||
              a.durum == ArizaDurum.reddedildi;
        case _SakinFiltresi.tumu:
          return true;
      }
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _FilterChip(
                  label: 'Tümü',
                  selected: _sakinFilter == _SakinFiltresi.tumu,
                  onTap: () =>
                      setState(() => _sakinFilter = _SakinFiltresi.tumu),
                ),
                _FilterChip(
                  label: 'Açık Arızalar',
                  selected: _sakinFilter == _SakinFiltresi.acik,
                  color: Colors.orange,
                  icon: Icons.pending_outlined,
                  onTap: () =>
                      setState(() => _sakinFilter = _SakinFiltresi.acik),
                ),
                _FilterChip(
                  label: 'Geçmiş',
                  selected: _sakinFilter == _SakinFiltresi.gecmis,
                  color: Colors.green,
                  icon: Icons.check_circle_outline,
                  onTap: () =>
                      setState(() => _sakinFilter = _SakinFiltresi.gecmis),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8E8E8)),

          Expanded(
            child: _ArizaListView(
              arizaState: arizaState,
              arizalar: arizalar,
              isAdmin: false,
              userId: userId,
              onDelete: null,
              onRefresh: _load,
              emptyMessage: _sakinFilter == _SakinFiltresi.gecmis
                  ? 'Geçmiş arıza kaydı bulunamadı.'
                  : _sakinFilter == _SakinFiltresi.acik
                      ? 'Aktif arıza kaydı yok.'
                      : 'Henüz arıza kaydı yok.',
            ),
          ),
        ],
      ),
      floatingActionButton: _buildAddFab(context, cs, isDark),
    );
  }

  Widget _buildMiniRefreshFab(ColorScheme cs, bool isDark) {
    return FloatingActionButton(
      heroTag: 'refresh',
      mini: true,
      onPressed: _load,
      backgroundColor: isDark ? cs.surfaceContainerHigh : cs.surfaceContainerLow,
      foregroundColor: cs.primary,
      elevation: 0,
      child: const Icon(Icons.refresh, size: 20),
    );
  }

  Widget _buildAddFab(BuildContext context, ColorScheme cs, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(isDark ? 0.3 : 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        heroTag: 'add',
        onPressed: () => context.push('/ana-sayfa/arizalar/yeni'),
        icon: const Icon(Icons.add),
        label: const Text('Arıza Bildir'),
      ),
    );
  }

  Future<void> _confirmDelete(ArizaModel ariza) async {
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Arızayı Sil'),
        content: Text('"${ariza.baslik}" kaydı silinecek. Emin misiniz?'),
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
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(arizaListProvider.notifier).delete(ariza.id);
    }
  }
}

// ─── Yeniden kullanılabilir arıza listesi ─────────────────────────────────────

class _ArizaListView extends ConsumerStatefulWidget {
  final ArizaListState arizaState;
  final List<ArizaModel> arizalar;
  final bool isAdmin;
  final int userId;
  final Future<void> Function(ArizaModel)? onDelete;
  final VoidCallback onRefresh;
  final String emptyMessage;

  const _ArizaListView({
    required this.arizaState,
    required this.arizalar,
    required this.isAdmin,
    required this.userId,
    required this.onDelete,
    required this.onRefresh,
    this.emptyMessage = 'Henüz arıza kaydı yok.',
  });

  @override
  ConsumerState<_ArizaListView> createState() => _ArizaListViewState();
}

class _ArizaListViewState extends ConsumerState<_ArizaListView> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 200) {
      ref.read(arizaListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final arizaState = widget.arizaState;
    final arizalar = widget.arizalar;
    final cs = Theme.of(context).colorScheme;

    if (arizaState.isLoading && arizaState.arizalar.isEmpty) {
      return Center(child: CircularProgressIndicator(color: cs.primary));
    }
    if (arizaState.errorMessage != null && arizaState.arizalar.isEmpty) {
      return _ErrorView(
        message: arizaState.errorMessage!,
        onRetry: () => ref.read(arizaListProvider.notifier).load(),
      );
    }
    if (arizalar.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary.withOpacity(0.08),
              ),
              child: Icon(Icons.handyman_outlined, size: 48, color: cs.primary.withOpacity(0.5)),
            ),
            const SizedBox(height: 16),
            Text(widget.emptyMessage,
                style: GoogleFonts.inter(color: cs.onSurfaceVariant, fontSize: 15)),
          ],
        ),
      );
    }

    final showFooter = arizaState.isLoadingMore || !arizaState.hasMore;
    final itemCount = arizalar.length + (showFooter ? 1 : 0);

    return RefreshIndicator(
      color: cs.primary,
      onRefresh: () async => widget.onRefresh(),
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          if (i >= arizalar.length) {
            if (arizaState.isLoadingMore) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator(color: cs.primary)),
              );
            }
            if (!arizaState.hasMore && arizalar.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text('Tüm arızalar yüklendi.',
                      style: GoogleFonts.inter(color: cs.onSurfaceVariant, fontSize: 13)),
                ),
              );
            }
            return const SizedBox.shrink();
          }
          final ariza = arizalar[i];
          return _ArizaCard(
            ariza: ariza,
            isAdmin: widget.isAdmin,
            userId: widget.userId,
            onDelete: widget.isAdmin && widget.onDelete != null
                ? () => widget.onDelete!(ariza)
                : null,
            onTap: () => context.push('/ana-sayfa/arizalar/${ariza.id}'),
          );
        },
      ),
    );
  }
}

// ─── Arıza kartı ─────────────────────────────────────────────────────────────

class _ArizaCard extends ConsumerWidget {
  final ArizaModel ariza;
  final bool isAdmin;
  final int userId;
  final VoidCallback? onDelete;
  final VoidCallback onTap;

  const _ArizaCard({
    required this.ariza,
    required this.isAdmin,
    required this.userId,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr =
        DateFormat('dd.MM.yyyy HH:mm').format(ariza.tarih.toLocal());
    final arizaState = ref.watch(arizaListProvider);
    final takipYukleniyor = arizaState.loadingTakipIds.contains(ariza.id);
    final takipGoster = !isAdmin;
    final dColor = durumColor(ariza.durum);

    // Bildiren gösterimi
    final String bildirenLabel;
    if (isAdmin) {
      bildirenLabel =
          '${ariza.bildirenDaireNo} · ${ariza.bildirenAdSoyad}';
    } else if (ariza.bildirenId == userId) {
      bildirenLabel = 'Sen';
    } else {
      bildirenLabel = 'Bina Sakini';
    }

    return Dismissible(
      key: ValueKey(ariza.id),
      direction:
          isAdmin ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: cs.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete?.call();
        return false;
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHigh : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFE8E8E8),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            if (isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                // Sol kenar renk çizgisi
                Container(
                  width: 4,
                  height: 100,
                  decoration: BoxDecoration(
                    color: dColor,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: dColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(durumIcon(ariza.durum),
                                  color: dColor, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                ariza.baslik,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: cs.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isAdmin) _PriorityBadge(oncelik: ariza.oncelik),
                            if (takipGoster) ...[
                              const SizedBox(width: 4),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: takipYukleniyor
                                    ? null
                                    : () => ref
                                        .read(arizaListProvider.notifier)
                                        .toggleTakip(ariza.id),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: takipYukleniyor
                                      ? SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: cs.primary),
                                        )
                                      : Icon(
                                          ariza.kullaniciTakipEdiyor
                                              ? Icons.notifications_active
                                              : Icons.notifications_none,
                                          size: 20,
                                          color: ariza.kullaniciTakipEdiyor
                                              ? cs.primary
                                              : cs.outline,
                                        ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ariza.aciklama,
                          style: GoogleFonts.inter(
                              color: cs.onSurfaceVariant, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _DurumBadge(durum: ariza.durum),
                            if (ariza.takipciSayisi > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.notifications_active,
                                        size: 11, color: Colors.orange),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${ariza.takipciSayisi}',
                                      style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: Colors.orange,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const Spacer(),
                            Icon(Icons.person_outline,
                                size: 13, color: cs.outline),
                            const SizedBox(width: 3),
                            Text(
                              bildirenLabel,
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: cs.outline),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.schedule, size: 12, color: cs.outline),
                            const SizedBox(width: 4),
                            Text(
                              dateStr,
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: cs.outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Yardımcı widget'lar ──────────────────────────────────────────────────────

class _DurumBadge extends StatelessWidget {
  final ArizaDurum durum;
  const _DurumBadge({required this.durum});

  @override
  Widget build(BuildContext context) {
    final color = durumColor(durum);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        durum.label,
        style: GoogleFonts.inter(
            fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final ArizaOncelik oncelik;
  const _PriorityBadge({required this.oncelik});

  @override
  Widget build(BuildContext context) {
    final color = oncelikColor(oncelik);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        oncelik.label,
        style: GoogleFonts.inter(
            fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final IconData? icon;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = color ?? cs.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? c.withOpacity(isDark ? 0.2 : 0.15)
                : (isDark
                    ? cs.surfaceContainerHighest
                    : cs.surfaceContainerHigh),
            borderRadius: BorderRadius.circular(20),
            border: selected
                ? Border.all(color: c.withOpacity(0.4))
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: selected ? c : cs.onSurfaceVariant),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  color: selected ? c : cs.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.error.withOpacity(0.08),
              ),
              child: Icon(Icons.error_outline, size: 48, color: cs.error),
            ),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: cs.onSurfaceVariant)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(minimumSize: const Size(140, 44)),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}
