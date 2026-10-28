import 'package:flutter/material.dart';

class FutuerTheme {
  FutuerTheme._();

  static const Color brandPrimary = Color(0xFF00E5FF); // Electric Cyan
  static const Color brandPrimaryDark = Color(0xFF00B0FF);
  static const Color brandSecondary = Color(0xFF6366F1); // Indigo
  static const Color darkBg = Color(0xFF0A0E17);
  static const Color darkSurface = Color(0xFF131A29);
  static const Color darkSurfaceVariant = Color(0xFF1E283C);

  static const Color onlineColor = Color(0xFF00E676);
  static const Color offlineColor = Color(0xFF78909C);
  static const Color connectingColor = Color(0xFFFFB300);
  static const Color permissionReqColor = Color(0xFFFF5252);

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandSecondary,
        primary: const Color(0xFF1976D2),
        secondary: const Color(0xFF0097A7),
        surface: Colors.white,
      ),
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: brandPrimary,
        secondary: brandSecondary,
        surface: darkSurface,
        onSurface: Colors.white,
        surfaceContainerHighest: darkSurfaceVariant,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: darkSurfaceVariant.withValues(alpha: 0.5),
      ),
    );
  }
}
