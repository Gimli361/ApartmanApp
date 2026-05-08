import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Uygulama genelinde kullanılan özel buton widget'ı
/// Neon glow shadow efekti ve modern tasarım.
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (onPressed != null && !isLoading)
            BoxShadow(
              color: cs.primary.withOpacity(isDark ? 0.3 : 0.2),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(text, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
