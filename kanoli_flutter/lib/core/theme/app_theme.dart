import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const Color background = Color(0xFF15141B);
  static const Color foreground = Color(0xFFBDBDBD);
  static const Color muted = Color(0xFF6D6D6D);
  static const Color primary = Color(0xFF8464C6);
  static const Color secondary = Color(0xFF54C59F);
  static const Color tertiary = Color(0xFFC7A06F);
  static const Color quaternary = Color(0xFFC17AC8);
  static const Color quinary = Color(0xFF6CB2C7);
  static const Color senary = Color(0xFFC55858);
  static const Color selection = Color(0x803D375E);
  static const Color surfaceSoft = Color(0xCC201E2A);
  static const Color surfaceElevated = Color(0xCC2B2740);
  static const Color outline = Color(0x664D4675);

  static const LinearGradient workspaceGradient = LinearGradient(
    colors: <Color>[background, Color(0xFF221A34), Color(0xFF30224A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient startupPanelGradient = LinearGradient(
    colors: <Color>[Color(0xCC2D2442), Color(0xCC1E2236)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Build once to keep theme setup cheap at runtime.
  static final ThemeData darkAura = _buildDarkAura();

  static ThemeData _buildDarkAura() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: primary,
          secondary: secondary,
          tertiary: quinary,
          error: senary,
          surface: background,
          onSurface: foreground,
          onPrimary: background,
          onSecondary: background,
          onTertiary: background,
          outline: outline,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
        titleMedium: TextStyle(color: foreground, fontWeight: FontWeight.w700),
        bodyMedium: TextStyle(color: foreground),
        bodySmall: TextStyle(color: muted),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Color(0xCC15141B),
        foregroundColor: foreground,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(color: outline),
      cardTheme: CardThemeData(
        color: surfaceSoft,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: outline),
        ),
      ),
      chipTheme: ChipThemeData.fromDefaults(
        brightness: Brightness.dark,
        secondaryColor: primary,
        labelStyle: const TextStyle(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ).copyWith(
        backgroundColor: surfaceElevated,
        selectedColor: primary,
        side: const BorderSide(color: outline),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: foreground,
          disabledForegroundColor: muted,
          hoverColor: selection,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: background,
          disabledBackgroundColor: muted,
          disabledForegroundColor: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          side: const BorderSide(color: outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: TextStyle(color: foreground),
      ),
    );
  }
}
