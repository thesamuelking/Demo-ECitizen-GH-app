import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Ghana flag colors
  static const ghRed = Color(0xFFCE1126);
  static const ghGold = Color(0xFFFCD116);
  static const ghGreen = Color(0xFF006B3F);
  static const ghBlack = Color(0xFF1A1A1A);

  // Surface colors
  static const surface = Color(0xFFF4F6F9);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFE5E7EB);
  static const muted = Color(0xFF8D9BAA);
  static const mutedLight = Color(0xFF8291A0);

  // Service accent colors
  static const birthRed = Color(0xFFCE1126);
  static const passportGreen = Color(0xFF006B3F);
  static const driversAmber = Color(0xFFB45309);
  static const nhisBlue = Color(0xFF1D4ED8);
  static const ghanacardPurple = Color(0xFF7C3AED);

  // Status colors
  static const statusPending = Color(0xFFF59E0B);
  static const statusProcessing = Color(0xFF3B82F6);
  static const statusApproved = Color(0xFF10B981);
  static const statusReady = Color(0xFF059669);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.ghRed,
        primary: AppColors.ghRed,
        secondary: AppColors.ghGreen,
        tertiary: AppColors.ghGold,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.surface,
      fontFamily: GoogleFonts.inter().fontFamily,
      fontFamilyFallback: const [
        'Noto Sans',
        'Noto Sans Symbols 2',
        'Noto Color Emoji',
        'Segoe UI Emoji',
        'Arial',
      ],
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.ghBlack,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.ghBlack,
        ),
        displaySmall: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.ghBlack,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.ghBlack,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.ghBlack,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.ghBlack,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.ghBlack,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.muted,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.mutedLight,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ghRed,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.ghRed, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.mutedLight,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.ghRed,
      brightness: Brightness.dark,
      primary: AppColors.ghRed,
      secondary: AppColors.ghGreen,
    );
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF101418),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
      cardTheme: CardThemeData(
        color: const Color(0xFF1B2228),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
