import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/domain/user_model.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../shared/models/blok_model.dart';
import '../../../shared/models/daire_model.dart';
import '../../../shared/services/api_service.dart';
import 'providers/kullanici_provider.dart';

class KullaniciListScreen extends ConsumerWidget {
  const KullaniciListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(kullaniciListProvider);

    return Scaffold(
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.kullanicilar.isEmpty
              ? _EmptyState(
                  onAdd: () => _showEkleSheet(context, ref),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(kullaniciListProvider.notifier).load(),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: state.kullanicilar.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final k = state.kullanicilar[i];
                      return _KullaniciTile(
                        kullanici: k,
                        onDelete: () => _confirmDelete(context, ref, k),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEkleSheet(context, ref),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Üye Ekle'),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, UserModel k) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Üyeyi Sil'),
        content: Text('"${k.adSoyad}" adlı üyeyi silmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final ok = await ref.read(kullaniciListProvider.notifier).delete(k.id);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? '${k.adSoyad} silindi.' : 'Silme başarısız.'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  void _showEkleSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EkleSheet(ref: ref),
    );
  }
}

// ─── Boş Durum ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 12),
          const Text('Henüz üye kaydı yok.',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('İlk Üyeyi Ekle'),
          ),
        ],
      ),
    );
  }
}

// ─── Kullanıcı Satırı ─────────────────────────────────────────────────────────

class _KullaniciTile extends ConsumerWidget {
  final UserModel kullanici;
  final VoidCallback onDelete;

  const _KullaniciTile({required this.kullanici, required this.onDelete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = kullanici.rol == UserRole.admin;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            (isAdmin ? Colors.red : Colors.blue).withValues(alpha: 0.12),
        child: Text(
          kullanici.adSoyad.isNotEmpty
              ? kullanici.adSoyad[0].toUpperCase()
              : '?',
          style: TextStyle(
            color: isAdmin ? Colors.red[700] : Colors.blue[700],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(kullanici.adSoyad,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(kullanici.email,
          style: const TextStyle(fontSize: 12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (isAdmin ? Colors.red : Colors.blue)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isAdmin ? 'Yönetici' : 'Sakin',
                  style: TextStyle(
                    fontSize: 11,
                    color: isAdmin ? Colors.red[700] : Colors.blue[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (kullanici.daireNo.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Daire ${kullanici.daireNo}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ],
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
            onPressed: () => _showDuzenleSheet(context, ref),
            tooltip: 'Düzenle',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: onDelete,
            tooltip: 'Sil',
          ),
        ],
      ),
    );
  }

  void _showDuzenleSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _DuzenleSheet(kullanici: kullanici, ref: ref),
    );
  }
}

// ─── Üye Ekle Alt Sayfası ─────────────────────────────────────────────────────

class _EkleSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _EkleSheet({required this.ref});

  @override
  ConsumerState<_EkleSheet> createState() => _EkleSheetState();
}

class _EkleSheetState extends ConsumerState<_EkleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _adCtrl = TextEditingController();
  final _soyadCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _sifreCtrl = TextEditingController();
  final _daireNoCtrl = TextEditingController();

  BlokModel? _secilenBlok;
  DaireModel? _secilenDaire;
  List<BlokModel> _bloklar = [];
  bool _bloklarYukleniyor = true;

  String _rol = 'Sakin';
  bool _sifreGoster = false;
  bool _isSubmitting = false;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _loadBloklar();
  }

  Future<void> _loadBloklar() async {
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
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() => _bloklarYukleniyor = false);
        debugPrint('[BlokLoad] ${ApiService.handleDioError(e).message}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _bloklarYukleniyor = false);
        debugPrint('[BlokLoad] $e');
      }
    }
  }

  List<DaireModel> get _mevcutDaireler => _secilenBlok?.daireler ?? [];

  @override
  void dispose() {
    _adCtrl.dispose();
    _soyadCtrl.dispose();
    _emailCtrl.dispose();
    _sifreCtrl.dispose();
    _daireNoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _hata = null;
    });

    final blokNo = _secilenBlok?.ad;
    final daireNoRaw = _secilenDaire?.daireNo ?? _daireNoCtrl.text.trim();
    final daireNo = daireNoRaw.isEmpty ? null : daireNoRaw;

    final ok = await widget.ref.read(kullaniciListProvider.notifier).create(
          ad: _adCtrl.text.trim(),
          soyad: _soyadCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          sifre: _sifreCtrl.text,
          rol: _rol,
          daireNo: daireNo,
          blokNo: blokNo,
        );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Üye başarıyla eklendi.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() {
        _hata = widget.ref.read(kullaniciListProvider).errorMessage ??
            'Bir hata oluştu.';
      });
    }
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
            // Başlık
            Row(
              children: [
                const Icon(Icons.person_add_outlined),
                const SizedBox(width: 10),
                const Text('Yeni Üye Ekle',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Ad / Soyad
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _adCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Ad *',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Zorunlu' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _soyadCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Soyad *',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Zorunlu' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // E-posta
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'E-posta *',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'E-posta zorunludur.';
                if (!v.contains('@')) return 'Geçerli bir e-posta girin.';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Şifre
            TextFormField(
              controller: _sifreCtrl,
              obscureText: !_sifreGoster,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Şifre *',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: IconButton(
                  icon: Icon(_sifreGoster
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () =>
                      setState(() => _sifreGoster = !_sifreGoster),
                ),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Şifre zorunludur.' : null,
            ),
            const SizedBox(height: 12),

            // Blok + Daire No
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Blok dropdown
                Expanded(
                  flex: 5,
                  child: _bloklarYukleniyor
                      ? const SizedBox(
                          height: 48,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : DropdownButtonFormField<BlokModel?>(
                          value: _secilenBlok,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Blok',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem<BlokModel?>(
                              value: null,
                              child: Text('— Seç —'),
                            ),
                            ..._bloklar.map(
                              (b) => DropdownMenuItem<BlokModel?>(
                                value: b,
                                child: Text('${b.ad} Blok'),
                              ),
                            ),
                          ],
                          onChanged: (b) => setState(() {
                            _secilenBlok = b;
                            _secilenDaire = null;
                            _daireNoCtrl.clear();
                          }),
                        ),
                ),
                const SizedBox(width: 10),
                // Daire: tanımlı varsa dropdown, yoksa serbest metin
                Expanded(
                  flex: 4,
                  child: _mevcutDaireler.isNotEmpty
                      ? DropdownButtonFormField<DaireModel?>(
                          value: _secilenDaire,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Daire',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem<DaireModel?>(
                              value: null,
                              child: Text('— Seç —'),
                            ),
                            ..._mevcutDaireler.map(
                              (d) => DropdownMenuItem<DaireModel?>(
                                value: d,
                                child: Text('Daire ${d.daireNo}'),
                              ),
                            ),
                          ],
                          onChanged: (d) =>
                              setState(() => _secilenDaire = d),
                        )
                      : TextFormField(
                          controller: _daireNoCtrl,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Daire No',
                            hintText: 'Örn: 3, 12',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Rol
            DropdownButtonFormField<String>(
              value: _rol,
              decoration: const InputDecoration(
                labelText: 'Rol *',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'Sakin', child: Text('Sakin')),
                DropdownMenuItem(value: 'Admin', child: Text('Yönetici')),
              ],
              onChanged: (v) => setState(() => _rol = v ?? 'Sakin'),
            ),

            // Hata mesajı
            if (_hata != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(
                  _hata!,
                  style: TextStyle(color: Colors.red[700], fontSize: 13),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Kaydet butonu
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Üye Düzenle / Şifre Sıfırla Sheet ───────────────────────────────────────

class _DuzenleSheet extends ConsumerStatefulWidget {
  final UserModel kullanici;
  final WidgetRef ref;

  const _DuzenleSheet({required this.kullanici, required this.ref});

  @override
  ConsumerState<_DuzenleSheet> createState() => _DuzenleSheetState();
}

class _DuzenleSheetState extends ConsumerState<_DuzenleSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  // Bilgi sekmesi
  late final TextEditingController _adCtrl;
  late final TextEditingController _soyadCtrl;
  final TextEditingController _daireNoCtrl = TextEditingController();
  BlokModel? _secilenBlok;
  DaireModel? _secilenDaire;
  List<BlokModel> _bloklar = [];
  bool _bloklarYukleniyor = true;
  bool _bilgiLoading = false;
  String? _bilgiHata;

  // Şifre sekmesi
  final _yeniSifreCtrl = TextEditingController();
  final _yeniSifreTekrarCtrl = TextEditingController();
  bool _sifreGoster = false;
  bool _sifreLoading = false;
  String? _sifreHata;

  List<DaireModel> get _mevcutDaireler => _secilenBlok?.daireler ?? [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    final parts = widget.kullanici.adSoyad.trim().split(' ');
    _adCtrl = TextEditingController(text: parts.first);
    _soyadCtrl = TextEditingController(
        text: parts.length > 1 ? parts.sublist(1).join(' ') : '');
    _loadBloklar();
  }

  Future<void> _loadBloklar() async {
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
          // Mevcut blok/daireyi ön seç
          final mevcutBlokAd = widget.kullanici.blokNo;
          if (mevcutBlokAd != null && mevcutBlokAd.isNotEmpty) {
            _secilenBlok = data.where((b) => b.ad == mevcutBlokAd).firstOrNull;
            if (_secilenBlok != null) {
              _secilenDaire = _secilenBlok!.daireler
                  .where((d) => d.daireNo == widget.kullanici.daireNo)
                  .firstOrNull;
              if (_secilenDaire == null) {
                _daireNoCtrl.text = widget.kullanici.daireNo;
              }
            }
          } else {
            _daireNoCtrl.text = widget.kullanici.daireNo;
          }
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _bloklarYukleniyor = false;
          _daireNoCtrl.text = widget.kullanici.daireNo;
        });
        debugPrint('[BlokLoad] ${ApiService.handleDioError(e).message}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _bloklarYukleniyor = false;
          _daireNoCtrl.text = widget.kullanici.daireNo;
        });
      }
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    _adCtrl.dispose();
    _soyadCtrl.dispose();
    _daireNoCtrl.dispose();
    _yeniSifreCtrl.dispose();
    _yeniSifreTekrarCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Başlık
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.withValues(alpha: 0.12),
                  child: Text(
                    widget.kullanici.adSoyad.isNotEmpty
                        ? widget.kullanici.adSoyad[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.kullanici.adSoyad,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(widget.kullanici.email,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          TabBar(
            controller: _tab,
            tabs: const [
              Tab(icon: Icon(Icons.person_outline, size: 18), text: 'Bilgiler'),
              Tab(icon: Icon(Icons.lock_outline, size: 18), text: 'Şifre'),
            ],
          ),
          // Tab içeriği — sabit yükseklik (klavye açıksa scroll oluyor)
          SizedBox(
            height: 320,
            child: TabBarView(
              controller: _tab,
              children: [
                _buildBilgiTab(),
                _buildSifreTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBilgiTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _adCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                      labelText: 'Ad *',
                      border: OutlineInputBorder(),
                      isDense: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _soyadCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                      labelText: 'Soyad *',
                      border: OutlineInputBorder(),
                      isDense: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Blok + Daire seçimi
          _bloklarYukleniyor
              ? const SizedBox(
                  height: 48,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
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
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<BlokModel?>(
                            value: null,
                            child: Text('— Seç —'),
                          ),
                          ..._bloklar.map((b) => DropdownMenuItem<BlokModel?>(
                                value: b,
                                child: Text('${b.ad} Blok'),
                              )),
                        ],
                        onChanged: (b) => setState(() {
                          _secilenBlok = b;
                          _secilenDaire = null;
                          _daireNoCtrl.clear();
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 4,
                      child: _mevcutDaireler.isNotEmpty
                          ? DropdownButtonFormField<DaireModel?>(
                              value: _secilenDaire,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Daire',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: [
                                const DropdownMenuItem<DaireModel?>(
                                  value: null,
                                  child: Text('— Seç —'),
                                ),
                                ..._mevcutDaireler.map(
                                  (d) => DropdownMenuItem<DaireModel?>(
                                    value: d,
                                    child: Text('Daire ${d.daireNo}'),
                                  ),
                                ),
                              ],
                              onChanged: (d) =>
                                  setState(() => _secilenDaire = d),
                            )
                          : TextFormField(
                              controller: _daireNoCtrl,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                labelText: 'Daire No',
                                hintText: 'Örn: 3, 12',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                    ),
                  ],
                ),
          if (_bilgiHata != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!)),
              child: Text(_bilgiHata!,
                  style: TextStyle(color: Colors.red[700], fontSize: 12)),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _bilgiLoading ? null : _saveBilgi,
            icon: _bilgiLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check, size: 18),
            label: const Text('Güncelle'),
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44)),
          ),
        ],
      ),
    );
  }

  Widget _buildSifreTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        children: [
          TextFormField(
            controller: _yeniSifreCtrl,
            obscureText: !_sifreGoster,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Yeni Şifre *',
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: IconButton(
                icon: Icon(_sifreGoster
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () =>
                    setState(() => _sifreGoster = !_sifreGoster),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _yeniSifreTekrarCtrl,
            obscureText: !_sifreGoster,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
                labelText: 'Şifre Tekrar *',
                border: OutlineInputBorder(),
                isDense: true),
          ),
          if (_sifreHata != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!)),
              child: Text(_sifreHata!,
                  style: TextStyle(color: Colors.red[700], fontSize: 12)),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _sifreLoading ? null : _saveSifre,
            icon: _sifreLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.lock_reset, size: 18),
            label: const Text('Şifreyi Sıfırla'),
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBilgi() async {
    final ad = _adCtrl.text.trim();
    final soyad = _soyadCtrl.text.trim();
    if (ad.isEmpty || soyad.isEmpty) {
      setState(() => _bilgiHata = 'Ad ve soyad zorunludur.');
      return;
    }
    setState(() {
      _bilgiLoading = true;
      _bilgiHata = null;
    });
    final daireNoRaw = _secilenDaire?.daireNo ?? _daireNoCtrl.text.trim();
    final err = await widget.ref.read(kullaniciListProvider.notifier).update(
          id: widget.kullanici.id,
          ad: ad,
          soyad: soyad,
          daireNo: daireNoRaw.isEmpty ? null : daireNoRaw,
          blokNo: _secilenBlok?.ad,
        );
    if (!mounted) return;
    setState(() => _bilgiLoading = false);
    if (err != null) {
      setState(() => _bilgiHata = err);
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Bilgiler güncellendi.'),
            backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _saveSifre() async {
    final yeni = _yeniSifreCtrl.text;
    final tekrar = _yeniSifreTekrarCtrl.text;
    if (yeni.isEmpty) {
      setState(() => _sifreHata = 'Yeni şifre zorunludur.');
      return;
    }
    if (yeni != tekrar) {
      setState(() => _sifreHata = 'Şifreler eşleşmiyor.');
      return;
    }
    setState(() {
      _sifreLoading = true;
      _sifreHata = null;
    });
    final err = await widget.ref.read(kullaniciListProvider.notifier).resetSifre(
          id: widget.kullanici.id,
          yeniSifre: yeni,
        );
    if (!mounted) return;
    setState(() => _sifreLoading = false);
    if (err != null) {
      setState(() => _sifreHata = err);
    } else {
      _yeniSifreCtrl.clear();
      _yeniSifreTekrarCtrl.clear();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Şifre başarıyla sıfırlandı.'),
            backgroundColor: Colors.green),
      );
    }
  }
}
