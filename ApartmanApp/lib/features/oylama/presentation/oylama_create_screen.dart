import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/result.dart';
import '../domain/oylama_model.dart';
import 'providers/oylama_provider.dart';

class OylamaCreateScreen extends ConsumerStatefulWidget {
  const OylamaCreateScreen({super.key});

  @override
  ConsumerState<OylamaCreateScreen> createState() =>
      _OylamaCreateScreenState();
}

class _OylamaCreateScreenState extends ConsumerState<OylamaCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _baslikCtrl = TextEditingController();
  final _aciklamaCtrl = TextEditingController();
  final List<TextEditingController> _secenekCtrls = [
    TextEditingController(),
    TextEditingController(),
  ];
  DateTime _bitisTarihi = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;

  @override
  void dispose() {
    _baslikCtrl.dispose();
    _aciklamaCtrl.dispose();
    for (final c in _secenekCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd.MM.yyyy HH:mm');
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
          title: Text('Yeni Oylama',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Oylama Oluştur',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sakinler için yeni bir oylama başlatın.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // Başlık
              _sectionLabel('BAŞLIK', cs),
              const SizedBox(height: 8),
              TextFormField(
                controller: _baslikCtrl,
                decoration: InputDecoration(
                  hintText: 'Oylama başlığını girin',
                  prefixIcon: Icon(Icons.title, color: cs.outline),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Başlık zorunludur'
                    : null,
              ),
              const SizedBox(height: 20),

              // Açıklama
              _sectionLabel('AÇIKLAMA', cs),
              const SizedBox(height: 8),
              TextFormField(
                controller: _aciklamaCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Açıklama girin (opsiyonel)',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.description_outlined, color: cs.outline),
                  ),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),

              // Bitiş tarihi
              _sectionLabel('BİTİŞ TARİHİ', cs),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark ? cs.surfaceContainer : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 20, color: cs.outline),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          fmt.format(_bitisTarihi),
                          style: GoogleFonts.inter(
                              fontSize: 14, color: cs.onSurface),
                        ),
                      ),
                      Icon(Icons.edit_outlined, size: 18, color: cs.outline),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Seçenekler
              Row(
                children: [
                  Text('SEÇENEKLER',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.outline,
                        letterSpacing: 1.2,
                      )),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _secenekCtrls.length >= 8
                        ? null
                        : () {
                            setState(() {
                              _secenekCtrls.add(TextEditingController());
                            });
                          },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ekle'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ...List.generate(_secenekCtrls.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.primary.withOpacity(0.1),
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: cs.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _secenekCtrls[i],
                          decoration: InputDecoration(
                            hintText: 'Seçenek ${i + 1}',
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Seçenek boş olamaz'
                                  : null,
                        ),
                      ),
                      if (_secenekCtrls.length > 2) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline,
                              color: cs.error, size: 22),
                          onPressed: () {
                            setState(() {
                              _secenekCtrls[i].dispose();
                              _secenekCtrls.removeAt(i);
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                );
              }),

              const SizedBox(height: 32),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withOpacity(isDark ? 0.3 : 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check),
                  label: const Text('Oluştur'),
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _bitisTarihi,
      firstDate: now.add(const Duration(hours: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_bitisTarihi),
    );
    if (time == null) return;

    setState(() {
      _bitisTarihi = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final secenekler = _secenekCtrls
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (secenekler.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('En az 2 seçenek giriniz.')));
      return;
    }

    if (_bitisTarihi.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Bitiş tarihi gelecekte olmalıdır.')));
      return;
    }

    setState(() => _isLoading = true);

    final result = await ref.read(oylamaRepositoryProvider).create(
          baslik: _baslikCtrl.text.trim(),
          aciklama: _aciklamaCtrl.text.trim().isEmpty
              ? null
              : _aciklamaCtrl.text.trim(),
          bitisTarihi: _bitisTarihi,
          secenekler: secenekler,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result is Success<OylamaDetailModel, AppError>) {
      context.pop(true);
    } else if (result is Failure<OylamaDetailModel, AppError>) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error.message)));
    }
  }
}
