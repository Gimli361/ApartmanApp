import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeriden Seç'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
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
          ref.read(arizaListProvider).errorMessage ?? 'Bir hata oluştu.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arıza Bildir')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Başlık
              TextFormField(
                controller: _baslikCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Başlık',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Başlık boş olamaz.' : null,
              ),
              const SizedBox(height: 16),

              // Açıklama
              TextFormField(
                controller: _aciklamaCtrl,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  prefixIcon: Icon(Icons.description_outlined),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Açıklama boş olamaz.'
                    : null,
              ),
              const SizedBox(height: 16),

              // Öncelik seçimi
              Text('Öncelik',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ArizaOncelik.values.map((o) {
                  final selected = _oncelik == o;
                  return ChoiceChip(
                    label: Text(o.label),
                    selected: selected,
                    onSelected: (_) => setState(() => _oncelik = o),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Fotoğraf seçimi
              Text('Fotoğraf (İsteğe Bağlı)',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              InkWell(
                onTap: _showImageSourceSheet,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[50],
                  ),
                  child: _foto != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Image.file(_foto!, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: GestureDetector(
                                onTap: () => setState(() => _foto = null),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
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
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 40, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text('Fotoğraf ekle',
                                style: TextStyle(color: Colors.grey[500])),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 28),

              // Gönder butonu
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50)),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Bildir'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
