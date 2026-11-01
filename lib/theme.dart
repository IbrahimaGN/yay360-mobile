import 'package:flutter/material.dart';

abstract final class YayColors {
  static const rose = Color(0xFFE87A90);
  static const roseDark = Color(0xFFD65F78);
  static const navy = Color(0xFF1D3557);
  static const teal = Color(0xFF2A9D8F);
  static const green = teal;
  static const canvas = Color(0xFFFAFAFA);
  static const softGray = Color(0xFFF4F6F8);
  static const surface = Colors.white;
  static const ink = Color(0xFF2B2D42);
  static const muted = Color(0xFF737582);
  static const border = Color(0xFFE3E5E8);
  static const paleRose = Color(0xFFFCECEF);
  static const paleGreen = Color(0xFFE8F5F2);
  static const paleGold = Color(0xFFFFF3E3);
  static const success = Color(0xFF2ECC71);
  static const warning = Color(0xFFF39C12);
  static const urgent = Color(0xFFE74C3C);
}

extension YayThemeColors on BuildContext {
  Color get yayInk => Theme.of(this).colorScheme.onSurface;
  Color get yayMuted => Theme.of(this).colorScheme.onSurfaceVariant;
  Color get yayCanvas => Theme.of(this).scaffoldBackgroundColor;
  Color get yaySurface => Theme.of(this).colorScheme.surface;
  Color get yayBorder => Theme.of(this).colorScheme.outlineVariant;
  Color get yayRoseContainer => Theme.of(this).colorScheme.primaryContainer;
  Color get yayTealContainer => Theme.of(this).colorScheme.secondaryContainer;
  Color get yayWarningContainer => Theme.of(this).colorScheme.tertiaryContainer;
}

abstract final class YayTheme {
  static ThemeData get light {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: YayColors.rose,
          brightness: Brightness.light,
          primary: YayColors.rose,
          secondary: YayColors.teal,
          tertiary: YayColors.warning,
          surface: YayColors.surface,
        ).copyWith(
          onSurface: YayColors.ink,
          onSurfaceVariant: YayColors.muted,
          outlineVariant: YayColors.border,
          error: YayColors.urgent,
          primaryContainer: YayColors.paleRose,
          onPrimaryContainer: YayColors.roseDark,
          secondaryContainer: YayColors.paleGreen,
          onSecondaryContainer: YayColors.teal,
          tertiaryContainer: YayColors.paleGold,
        );
    return _build(scheme, YayColors.canvas, Brightness.light);
  }

  static ThemeData get dark {
    const background = Color(0xFF171A21);
    const surface = Color(0xFF222630);
    const ink = Color(0xFFF4F2F3);
    const muted = Color(0xFFB5B7C0);
    const border = Color(0xFF3A3E49);
    const roseContainer = Color(0xFF4B2C36);
    const tealContainer = Color(0xFF1F403D);
    const warningContainer = Color(0xFF4A3822);
    final scheme =
        ColorScheme.fromSeed(
          seedColor: YayColors.rose,
          brightness: Brightness.dark,
          primary: YayColors.rose,
          secondary: YayColors.teal,
          tertiary: YayColors.warning,
          surface: surface,
        ).copyWith(
          onSurface: ink,
          onSurfaceVariant: muted,
          outlineVariant: border,
          error: YayColors.urgent,
          primaryContainer: roseContainer,
          onPrimaryContainer: const Color(0xFFFFD9E0),
          secondaryContainer: tealContainer,
          onSecondaryContainer: const Color(0xFFB5E8DF),
          tertiaryContainer: warningContainer,
        );
    return _build(scheme, background, Brightness.dark);
  }

  static ThemeData _build(
    ColorScheme scheme,
    Color background,
    Brightness brightness,
  ) {
    final border = scheme.outlineVariant;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light
            ? YayColors.softGray
            : scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.secondary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
      ),
    );
  }
}
