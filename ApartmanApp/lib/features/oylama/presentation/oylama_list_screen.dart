import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: _isAdmin
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
                onPressed: () async {
                  final created = await context.push<bool>('/ana-sayfa/oylamalar/yeni');
                  if (created == true && mounted) {
                    ref.read(oylamaListProvider.notifier).load();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Yeni Oylama'),
              ),
            )
          : null,
      body: Builder(builder: (_) {
        if (state.isLoading) {
          return Center(child: CircularProgressIndicator(color: cs.primary));
        }
        if (state.error != null) {
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
                      style: GoogleFonts.inter(color: cs.error),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.read(oylamaListProvider.notifier).load(),
                    style: FilledButton.styleFrom(minimumSize: const Size(140, 44)),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            ),
          );
        }
        if (state.oylamalar.isEmpty) {
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
                  child: Icon(Icons.how_to_vote_outlined,
                      size: 48, color: cs.primary.withOpacity(0.5)),
                ),
                const SizedBox(height: 16),
                Text('Henüz oylama yok.',
                    style: GoogleFonts.inter(
                        color: cs.onSurfaceVariant, fontSize: 15)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: cs.primary,
          onRefresh: () => ref.read(oylamaListProvider.notifier).load(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt = DateFormat('dd.MM.yyyy HH:mm');

    Color statusColor;
    String statusText;
    IconData statusIcon;
    if (!oylama.aktifMi) {
      statusColor = Colors.grey;
      statusText = 'Pasif';
      statusIcon = Icons.pause_circle_outline;
    } else if (oylama.suresiDoldu) {
      statusColor = Colors.orange;
      statusText = 'Süresi Doldu';
      statusIcon = Icons.timer_off_outlined;
    } else {
      statusColor = Colors.green;
      statusText = 'Açık';
      statusIcon = Icons.check_circle_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : const Color(0xFFE8E8E8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
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
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: cs.onSurface,
                          )),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(statusText,
                              style: GoogleFonts.inter(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (oylama.aciklama != null &&
                    oylama.aciklama!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(oylama.aciklama!,
                      style: GoogleFonts.inter(
                          color: cs.onSurfaceVariant, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.how_to_vote_outlined,
                        size: 14, color: cs.outline),
                    const SizedBox(width: 4),
                    Text('${oylama.toplamOySayisi} oy',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: cs.onSurfaceVariant)),
                    const Spacer(),
                    Icon(Icons.schedule, size: 14, color: cs.outline),
                    const SizedBox(width: 4),
                    Text(fmt.format(oylama.bitisTarihi.toLocal()),
                        style: GoogleFonts.inter(
                            fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
                if (oylama.kullaniciOyKullandi) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle,
                            size: 14, color: Colors.green[600]),
                        const SizedBox(width: 4),
                        Text('Oyunuzu kullandınız',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: Colors.green[600])),
                      ],
                    ),
                  ),
                ],
                // Admin: toggle + sil
                if (isAdmin) ...[
                  const SizedBox(height: 12),
                  Divider(
                      color: isDark ? cs.outlineVariant : const Color(0xFFE8E8E8)),
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
                        label: Text(
                            oylama.aktifMi ? 'Pasif Et' : 'Aktif Et',
                            style: GoogleFonts.inter(fontSize: 12)),
                      ),
                      const SizedBox(width: 4),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                            foregroundColor: cs.error),
                        onPressed: () => _confirmDelete(context, ref),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: Text('Sil',
                            style: GoogleFonts.inter(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final cs = Theme.of(context).colorScheme;
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
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              minimumSize: const Size(80, 40),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
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
