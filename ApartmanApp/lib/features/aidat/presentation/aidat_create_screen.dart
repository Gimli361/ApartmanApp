import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/result.dart';
import '../domain/aidat_model.dart';
import '../../../features/auth/domain/user_model.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../shared/services/api_service.dart';
import 'providers/aidat_provider.dart';
import 'providers/otomatik_aidat_provider.dart';

class AidatCreateScreen extends ConsumerStatefulWidget {
  const AidatCreateScreen({super.key});

  @override
  ConsumerState<AidatCreateScreen> createState() => _AidatCreateScreenState();
}

class _AidatCreateScreenState extends ConsumerState<AidatCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tutarCtrl = TextEditingController();

  List<UserModel> _kullanicilar = [];
  bool _kullanicilarYukleniyor = true;

  UserModel? _seciliKullanici;
  int _ay = DateTime.now().month;
  int _yil = DateTime.now().year;
  bool _isSubmitting = false;
  bool _otomatikYenile = false;

  @override
  void initState() {
    super.initState();
    _fetchKullanicilar();
  }

  @override
  void dispose() {
    _tutarCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchKullanicilar() async {
    final api = ref.read(apiServiceProvider);
    try {
      final response = await api.dio.get('/api/kullanici');
      final List<dynamic> data = response.data['data'] as List<dynamic>;
      setState(() {
        _kullanicilar = data
            .cast<Map<String, dynamic>>()
            .map(UserModel.fromJson)
            .where((u) => u.rol == UserRole.sakin)
            .toList()
          ..sort((a, b) => a.daireNo.compareTo(b.daireNo));
        _kullanicilarYukleniyor = false;
      });
    } on DioException catch (e) {
      setState(() => _kullanicilarYukleniyor = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(ApiService.handleDioError(e).message),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _kaydet() async {
    if (!_formKey.currentState!.validate()) return;
    if (_seciliKullanici == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Lütfen bir sakin seçin.'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final tutar =
        double.parse(_tutarCtrl.text.trim().replaceAll(',', '.'));

    final result = await ref.read(aidatProvider.notifier).create(
          kullaniciId: _seciliKullanici!.id,
          tutar: tutar,
          ay: _ay,
          yil: _yil,
        );

    // Otomatik yenile açıksa kaydet/güncelle
    if (_otomatikYenile && result is Success) {
      await ref.read(otomatikAidatProvider.notifier).upsert(
            _seciliKullanici!.id,
            tutar,
          );
    }

    setState(() => _isSubmitting = false);

    if (!mounted) return;
    if (result is Success) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_otomatikYenile
                ? 'Aidat oluşturuldu ve otomatik yenileme açıldı.'
                : 'Aidat kaydı oluşturuldu.'),
            backgroundColor: Colors.green),
      );
    } else if (result is Failure<AidatModel, AppError>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(result.error.message),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Aidat Kaydı')),
      body: _kullanicilarYukleniyor
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sakin seçimi
                    DropdownButtonFormField<UserModel>(
                      value: _seciliKullanici,
                      decoration: const InputDecoration(
                        labelText: 'Sakin',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      hint: const Text('Sakin seçin'),
                      items: _kullanicilar
                          .map((u) => DropdownMenuItem(
                                value: u,
                                child: Text(
                                    'Daire ${u.daireNo} — ${u.adSoyad}'),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _seciliKullanici = v),
                      validator: (_) => _seciliKullanici == null
                          ? 'Sakin seçimi zorunludur.'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Tutar
                    TextFormField(
                      controller: _tutarCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Tutar (₺)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Tutar boş olamaz.';
                        }
                        final val = double.tryParse(
                            v.trim().replaceAll(',', '.'));
                        if (val == null || val <= 0) {
                          return 'Geçerli bir tutar girin.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Ay & Yıl
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _ay,
                            decoration: const InputDecoration(
                              labelText: 'Ay',
                              border: OutlineInputBorder(),
                            ),
                            items: List.generate(
                              12,
                              (i) => DropdownMenuItem(
                                value: i + 1,
                                child: Text(_ayAd(i + 1)),
                              ),
                            ),
                            onChanged: (v) =>
                                setState(() => _ay = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _yil,
                            decoration: const InputDecoration(
                              labelText: 'Yıl',
                              border: OutlineInputBorder(),
                            ),
                            items: List.generate(
                              5,
                              (i) => DropdownMenuItem(
                                value: DateTime.now().year - 1 + i,
                                child: Text(
                                    '${DateTime.now().year - 1 + i}'),
                              ),
                            ),
                            onChanged: (v) =>
                                setState(() => _yil = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Otomatik yenile toggle
                    Card(
                      margin: EdgeInsets.zero,
                      child: SwitchListTile(
                        value: _otomatikYenile,
                        onChanged: (v) =>
                            setState(() => _otomatikYenile = v),
                        secondary: Icon(
                          Icons.autorenew,
                          color: _otomatikYenile
                              ? Colors.green
                              : Colors.grey,
                        ),
                        title: const Text('Her ay otomatik yenile'),
                        subtitle: const Text(
                          'Her ayın başında bu sakin için otomatik aidat oluşturulur.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _kaydet,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white))
                            : const Text('Kaydet'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  static String _ayAd(int ay) => const [
        '',
        'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
      ][ay];
}
