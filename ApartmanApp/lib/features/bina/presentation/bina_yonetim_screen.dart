import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../shared/models/blok_model.dart';
import '../../../shared/models/daire_model.dart';
import '../../../shared/services/api_service.dart';

class BinaYonetimScreen extends ConsumerStatefulWidget {
  const BinaYonetimScreen({super.key});

  @override
  ConsumerState<BinaYonetimScreen> createState() => _BinaYonetimScreenState();
}

class _BinaYonetimScreenState extends ConsumerState<BinaYonetimScreen> {
  List<BlokModel> _bloklar = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final api = ref.read(apiServiceProvider);
    try {
      final res = await api.dio.get('/api/blok/detay');
      if (!mounted) return;
      final data = (res.data['data'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(BlokModel.fromJson)
          .toList();
      setState(() {
        _bloklar = data;
        _isLoading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = ApiService.handleDioError(e).message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  // ── Blok Ekle ──────────────────────────────────────────────────────────────

  Future<void> _blokEkle() async {
    final ctrl = TextEditingController();
    String? hata;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Row(children: [
            Icon(Icons.add_home_outlined, color: Colors.blue),
            SizedBox(width: 8),
            Text('Blok Ekle'),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      autofocus: true,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Blok Adı',
                        hintText: 'Örn: A, B, Kuzey',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        errorText: hata,
                      ),
                      onSubmitted: (_) => Navigator.pop(ctx, true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Blok', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ekle')),
          ],
        ),
      ),
    );

    if (ok != true || !mounted) return;
    final ad = ctrl.text.trim();
    if (ad.isEmpty) return;

    final api = ref.read(apiServiceProvider);
    try {
      await api.dio.post('/api/blok', data: {'ad': ad});
      _snack('$ad Blok eklendi.', Colors.green);
      _load();
    } on DioException catch (e) {
      _snack(ApiService.handleDioError(e).message, Colors.red);
    } catch (e) {
      _snack(e.toString(), Colors.red);
    }
  }

  Future<void> _blokSil(BlokModel blok) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bloğu Sil'),
        content: Text('"${blok.ad} Blok" ve ${blok.daireler.length} dairesi silinecek. Emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final api = ref.read(apiServiceProvider);
    try {
      await api.dio.delete('/api/blok/${blok.id}');
      if (!mounted) return;
      setState(() => _bloklar.removeWhere((b) => b.id == blok.id));
      _snack('${blok.ad} Blok silindi.', Colors.green);
    } on DioException catch (e) {
      _snack(ApiService.handleDioError(e).message, Colors.red);
    } catch (e) {
      _snack(e.toString(), Colors.red);
    }
  }

  // ── Daire Ekle ─────────────────────────────────────────────────────────────

  Future<void> _daireEkle(BlokModel blok) async {
    final ctrl = TextEditingController();
    String? hata;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Row(children: [
            const Icon(Icons.door_front_door_outlined, color: Colors.blue),
            const SizedBox(width: 8),
            Text('${blok.ad} Blok — Daire Ekle'),
          ]),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Daire Numarası',
              hintText: 'Örn: 1, 2, 3A',
              border: const OutlineInputBorder(),
              isDense: true,
              errorText: hata,
            ),
            onSubmitted: (_) => Navigator.pop(ctx, true),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ekle')),
          ],
        ),
      ),
    );

    if (ok != true || !mounted) return;
    final no = ctrl.text.trim();
    if (no.isEmpty) return;

    final api = ref.read(apiServiceProvider);
    try {
      await api.dio.post('/api/daire', data: {'blokId': blok.id, 'daireNo': no});
      if (!mounted) return;
      _snack('Daire $no eklendi.', Colors.green);
      _load();
    } on DioException catch (e) {
      _snack(ApiService.handleDioError(e).message, Colors.red);
    } catch (e) {
      _snack(e.toString(), Colors.red);
    }
  }

  Future<void> _daireSil(DaireModel daire, BlokModel blok) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Daireyi Sil'),
        content: Text('"Daire ${daire.daireNo}" silinecek. Emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final api = ref.read(apiServiceProvider);
    try {
      await api.dio.delete('/api/daire/${daire.id}');
      if (!mounted) return;
      setState(() {
        final idx = _bloklar.indexWhere((b) => b.id == blok.id);
        if (idx >= 0) {
          _bloklar[idx] = BlokModel(
            id: blok.id,
            ad: blok.ad,
            daireler: _bloklar[idx].daireler.where((d) => d.id != daire.id).toList(),
          );
        }
      });
      _snack('Daire ${daire.daireNo} silindi.', Colors.green);
    } on DioException catch (e) {
      _snack(ApiService.handleDioError(e).message, Colors.red);
    } catch (e) {
      _snack(e.toString(), Colors.red);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _load,
          child: _bloklar.isEmpty
              ? ListView(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.apartment_outlined,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            const Text('Henüz blok tanımlanmamış.',
                                style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _blokEkle,
                              icon: const Icon(Icons.add_home_outlined),
                              label: const Text('İlk Bloku Ekle'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: _bloklar.length,
                  itemBuilder: (ctx, i) {
                    final blok = _bloklar[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Colors.blue.withValues(alpha: 0.12),
                          child: Text(
                            blok.ad.isNotEmpty
                                ? blok.ad[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text('${blok.ad} Blok',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${blok.daireler.length} daire',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add,
                                  color: Colors.blue),
                              tooltip: 'Daire Ekle',
                              onPressed: () => _daireEkle(blok),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              tooltip: 'Bloğu Sil',
                              onPressed: () => _blokSil(blok),
                            ),
                          ],
                        ),
                        children: blok.daireler.isEmpty
                            ? [
                                const Padding(
                                  padding:
                                      EdgeInsets.symmetric(vertical: 12),
                                  child: Center(
                                    child: Text(
                                        'Henüz daire eklenmemiş.',
                                        style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13)),
                                  ),
                                ),
                              ]
                            : blok.daireler
                                .map((d) => ListTile(
                                      dense: true,
                                      leading: const Icon(
                                          Icons.door_front_door_outlined,
                                          size: 18,
                                          color: Colors.grey),
                                      title: Text('Daire ${d.daireNo}'),
                                      subtitle: d.sakin != null
                                          ? Row(
                                              children: [
                                                const Icon(
                                                    Icons.person,
                                                    size: 12,
                                                    color: Colors.blue),
                                                const SizedBox(width: 3),
                                                Expanded(
                                                  child: Text(
                                                    d.sakin!.adSoyad,
                                                    style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.blue),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : const Text(
                                              'Boş',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey,
                                                  fontStyle: FontStyle.italic),
                                            ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.close,
                                            size: 18, color: Colors.red),
                                        onPressed: () =>
                                            _daireSil(d, blok),
                                      ),
                                    ))
                                .toList(),
                      ),
                    );
                  },
                ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: _blokEkle,
            icon: const Icon(Icons.add_home_outlined),
            label: const Text('Blok Ekle'),
          ),
        ),
      ],
    );
  }
}
