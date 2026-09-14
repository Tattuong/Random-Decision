import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/app_colors.dart';

final Map<String, ThemeData> _themeCache = {};

class AppThemePreset {
  final String id;
  final Color primary;
  final Color primaryLight;
  final Color background;
  final Color surface;
  final Color darkBackground;
  final Color darkSurface;
  final LinearGradient headerGradient;
  final LinearGradient balanceGradient;

  const AppThemePreset({
    required this.id,
    required this.primary,
    required this.primaryLight,
    required this.background,
    required this.surface,
    required this.darkBackground,
    required this.darkSurface,
    required this.headerGradient,
    required this.balanceGradient,
  });

  ThemeData lightTheme() =>
      _themeCache.putIfAbsent('$id-light', () => _buildTheme(
            brightness: Brightness.light,
            scaffold: background,
            surfaceColor: surface,
            onSurface: AppColors.onSurface,
          ));

  ThemeData darkTheme() =>
      _themeCache.putIfAbsent('$id-dark', () => _buildTheme(
            brightness: Brightness.dark,
            scaffold: darkBackground,
            surfaceColor: darkSurface,
            onSurface: const Color(0xFFF1F5F9),
          ));

  ThemeData _buildTheme({
    required Brightness brightness,
    required Color scaffold,
    required Color surfaceColor,
    required Color onSurface,
  }) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      primaryColor: isDark ? primaryLight : primary,
      scaffoldBackgroundColor: scaffold,
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: primaryLight,
              secondary: primary,
              surface: surfaceColor,
              onSurface: onSurface,
              onPrimary: AppColors.onPrimary,
            )
          : ColorScheme.light(
              primary: primary,
              secondary: primaryLight,
              surface: surfaceColor,
              onPrimary: AppColors.onPrimary,
              onSurface: onSurface,
            ),
      textTheme: GoogleFonts.outfitTextTheme(isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: onSurface),
        iconTheme: IconThemeData(color: onSurface),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark ? primaryLight : primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 6,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkSurface : AppColors.surfaceVariant,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? primaryLight : primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class AppThemePresets {
  AppThemePresets._();

  static const AppThemePreset defaultPreset = AppThemePreset(
    id: 'theme_default',
    primary: AppColors.primary,
    primaryLight: AppColors.primaryLight,
    background: AppColors.background,
    surface: AppColors.surface,
    darkBackground: AppColors.darkBackground,
    darkSurface: AppColors.darkSurface,
    headerGradient: AppColors.headerGradient,
    balanceGradient: AppColors.heroGradient,
  );

  static const AppThemePreset sunset = AppThemePreset(
    id: 'theme_sunset',
    primary: Color(0xFFE17055),
    primaryLight: Color(0xFFFF7675),
    background: Color(0xFFFFF5F3),
    surface: Color(0xFFFFFFFF),
    darkBackground: Color(0xFF2D1B1B),
    darkSurface: Color(0xFF4A2C2C),
    headerGradient: LinearGradient(colors: [Color(0xFFD63031), Color(0xFFE17055), Color(0xFFFF7675)]),
    balanceGradient: LinearGradient(colors: [Color(0xFFE17055), Color(0xFFFF7675)]),
  );

  static const AppThemePreset midnight = AppThemePreset(
    id: 'theme_midnight',
    primary: Color(0xFF0984E3),
    primaryLight: Color(0xFF74B9FF),
    background: Color(0xFFF0F8FF),
    surface: Color(0xFFFFFFFF),
    darkBackground: Color(0xFF0C1B2A),
    darkSurface: Color(0xFF1A2F45),
    headerGradient: LinearGradient(colors: [Color(0xFF0652DD), Color(0xFF0984E3), Color(0xFF74B9FF)]),
    balanceGradient: LinearGradient(colors: [Color(0xFF0984E3), Color(0xFF74B9FF)]),
  );

  static const AppThemePreset tropical = AppThemePreset(
    id: 'theme_tropical',
    primary: Color(0xFF00B894),
    primaryLight: Color(0xFF55EFC4),
    background: Color(0xFFF0FFF8),
    surface: Color(0xFFFFFFFF),
    darkBackground: Color(0xFF0D2818),
    darkSurface: Color(0xFF1A3D2A),
    headerGradient: LinearGradient(colors: [Color(0xFF00A085), Color(0xFF00B894), Color(0xFF55EFC4)]),
    balanceGradient: LinearGradient(colors: [Color(0xFF00B894), Color(0xFF55EFC4)]),
  );

  static const AppThemePreset sakura = AppThemePreset(
    id: 'theme_sakura',
    primary: Color(0xFFFD79A8),
    primaryLight: Color(0xFFFFB8D0),
    background: Color(0xFFFFF0F5),
    surface: Color(0xFFFFFFFF),
    darkBackground: Color(0xFF3D1F2E),
    darkSurface: Color(0xFF5C2D42),
    headerGradient: LinearGradient(colors: [Color(0xFFE84393), Color(0xFFFD79A8), Color(0xFFFFB8D0)]),
    balanceGradient: LinearGradient(colors: [Color(0xFFFD79A8), Color(0xFFFFB8D0)]),
  );

  static const Map<String, AppThemePreset> byId = {
    'theme_default': defaultPreset,
    'theme_sunset': sunset,
    'theme_midnight': midnight,
    'theme_tropical': tropical,
    'theme_sakura': sakura,
  };

  static AppThemePreset get(String? id) => byId[id] ?? defaultPreset;
}

class WheelBackground {
  final String id;
  final LinearGradient gradient;

  const WheelBackground({required this.id, required this.gradient});

  static const WheelBackground defaultBg = WheelBackground(
    id: 'bg_default',
    gradient: AppColors.heroGradient,
  );

  static const WheelBackground sunrise = WheelBackground(
    id: 'bg_sunrise',
    gradient: LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53), Color(0xFFFFD93D)]),
  );

  static const WheelBackground ocean = WheelBackground(
    id: 'bg_ocean',
    gradient: LinearGradient(colors: [Color(0xFF0984E3), Color(0xFF74B9FF), Color(0xFF81ECEC)]),
  );

  static const WheelBackground aurora = WheelBackground(
    id: 'bg_aurora',
    gradient: LinearGradient(colors: [Color(0xFF6C3CE0), Color(0xFF00B894), Color(0xFF74B9FF)]),
  );

  static const WheelBackground galaxy = WheelBackground(
    id: 'bg_galaxy',
    gradient: LinearGradient(colors: [Color(0xFF2D1B69), Color(0xFF6C3CE0), Color(0xFF11998E)]),
  );

  static const Map<String, WheelBackground> byId = {
    'bg_default': defaultBg,
    'bg_sunrise': sunrise,
    'bg_ocean': ocean,
    'bg_aurora': aurora,
    'bg_galaxy': galaxy,
  };

  static WheelBackground get(String? id) => byId[id] ?? defaultBg;
}

class WheelStyle {
  final String id;
  final double glowBlur;
  final double glowSpread;
  final Color glowColor;
  final Color pointerTop;
  final Color pointerBottom;
  final Color centerColor;
  final Color centerIconColor;
  final Color outerRingColor;
  final double outerRingWidth;
  final double segmentBorderWidth;
  final double segmentBorderAlpha;
  final double labelFontSize;

  const WheelStyle({
    required this.id,
    this.glowBlur = 28,
    this.glowSpread = 2,
    this.glowColor = const Color(0xFF6C3CE0),
    this.pointerTop = const Color(0xFFFFD93D),
    this.pointerBottom = const Color(0xFFFF6B6B),
    this.centerColor = const Color(0xFFF0F2FA),
    this.centerIconColor = const Color(0xFF6C3CE0),
    this.outerRingColor = Colors.white,
    this.outerRingWidth = 4,
    this.segmentBorderWidth = 2,
    this.segmentBorderAlpha = 0.65,
    this.labelFontSize = 13,
  });

  static const WheelStyle defaultStyle = WheelStyle(id: 'skin_default');

  static const WheelStyle neon = WheelStyle(
    id: 'skin_neon',
    glowBlur: 40,
    glowSpread: 6,
    glowColor: Color(0xFF00F5FF),
    pointerTop: Color(0xFF00F5FF),
    pointerBottom: Color(0xFF7C3AED),
    centerColor: Color(0xFF1A1F35),
    centerIconColor: Color(0xFF00F5FF),
    outerRingColor: Color(0xFF00F5FF),
    labelFontSize: 12,
  );

  static const WheelStyle classic = WheelStyle(
    id: 'skin_classic',
    glowBlur: 16,
    glowSpread: 0,
    glowColor: Color(0xFFFFB020),
    pointerTop: Color(0xFFFFD93D),
    pointerBottom: Color(0xFFE17055),
    centerColor: Colors.white,
    centerIconColor: Color(0xFFE17055),
    outerRingWidth: 6,
    segmentBorderAlpha: 0.9,
    labelFontSize: 14,
  );

  static const WheelStyle glass = WheelStyle(
    id: 'skin_glass',
    glowBlur: 32,
    glowSpread: 4,
    glowColor: Colors.white,
    pointerTop: Colors.white,
    pointerBottom: Color(0xFF74B9FF),
    centerColor: Color(0x33FFFFFF),
    centerIconColor: Colors.white,
    outerRingColor: Colors.white70,
    segmentBorderAlpha: 0.4,
  );

  static const Map<String, WheelStyle> byId = {
    'skin_default': defaultStyle,
    'skin_neon': neon,
    'skin_classic': classic,
    'skin_glass': glass,
  };

  static WheelStyle get(String? id) => byId[id] ?? defaultStyle;
}
