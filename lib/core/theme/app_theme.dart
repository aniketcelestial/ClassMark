import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color Palette
  static const Color primaryBlue = Color(0xFF4F9DFF);
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);

  static const Color bgDark = Color(0xFF060818);
  static const Color bgCard = Color(0xFF0D1225);
  static const Color bgSurface = Color(0xFF111827);

  static const Color glassWhite = Color(0x14FFFFFF);
  static const Color glassBorder = Color(0x26FFFFFF);
  static const Color textPrimary = Color(0xFFEFF6FF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF475569);

  // Teacher gradient
  static const List<Color> teacherGradient = [
    Color(0xFF4F9DFF),
    Color(0xFF8B5CF6),
  ];

  // Student gradient
  static const List<Color> studentGradient = [
    Color(0xFF06B6D4),
    Color(0xFF10B981),
  ];

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: primaryPurple,
        surface: bgSurface,
        error: errorRed,
      ),
      textTheme: GoogleFonts.spaceGroteskTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
              color: textPrimary, fontSize: 48, fontWeight: FontWeight.w700),
          displayMedium: TextStyle(
              color: textPrimary, fontSize: 36, fontWeight: FontWeight.w700),
          displaySmall: TextStyle(
              color: textPrimary, fontSize: 28, fontWeight: FontWeight.w600),
          headlineLarge: TextStyle(
              color: textPrimary, fontSize: 24, fontWeight: FontWeight.w600),
          headlineMedium: TextStyle(
              color: textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(
              color: textPrimary, fontSize: 18, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(
              color: textPrimary, fontSize: 16, fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(
              color: textSecondary, fontSize: 14, fontWeight: FontWeight.w400),
          bodySmall: TextStyle(
              color: textMuted, fontSize: 12, fontWeight: FontWeight.w400),
          labelLarge: TextStyle(
              color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glassWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed),
        ),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
