import 'package:flutter/material.dart';

/// Palette YAY360, identique à celle du portail web (`yay360-web/src/styles/_tokens.scss`).
///
/// Contraste vérifié (WCAG) pour chaque couple texte / fond, en clair comme en sombre :
/// texte ≥ 4,5:1, icônes et grands titres ≥ 3:1.
/// - Texte turquoise → [tealInk] ; le turquoise vif [teal] ne sert qu'aux icônes et grands titres.
/// - Orange : fond d'action avec texte foncé [onAccent] (5,85:1), jamais du texte orange clair.
/// - Fonds pleins avec texte blanc : [tealDark], [dangerStrong], [successStrong].
@immutable
class YayPalette extends ThemeExtension<YayPalette> {
  const YayPalette({
    required this.teal,
    required this.tealInk,
    required this.tealDark,
    required this.tealSoft,
    required this.tealSofter,
    required this.tealLine,
    required this.orange,
    required this.orangeHover,
    required this.orangeInk,
    required this.orangeSoft,
    required this.orangeLine,
    required this.lilacInk,
    required this.lilacSoft,
    required this.bg,
    required this.panel,
    required this.surface,
    required this.surface2,
    required this.textMain,
    required this.textMuted,
    required this.textSoft,
    required this.borderLight,
    required this.borderStrong,
    required this.success,
    required this.successSoft,
    required this.successLine,
    required this.successStrong,
    required this.warning,
    required this.warningSoft,
    required this.warningLine,
    required this.danger,
    required this.dangerSoft,
    required this.dangerLine,
    required this.dangerStrong,
    required this.onStrong,
    required this.onAccent,
    required this.banner1,
    required this.banner2,
    required this.viz1,
    required this.viz2,
    required this.viz3,
    required this.vizTrack,
  });

  final Color teal, tealInk, tealDark, tealSoft, tealSofter, tealLine;
  final Color orange, orangeHover, orangeInk, orangeSoft, orangeLine;
  final Color lilacInk, lilacSoft;
  final Color bg, panel, surface, surface2;
  final Color textMain, textMuted, textSoft;
  final Color borderLight, borderStrong;
  final Color success, successSoft, successLine, successStrong;
  final Color warning, warningSoft, warningLine;
  final Color danger, dangerSoft, dangerLine, dangerStrong;

  /// Texte sur fond plein turquoise foncé, rouge ou vert.
  final Color onStrong;

  /// Texte sur l'orange : reste foncé dans les deux thèmes.
  final Color onAccent;

  /// Bannières dégradées avec texte blanc.
  final Color banner1, banner2;

  /// Palette des graphiques (ordre fixe, validée daltonisme) et fond des anneaux.
  final Color viz1, viz2, viz3, vizTrack;

  static const light = YayPalette(
    teal: Color(0xFF2BA3A8),
    tealInk: Color(0xFF15777C),
    tealDark: Color(0xFF1A7F86),
    tealSoft: Color(0xFFE3F4F5),
    tealSofter: Color(0xFFF1FAFA),
    tealLine: Color(0xFFCDEBEC),
    orange: Color(0xFFF7A84B),
    orangeHover: Color(0xFFF29A33),
    orangeInk: Color(0xFFA85A06),
    orangeSoft: Color(0xFFFEF1E2),
    orangeLine: Color(0xFFE08A25),
    lilacInk: Color(0xFF4A5FB0),
    lilacSoft: Color(0xFFECF0FC),
    bg: Color(0xFFE6F4F5),
    panel: Color(0xFFF4FBFB),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF6FAFA),
    textMain: Color(0xFF2D3B45),
    textMuted: Color(0xFF5A6B74),
    textSoft: Color(0xFF8A9AA2),
    borderLight: Color(0xFFE4EEF0),
    borderStrong: Color(0xFFC9D9DC),
    success: Color(0xFF1E7A4C),
    successSoft: Color(0xFFE3F5EC),
    successLine: Color(0xFF9FD6B8),
    successStrong: Color(0xFF1E7A4C),
    warning: Color(0xFF9A5B00),
    warningSoft: Color(0xFFFFF4E0),
    warningLine: Color(0xFFF6CF9F),
    danger: Color(0xFFC62828),
    dangerSoft: Color(0xFFFDECEC),
    dangerLine: Color(0xFFF2B8B8),
    dangerStrong: Color(0xFFC62828),
    onStrong: Color(0xFFFFFFFF),
    onAccent: Color(0xFF2D3B45),
    banner1: Color(0xFF1A7F86),
    banner2: Color(0xFF2BA3A8),
    viz1: Color(0xFF14969C),
    viz2: Color(0xFFE08A25),
    viz3: Color(0xFF6F86D6),
    vizTrack: Color(0xFFE3F4F5),
  );

  static const dark = YayPalette(
    teal: Color(0xFF3FC3C9),
    tealInk: Color(0xFF5CCFD4),
    tealDark: Color(0xFF17767C),
    tealSoft: Color(0xFF173E44),
    tealSofter: Color(0xFF132E33),
    tealLine: Color(0xFF255A60),
    orange: Color(0xFFF7A84B),
    orangeHover: Color(0xFFF9B964),
    orangeInk: Color(0xFFF4B266),
    orangeSoft: Color(0xFF36281A),
    orangeLine: Color(0xFFD98A2E),
    lilacInk: Color(0xFFAAB8F0),
    lilacSoft: Color(0xFF232A47),
    bg: Color(0xFF0E1A1D),
    panel: Color(0xFF122126),
    surface: Color(0xFF16282E),
    surface2: Color(0xFF1B3138),
    textMain: Color(0xFFE4EDEF),
    textMuted: Color(0xFFA7B8BF),
    textSoft: Color(0xFF7C9198),
    borderLight: Color(0xFF24393F),
    borderStrong: Color(0xFF36545C),
    success: Color(0xFF63D19C),
    successSoft: Color(0xFF163325),
    successLine: Color(0xFF2E6B4C),
    successStrong: Color(0xFF1E7A4C),
    warning: Color(0xFFF0B862),
    warningSoft: Color(0xFF382B16),
    warningLine: Color(0xFF6B4E22),
    danger: Color(0xFFFF8F86),
    dangerSoft: Color(0xFF3B1E20),
    dangerLine: Color(0xFF7A3434),
    dangerStrong: Color(0xFFC62828),
    onStrong: Color(0xFFFFFFFF),
    onAccent: Color(0xFF2D3B45),
    banner1: Color(0xFF0F4E53),
    banner2: Color(0xFF17767C),
    viz1: Color(0xFF22A0A6),
    viz2: Color(0xFFCF7D24),
    viz3: Color(0xFF7C90DA),
    vizTrack: Color(0xFF1E3940),
  );

  @override
  YayPalette copyWith() => this;

  @override
  YayPalette lerp(ThemeExtension<YayPalette>? other, double t) =>
      (other is YayPalette && t >= 0.5) ? other : this;
}

extension YayThemeColors on BuildContext {
  /// Palette du thème courant (clair ou sombre).
  YayPalette get yay => Theme.of(this).extension<YayPalette>() ?? YayPalette.light;
}

abstract final class YayTheme {
  static const fontFamily = 'Poppins';

  static ThemeData get light => _build(YayPalette.light, Brightness.light);
  static ThemeData get dark => _build(YayPalette.dark, Brightness.dark);

  static ThemeData _build(YayPalette p, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      // Action principale : bouton orange, texte foncé
      primary: p.orange,
      onPrimary: p.onAccent,
      primaryContainer: p.orangeSoft,
      onPrimaryContainer: p.orangeInk,
      // Identité : turquoise
      secondary: p.tealInk,
      onSecondary: brightness == Brightness.light ? p.onStrong : p.bg,
      secondaryContainer: p.tealSoft,
      onSecondaryContainer: p.tealInk,
      tertiary: p.lilacInk,
      onTertiary: p.surface,
      tertiaryContainer: p.lilacSoft,
      onTertiaryContainer: p.lilacInk,
      error: p.danger,
      onError: brightness == Brightness.light ? p.onStrong : p.bg,
      errorContainer: p.dangerSoft,
      onErrorContainer: p.danger,
      surface: p.surface,
      onSurface: p.textMain,
      onSurfaceVariant: p.textMuted,
      surfaceContainerLowest: p.surface,
      surfaceContainerLow: p.surface2,
      surfaceContainer: p.surface2,
      surfaceContainerHigh: p.surface2,
      surfaceContainerHighest: p.surface2,
      outline: p.borderStrong,
      outlineVariant: p.borderLight,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: p.textMain,
      onInverseSurface: p.surface,
      inversePrimary: p.tealDark,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
    );
    final textTheme = base.textTheme.apply(
      fontFamily: fontFamily,
      bodyColor: p.textMain,
      displayColor: p.textMain,
    );

    RoundedRectangleBorder arrondi(double r, [BorderSide side = BorderSide.none]) =>
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(r), side: side);
    const boutonTexte = TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600, fontSize: 15);

    OutlineInputBorder bordure(Color c, [double w = 1.5]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c, width: w),
    );

    return base.copyWith(
      colorScheme: scheme,
      extensions: [p],
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      iconTheme: IconThemeData(color: p.textMuted),
      dividerTheme: DividerThemeData(color: p.borderLight, thickness: 1.5, space: 1.5),
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        foregroundColor: p.textMain,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w600, color: p.textMain,
        ),
      ),
      // Bouton principal : orange, bordure, texte foncé
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(64, 50)),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20)),
          textStyle: const WidgetStatePropertyAll(boutonTexte),
          shape: WidgetStatePropertyAll(arrondi(14)),
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.disabled)) return p.surface2;
            if (s.contains(WidgetState.pressed) || s.contains(WidgetState.hovered)) return p.orangeHover;
            return p.orange;
          }),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled) ? p.textMuted : p.onAccent,
          ),
          side: WidgetStateProperty.resolveWith(
            (s) => BorderSide(
              color: s.contains(WidgetState.disabled) ? p.borderStrong : p.orangeLine,
              width: 1.5,
            ),
          ),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      // Bouton secondaire : contour turquoise
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(64, 50)),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20)),
          textStyle: const WidgetStatePropertyAll(boutonTexte),
          shape: WidgetStatePropertyAll(arrondi(14)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.pressed) ? p.tealSoft : p.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled) ? p.textMuted : p.tealInk,
          ),
          side: WidgetStateProperty.resolveWith(
            (s) => BorderSide(
              color: s.contains(WidgetState.disabled) ? p.borderStrong : p.teal,
              width: 1.5,
            ),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.tealInk,
          minimumSize: const Size(44, 44),
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600, fontSize: 14),
          shape: arrondi(12),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: p.tealInk,
          backgroundColor: p.tealSoft,
          minimumSize: const Size(44, 44),
          shape: arrondi(14, BorderSide(color: p.tealLine, width: 1.5)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        labelStyle: TextStyle(color: p.textMuted, fontWeight: FontWeight.w500),
        floatingLabelStyle: TextStyle(color: p.tealInk, fontWeight: FontWeight.w600),
        hintStyle: TextStyle(color: p.textMuted),
        helperStyle: TextStyle(color: p.textMuted, fontSize: 12),
        errorStyle: TextStyle(color: p.danger, fontSize: 12, fontWeight: FontWeight.w500),
        prefixIconColor: p.textMuted,
        suffixIconColor: p.textMuted,
        border: bordure(p.borderStrong),
        enabledBorder: bordure(p.borderStrong),
        focusedBorder: bordure(p.teal, 2),
        errorBorder: bordure(p.danger),
        focusedErrorBorder: bordure(p.danger, 2),
        disabledBorder: bordure(p.borderLight),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: arrondi(20, BorderSide(color: p.borderLight, width: 1.5)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: p.tealDark,
        disabledColor: p.surface2,
        labelStyle: TextStyle(fontFamily: fontFamily, color: p.textMain, fontWeight: FontWeight.w500, fontSize: 13),
        secondaryLabelStyle: TextStyle(fontFamily: fontFamily, color: p.onStrong, fontWeight: FontWeight.w600, fontSize: 13),
        checkmarkColor: p.onStrong,
        side: BorderSide(color: p.borderStrong, width: 1.5),
        shape: arrondi(999),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.tealSoft,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontFamily: fontFamily,
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? p.tealInk : p.textMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(color: s.contains(WidgetState.selected) ? p.tealInk : p.textMuted, size: 24),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: arrondi(28),
        titleTextStyle: TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w600, color: p.textMain),
        contentTextStyle: TextStyle(fontFamily: fontFamily, fontSize: 14, color: p.textMuted, height: 1.5),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: p.surface,
        showDragHandle: true,
        dragHandleColor: p.borderStrong,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        // Fond foncé dans les deux thèmes : texte clair et action orange restent lisibles
        backgroundColor: brightness == Brightness.light ? p.textMain : p.surface2,
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: brightness == Brightness.light ? p.surface : p.textMain,
          fontSize: 14,
        ),
        actionTextColor: p.orange,
        shape: arrondi(14),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.teal,
        linearTrackColor: p.vizTrack,
        circularTrackColor: p.vizTrack,
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.tealInk : p.textMuted),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.tealDark : Colors.transparent),
        checkColor: WidgetStatePropertyAll(p.onStrong),
        side: BorderSide(color: p.borderStrong, width: 1.5),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.tealInk,
        textColor: p.textMain,
        shape: arrondi(14),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: p.textMain, borderRadius: BorderRadius.circular(10)),
        textStyle: TextStyle(fontFamily: fontFamily, color: p.surface, fontSize: 12),
      ),
    );
  }
}
