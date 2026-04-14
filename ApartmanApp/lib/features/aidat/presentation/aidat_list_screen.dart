import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/result.dart';
import '../domain/aidat_model.dart';
import '../domain/otomatik_aidat_model.dart';
import 'providers/aidat_provider.dart';
import 'providers/otomatik_aidat_provider.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/auth/domain/user_model.dart';

// ─── Ana ekran (sekmeli) ─────────────────────────────────────────────────────

class AidatListScreen extends ConsumerStatefulWidget {
  const AidatListScreen({super.key});

  @override
  ConsumerState<AidatListScreen> createState() => _AidatListScreenState();
}

class _AidatListScreenState extends ConsumerState<AidatListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  bool get _isAdmin =>
      ref.read(authProvider).user?.rol == UserRole.admin;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _isAdmin ? 2 : 1, vsync: this);
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _load() {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    if (user.rol == UserRole.admin) {
      ref.read(aidatProvider.notifier).loadAll();
      ref.read(otomatikAidatProvider.notifier).load();
    } else {
      ref.read(aidatProvider.notifier).loadByKullanici(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _isAdmin;

    return Scaffold(
      appBar: isAdmin
          ? AppBar(
              automaticallyImplyLeading: false,
              toolbarHeight: 0,
              bottom: TabBar(
                controller: _tab,
                tabs: const [
                  Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Aidatlar'),
                  Tab(icon: Icon(Icons.autorenew), text: 'Otomatik'),
                ],
              ),
            )
          : null,
      body: isAdmin
          ? TabBarView(
              controller: _tab,
              children: [
                _AidatTab(isAdmin: true, onLoad: _load),
                const _OtomatikTab(),
              ],
            )
          : _AidatTab(isAdmin: false, onLoad: _load),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => context.push('/ana-sayfa/aidatlar/yeni'),
              tooltip: 'Yeni Aidat Ekle',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

// ─── Sekme 1: Aidat listesi ──────────────────────────────────────────────────

class _AidatTab extends ConsumerWidget {
  const _AidatTab({required this.isAdmin, required this.onLoad});
  final bool isAdmin;
  final VoidCallback onLoad;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aidatProvider);

    return RefreshIndicator(
      onRefresh: () async => onLoad(),
      child: _buildBody(context, ref, state),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, AidatState state) {
    if (state.isLoading && state.aidatlar.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.aidatlar.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(state.error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onLoad, child: const Text('Tekrar Dene')),
          ],
        ),
      );
    }
    if (state.aidatlar.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Henüz aidat kaydı yok',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.aidatlar.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final aidat = state.aidatlar[i];
        return _AidatTile(
          aidat: aidat,
          isAdmin: isAdmin,
          onDurumChanged: isAdmin
              ? (d) => ref.read(aidatProvider.notifier).updateOdemeDurum(aidat.id, d)
              : null,
        );
      },
    );
  }
}

// ─── Sekme 2: Otomatik aidatlar ──────────────────────────────────────────────

class _OtomatikTab extends ConsumerStatefulWidget {
  const _OtomatikTab();

  @override
  ConsumerState<_OtomatikTab> createState() => _OtomatikTabState();
}

class _OtomatikTabState extends ConsumerState<_OtomatikTab> {
  bool _uretiliyor = false;

  Future<void> _uretBuAy() async {
    setState(() => _uretiliyor = true);
    final result =
        await ref.read(otomatikAidatProvider.notifier).uretBuAy();
    setState(() => _uretiliyor = false);
    if (!mounted) return;

    final String msg;
    final bool isOk;
    if (result is Success<String, AppError>) {
      msg = (result as Success<String, AppError>).data;
      isOk = true;
    } else {
      msg = (result as Failure<String, AppError>).error.message;
      isOk = false;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isOk ? Colors.green : Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(otomatikAidatProvider);

    return Column(
      children: [
        // Üst banner — "Bu Ayı Oluştur"
        Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Aktif kayıtlar her gece otomatik oluşturulur.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: _uretiliyor ? null : _uretBuAy,
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: _uretiliyor
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Bu Ayı Oluştur', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),

        // Liste
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(otomatikAidatProvider.notifier).load(),
            child: _buildBody(context, state),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, OtomatikAidatState state) {
    if (state.isLoading && state.liste.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.liste.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(state.error!, textAlign: TextAlign.center),
          ],
        ),
      );
    }
    if (state.liste.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.autorenew, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Otomatik aidat tanımlanmamış',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
            SizedBox(height: 8),
            Text(
              'Aidat oluştururken\n"Otomatik yenile" seçeneğini işaretle.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.liste.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final o = state.liste[i];
        return _OtomatikTile(kayit: o);
      },
    );
  }
}

class _OtomatikTile extends ConsumerWidget {
  const _OtomatikTile({required this.kayit});
  final OtomatikAidatModel kayit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sonUretim = (kayit.sonUretimAy != null && kayit.sonUretimYil != null)
        ? '${_ayAd(kayit.sonUretimAy!)} ${kayit.sonUretimYil}'
        : 'Henüz üretilmedi';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: (kayit.aktifMi ? Colors.green : Colors.grey)
            .withValues(alpha: 0.15),
        child: Icon(
          Icons.autorenew,
          color: kayit.aktifMi ? Colors.green : Colors.grey,
          size: 20,
        ),
      ),
      title: Text(
        'Daire ${kayit.daireNo} — ${kayit.kullaniciAdSoyad}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '₺${kayit.tutar.toStringAsFixed(2)} / ay',
            style: const TextStyle(fontSize: 13),
          ),
          Text(
            'Son üretim: $sonUretim',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
      isThreeLine: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tutar düzenle
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: 'Tutarı Düzenle',
            onPressed: () => _tutarDuzenle(context, ref),
          ),
          // Toggle
          Switch(
            value: kayit.aktifMi,
            onChanged: (_) =>
                ref.read(otomatikAidatProvider.notifier).toggle(kayit.id),
          ),
        ],
      ),
    );
  }

  void _tutarDuzenle(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController(
        text: kayit.tutar.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Daire ${kayit.daireNo} Tutarı'),
        content: TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Tutar (₺)',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () async {
              final tutar = double.tryParse(
                  ctrl.text.trim().replaceAll(',', '.'));
              if (tutar == null || tutar <= 0) return;
              Navigator.pop(ctx);
              final result = await ref
                  .read(otomatikAidatProvider.notifier)
                  .updateTutar(kayit.id, tutar);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(result is Success
                    ? 'Tutar güncellendi.'
                    : (result as Failure<void, dynamic>).error.message),
                backgroundColor:
                    result is Success ? Colors.green : Colors.red,
              ));
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  static String _ayAd(int ay) => const [
        '',
        'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
      ][ay];
}

// ─── Aidat tile (mevcut) ─────────────────────────────────────────────────────

class _AidatTile extends StatelessWidget {
  const _AidatTile({
    required this.aidat,
    required this.isAdmin,
    this.onDurumChanged,
  });

  final AidatModel aidat;
  final bool isAdmin;
  final void Function(OdemeDurumu)? onDurumChanged;

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = _durumStyle(aidat.odemeDurumu);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        '${_ayAd(aidat.ay)} ${aidat.yil}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '₺${aidat.tutar.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          if (isAdmin) ...[
            Text(aidat.kullaniciAdSoyad,
                style: const TextStyle(fontSize: 13)),
            Text('Daire ${aidat.daireNo}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
          if (aidat.odemeTarihi != null)
            Text(
              'Ödendi: ${DateFormat('d MMMM y', 'tr').format(aidat.odemeTarihi!.toLocal())}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      ),
      trailing: isAdmin
          ? _AdminDurumMenu(
              current: aidat.odemeDurumu,
              onChanged: onDurumChanged,
            )
          : _DurumChip(label: label, color: color),
      isThreeLine: isAdmin,
    );
  }

  static (Color, IconData, String) _durumStyle(OdemeDurumu d) =>
      switch (d) {
        OdemeDurumu.odendi =>
          (Colors.green, Icons.check_circle_outline, 'Ödendi'),
        OdemeDurumu.gecikti =>
          (Colors.red, Icons.warning_amber_outlined, 'Gecikti'),
        OdemeDurumu.beklemede =>
          (Colors.orange, Icons.schedule, 'Beklemede'),
      };

  static String _ayAd(int ay) => const [
        '',
        'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
      ][ay];
}

class _DurumChip extends StatelessWidget {
  const _DurumChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _AdminDurumMenu extends StatelessWidget {
  const _AdminDurumMenu({required this.current, this.onChanged});
  final OdemeDurumu current;
  final void Function(OdemeDurumu)? onChanged;

  @override
  Widget build(BuildContext context) {
    final (color, _, label) = _labelOf(current);
    return PopupMenuButton<OdemeDurumu>(
      onSelected: onChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: color, size: 16),
          ],
        ),
      ),
      itemBuilder: (_) => OdemeDurumu.values
          .map((d) =>
              PopupMenuItem(value: d, child: Text(_labelOf(d).$3)))
          .toList(),
    );
  }

  static (Color, IconData, String) _labelOf(OdemeDurumu d) => switch (d) {
        OdemeDurumu.odendi =>
          (Colors.green, Icons.check_circle_outline, 'Ödendi'),
        OdemeDurumu.gecikti =>
          (Colors.red, Icons.warning_amber_outlined, 'Gecikti'),
        OdemeDurumu.beklemede =>
          (Colors.orange, Icons.schedule, 'Beklemede'),
      };
}
