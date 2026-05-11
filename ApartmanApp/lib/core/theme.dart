import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// PropertyPulse Design System — Uygulama teması
class AppTheme {
  AppTheme._();

  // ── Light Mode Renkler ─────────────────────────────────────────────────────
  static const Color primaryLight = Color(0xFF1A237E); // Navy
  static const Color secondaryLight = Color(0xFF006875);
  static const Color secondaryContainerLight = Color(0xFF00E3FD); // Turquoise accent
  static const Color errorLight = Color(0xFFBA1A1A);
  static const Color surfaceLight = Color(0xFFF7F9FB);
  static const Color surfaceContainerLight = Color(0xFFECEEF0);
  static const Color surfaceContainerHighLight = Color(0xFFE6E8EA);
  static const Color surfaceContainerHighestLight = Color(0xFFE0E3E5);
  static const Color surfaceContainerLowLight = Color(0xFFF2F4F6);
  static const Color surfaceContainerLowestLight = Color(0xFFFFFFFF);
  static const Color onSurfaceLight = Color(0xFF191C1E);
  static const Color onSurfaceVariantLight = Color(0xFF454652);
  static const Color outlineLight = Color(0xFF767683);
  static const Color outlineVariantLight = Color(0xFFC6C5D4);

  // ── Dark Mode Renkler ──────────────────────────────────────────────────────
  static const Color primaryDark = Color(0xFF00E3FD); // Neon Turquoise
  static const Color secondaryDark = Color(0xFF00D7EF);
  static const Color secondaryContainerDark = Color(0xFF00E3FD);
  static const Color errorDark = Color(0xFFFF5449);
  static const Color surfaceDark = Color(0xFF111318); // Deep charcoal
  static const Color surfaceContainerDark = Color(0xFF1E2025);
  static const Color surfaceContainerHighDark = Color(0xFF282A2F);
  static const Color surfaceContainerHighestDark = Color(0xFF33353A);
  static const Color surfaceContainerLowDark = Color(0xFF1A1C1E);
  static const Color surfaceContainerLowestDark = Color(0xFF0B0E11);
  static const Color onSurfaceDark = Color(0xFFE2E2E6);
  static const Color onSurfaceVariantDark = Color(0xFFC4C6D0);
  static const Color outlineDark = Color(0xFF8E9199);
  static const Color outlineVariantDark = Color(0xFF44474E);

  // ── Ortak ──────────────────────────────────────────────────────────────────
  static const Color successColor = Color(0xFF388E3C);
  static const double _borderRadius = 16.0;
  static const double _inputRadius = 12.0;
  static const double _buttonRadius = 12.0;
  static const double _bottomSheetRadius = 24.0;

  // Uyumluluk — eski referanslar kırılmasın
  static const Color primaryColor = primaryDark;

  // ── LIGHT THEME ────────────────────────────────────────────────────────────

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryLight,
        onPrimary: Colors.white,
        secondary: secondaryLight,
        onSecondary: Colors.white,
        secondaryContainer: secondaryContainerLight,
        error: errorLight,
        onError: Colors.white,
        surface: surfaceLight,
        onSurface: onSurfaceLight,
        onSurfaceVariant: onSurfaceVariantLight,
        outline: outlineLight,
        outlineVariant: outlineVariantLight,
        surfaceContainerHighest: surfaceContainerHighestLight,
        surfaceContainerHigh: surfaceContainerHighLight,
        surfaceContainer: surfaceContainerLight,
        surfaceContainerLow: surfaceContainerLowLight,
        surfaceContainerLowest: surfaceContainerLowestLight,
      ),
      textTheme: GoogleFonts.interTextTheme(),
    );

    return base.copyWith(
      scaffoldBackgroundColor: surfaceLight,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: primaryLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.inter(
          color: primaryLight,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          side: const BorderSide(color: outlineVariantLight),
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: const BorderSide(color: outlineVariantLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: const BorderSide(color: outlineVariantLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: const BorderSide(color: secondaryContainerLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: const BorderSide(color: errorLight),
        ),
        labelStyle: GoogleFonts.inter(
          color: onSurfaceVariantLight,
          fontSize: 14,
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(_bottomSheetRadius),
          ),
        ),
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primaryLight.withOpacity(0.08),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryLight, size: 24);
          }
          return IconThemeData(color: Colors.grey[400], size: 24);
        }),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryLight,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primaryLight,
        unselectedLabelColor: onSurfaceVariantLight,
        indicatorColor: secondaryContainerLight,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide.none,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerTheme: const DividerThemeData(
        thickness: 1,
        color: Color(0xFFE8E8E8),
      ),
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      extensions: const [
        AppSpacing(),
      ],
    );
  }

  // ── DARK THEME ─────────────────────────────────────────────────────────────

  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryDark,
        onPrimary: Color(0xFF00363D),
        secondary: secondaryDark,
        onSecondary: Color(0xFF00363D),
        secondaryContainer: secondaryContainerDark,
        error: errorDark,
        onError: Color(0xFF690005),
        surface: surfaceDark,
        onSurface: onSurfaceDark,
        onSurfaceVariant: onSurfaceVariantDark,
        outline: outlineDark,
        outlineVariant: outlineVariantDark,
        surfaceContainerHighest: surfaceContainerHighestDark,
        surfaceContainerHigh: surfaceContainerHighDark,
        surfaceContainer: surfaceContainerDark,
        surfaceContainerLow: surfaceContainerLowDark,
        surfaceContainerLowest: surfaceContainerLowestDark,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: surfaceDark,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceContainerLowestDark,
        foregroundColor: primaryDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.inter(
          color: primaryDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        shape: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          side: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        elevation: 0,
        color: surfaceContainerDark,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: const Color(0xFF00363D),
          elevation: 0,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: const Color(0xFF00363D),
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryDark,
          side: const BorderSide(color: outlineVariantDark),
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerDark,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: const BorderSide(color: outlineVariantDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: const BorderSide(color: outlineVariantDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: const BorderSide(color: primaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: const BorderSide(color: errorDark),
        ),
        labelStyle: GoogleFonts.inter(
          color: onSurfaceVariantDark,
          fontSize: 14,
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        surfaceTintColor: Colors.transparent,
        backgroundColor: surfaceContainerHighDark,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(_bottomSheetRadius),
          ),
        ),
        surfaceTintColor: Colors.transparent,
        backgroundColor: surfaceContainerDark,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        elevation: 0,
        backgroundColor: surfaceContainerLowestDark,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primaryDark.withOpacity(0.1),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryDark, size: 24);
          }
          return const IconThemeData(color: outlineDark, size: 24);
        }),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryDark,
        foregroundColor: const Color(0xFF00363D),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primaryDark,
        unselectedLabelColor: onSurfaceVariantDark,
        indicatorColor: primaryDark,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide.none,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerTheme: DividerThemeData(
        thickness: 1,
        color: Colors.white.withOpacity(0.05),
      ),
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
        ),
        surfaceTintColor: Colors.transparent,
        color: surfaceContainerHighDark,
      ),
      extensions: const [
        AppSpacing(),
      ],
    );
  }
}

/// Design token'ları — spacing sabitleri
@immutable
class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({
    this.stackSm = 8.0,
    this.stackMd = 16.0,
    this.stackLg = 24.0,
    this.gutterCard = 16.0,
    this.marginPage = 20.0,
  });

  final double stackSm;
  final double stackMd;
  final double stackLg;
  final double gutterCard;
  final double marginPage;

  @override
  AppSpacing copyWith({
    double? stackSm,
    double? stackMd,
    double? stackLg,
    double? gutterCard,
    double? marginPage,
  }) {
    return AppSpacing(
      stackSm: stackSm ?? this.stackSm,
      stackMd: stackMd ?? this.stackMd,
      stackLg: stackLg ?? this.stackLg,
      gutterCard: gutterCard ?? this.gutterCard,
      marginPage: marginPage ?? this.marginPage,
    );
  }

  @override
  AppSpacing lerp(covariant ThemeExtension<AppSpacing>? other, double t) {
    if (other is! AppSpacing) return this;
    return AppSpacing(
      stackSm: lerpDouble(stackSm, other.stackSm, t) ?? stackSm,
      stackMd: lerpDouble(stackMd, other.stackMd, t) ?? stackMd,
      stackLg: lerpDouble(stackLg, other.stackLg, t) ?? stackLg,
      gutterCard: lerpDouble(gutterCard, other.gutterCard, t) ?? gutterCard,
      marginPage: lerpDouble(marginPage, other.marginPage, t) ?? marginPage,
    );
  }

  static double? lerpDouble(double? a, double? b, double t) {
    if (a == null && b == null) return null;
    a ??= 0.0;
    b ??= 0.0;
    return a + (b - a) * t;
  }
}
