import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../domain/oylama_model.dart';
import 'providers/oylama_provider.dart';

class OylamaDetailScreen extends ConsumerStatefulWidget {
  final int oylamaId;
  const OylamaDetailScreen({super.key, required this.oylamaId});

  @override
  ConsumerState<OylamaDetailScreen> createState() =>
      _OylamaDetailScreenState();
}

class _OylamaDetailScreenState extends ConsumerState<OylamaDetailScreen> {
  int? _selectedSecenekId;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(oylamaDetailProvider(widget.oylamaId).notifier)
          .load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(oylamaDetailProvider(widget.oylamaId));

    if (state.isLoading && state.oylama == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Oylama')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.oylama == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Oylama')),
        body: Center(
          child: Text(state.error ?? 'Oylama yüklenemedi.',
              style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    final oylama = state.oylama!;
    final fmt = DateFormat('dd.MM.yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(title: Text(oylama.baslik)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Durum banner
            _StatusBanner(oylama: oylama),
            const SizedBox(height: 16),

            // Açıklama
            if (oylama.aciklama != null && oylama.aciklama!.isNotEmpty) ...[
              Text(oylama.aciklama!,
                  style: TextStyle(color: Colors.grey[700], fontSize: 14)),
              const SizedBox(height: 12),
            ],

            // Meta bilgi
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'Bitiş: ${fmt.format(oylama.bitisTarihi.toLocal())}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Spacer(),
                Icon(Icons.how_to_vote_outlined,
                    size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text('${oylama.toplamOySayisi} toplam oy',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            const Divider(height: 24),

            // Seçenekler
            Text('Seçenekler',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            ...oylama.secenekler.map((s) => _SecenekTile(
                  secenek: s,
                  oylamaAcik: oylama.acikMi,
                  kullaniciOyKullandi: oylama.kullaniciOyKullandi,
                  kullaniciSecenekId: oylama.kullaniciSecenekId,
                  selectedId: _selectedSecenekId,
                  onSelect: oylama.acikMi && !oylama.kullaniciOyKullandi
                      ? (id) => setState(() => _selectedSecenekId = id)
                      : null,
                )),

            const SizedBox(height: 24),

            // Oy ver butonu
            if (oylama.acikMi && !oylama.kullaniciOyKullandi)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _selectedSecenekId == null
                      ? null
                      : () => _oyVer(oylama),
                  icon: state.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.how_to_vote),
                  label: const Text('Oy Ver'),
                ),
              ),

            // Oy geri al butonu
            if (oylama.acikMi && oylama.kullaniciOyKullandi)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: state.isLoading ? null : () => _oyGeriAl(),
                  icon: state.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.undo),
                  label: const Text('Oyumu Geri Al'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange[700]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _oyVer(OylamaDetailModel oylama) async {
    if (_selectedSecenekId == null) return;
    final notifier =
        ref.read(oylamaDetailProvider(widget.oylamaId).notifier);
    final err = await notifier.oyVer(_selectedSecenekId!);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
    } else {
      setState(() => _selectedSecenekId = null);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oyunuz kaydedildi.')));
    }
  }

  Future<void> _oyGeriAl() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Oy Geri Al'),
        content:
            const Text('Oyunuzu geri almak istediğinize emin misiniz?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Geri Al'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final notifier =
        ref.read(oylamaDetailProvider(widget.oylamaId).notifier);
    final err = await notifier.oyGeriAl();
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oyunuz geri alındı.')));
    }
  }
}

class _StatusBanner extends StatelessWidget {
  final OylamaDetailModel oylama;
  const _StatusBanner({required this.oylama});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    IconData icon;

    if (!oylama.aktifMi) {
      color = Colors.grey;
      text = 'Bu oylama pasif durumda';
      icon = Icons.pause_circle_outline;
    } else if (oylama.suresiDoldu) {
      color = Colors.orange;
      text = 'Bu oylamanın süresi doldu';
      icon = Icons.timer_off_outlined;
    } else if (oylama.kullaniciOyKullandi) {
      color = Colors.green;
      text = 'Oyunuzu kullandınız';
      icon = Icons.check_circle_outline;
    } else {
      color = Colors.blue;
      text = 'Oy kullanabilirsiniz';
      icon = Icons.how_to_vote_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(text,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

class _SecenekTile extends StatelessWidget {
  final OylamaSecenekModel secenek;
  final bool oylamaAcik;
  final bool kullaniciOyKullandi;
  final int? kullaniciSecenekId;
  final int? selectedId;
  final ValueChanged<int>? onSelect;

  const _SecenekTile({
    required this.secenek,
    required this.oylamaAcik,
    required this.kullaniciOyKullandi,
    required this.kullaniciSecenekId,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedId == secenek.id;
    final isVoted = kullaniciSecenekId == secenek.id;
    final showResults = kullaniciOyKullandi || !oylamaAcik;

    return GestureDetector(
      onTap: onSelect != null ? () => onSelect!(secenek.id) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.08)
              : isVoted
                  ? Colors.green.withValues(alpha: 0.06)
                  : null,
          border: Border.all(
            color: isSelected
                ? Colors.blue
                : isVoted
                    ? Colors.green
                    : Colors.grey.shade300,
            width: isSelected || isVoted ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (onSelect != null)
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected ? Colors.blue : Colors.grey,
                    size: 20,
                  )
                else if (isVoted)
                  const Icon(Icons.check_circle,
                      color: Colors.green, size: 20)
                else
                  const Icon(Icons.circle_outlined,
                      color: Colors.grey, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(secenek.metin,
                      style: TextStyle(
                          fontWeight: isVoted
                              ? FontWeight.bold
                              : FontWeight.normal)),
                ),
                if (showResults)
                  Text('${secenek.oySayisi} oy',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
              ],
            ),
            if (showResults) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: secenek.oranYuzde / 100,
                  backgroundColor: Colors.grey.shade200,
                  color: isVoted ? Colors.green : Colors.blue,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              Text('%${secenek.oranYuzde.toStringAsFixed(1)}',
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey)),
            ],
          ],
        ),
      ),
    );
  }
}
