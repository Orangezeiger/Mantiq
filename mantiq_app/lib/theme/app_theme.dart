import 'package:flutter/material.dart';

// Farben und Theme fuer die gesamte App
class AppColors {
  static const bg        = Color(0xFF0F1117);
  static const surface   = Color(0xFF1C1F2A);
  static const surface2  = Color(0xFF252836);
  static const border    = Color(0xFF2E3347);
  static const primary   = Color(0xFF7C6AF5);
  static const primaryH  = Color(0xFF6B59E0);
  static const success   = Color(0xFF34D399);
  static const error     = Color(0xFFF87171);
  static const warning   = Color(0xFFFBBF24);
  static const text      = Color(0xFFF1F5F9);
  static const textMuted = Color(0xFF94A3B8);
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      surface:   AppColors.surface,
      primary:   AppColors.primary,
      error:     AppColors.error,
    ),
    fontFamily: 'SF Pro Display', // faellt auf System-Font zurueck
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.text,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    textTheme: const TextTheme(
      bodyLarge:   TextStyle(color: AppColors.text,      fontSize: 16),
      bodyMedium:  TextStyle(color: AppColors.text,      fontSize: 14),
      bodySmall:   TextStyle(color: AppColors.textMuted, fontSize: 12),
      headlineMedium: TextStyle(color: AppColors.text, fontSize: 24, fontWeight: FontWeight.w800),
      titleLarge:  TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w700),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface2,
      hintStyle: const TextStyle(color: AppColors.textMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    dividerColor: AppColors.border,
  );
}
