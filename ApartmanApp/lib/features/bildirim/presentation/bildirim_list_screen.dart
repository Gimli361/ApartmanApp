import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../domain/bildirim_model.dart';
import 'providers/bildirim_provider.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/auth/domain/user_model.dart';
import '../../../shared/models/blok_model.dart';
import '../../../shared/models/daire_model.dart';
import '../../../shared/providers/bina_provider.dart';

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

  bool get _isAdmin =>
      ref.read(authProvider).user?.rol == UserRole.admin;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bildirimProvider);
    final hasUnread = state.unreadCount > 0;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(bildirimProvider.notifier).load(),
        child: _buildBody(context, state),
      ),
      floatingActionButton: _buildFab(hasUnread),
    );
  }

  Widget? _buildFab(bool hasUnread) {
    if (_isAdmin) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (hasUnread) ...[
            FloatingActionButton.small(
              heroTag: 'okundu',
              onPressed: () =>
                  ref.read(bildirimProvider.notifier).markAllAsRead(),
              tooltip: 'Tümünü Okundu İşaretle',
              child: const Icon(Icons.done_all, size: 20),
            ),
            const SizedBox(height: 10),
          ],
          FloatingActionButton.extended(
            heroTag: 'bildirimGonder',
            onPressed: () => _showBildirimSecenekleri(context),
            icon: const Icon(Icons.send_outlined),
            label: const Text('Bildirim Gönder'),
          ),
        ],
      );
    }
    if (hasUnread) {
      return FloatingActionButton.extended(
        onPressed: () =>
            ref.read(bildirimProvider.notifier).markAllAsRead(),
        icon: const Icon(Icons.done_all),
        label: const Text('Tümünü Okundu İşaretle'),
      );
    }
    return null;
  }

  void _showBildirimSecenekleri(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text('Bildirim Türü Seçin',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.withValues(alpha: 0.12),
                child: const Icon(Icons.campaign_outlined,
                    color: Colors.blue),
              ),
              title: const Text('Tüm Sakinlere Duyuru'),
              subtitle: const Text('Tüm sakinlere push bildirim gönderir',
                  style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _showDuyuruSheet(context);
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.withValues(alpha: 0.12),
                child: const Icon(Icons.apartment_outlined,
                    color: Colors.orange),
              ),
              title: const Text('Bloğa Bildirim'),
              subtitle: const Text('Tüm bloğa bildirim gönderir',
                  style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _showBlokBildirimSheet(context);
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.withValues(alpha: 0.12),
                child:
                    const Icon(Icons.home_outlined, color: Colors.green),
              ),
              title: const Text('Daireye Bildirim'),
              subtitle: const Text('Belirli bir daireye mesaj gönderir',
                  style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _showDaireBildirimSheet(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showDuyuruSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _DuyuruSheet(
        onSend: (baslik, icerik) async {
          return ref
              .read(bildirimProvider.notifier)
              .sendDuyuru(baslik, icerik);
        },
      ),
    );
  }

  void _showBlokBildirimSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _BlokBildirimSheet(
        onSend: (blokNo, baslik, icerik) async {
          return ref
              .read(bildirimProvider.notifier)
              .sendBlokBildirim(blokNo, baslik, icerik);
        },
      ),
    );
  }

  void _showDaireBildirimSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _DaireBildirimSheet(
        onSend: (daireNo, baslik, icerik, {blokNo}) async {
          return ref
              .read(bildirimProvider.notifier)
              .sendDaireBildirim(daireNo, baslik, icerik, blokNo: blokNo);
        },
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
      padding: const EdgeInsets.only(bottom: 100, top: 8),
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
            Text(b.icerik,
                style: const TextStyle(fontSize: 14, height: 1.5)),
            const SizedBox(height: 12),
            Text(
              DateFormat('d MMMM y, HH:mm', 'tr')
                  .format(b.gonderimTarihi.toLocal()),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Duyuru Sheet ─────────────────────────────────────────────────────────────

class _DuyuruSheet extends StatefulWidget {
  final Future<String?> Function(String baslik, String icerik) onSend;

  const _DuyuruSheet({required this.onSend});

  @override
  State<_DuyuruSheet> createState() => _DuyuruSheetState();
}

class _DuyuruSheetState extends State<_DuyuruSheet> {
  final _formKey = GlobalKey<FormState>();
  final _baslikCtrl = TextEditingController();
  final _icerikCtrl = TextEditingController();
  bool _isLoading = false;
  String? _hata;

  @override
  void dispose() {
    _baslikCtrl.dispose();
    _icerikCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.withValues(alpha: 0.12),
                  child: const Icon(Icons.campaign_outlined,
                      color: Colors.blue),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Tüm Sakinlere Duyuru',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(height: 20),
            TextFormField(
              controller: _baslikCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Başlık *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Başlık zorunludur' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _icerikCtrl,
              maxLines: 4,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'İçerik *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'İçerik zorunludur' : null,
            ),
            if (_hata != null) ...[
              const SizedBox(height: 8),
              _ErrorBox(message: _hata!),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_outlined),
              label: const Text('Gönder'),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _hata = null;
    });
    final err = await widget.onSend(
        _baslikCtrl.text.trim(), _icerikCtrl.text.trim());
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (err != null) {
      setState(() => _hata = err);
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Duyuru tüm sakinlere gönderildi.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

// ─── Bloğa Bildirim Sheet ─────────────────────────────────────────────────────

class _BlokBildirimSheet extends ConsumerStatefulWidget {
  final Future<String?> Function(String blokNo, String baslik, String icerik)
      onSend;

  const _BlokBildirimSheet({required this.onSend});

  @override
  ConsumerState<_BlokBildirimSheet> createState() => _BlokBildirimSheetState();
}

class _BlokBildirimSheetState extends ConsumerState<_BlokBildirimSheet> {
  final _formKey = GlobalKey<FormState>();
  final _baslikCtrl = TextEditingController();
  final _icerikCtrl = TextEditingController();
  String? _secilenBlok;
  bool _isLoading = false;
  String? _hata;

  @override
  void dispose() {
    _baslikCtrl.dispose();
    _icerikCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final binaAsync = ref.watch(binaProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange.withValues(alpha: 0.12),
                  child: const Icon(Icons.apartment_outlined,
                      color: Colors.orange),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Bloğa Bildirim',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(height: 20),
            binaAsync.when(
              loading: () => const Center(
                  child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(),
              )),
              error: (e, _) => Text('Bloklar yüklenemedi: $e',
                  style: const TextStyle(color: Colors.red)),
              data: (bloklar) => DropdownButtonFormField<String>(
                value: _secilenBlok,
                decoration: const InputDecoration(
                  labelText: 'Blok *',
                  prefixIcon: Icon(Icons.apartment_outlined),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                hint: const Text('Blok seçin'),
                items: bloklar
                    .map((b) => DropdownMenuItem(
                          value: b.ad,
                          child: Text('${b.ad} Blok'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _secilenBlok = v),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Blok seçimi zorunludur' : null,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _baslikCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Başlık *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Başlık zorunludur' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _icerikCtrl,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'İçerik *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'İçerik zorunludur' : null,
            ),
            if (_hata != null) ...[
              const SizedBox(height: 8),
              _ErrorBox(message: _hata!),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_outlined),
              label: const Text('Gönder'),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _hata = null;
    });
    final err = await widget.onSend(
      _secilenBlok!,
      _baslikCtrl.text.trim(),
      _icerikCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (err != null) {
      setState(() => _hata = err);
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('$_secilenBlok bloğundaki sakinlere bildirim gönderildi.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}

// ─── Daireye Bildirim Sheet ───────────────────────────────────────────────────

class _DaireBildirimSheet extends ConsumerStatefulWidget {
  final Future<String?> Function(String daireNo, String baslik, String icerik,
      {String? blokNo}) onSend;

  const _DaireBildirimSheet({required this.onSend});

  @override
  ConsumerState<_DaireBildirimSheet> createState() =>
      _DaireBildirimSheetState();
}

class _DaireBildirimSheetState extends ConsumerState<_DaireBildirimSheet> {
  final _formKey = GlobalKey<FormState>();
  final _baslikCtrl = TextEditingController();
  final _icerikCtrl = TextEditingController();
  String? _secilenBlok;
  String? _secilenDaire;
  bool _isLoading = false;
  String? _hata;

  @override
  void dispose() {
    _baslikCtrl.dispose();
    _icerikCtrl.dispose();
    super.dispose();
  }

  List<DaireModel> _filtrelenmissDaireler(List<BlokModel> bloklar) {
    if (_secilenBlok == null) {
      return bloklar.expand((b) => b.daireler).toList();
    }
    return bloklar
        .where((b) => b.ad == _secilenBlok)
        .expand((b) => b.daireler)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final binaAsync = ref.watch(binaProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green.withValues(alpha: 0.12),
                  child: const Icon(Icons.home_outlined, color: Colors.green),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Daireye Bildirim',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(height: 20),
            binaAsync.when(
              loading: () => const Center(
                  child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(),
              )),
              error: (e, _) => Text('Bloklar yüklenemedi: $e',
                  style: const TextStyle(color: Colors.red)),
              data: (bloklar) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Blok dropdown (opsiyonel)
                  DropdownButtonFormField<String>(
                    value: _secilenBlok,
                    decoration: const InputDecoration(
                      labelText: 'Blok (opsiyonel)',
                      prefixIcon: Icon(Icons.apartment_outlined),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    hint: const Text('Tüm bloklar'),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('— Tüm bloklar —')),
                      ...bloklar.map((b) => DropdownMenuItem(
                            value: b.ad,
                            child: Text('${b.ad} Blok'),
                          )),
                    ],
                    onChanged: (v) => setState(() {
                      _secilenBlok = v;
                      _secilenDaire = null; // blok değişince daireyi sıfırla
                    }),
                  ),
                  const SizedBox(height: 12),
                  // Daire dropdown (bloka göre filtreli)
                  DropdownButtonFormField<String>(
                    value: _secilenDaire,
                    decoration: const InputDecoration(
                      labelText: 'Daire *',
                      prefixIcon: Icon(Icons.door_front_door_outlined),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    hint: const Text('Daire seçin'),
                    items: _filtrelenmissDaireler(bloklar)
                        .map((d) {
                          final blokAdi = bloklar
                              .firstWhere((b) => b.id == d.blokId,
                                  orElse: () => bloklar.first)
                              .ad;
                          return DropdownMenuItem(
                            value: d.daireNo,
                            child: Text('$blokAdi - ${d.daireNo}'),
                          );
                        })
                        .toList(),
                    onChanged: (v) => setState(() => _secilenDaire = v),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Daire seçimi zorunludur' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _baslikCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Başlık *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Başlık zorunludur' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _icerikCtrl,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'İçerik *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'İçerik zorunludur' : null,
            ),
            if (_hata != null) ...[
              const SizedBox(height: 8),
              _ErrorBox(message: _hata!),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_outlined),
              label: const Text('Gönder'),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _hata = null;
    });
    final err = await widget.onSend(
      _secilenDaire!,
      _baslikCtrl.text.trim(),
      _icerikCtrl.text.trim(),
      blokNo: _secilenBlok,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (err != null) {
      setState(() => _hata = err);
    } else {
      Navigator.pop(context);
      final hedef = _secilenBlok != null
          ? '$_secilenBlok Blok $_secilenDaire'
          : _secilenDaire!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$hedef dairesine bildirim gönderildi.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

// ─── Yardımcı Widget'lar ──────────────────────────────────────────────────────

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[200]!)),
      child: Text(message,
          style: TextStyle(color: Colors.red[700], fontSize: 13)),
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
          ? Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: 0.3)
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
      'YeniAriza' => (Icons.report_problem_outlined, Colors.red),
      'Duyuru' => (Icons.campaign_outlined, Colors.blue),
      'DaireMesaj' => (Icons.home_outlined, Colors.green),
      'BlokMesaj' => (Icons.apartment_outlined, Colors.orange),
      _ => (Icons.notifications_outlined, Colors.grey),
    };
    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.15),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
