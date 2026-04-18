import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  _FilterChip(
                    label: 'Tüm Bloklar',
                    selected: _blokFilter == null,
                    onTap: () => setState(() => _blokFilter = null),
                  ),
                  ...bloklar.map((b) => _FilterChip(
                        label: '$b Blok',
                        selected: _blokFilter == b,
                        color: Theme.of(context).colorScheme.secondary,
                        icon: Icons.apartment,
                        onTap: () => setState(
                            () => _blokFilter = _blokFilter == b ? null : b),
                      )),
                ],
              ),
            ),

          // Durum + takip filtre çipleri
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

          const Divider(height: 1),

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
          FloatingActionButton(
            heroTag: 'refresh',
            mini: true,
            onPressed: _load,
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'add',
            onPressed: () => context.push('/ana-sayfa/arizalar/yeni'),
            icon: const Icon(Icons.add),
            label: const Text('Arıza Bildir'),
          ),
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
    // Sakin listesi: kendi bloğu + ortak alan (blokNo == null)
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
          // Basit iki çip: Açık / Geçmiş
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

          const Divider(height: 1),

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
      // Sakin için sadece tek FAB: refresh yok, pull-to-refresh kullanılır
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add',
        onPressed: () => context.push('/ana-sayfa/arizalar/yeni'),
        icon: const Icon(Icons.add),
        label: const Text('Arıza Bildir'),
      ),
    );
  }

  Future<void> _confirmDelete(ArizaModel ariza) async {
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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

class _ArizaListView extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    if (arizaState.isLoading && arizaState.arizalar.isEmpty) {
      return const Center(child: CircularProgressIndicator());
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
            const Icon(Icons.handyman_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(emptyMessage,
                style: const TextStyle(color: Colors.grey, fontSize: 15)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: arizalar.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final ariza = arizalar[i];
          return _ArizaCard(
            ariza: ariza,
            isAdmin: isAdmin,
            userId: userId,
            onDelete:
                isAdmin && onDelete != null ? () => onDelete!(ariza) : null,
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
    final dateStr =
        DateFormat('dd.MM.yyyy HH:mm').format(ariza.tarih.toLocal());
    final arizaState = ref.watch(arizaListProvider);
    final takipYukleniyor = arizaState.loadingTakipIds.contains(ariza.id);
    final takipGoster = !isAdmin;

    // Bildiren gösterimi: admin tam bilgi görür, sakin gizlilik kuralına tabi
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
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete?.call();
        return false;
      },
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(durumIcon(ariza.durum),
                        color: durumColor(ariza.durum), size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        ariza.baslik,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Öncelik rozeti yalnızca admin'e gösterilir
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
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : Icon(
                                  ariza.kullaniciTakipEdiyor
                                      ? Icons.notifications_active
                                      : Icons.notifications_none,
                                  size: 20,
                                  color: ariza.kullaniciTakipEdiyor
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey[500],
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  ariza.aciklama,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _DurumBadge(durum: ariza.durum),
                    if (ariza.takipciSayisi > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.notifications_active,
                                size: 11, color: Colors.orange),
                            const SizedBox(width: 3),
                            Text(
                              '${ariza.takipciSayisi}',
                              style: const TextStyle(
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
                        size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 3),
                    Text(
                      bildirenLabel,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        durum.label,
        style: TextStyle(
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        oncelik.label,
        style: TextStyle(
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
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: icon != null
            ? Icon(icon, size: 14, color: selected ? c : Colors.grey)
            : null,
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: c.withValues(alpha: 0.2),
        checkmarkColor: c,
        labelStyle: TextStyle(
          color: selected ? c : null,
          fontWeight: selected ? FontWeight.w600 : null,
          fontSize: 12,
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Tekrar Dene')),
        ],
      ),
    );
  }
}
