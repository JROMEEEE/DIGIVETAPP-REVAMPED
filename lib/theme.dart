import 'package:flutter/material.dart';

/// Colors shared with the DIGIVET Online web portal so the app and site
/// read as one product.
class Brand {
  static const maroon900 = Color(0xFF4C1420);
  static const maroon700 = Color(0xFF7C1F2C);
  static const maroon600 = Color(0xFF8E2735);
  static const maroon100 = Color(0xFFF1DEE0);
  static const gold500 = Color(0xFFC89B2A);
  static const gold300 = Color(0xFFE8C46A);
  static const gold100 = Color(0xFFF2E4C4);
  static const ink = Color(0xFF0F172A);
  static const inkSoft = Color(0xFF475569);
  static const border = Color(0xFFE2E8F0);
  static const surfaceAlt = Color(0xFFF8FAFC);
  static const green100 = Color(0xFFDFF3E4);
  static const green700 = Color(0xFF256B3A);
  static const cream = Color(0xFFF5EAD6);

  /// Serif used for headlines (the web uses Georgia; Android's built-in serif
  /// is the closest without shipping a font).
  static const serif = 'serif';
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Brand.maroon700,
      primary: Brand.maroon700,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.white,
    dividerColor: Brand.border,
  );
}
