import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../domain/ariza_model.dart';
import '../../../core/result.dart';
import '../../../features/auth/domain/user_model.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import 'ariza_helpers.dart';
import 'providers/ariza_provider.dart';

final _fotolarProvider =
    FutureProvider.family<List<String>, int>((ref, arizaId) async {
  final repo = ref.read(arizaRepositoryProvider);
  final result = await repo.getFotolar(arizaId);
  if (result is Success<List<String>, AppError>) return result.data;
  return [];
});

// Invalidate edilebilir takip durumu provider'ı (detail ekranına özel)
final _takipDurumuDetailProvider =
    FutureProvider.family<TakipDurumuModel, int>((ref, arizaId) async {
  final repo = ref.read(arizaRepositoryProvider);
  final result = await repo.getTakipDurumu(arizaId);
  if (result is Success<TakipDurumuModel, AppError>) return result.data;
  return const TakipDurumuModel(takipEdiyor: false, takipciSayisi: 0);
});

class ArizaDetailScreen extends ConsumerWidget {
  final int arizaId;

  const ArizaDetailScreen({super.key, required this.arizaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arizaState = ref.watch(arizaListProvider);
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.rol == UserRole.admin;
    final takipAsync = ref.watch(_takipDurumuDetailProvider(arizaId));
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final ariza = arizaState.arizalar
        .cast<ArizaModel?>()
        .firstWhere((a) => a?.id == arizaId, orElse: () => null);

    if (ariza == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text('Arıza bulunamadı.',
              style: GoogleFonts.inter(color: cs.onSurfaceVariant)),
        ),
      );
    }

    // Takip durumu
    final takipDurumu = takipAsync.valueOrNull;
    final takipEdiyor = takipDurumu?.takipEdiyor ?? ariza.kullaniciTakipEdiyor;
    final takipciSayisi = takipDurumu?.takipciSayisi ?? ariza.takipciSayisi;
    final sakinTakipGoster = !isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text('Arıza Detayı',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        actions: [
          if (sakinTakipGoster)
            takipAsync.when(
              loading: () => Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: cs.primary),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (_) => IconButton(
                icon: Icon(
                  takipEdiyor
                      ? Icons.notifications_active
                      : Icons.notifications_none,
                  color: takipEdiyor ? cs.primary : null,
                ),
                tooltip: takipEdiyor ? 'Takipten Çık' : 'Takip Et',
                onPressed: () =>
                    _toggleTakip(context, ref, ariza.id, takipEdiyor),
              ),
            ),
          if (isAdmin)
            PopupMenuButton<ArizaDurum>(
              icon: Icon(Icons.update, color: cs.primary),
              tooltip: 'Durum Güncelle',
              onSelected: (d) => _updateDurum(context, ref, ariza, d),
              itemBuilder: (_) => ArizaDurum.values
                  .map((d) => PopupMenuItem(
                        value: d,
                        child: Row(
                          children: [
                            Icon(durumIcon(d), color: durumColor(d), size: 18),
                            const SizedBox(width: 8),
                            Text(d.label),
                          ],
                        ),
                      ))
                  .toList(),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Status & Priority Badges ──
          Row(
            children: [
              _Badge(
                label: ariza.durum.label,
                color: durumColor(ariza.durum),
                icon: durumIcon(ariza.durum),
              ),
              const SizedBox(width: 8),
              _Badge(
                label: ariza.oncelik.label,
                color: oncelikColor(ariza.oncelik),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Title ──
          Text(
            ariza.baslik,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),

          // ── Description ──
          Text(
            ariza.aciklama,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.6,
              color: cs.onSurfaceVariant,
            ),
          ),

          // Red nedeni göster
          if (ariza.durum == ArizaDurum.reddedildi &&
              ariza.redNedeni != null &&
              ariza.redNedeni!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.error.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.cancel_outlined, color: cs.error, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Red Nedeni',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: cs.error,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(ariza.redNedeni!,
                            style: GoogleFonts.inter(
                                fontSize: 13, color: cs.onSurface)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          // ── Info Section ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? cs.surfaceContainerHigh : cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : const Color(0xFFE8E8E8),
              ),
            ),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.person_outline,
                  label: 'Bildiren',
                  value:
                      '${ariza.bildirenAdSoyad} (Daire ${ariza.bildirenDaireNo})',
                  cs: cs,
                ),
                Divider(
                    height: 20,
                    color:
                        isDark ? cs.outlineVariant : const Color(0xFFE8E8E8)),
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Tarih',
                  value: DateFormat('dd.MM.yyyy HH:mm')
                      .format(ariza.tarih.toLocal()),
                  cs: cs,
                ),
                Divider(
                    height: 20,
                    color:
                        isDark ? cs.outlineVariant : const Color(0xFFE8E8E8)),
                _InfoRow(
                  icon: Icons.tag,
                  label: 'ID',
                  value: '#${ariza.id}',
                  cs: cs,
                ),
                if (takipciSayisi > 0) ...[
                  Divider(
                      height: 20,
                      color:
                          isDark ? cs.outlineVariant : const Color(0xFFE8E8E8)),
                  _InfoRow(
                    icon: Icons.group_outlined,
                    label: 'Takip',
                    value: takipciSayisi == 1
                        ? '1 komşunuz bu sorunu takip ediyor'
                        : '$takipciSayisi komşunuz bu sorunu takip ediyor',
                    cs: cs,
                  ),
                ],
              ],
            ),
          ),

          // ── Fotoğraflar ──
          const SizedBox(height: 24),
          Text(
            'FOTOĞRAFLAR',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.outline,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _FotolarSection(arizaId: ariza.id),

          // ── Admin: Durum Güncelle ──
          if (isAdmin) ...[
            const SizedBox(height: 24),
            Text(
              'DURUM GÜNCELLE',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.outline,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ArizaDurum.values
                  .map((d) => ActionChip(
                        avatar: Icon(durumIcon(d),
                            color: durumColor(d), size: 16),
                        label: Text(d.label),
                        onPressed: ariza.durum == d
                            ? null
                            : () => _updateDurum(context, ref, ariza, d),
                        backgroundColor: ariza.durum == d
                            ? durumColor(d).withOpacity(0.15)
                            : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _toggleTakip(
    BuildContext context,
    WidgetRef ref,
    int arizaId,
    bool suankiTakipEdiyor,
  ) async {
    final repo = ref.read(arizaRepositoryProvider);
    final result = suankiTakipEdiyor
        ? await repo.takiptenCik(arizaId)
        : await repo.takipEt(arizaId);

    if (!context.mounted) return;

    if (result is Success) {
      ref.invalidate(_takipDurumuDetailProvider(arizaId));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(suankiTakipEdiyor
            ? 'Arıza takibinden çıkıldı.'
            : 'Arıza takibe alındı. Güncellemelerden haberdar edileceksiniz.'),
        backgroundColor: Colors.green,
      ));
    } else if (result is Failure) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('İşlem başarısız.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _updateDurum(
    BuildContext context,
    WidgetRef ref,
    ArizaModel ariza,
    ArizaDurum yeniDurum,
  ) async {
    String? redNedeni;

    // Reddedildi seçilirse red nedeni sor
    if (yeniDurum == ArizaDurum.reddedildi && context.mounted) {
      redNedeni = await _showRedNedeniDialog(context);
      if (redNedeni == null) return; // iptal
    }

    if (!context.mounted) return;

    final success = await ref
        .read(arizaListProvider.notifier)
        .updateDurum(ariza.id, yeniDurum, redNedeni: redNedeni);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? 'Durum "${yeniDurum.label}" olarak güncellendi.'
          : ref.read(arizaListProvider).errorMessage ?? 'Hata oluştu.'),
      backgroundColor: success ? Colors.green : Colors.red,
    ));
  }

  Future<String?> _showRedNedeniDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Red Nedeni'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Örn: Kullanıcı hatası, garanti kapsamı dışı...',
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              final val = controller.text.trim();
              if (val.isEmpty) return;
              Navigator.pop(ctx, val);
            },
            style: FilledButton.styleFrom(minimumSize: const Size(80, 40)),
            child: const Text('Reddet'),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _Badge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: GoogleFonts.inter(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme cs;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: cs.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 11, color: cs.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(value,
                  style: GoogleFonts.inter(
                      fontSize: 14, color: cs.onSurface)),
            ],
          ),
        ),
      ],
    );
  }
}

class _FotolarSection extends ConsumerWidget {
  final int arizaId;
  const _FotolarSection({required this.arizaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_fotolarProvider(arizaId));
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return async.when(
      loading: () => SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator(color: cs.primary)),
      ),
      error: (_, __) => Text('Fotoğraflar yüklenemedi.',
          style: GoogleFonts.inter(color: cs.error)),
      data: (urls) {
        if (urls.isEmpty) {
          return Text('Fotoğraf yok.',
              style: GoogleFonts.inter(
                  color: cs.onSurfaceVariant, fontSize: 13));
        }
        return SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: urls.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final url = urls[i];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _FullScreenImage(url: url),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : const Color(0xFFE8E8E8),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      url,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 120,
                        height: 120,
                        color: isDark
                            ? cs.surfaceContainerHigh
                            : cs.surfaceContainerLow,
                        child: Icon(Icons.broken_image,
                            color: cs.onSurfaceVariant),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _FullScreenImage extends StatelessWidget {
  final String url;
  const _FullScreenImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar:
          AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
