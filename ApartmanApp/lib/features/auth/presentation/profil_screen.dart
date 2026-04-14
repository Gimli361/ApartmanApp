import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/result.dart';
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
  late final TextEditingController _daireCtrl;
  late final TextEditingController _blokCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    final parts = (user?.adSoyad ?? '').split(' ');
    _adCtrl = TextEditingController(text: parts.isNotEmpty ? parts.first : '');
    _soyadCtrl = TextEditingController(
        text: parts.length > 1 ? parts.sublist(1).join(' ') : '');
    _daireCtrl = TextEditingController(text: user?.daireNo ?? '');
    _blokCtrl = TextEditingController(text: user?.blokNo ?? '');
  }

  @override
  void dispose() {
    _adCtrl.dispose();
    _soyadCtrl.dispose();
    _daireCtrl.dispose();
    _blokCtrl.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final blokNoVal = _blokCtrl.text.trim();
    final result = await ref.read(authProvider.notifier).updateProfile(
          ad: _adCtrl.text.trim(),
          soyad: _soyadCtrl.text.trim(),
          daireNo: _daireCtrl.text.trim(),
          blokNo: blokNoVal.isEmpty ? null : blokNoVal,
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
            TextFormField(
              controller: _daireCtrl,
              decoration: const InputDecoration(
                labelText: 'Daire No',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Daire no boş olamaz.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _blokCtrl,
              decoration: const InputDecoration(
                labelText: 'Blok No (ör: A, B, 1)',
                border: OutlineInputBorder(),
                helperText: 'Aynı bloktaki arızaları takip etmek için doldurun.',
              ),
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
