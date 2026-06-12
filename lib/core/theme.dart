import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Light
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF000000);
  // Dark
  static const surfaceDark = Color(0xFF0B0B0C);
  static const inkDark = Color(0xFFFFFFFF);
  // Card elevation in dark mode — slightly lighter than the page bg
  static const cardSurfaceDark = Color(0xFF1A1A1B);

  // Accent (shared)
  static const green = Color(0xFFA4F133);
  static const danger = Color(0xFFE53935);

  static Color greenSoft = const Color(0xFFA4F133).withValues(alpha: 0.12);

  // Light opacities
  static Color inkMuted = Colors.black.withValues(alpha: 0.60);
  static Color inkSubtle = Colors.black.withValues(alpha: 0.38);
  static Color hairline = Colors.black.withValues(alpha: 0.08);

  // Dark opacities
  static Color inkMutedDark = Colors.white.withValues(alpha: 0.65);
  static Color inkSubtleDark = Colors.white.withValues(alpha: 0.40);
  static Color hairlineDark = Colors.white.withValues(alpha: 0.12);
}

/// Theme-aware color tokens read from `BuildContext`.
extension AppColorsX on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;
  Color get surface => _isDark ? AppColors.surfaceDark : AppColors.surface;
  Color get ink => _isDark ? AppColors.inkDark : AppColors.ink;
  Color get inkMuted => _isDark ? AppColors.inkMutedDark : AppColors.inkMuted;
  Color get inkSubtle =>
      _isDark ? AppColors.inkSubtleDark : AppColors.inkSubtle;
  Color get hairline =>
      _isDark ? AppColors.hairlineDark : AppColors.hairline;
  // Use for content cards so they sit visually above the page background.
  Color get cardSurface =>
      _isDark ? AppColors.cardSurfaceDark : AppColors.surface;
}

ThemeData buildAppTheme() => _buildTheme(Brightness.light);
ThemeData buildDarkAppTheme() => _buildTheme(Brightness.dark);

ThemeData _buildTheme(Brightness b) {
  final isDark = b == Brightness.dark;
  final base = isDark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);

  final ink = isDark ? AppColors.inkDark : AppColors.ink;
  final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
  final muted = isDark ? AppColors.inkMutedDark : AppColors.inkMuted;
  final subtle = isDark ? AppColors.inkSubtleDark : AppColors.inkSubtle;
  final hairline = isDark ? AppColors.hairlineDark : AppColors.hairline;

  final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
    bodyColor: ink,
    displayColor: ink,
  );

  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.green,
    brightness: b,
    surface: surface,
    primary: ink,
    onPrimary: surface,
    secondary: AppColors.green,
    onSecondary: AppColors.ink,
    error: AppColors.danger,
  );

  // FAB inverts in dark mode so it pops.
  final fabBg = isDark ? AppColors.inkDark : AppColors.ink;
  final fabFg = isDark ? AppColors.surfaceDark : AppColors.surface;

  return base.copyWith(
    scaffoldBackgroundColor: surface,
    colorScheme: scheme,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      surfaceTintColor: surface,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 22,
        letterSpacing: -0.3,
        color: ink,
      ),
    ),
    dividerTheme: DividerThemeData(color: hairline, thickness: 1, space: 1),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: hairline),
        borderRadius: BorderRadius.circular(20),
      ),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ink,
        foregroundColor: surface,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        side: BorderSide(color: hairline),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: ink),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: fabBg,
      foregroundColor: fabFg,
      elevation: 4,
      shape: const CircleBorder(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      hintStyle: textTheme.bodyMedium?.copyWith(color: subtle),
      labelStyle: textTheme.bodyMedium?.copyWith(color: muted),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: ink, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: surface,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: ink,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: surface),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    splashFactory: NoSplash.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
    }),
  );
}

/// Static styles — left without `color` so DefaultTextStyle / Theme provides it.
class AppTextStyles {
  static TextStyle display = GoogleFonts.plusJakartaSans(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
  );
  static TextStyle headline = GoogleFonts.plusJakartaSans(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );
  static TextStyle title = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  static TextStyle body = GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );
  static TextStyle caption = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  );
}
