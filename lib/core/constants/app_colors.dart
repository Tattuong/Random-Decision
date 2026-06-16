import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6C3CE0);
  static const Color primaryLight = Color(0xFF9B6DFF);
  static const Color primaryDark = Color(0xFF4A1FA8);

  static const Color accent = Color(0xFFFF6B6B);
  static const Color accentAlt = Color(0xFFFF8E53);

  static const Color background = Color(0xFFF5F7FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEEF1FA);

  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF2D3436);
  static const Color onSurfaceVariant = Color(0xFF636E72);

  static const Color success = Color(0xFF00B894);
  static const Color warning = Color(0xFFFFB020);
  static const Color error = Color(0xFFE17055);
  static const Color coin = Color(0xFFFFC107);

  static const Color darkBackground = Color(0xFF121826);
  static const Color darkSurface = Color(0xFF1E2433);

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C3CE0), Color(0xFF9B6DFF), Color(0xFFFF6B9D)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C3CE0), Color(0xFFFF6B9D)],
  );

  static const List<Color> memberPalette = [
    Color(0xFF5B7FFF),
    Color(0xFFFF6B6B),
    Color(0xFF00B894),
    Color(0xFFFF8E53),
    Color(0xFF74B9FF),
    Color(0xFFFFB020),
    Color(0xFFE17055),
    Color(0xFF81ECEC),
    Color(0xFF8FA8FF),
    Color(0xFF55EFC4),
  ];
}
