import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          ? Container(
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
                onPressed: () => context.push('/ana-sayfa/aidatlar/yeni'),
                icon: const Icon(Icons.add),
                label: const Text('Yeni Aidat'),
              ),
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
    final cs = Theme.of(context).colorScheme;

    return RefreshIndicator(
      color: cs.primary,
      onRefresh: () async => onLoad(),
      child: _buildBody(context, ref, state),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, AidatState state) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.isLoading && state.aidatlar.isEmpty) {
      return Center(child: CircularProgressIndicator(color: cs.primary));
    }
    if (state.error != null && state.aidatlar.isEmpty) {
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
              Text(state.error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: cs.onSurfaceVariant)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onLoad,
                style: FilledButton.styleFrom(minimumSize: const Size(140, 44)),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }
    if (state.aidatlar.isEmpty) {
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
              child: Icon(Icons.receipt_long_outlined,
                  size: 48, color: cs.primary.withOpacity(0.5)),
            ),
            const SizedBox(height: 16),
            Text('Henüz aidat kaydı yok',
                style: GoogleFonts.inter(
                    color: cs.onSurfaceVariant, fontSize: 15)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: state.aidatlar.length,
      itemBuilder: (context, i) {
        final aidat = state.aidatlar[i];
        return _AidatTile(
          aidat: aidat,
          isAdmin: isAdmin,
          onDurumChanged: isAdmin
              ? (d) async {
                  final result = await ref
                      .read(aidatProvider.notifier)
                      .updateOdemeDurum(aidat.id, d);
                  if (!context.mounted) return;
                  if (result is Failure<AidatModel, AppError>) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result.error.message)),
                    );
                  }
                }
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Üst banner
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.primary.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: cs.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Aktif kayıtlar her gece otomatik oluşturulur.',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: _uretiliyor ? null : _uretBuAy,
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: _uretiliyor
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: cs.primary))
                    : Text('Bu Ayı Oluştur',
                        style: GoogleFonts.inter(fontSize: 12)),
              ),
            ],
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            color: cs.primary,
            onRefresh: () => ref.read(otomatikAidatProvider.notifier).load(),
            child: _buildBody(context, state, cs, isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(
      BuildContext context, OtomatikAidatState state, ColorScheme cs, bool isDark) {
    if (state.isLoading && state.liste.isEmpty) {
      return Center(child: CircularProgressIndicator(color: cs.primary));
    }
    if (state.error != null && state.liste.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: cs.error),
            const SizedBox(height: 12),
            Text(state.error!, textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }
    if (state.liste.isEmpty) {
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
              child: Icon(Icons.autorenew,
                  size: 48, color: cs.primary.withOpacity(0.5)),
            ),
            const SizedBox(height: 16),
            Text('Otomatik aidat tanımlanmamış',
                style: GoogleFonts.inter(
                    color: cs.onSurfaceVariant, fontSize: 15)),
            const SizedBox(height: 4),
            Text(
              'Aidat oluştururken\n"Otomatik yenile" seçeneğini işaretle.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: cs.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: state.liste.length,
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sonUretim = (kayit.sonUretimAy != null && kayit.sonUretimYil != null)
        ? '${_ayAd(kayit.sonUretimAy!)} ${kayit.sonUretimYil}'
        : 'Henüz üretilmedi';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : const Color(0xFFE8E8E8),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (kayit.aktifMi ? Colors.green : Colors.grey)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.autorenew,
              color: kayit.aktifMi ? Colors.green : Colors.grey,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daire ${kayit.daireNo} — ${kayit.kullaniciAdSoyad}',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: cs.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  '₺${kayit.tutar.toStringAsFixed(2)} / ay',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  'Son üretim: $sonUretim',
                  style: GoogleFonts.inter(fontSize: 11, color: cs.outline),
                ),
              ],
            ),
          ),
          // Tutar düzenle
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 20, color: cs.outline),
            tooltip: 'Tutarı Düzenle',
            onPressed: () => _tutarDuzenle(context, ref),
          ),
          // Toggle
          Switch(
            value: kayit.aktifMi,
            activeColor: cs.primary,
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
            style: FilledButton.styleFrom(minimumSize: const Size(80, 40)),
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

// ─── Aidat tile ──────────────────────────────────────────────────────────────

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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (color, icon, label) = _durumStyle(aidat.odemeDurumu);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: aidat.odemeDurumu == OdemeDurumu.gecikti
              ? cs.error.withOpacity(0.3)
              : (isDark
                  ? Colors.white.withOpacity(0.05)
                  : const Color(0xFFE8E8E8)),
          width: aidat.odemeDurumu == OdemeDurumu.gecikti ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_ayAd(aidat.ay)} ${aidat.yil}',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: cs.onSurface),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₺${aidat.tutar.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: color,
                      decoration: aidat.odemeDurumu == OdemeDurumu.odendi
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: 2),
                    Text(aidat.kullaniciAdSoyad,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: cs.onSurfaceVariant)),
                    Text('Daire ${aidat.daireNo}',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: cs.outline)),
                  ],
                  if (aidat.odemeTarihi != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              size: 12, color: Colors.green[600]),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('d MMMM y', 'tr')
                                .format(aidat.odemeTarihi!.toLocal()),
                            style: GoogleFonts.inter(
                                fontSize: 11, color: cs.outline),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            isAdmin
                ? _AdminDurumMenu(
                    current: aidat.odemeDurumu,
                    onChanged: onDurumChanged,
                  )
                : _DurumChip(label: label, color: color),
          ],
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    color: color,
                    fontSize: 11,
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
