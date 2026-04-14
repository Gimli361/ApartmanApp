import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    final ariza = arizaState.arizalar
        .cast<ArizaModel?>()
        .firstWhere((a) => a?.id == arizaId, orElse: () => null);

    if (ariza == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Arıza bulunamadı.')),
      );
    }

    // Takip durumu: provider'dan günceli al, yoksa model'den
    final takipDurumu = takipAsync.valueOrNull;
    final takipEdiyor = takipDurumu?.takipEdiyor ?? ariza.kullaniciTakipEdiyor;
    final takipciSayisi = takipDurumu?.takipciSayisi ?? ariza.takipciSayisi;

    final sakinTakipGoster = !isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Arıza Detayı'),
        actions: [
          if (sakinTakipGoster)
            takipAsync.when(
              loading: () =>
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              error: (_, __) => const SizedBox.shrink(),
              data: (_) => IconButton(
                icon: Icon(
                  takipEdiyor ? Icons.notifications_active : Icons.notifications_none,
                  color: takipEdiyor
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                tooltip: takipEdiyor ? 'Takipten Çık' : 'Takip Et',
                onPressed: () =>
                    _toggleTakip(context, ref, ariza.id, takipEdiyor),
              ),
            ),
          if (isAdmin)
            PopupMenuButton<ArizaDurum>(
              icon: const Icon(Icons.update),
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
        padding: const EdgeInsets.all(16),
        children: [
          // Durum + öncelik row
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
          const SizedBox(height: 16),

          Text(
            ariza.baslik,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Text(ariza.aciklama,
              style: const TextStyle(fontSize: 15, height: 1.5)),

          // Red nedeni göster
          if (ariza.durum == ArizaDurum.reddedildi &&
              ariza.redNedeni != null &&
              ariza.redNedeni!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.cancel_outlined, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Red Nedeni',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.red,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(ariza.redNedeni!,
                            style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          const Divider(),
          const SizedBox(height: 12),

          _InfoRow(
            icon: Icons.person_outline,
            label: 'Bildiren',
            value: '${ariza.bildirenAdSoyad} (Daire ${ariza.bildirenDaireNo})',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Tarih',
            value: DateFormat('dd.MM.yyyy HH:mm').format(ariza.tarih.toLocal()),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.tag,
            label: 'ID',
            value: '#${ariza.id}',
          ),

          // Takipçi bilgisi
          if (takipciSayisi > 0) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.group_outlined,
              label: 'Takip',
              value: takipciSayisi == 1
                  ? '1 komşunuz bu sorunu takip ediyor'
                  : '$takipciSayisi komşunuz bu sorunu takip ediyor',
            ),
          ],

          // Fotoğraflar
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          Text('Fotoğraflar', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          _FotolarSection(arizaId: ariza.id),

          if (isAdmin) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            Text('Durum Güncelle',
                style: Theme.of(context).textTheme.labelLarge),
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
                            ? durumColor(d).withValues(alpha: 0.15)
                            : null,
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
            border: OutlineInputBorder(),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
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

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 14)),
          ],
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

    return async.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const Text('Fotoğraflar yüklenemedi.'),
      data: (urls) {
        if (urls.isEmpty) {
          return Text('Fotoğraf yok.',
              style: TextStyle(color: Colors.grey[500], fontSize: 13));
        }
        return SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: urls.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final url = urls[i];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _FullScreenImage(url: url),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    url,
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 110,
                      height: 110,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
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
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
