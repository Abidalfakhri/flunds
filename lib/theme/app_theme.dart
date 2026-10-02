import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FlundsColors {
  FlundsColors._();

  static const primary = Color(0xFF1B5E4F);
  static const primaryDark = Color(0xFF123F36);
  static const primarySoft = Color(0xFFDCEAE2);

  static const accent = Color(0xFFD97757);
  static const accentSoft = Color(0xFFF4E1D6);

  static const ownerCutBg = Color(0xFFE4EDF7);
  static const ownerCutText = Color(0xFF1B537F);

  static const income = Color(0xFF2F7A4D);
  static const incomeSoft = Color(0xFFE1F0E6);
  static const expense = Color(0xFFC1533A);
  static const expenseSoft = Color(0xFFF8E3DE);

  static const scaffoldBg = Color(0xFFFBF8F3);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceLine = Color(0xFFEDE7DB);

  static const textPrimary = Color(0xFF211D17);
  static const textMuted = Color(0xFF6F695D);
}

class FlundsTheme {
  FlundsTheme._();

  static ThemeData get light {
    final base = ColorScheme.fromSeed(
      seedColor: FlundsColors.primary,
      brightness: Brightness.light,
      surface: FlundsColors.surface,
    );

    final colorScheme = base.copyWith(
      primary: FlundsColors.primary,
      secondary: FlundsColors.accent,
      surface: FlundsColors.surface,
      error: FlundsColors.expense,
    );

    final headingFont = GoogleFonts.sora();
    final bodyFont = GoogleFonts.plusJakartaSans();

    final textTheme = TextTheme(
      displaySmall: headingFont.copyWith(fontSize: 30, fontWeight: FontWeight.w700, color: FlundsColors.textPrimary, letterSpacing: -0.5),
      headlineSmall: headingFont.copyWith(fontSize: 22, fontWeight: FontWeight.w700, color: FlundsColors.textPrimary, letterSpacing: -0.3),
      titleLarge: headingFont.copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: FlundsColors.textPrimary),
      titleMedium: bodyFont.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: FlundsColors.textPrimary),
      titleSmall: bodyFont.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: FlundsColors.textPrimary),
      bodyLarge: bodyFont.copyWith(fontSize: 15, color: FlundsColors.textPrimary, height: 1.4),
      bodyMedium: bodyFont.copyWith(fontSize: 13.5, color: FlundsColors.textPrimary, height: 1.4),
      bodySmall: bodyFont.copyWith(fontSize: 12, color: FlundsColors.textMuted),
      labelLarge: bodyFont.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: FlundsColors.scaffoldBg,
      textTheme: textTheme,
      fontFamily: bodyFont.fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: FlundsColors.scaffoldBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: headingFont.copyWith(fontSize: 19, fontWeight: FontWeight.w700, color: FlundsColors.textPrimary),
        iconTheme: const IconThemeData(color: FlundsColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: FlundsColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: FlundsColors.surfaceLine),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: FlundsColors.surface,
        selectedColor: FlundsColors.primarySoft,
        side: const BorderSide(color: FlundsColors.surfaceLine),
        labelStyle: bodyFont.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600, color: FlundsColors.textPrimary),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FlundsColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: FlundsColors.surfaceLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: FlundsColors.surfaceLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: FlundsColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: FlundsColors.expense, width: 1.4),
        ),
        labelStyle: bodyFont.copyWith(color: FlundsColors.textMuted, fontSize: 13.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FlundsColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: FlundsColors.primary.withValues(alpha: 0.4),
          elevation: 0,
          minimumSize: const Size.fromHeight(50),
          textStyle: bodyFont.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FlundsColors.textPrimary,
          side: const BorderSide(color: FlundsColors.surfaceLine),
          minimumSize: const Size.fromHeight(48),
          textStyle: bodyFont.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: FlundsColors.primary,
          textStyle: bodyFont.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(color: FlundsColors.surfaceLine, thickness: 1, space: 1),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? FlundsColors.primary : Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? FlundsColors.primarySoft : FlundsColors.surfaceLine),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: FlundsColors.textPrimary,
        contentTextStyle: bodyFont.copyWith(color: Colors.white, fontSize: 13.5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: FlundsColors.surface,
        selectedIconTheme: const IconThemeData(color: FlundsColors.primary),
        unselectedIconTheme: const IconThemeData(color: FlundsColors.textMuted),
        selectedLabelTextStyle: bodyFont.copyWith(color: FlundsColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: bodyFont.copyWith(color: FlundsColors.textMuted, fontSize: 12),
      ),
    );
  }
}
