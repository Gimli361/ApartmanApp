import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/result.dart';
import '../../../shared/models/blok_model.dart';
import '../../../shared/models/daire_model.dart';
import '../../../shared/services/api_service.dart';
import 'providers/auth_provider.dart';

class ProfilScreen extends ConsumerStatefulWidget {
  const ProfilScreen({super.key});

  @override
  ConsumerState<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends ConsumerState<ProfilScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Bilgilerim'),
            Tab(text: 'Şifre Değiştir'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _BilgilerTab(),
          _SifreTab(),
        ],
      ),
    );
  }
}

// ─── Bilgiler sekmesi ────────────────────────────────────────────────────────

class _BilgilerTab extends ConsumerStatefulWidget {
  const _BilgilerTab();

  @override
  ConsumerState<_BilgilerTab> createState() => _BilgilerTabState();
}

class _BilgilerTabState extends ConsumerState<_BilgilerTab> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _adCtrl;
  late final TextEditingController _soyadCtrl;
  final TextEditingController _daireCtrl = TextEditingController();
  BlokModel? _secilenBlok;
  DaireModel? _secilenDaire;
  List<BlokModel> _bloklar = [];
  bool _bloklarYukleniyor = true;
  bool _isLoading = false;

  List<DaireModel> get _mevcutDaireler => _secilenBlok?.daireler ?? [];

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    final parts = (user?.adSoyad ?? '').split(' ');
    _adCtrl = TextEditingController(text: parts.isNotEmpty ? parts.first : '');
    _soyadCtrl = TextEditingController(
        text: parts.length > 1 ? parts.sublist(1).join(' ') : '');
    _loadBloklar();
  }

  Future<void> _loadBloklar() async {
    final user = ref.read(authProvider).user;
    final api = ref.read(apiServiceProvider);
    try {
      final res = await api.dio.get('/api/blok');
      final data = (res.data['data'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(BlokModel.fromJson)
          .toList();
      if (mounted) {
        setState(() {
          _bloklar = data;
          _bloklarYukleniyor = false;
          final mevcutBlokAd = user?.blokNo;
          if (mevcutBlokAd != null && mevcutBlokAd.isNotEmpty) {
            _secilenBlok = data.where((b) => b.ad == mevcutBlokAd).firstOrNull;
            if (_secilenBlok != null) {
              _secilenDaire = _secilenBlok!.daireler
                  .where((d) => d.daireNo == (user?.daireNo ?? ''))
                  .firstOrNull;
              if (_secilenDaire == null) _daireCtrl.text = user?.daireNo ?? '';
            }
          } else {
            _daireCtrl.text = user?.daireNo ?? '';
          }
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _bloklarYukleniyor = false;
          _daireCtrl.text = user?.daireNo ?? '';
        });
        debugPrint('[BlokLoad] ${ApiService.handleDioError(e).message}');
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _bloklarYukleniyor = false;
          _daireCtrl.text = user?.daireNo ?? '';
        });
      }
    }
  }

  @override
  void dispose() {
    _adCtrl.dispose();
    _soyadCtrl.dispose();
    _daireCtrl.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final daireNoRaw = _secilenDaire?.daireNo ?? _daireCtrl.text.trim();
    final result = await ref.read(authProvider.notifier).updateProfile(
          ad: _adCtrl.text.trim(),
          soyad: _soyadCtrl.text.trim(),
          daireNo: daireNoRaw,
          blokNo: _secilenBlok?.ad,
        );

    setState(() => _isLoading = false);

    if (!mounted) return;
    if (result is Success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Bilgiler güncellendi.'),
            backgroundColor: Colors.green),
      );
    } else if (result is Failure<void, AppError>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(result.error.message),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 36,
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  user?.adSoyad.isNotEmpty == true
                      ? user!.adSoyad[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                user?.email ?? '',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _adCtrl,
              decoration: const InputDecoration(
                labelText: 'Ad',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Ad boş olamaz.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _soyadCtrl,
              decoration: const InputDecoration(
                labelText: 'Soyad',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Soyad boş olamaz.' : null,
            ),
            const SizedBox(height: 16),
            _bloklarYukleniyor
                ? const SizedBox(
                    height: 48,
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)))
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: DropdownButtonFormField<BlokModel?>(
                          value: _secilenBlok,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Blok',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<BlokModel?>(
                              value: null,
                              child: Text('— Seç —'),
                            ),
                            ..._bloklar.map((b) =>
                                DropdownMenuItem<BlokModel?>(
                                  value: b,
                                  child: Text('${b.ad} Blok'),
                                )),
                          ],
                          onChanged: (b) => setState(() {
                            _secilenBlok = b;
                            _secilenDaire = null;
                            _daireCtrl.clear();
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 4,
                        child: _mevcutDaireler.isNotEmpty
                            ? DropdownButtonFormField<DaireModel?>(
                                value: _secilenDaire,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Daire',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) => v == null && _daireCtrl.text.trim().isEmpty
                                    ? 'Daire seçiniz.'
                                    : null,
                                items: [
                                  const DropdownMenuItem<DaireModel?>(
                                    value: null,
                                    child: Text('— Seç —'),
                                  ),
                                  ..._mevcutDaireler.map((d) =>
                                      DropdownMenuItem<DaireModel?>(
                                        value: d,
                                        child: Text('Daire ${d.daireNo}'),
                                      )),
                                ],
                                onChanged: (d) =>
                                    setState(() => _secilenDaire = d),
                              )
                            : TextFormField(
                                controller: _daireCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Daire No',
                                  hintText: 'Örn: 3, 12',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Daire no boş olamaz.'
                                    : null,
                              ),
                      ),
                    ],
                  ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _kaydet,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Şifre sekmesi ───────────────────────────────────────────────────────────

class _SifreTab extends ConsumerStatefulWidget {
  const _SifreTab();

  @override
  ConsumerState<_SifreTab> createState() => _SifreTabState();
}

class _SifreTabState extends ConsumerState<_SifreTab> {
  final _formKey = GlobalKey<FormState>();
  final _eskiCtrl = TextEditingController();
  final _yeniCtrl = TextEditingController();
  final _tekrarCtrl = TextEditingController();
  bool _isLoading = false;
  bool _eskiGizli = true;
  bool _yeniGizli = true;

  @override
  void dispose() {
    _eskiCtrl.dispose();
    _yeniCtrl.dispose();
    _tekrarCtrl.dispose();
    super.dispose();
  }

  Future<void> _sifreDegistir() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result = await ref.read(authProvider.notifier).updateSifre(
          eskiSifre: _eskiCtrl.text,
          yeniSifre: _yeniCtrl.text,
        );

    setState(() => _isLoading = false);

    if (!mounted) return;
    if (result is Success) {
      _eskiCtrl.clear();
      _yeniCtrl.clear();
      _tekrarCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Şifre güncellendi.'),
            backgroundColor: Colors.green),
      );
    } else if (result is Failure<void, AppError>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(result.error.message),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _eskiCtrl,
              obscureText: _eskiGizli,
              decoration: InputDecoration(
                labelText: 'Mevcut Şifre',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                      _eskiGizli ? Icons.visibility_off : Icons.visibility),
                  onPressed: () =>
                      setState(() => _eskiGizli = !_eskiGizli),
                ),
              ),
              validator: (v) => v == null || v.isEmpty
                  ? 'Mevcut şifre boş olamaz.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _yeniCtrl,
              obscureText: _yeniGizli,
              decoration: InputDecoration(
                labelText: 'Yeni Şifre',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                      _yeniGizli ? Icons.visibility_off : Icons.visibility),
                  onPressed: () =>
                      setState(() => _yeniGizli = !_yeniGizli),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Yeni şifre boş olamaz.';
                if (v.length < 6) return 'En az 6 karakter olmalıdır.';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tekrarCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Yeni Şifre (Tekrar)',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v != _yeniCtrl.text
                  ? 'Şifreler eşleşmiyor.'
                  : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _sifreDegistir,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Şifreyi Değiştir'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
