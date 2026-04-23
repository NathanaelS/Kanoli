import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get darkAura {
    const background = Color(0xFF15141B);
    const foreground = Color(0xFFBDBDBD);
    const primary = Color(0xFF8464C6);
    const secondary = Color(0xFF54C59F);

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: primary,
          secondary: secondary,
          surface: background,
          onSurface: foreground,
          onPrimary: background,
          onSecondary: background,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: foreground),
        titleLarge: TextStyle(color: foreground, fontWeight: FontWeight.w700),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: background,
        foregroundColor: foreground,
      ),
      cardTheme: CardThemeData(
        color: primary.withValues(alpha: 0.18),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
