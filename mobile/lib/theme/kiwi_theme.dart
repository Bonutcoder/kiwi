// KIWI Minimal Standard Material Theme
// Simple, neutral theme with standard Material defaults and clean typography.

import 'package:flutter/material.dart';

class KiwiTheme {
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceElevated = Color(0xFF2C2C2C);
  static const Color tealAccent = Colors.blueAccent;
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textMuted = Colors.white54;

  // Status Colors
  static const Color verifiedBg = Color(0xFF121212);
  static const Color verifiedBorder = Colors.green;
  static const Color hostileBg = Color(0xFF121212);
  static const Color hostileBorder = Colors.red;
  static const Color challengingBg = Color(0xFF121212);
  static const Color challengingBorder = Colors.blue;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: const ColorScheme.dark(
        surface: Color(0xFF1E1E1E),
        primary: Colors.blueAccent,
        secondary: Colors.blueAccent,
        error: Colors.redAccent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF121212),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }
}
