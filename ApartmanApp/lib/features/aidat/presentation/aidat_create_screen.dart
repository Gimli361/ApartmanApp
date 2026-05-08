import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
          title: Text('Yeni Aidat Kaydı',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
      body: _kullanicilarYukleniyor
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aidat Kaydı',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sakin için aylık aidat oluşturun.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sakin seçimi
                    _sectionLabel('SAKİN', cs),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<UserModel>(
                      value: _seciliKullanici,
                      decoration: InputDecoration(
                        hintText: 'Sakin seçin',
                        prefixIcon:
                            Icon(Icons.person_outline, color: cs.outline),
                      ),
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
                    const SizedBox(height: 20),

                    // Tutar
                    _sectionLabel('TUTAR', cs),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _tutarCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        prefixIcon:
                            Icon(Icons.payments_outlined, color: cs.outline),
                        prefixText: '₺ ',
                        prefixStyle: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
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
                    const SizedBox(height: 20),

                    // Ay & Yıl
                    _sectionLabel('DÖNEM', cs),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _ay,
                            decoration: InputDecoration(
                              labelText: 'Ay',
                              prefixIcon: Icon(Icons.calendar_month_outlined,
                                  color: cs.outline),
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
                            decoration: InputDecoration(
                              labelText: 'Yıl',
                              prefixIcon: Icon(Icons.date_range_outlined,
                                  color: cs.outline),
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
                    const SizedBox(height: 20),

                    // Otomatik yenile toggle
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? cs.surfaceContainerHigh
                            : cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _otomatikYenile
                              ? Colors.green.withOpacity(0.3)
                              : (isDark
                                  ? cs.outlineVariant
                                  : const Color(0xFFE0E0E0)),
                        ),
                      ),
                      child: SwitchListTile(
                        value: _otomatikYenile,
                        onChanged: (v) =>
                            setState(() => _otomatikYenile = v),
                        activeColor: Colors.green,
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (_otomatikYenile
                                    ? Colors.green
                                    : Colors.grey)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.autorenew,
                            color: _otomatikYenile
                                ? Colors.green
                                : cs.outline,
                            size: 22,
                          ),
                        ),
                        title: Text('Her ay otomatik yenile',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        subtitle: Text(
                          'Her ayın başında bu sakin için otomatik aidat oluşturulur.',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: cs.onSurfaceVariant),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary
                                .withOpacity(isDark ? 0.3 : 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: FilledButton.icon(
                        onPressed: _isSubmitting ? null : _kaydet,
                        icon: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white))
                            : const Icon(Icons.save_outlined),
                        label: const Text('Kaydet'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionLabel(String text, ColorScheme cs) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: cs.outline,
        letterSpacing: 1.2,
      ),
    );
  }

  static String _ayAd(int ay) => const [
        '',
        'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
      ][ay];
}
