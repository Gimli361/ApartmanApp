import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../domain/ariza_model.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/bildirim/presentation/providers/bildirim_provider.dart';
import 'providers/ariza_provider.dart';

class ArizaCreateScreen extends ConsumerStatefulWidget {
  const ArizaCreateScreen({super.key});

  @override
  ConsumerState<ArizaCreateScreen> createState() => _ArizaCreateScreenState();
}

class _ArizaCreateScreenState extends ConsumerState<ArizaCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _baslikCtrl = TextEditingController();
  final _aciklamaCtrl = TextEditingController();
  ArizaOncelik _oncelik = ArizaOncelik.orta;
  bool _ortakAlan = false;
  File? _foto;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _baslikCtrl.dispose();
    _aciklamaCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked =
        await ImagePicker().pickImage(source: source, imageQuality: 75);
    if (picked != null) {
      setState(() => _foto = File(picked.path));
    }
  }

  void _showImageSourceSheet() {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.camera_alt, color: cs.primary),
                ),
                title: Text('Kamera', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.photo_library, color: cs.secondary),
                ),
                title: Text('Galeriden Seç', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authProvider).user;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    final (arizaOlustu, fotoYuklendi) =
        await ref.read(arizaListProvider.notifier).create(
              baslik: _baslikCtrl.text.trim(),
              aciklama: _aciklamaCtrl.text.trim(),
              oncelik: _oncelik,
              bildirenId: user.id,
              ortakAlan: _ortakAlan,
              foto: _foto,
            );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (arizaOlustu) {
      ref.read(bildirimProvider.notifier).load();
      if (!fotoYuklendi && _foto != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Arıza bildirildi, ancak fotoğraf yüklenemedi. Daha sonra tekrar deneyin.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Arıza başarıyla bildirildi.'),
            backgroundColor: Colors.green,
          ),
        );
      }
      context.pop();
    } else {
      final err =
          ref.read(arizaListProvider).errorMessage ?? 'Arıza bildirilemedi. Lütfen tekrar deneyin.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text('Arıza Bildir', style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sayfa başlığı
              Text(
                'Yeni Talep',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bakım sorunu veya hizmet talebi bildirin.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // Konum seçimi
              _sectionLabel('KONUM', cs),
              const SizedBox(height: 8),
              _KonumSecici(
                ortakAlan: _ortakAlan,
                onChanged: (val) => setState(() => _ortakAlan = val),
              ),
              const SizedBox(height: 20),

              // Başlık
              _sectionLabel('BAŞLIK', cs),
              const SizedBox(height: 8),
              TextFormField(
                controller: _baslikCtrl,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'Arızayı kısaca tanımlayın',
                  prefixIcon: Icon(Icons.title, color: cs.outline),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Başlık boş olamaz.' : null,
              ),
              const SizedBox(height: 20),

              // Açıklama
              _sectionLabel('AÇIKLAMA', cs),
              const SizedBox(height: 8),
              TextFormField(
                controller: _aciklamaCtrl,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Arızayı detaylı şekilde açıklayın...',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 60),
                    child: Icon(Icons.description_outlined, color: cs.outline),
                  ),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Açıklama boş olamaz.'
                    : null,
              ),
              const SizedBox(height: 20),

              // Öncelik seçimi
              _sectionLabel('ÖNCELİK', cs),
              const SizedBox(height: 8),
              Row(
                children: ArizaOncelik.values.map((o) {
                  final selected = _oncelik == o;
                  final color = _oncelikColor(o);
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: o != ArizaOncelik.values.last ? 8 : 0),
                      child: GestureDetector(
                        onTap: () => setState(() => _oncelik = o),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: selected
                                ? color.withOpacity(isDark ? 0.2 : 0.1)
                                : (isDark
                                    ? cs.surfaceContainerHigh
                                    : cs.surfaceContainerLow),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? color.withOpacity(0.5)
                                  : (isDark
                                      ? cs.outlineVariant
                                      : const Color(0xFFE0E0E0)),
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _oncelikIcon(o),
                                color: selected ? color : cs.onSurfaceVariant,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                o.label,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: selected ? color : cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Fotoğraf seçimi
              _sectionLabel('FOTOĞRAF', cs),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showImageSourceSheet,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark ? cs.outlineVariant : const Color(0xFFD0D0D0),
                      width: _foto != null ? 0 : 2,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    color: isDark
                        ? cs.surfaceContainerHigh
                        : cs.surfaceContainerLow,
                  ),
                  child: _foto != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(_foto!, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() => _foto = null),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: cs.error.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                size: 36, color: cs.onSurfaceVariant),
                            const SizedBox(height: 8),
                            Text(
                              'Fotoğraf ekle',
                              style: GoogleFonts.inter(
                                color: cs.onSurfaceVariant,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 32),

              // Gönder butonu
              Container(
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
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send),
                  label: Text(_isSubmitting ? 'Gönderiliyor...' : 'Bildir'),
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

  Color _oncelikColor(ArizaOncelik o) => switch (o) {
        ArizaOncelik.dusuk => Colors.green,
        ArizaOncelik.orta => Colors.orange,
        ArizaOncelik.yuksek => Colors.red,
        ArizaOncelik.kritik => const Color(0xFFD32F2F),
      };

  IconData _oncelikIcon(ArizaOncelik o) => switch (o) {
        ArizaOncelik.dusuk => Icons.arrow_downward,
        ArizaOncelik.orta => Icons.remove,
        ArizaOncelik.yuksek => Icons.arrow_upward,
        ArizaOncelik.kritik => Icons.priority_high,
      };
}

// ─── Konum seçici: Bloğum / Ortak Alan ───────────────────────────────────────

class _KonumSecici extends StatelessWidget {
  final bool ortakAlan;
  final ValueChanged<bool> onChanged;

  const _KonumSecici({required this.ortakAlan, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _KonumTile(
            icon: Icons.apartment,
            label: 'Bloğum',
            subtitle: 'Dairemi veya bloğumu etkiliyor',
            selected: !ortakAlan,
            onTap: () => onChanged(false),
            color: cs.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KonumTile(
            icon: Icons.location_city,
            label: 'Ortak Alan',
            subtitle: 'Havuz, otopark, bahçe vb.',
            selected: ortakAlan,
            onTap: () => onChanged(true),
            color: cs.secondary,
          ),
        ),
      ],
    );
  }
}

class _KonumTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _KonumTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(isDark ? 0.15 : 0.08)
              : (isDark ? cs.surfaceContainerHigh : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? color.withOpacity(0.5)
                : (isDark ? cs.outlineVariant : const Color(0xFFE0E0E0)),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected
                    ? color.withOpacity(0.15)
                    : cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  size: 20,
                  color: selected ? color : cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: selected ? color : cs.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
