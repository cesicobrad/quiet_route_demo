import 'package:flutter/material.dart';

class CozyTheme {
  static const Color cream = Color(0xFFFFFBF6);
  static const Color mint = Color(0xFFB8E3D3);
  static const Color lavender = Color(0xFFD7C9FF);
  static const Color peach = Color(0xFFFFC7A6);
  static const Color ink = Color(0xFF2F2A2A);
  static const Color muted = Color(0xFF7D7573);

  static ThemeData build() {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: cream,
      colorScheme: base.colorScheme.copyWith(
        primary: lavender,
        secondary: mint,
        surface: Colors.white,
        background: cream,
        onPrimary: ink,
        onSecondary: ink,
        onSurface: ink,
      ),
      textTheme: base.textTheme.copyWith(
        headlineSmall: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        titleMedium: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        bodyMedium: const TextStyle(
          fontSize: 16,
          color: ink,
        ),
        bodySmall: const TextStyle(
          fontSize: 13,
          color: muted,
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        shadowColor: ink.withOpacity(0.08),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink.withOpacity(0.9),
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
