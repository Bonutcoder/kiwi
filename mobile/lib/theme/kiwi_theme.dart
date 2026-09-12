import 'package:flutter/material.dart';

class KiwiTheme {
  // Canvas & Surfaces
  static const Color appBg = Color(0xFFBAC0B9);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color charcoal = Color(0xFF151719);
  static const Color searchBg = Color(0xFFD9DED8);

  // Status Colors
  static const Color verifiedMint = Color(0xFF8CE2A8);
  static const Color verifiedDark = Color(0xFF10B981);
  static const Color hostileRose = Color(0xFFFECDD3);
  static const Color hostileRed = Color(0xFFEF4444);
  static const Color telemetryBlue = Color(0xFF0284C7);

  // Text Colors
  static const Color textPrimary = Color(0xFF151719);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: appBg,
      colorScheme: const ColorScheme.light(
        primary: charcoal,
        secondary: verifiedMint,
        surface: cardBg,
        error: hostileRed,
      ),
      fontFamily: 'Space Grotesk',
    );
  }
}
