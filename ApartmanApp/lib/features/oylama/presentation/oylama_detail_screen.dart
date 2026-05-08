import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.isLoading && state.oylama == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Oylama',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
        body: Center(child: CircularProgressIndicator(color: cs.primary)),
      );
    }

    if (state.oylama == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Oylama',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
        body: Center(
          child: Text(state.error ?? 'Oylama yüklenemedi.',
              style: GoogleFonts.inter(color: cs.error)),
        ),
      );
    }

    final oylama = state.oylama!;
    final fmt = DateFormat('dd.MM.yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
          title: Text(oylama.baslik,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Durum banner
            _StatusBanner(oylama: oylama),
            const SizedBox(height: 20),

            // Açıklama
            if (oylama.aciklama != null && oylama.aciklama!.isNotEmpty) ...[
              Text(oylama.aciklama!,
                  style: GoogleFonts.inter(
                      color: cs.onSurfaceVariant, fontSize: 14, height: 1.5)),
              const SizedBox(height: 16),
            ],

            // Meta bilgi
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? cs.surfaceContainerHigh : cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : const Color(0xFFE8E8E8),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: cs.outline),
                  const SizedBox(width: 6),
                  Text(
                    'Bitiş: ${fmt.format(oylama.bitisTarihi.toLocal())}',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                  const Spacer(),
                  Icon(Icons.how_to_vote_outlined, size: 16, color: cs.outline),
                  const SizedBox(width: 6),
                  Text('${oylama.toplamOySayisi} toplam oy',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Seçenekler
            Text('SEÇENEKLER',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.outline,
                  letterSpacing: 1.2,
                )),
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
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    if (_selectedSecenekId != null)
                      BoxShadow(
                        color: cs.primary.withOpacity(isDark ? 0.3 : 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: FilledButton.icon(
                  onPressed: _selectedSecenekId == null
                      ? null
                      : () => _oyVer(oylama),
                  icon: state.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
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
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: cs.primary),
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
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(minimumSize: const Size(80, 40)),
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
    final cs = Theme.of(context).colorScheme;
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
      color = cs.primary;
      text = 'Oy kullanabilirsiniz';
      icon = Icons.how_to_vote_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: GoogleFonts.inter(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ),
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = selectedId == secenek.id;
    final isVoted = kullaniciSecenekId == secenek.id;
    final showResults = kullaniciOyKullandi || !oylamaAcik;

    return GestureDetector(
      onTap: onSelect != null ? () => onSelect!(secenek.id) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primary.withOpacity(isDark ? 0.12 : 0.06)
              : isVoted
                  ? Colors.green.withOpacity(isDark ? 0.1 : 0.05)
                  : (isDark ? cs.surfaceContainerHigh : Colors.white),
          border: Border.all(
            color: isSelected
                ? cs.primary.withOpacity(0.5)
                : isVoted
                    ? Colors.green.withOpacity(0.4)
                    : (isDark ? cs.outlineVariant : const Color(0xFFE0E0E0)),
            width: isSelected || isVoted ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
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
                    color: isSelected ? cs.primary : cs.outline,
                    size: 20,
                  )
                else if (isVoted)
                  const Icon(Icons.check_circle,
                      color: Colors.green, size: 20)
                else
                  Icon(Icons.circle_outlined,
                      color: cs.outline, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(secenek.metin,
                      style: GoogleFonts.inter(
                        fontWeight: isVoted
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: cs.onSurface,
                      )),
                ),
                if (showResults)
                  Text('${secenek.oySayisi} oy',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ),
            if (showResults) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: secenek.oranYuzde / 100,
                  backgroundColor: isDark
                      ? cs.surfaceContainerHighest
                      : const Color(0xFFE8E8E8),
                  color: isVoted ? Colors.green : cs.primary,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 6),
              Text('%${secenek.oranYuzde.toStringAsFixed(1)}',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: cs.onSurfaceVariant)),
            ],
          ],
        ),
      ),
    );
  }
}
