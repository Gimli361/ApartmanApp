import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../domain/oylama_model.dart';
import 'providers/oylama_provider.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/auth/domain/user_model.dart';

class OylamaListScreen extends ConsumerStatefulWidget {
  const OylamaListScreen({super.key});

  @override
  ConsumerState<OylamaListScreen> createState() => _OylamaListScreenState();
}

class _OylamaListScreenState extends ConsumerState<OylamaListScreen> {
  bool get _isAdmin =>
      ref.read(authProvider).user?.rol == UserRole.admin;

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(oylamaListProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(oylamaListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Oylamalar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(oylamaListProvider.notifier).load(),
          ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                final created = await context.push<bool>('/ana-sayfa/oylamalar/yeni');
                if (created == true && mounted) {
                  ref.read(oylamaListProvider.notifier).load();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Yeni Oylama'),
            )
          : null,
      body: Builder(builder: (_) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.read(oylamaListProvider.notifier).load(),
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          );
        }
        if (state.oylamalar.isEmpty) {
          return const Center(
            child: Text('Henüz oylama yok.',
                style: TextStyle(color: Colors.grey)),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(oylamaListProvider.notifier).load(),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: state.oylamalar.length,
            itemBuilder: (ctx, i) =>
                _OylamaCard(oylama: state.oylamalar[i], isAdmin: _isAdmin),
          ),
        );
      }),
    );
  }
}

class _OylamaCard extends ConsumerWidget {
  final OylamaModel oylama;
  final bool isAdmin;

  const _OylamaCard({required this.oylama, required this.isAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd.MM.yyyy HH:mm');

    Color statusColor;
    String statusText;
    if (!oylama.aktifMi) {
      statusColor = Colors.grey;
      statusText = 'Pasif';
    } else if (oylama.suresiDoldu) {
      statusColor = Colors.orange;
      statusText = 'Süresi Doldu';
    } else {
      statusColor = Colors.green;
      statusText = 'Açık';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/ana-sayfa/oylamalar/${oylama.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(oylama.baslik,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(statusText,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              if (oylama.aciklama != null && oylama.aciklama!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(oylama.aciklama!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.how_to_vote_outlined,
                      size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text('${oylama.toplamOySayisi} oy',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const Spacer(),
                  Icon(Icons.schedule, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(fmt.format(oylama.bitisTarihi.toLocal()),
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
              if (oylama.kullaniciOyKullandi) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.check_circle,
                        size: 14, color: Colors.green[600]),
                    const SizedBox(width: 4),
                    Text('Oyunuzu kullandınız',
                        style: TextStyle(
                            fontSize: 12, color: Colors.green[600])),
                  ],
                ),
              ],
              // Admin: toggle + sil
              if (isAdmin) ...[
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        await ref
                            .read(oylamaRepositoryProvider)
                            .toggleAktif(oylama.id);
                        ref.read(oylamaListProvider.notifier).load();
                      },
                      icon: Icon(
                          oylama.aktifMi ? Icons.pause : Icons.play_arrow,
                          size: 18),
                      label: Text(oylama.aktifMi ? 'Pasif Et' : 'Aktif Et',
                          style: const TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.red[700]),
                      onPressed: () => _confirmDelete(context, ref),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Sil',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Oylama Sil'),
        content:
            Text('"${oylama.baslik}" oylamasını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(oylamaRepositoryProvider).delete(oylama.id);
      ref.read(oylamaListProvider.notifier).removeById(oylama.id);
    }
  }
}
