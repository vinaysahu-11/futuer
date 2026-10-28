import 'package:flutter/material.dart';

class FutuerAgentTheme {
  FutuerAgentTheme._();

  static const Color brandPrimary = Color(0xFF00E5FF); // Electric Cyan
  static const Color brandSecondary = Color(0xFF6366F1); // Indigo
  static const Color darkBg = Color(0xFF0A0E17);
  static const Color darkSurface = Color(0xFF131A29);
  static const Color darkSurfaceVariant = Color(0xFF1E283C);

  static const Color onlineColor = Color(0xFF00E676);
  static const Color offlineColor = Color(0xFF78909C);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandSecondary,
        primary: const Color(0xFF1976D2),
        secondary: const Color(0xFF0097A7),
      ),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
    );
  }
}
