import 'package:flutter/material.dart';

class AppColors {
  static const bg        = Color(0xFF0f1117);
  static const card      = Color(0xFF1a1d2e);
  static const border    = Color(0xFF2a2d3e);
  static const primary   = Color(0xFF4f6ef7);
  static const purple    = Color(0xFF7c5cfc);
  static const text      = Color(0xFFe8eaf0);
  static const muted     = Color(0xFF8b8fa8);
  static const subtle    = Color(0xFF3d4060);
  static const green     = Color(0xFF22c55e);
  static const claude    = Color(0xFFf59e0b);
  static const gpt       = Color(0xFF10a37f);
  static const grok      = Color(0xFFf87171);
  static const ftA       = Color(0xFFa78bfa);
  static const ftB       = Color(0xFF4285f4);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.purple,
      surface: AppColors.card,
    ),
    fontFamily: 'SF Pro Display',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.card,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.text,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
      iconTheme: IconThemeData(color: AppColors.text),
    ),
    textTheme: const TextTheme(
      bodyLarge:  TextStyle(color: AppColors.text,  fontSize: 15),
      bodyMedium: TextStyle(color: AppColors.text,  fontSize: 14),
      bodySmall:  TextStyle(color: AppColors.muted, fontSize: 12),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bg,
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
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      labelStyle: const TextStyle(color: AppColors.muted),
      hintStyle: const TextStyle(color: AppColors.subtle),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
  );
}
