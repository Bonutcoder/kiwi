// Plain default Material Theme
import 'package:flutter/material.dart';

class KiwiTheme {
  static const Color background = Colors.white;
  static const Color surface = Colors.white;
  static const Color surfaceElevated = Colors.white;
  static const Color tealAccent = Colors.blue;
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;
  static const Color textMuted = Colors.black38;

  static const Color verifiedBg = Colors.white;
  static const Color verifiedBorder = Colors.green;
  static const Color hostileBg = Colors.white;
  static const Color hostileBorder = Colors.red;
  static const Color challengingBg = Colors.white;
  static const Color challengingBorder = Colors.blue;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: false,
      primarySwatch: Colors.blue,
    );
  }
}
