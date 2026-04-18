import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Oylama')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık
              TextFormField(
                controller: _baslikCtrl,
                decoration: const InputDecoration(
                  labelText: 'Başlık *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Başlık zorunludur'
                    : null,
              ),
              const SizedBox(height: 16),

              // Açıklama
              TextFormField(
                controller: _aciklamaCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Açıklama (opsiyonel)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Bitiş tarihi
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Bitiş Tarihi *',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(fmt.format(_bitisTarihi)),
                ),
              ),
              const SizedBox(height: 24),

              // Seçenekler
              Row(
                children: [
                  Text('Seçenekler',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
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
                      Expanded(
                        child: TextFormField(
                          controller: _secenekCtrls[i],
                          decoration: InputDecoration(
                            labelText: 'Seçenek ${i + 1}',
                            border: const OutlineInputBorder(),
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
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.red),
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

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
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
