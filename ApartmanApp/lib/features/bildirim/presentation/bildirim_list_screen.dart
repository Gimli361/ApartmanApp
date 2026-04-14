import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../domain/bildirim_model.dart';
import 'providers/bildirim_provider.dart';

class BildirimListScreen extends ConsumerStatefulWidget {
  const BildirimListScreen({super.key});

  @override
  ConsumerState<BildirimListScreen> createState() => _BildirimListScreenState();
}

class _BildirimListScreenState extends ConsumerState<BildirimListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(bildirimProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bildirimProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(bildirimProvider.notifier).load(),
        child: _buildBody(context, state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, BildirimState state) {
    if (state.isLoading && state.bildirimler.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.bildirimler.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(state.error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.read(bildirimProvider.notifier).load(),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (state.bildirimler.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Henüz bildirim yok',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.bildirimler.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final b = state.bildirimler[index];
        return _BildirimTile(
          bildirim: b,
          onTap: () {
            if (!b.okundu) {
              ref.read(bildirimProvider.notifier).markAsRead(b.id);
            }
            _showDetail(context, b);
          },
        );
      },
    );
  }

  void _showDetail(BuildContext context, BildirimModel b) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _TipIcon(tip: b.tip),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(b.baslik,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(b.icerik, style: const TextStyle(fontSize: 14, height: 1.5)),
            const SizedBox(height: 12),
            Text(
              DateFormat('d MMMM y, HH:mm', 'tr').format(b.gonderimTarihi.toLocal()),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _BildirimTile extends StatelessWidget {
  const _BildirimTile({required this.bildirim, required this.onTap});

  final BildirimModel bildirim;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !bildirim.okundu;
    return ListTile(
      onTap: onTap,
      tileColor: unread
          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      leading: _TipIcon(tip: bildirim.tip),
      title: Text(
        bildirim.baslik,
        style: TextStyle(
          fontWeight: unread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bildirim.icerik,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            _formatDate(bildirim.gonderimTarihi),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
      trailing: unread
          ? Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            )
          : null,
      isThreeLine: true,
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    final diff = now.difference(local);
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    return DateFormat('d MMM y', 'tr').format(local);
  }
}

class _TipIcon extends StatelessWidget {
  const _TipIcon({required this.tip});
  final String tip;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (tip) {
      'ArizaDurum' => (Icons.build_circle_outlined, Colors.orange),
      'YeniAriza'  => (Icons.report_problem_outlined, Colors.red),
      'Duyuru'     => (Icons.campaign_outlined, Colors.blue),
      'DaireMesaj' => (Icons.home_outlined, Colors.green),
      _            => (Icons.notifications_outlined, Colors.grey),
    };
    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.15),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
