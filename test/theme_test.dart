import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yay360_mobile/app.dart';
import 'package:yay360_mobile/state/auth_controller.dart';
import 'package:yay360_mobile/theme.dart';

/// Rapport de contraste WCAG entre deux couleurs opaques.
double contraste(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (clair, fonce) = la > lb ? (la, lb) : (lb, la);
  return (clair + 0.05) / (fonce + 0.05);
}

void main() {
  test('reprend la charte du portail web : action orange, identité turquoise, Poppins', () {
    final light = YayTheme.light;
    expect(light.brightness, Brightness.light);
    expect(light.colorScheme.primary, YayPalette.light.orange);
    expect(light.colorScheme.onPrimary, YayPalette.light.onAccent);
    expect(light.colorScheme.secondary, YayPalette.light.tealInk);
    expect(light.textTheme.bodyMedium?.fontFamily, YayTheme.fontFamily);
    expect(light.extension<YayPalette>(), YayPalette.light);

    final dark = YayTheme.dark;
    expect(dark.brightness, Brightness.dark);
    expect(dark.colorScheme.error, YayPalette.dark.danger);
    expect(dark.extension<YayPalette>(), YayPalette.dark);
  });

  group('contrastes des textes (WCAG ≥ 4,5:1)', () {
    for (final (nom, p) in [('clair', YayPalette.light), ('sombre', YayPalette.dark)]) {
      test('thème $nom', () {
        final fonds = [p.bg, p.panel, p.surface, p.surface2, p.tealSoft, p.tealSofter,
          p.orangeSoft, p.dangerSoft, p.successSoft, p.warningSoft, p.lilacSoft];
        for (final fond in fonds) {
          expect(contraste(p.textMain, fond), greaterThanOrEqualTo(4.5), reason: 'texte principal');
          expect(contraste(p.textMuted, fond), greaterThanOrEqualTo(4.5), reason: 'texte secondaire');
        }
        for (final fond in [p.bg, p.surface, p.surface2, p.tealSoft, p.tealSofter]) {
          expect(contraste(p.tealInk, fond), greaterThanOrEqualTo(4.5), reason: 'texte turquoise');
        }
        expect(contraste(p.orangeInk, p.surface), greaterThanOrEqualTo(4.5));
        expect(contraste(p.orangeInk, p.orangeSoft), greaterThanOrEqualTo(4.5));
        expect(contraste(p.danger, p.dangerSoft), greaterThanOrEqualTo(4.5));
        expect(contraste(p.success, p.successSoft), greaterThanOrEqualTo(4.5));
        expect(contraste(p.warning, p.warningSoft), greaterThanOrEqualTo(4.5));
        expect(contraste(p.lilacInk, p.lilacSoft), greaterThanOrEqualTo(4.5));
        // Fonds pleins
        expect(contraste(p.onAccent, p.orange), greaterThanOrEqualTo(4.5), reason: 'bouton orange');
        expect(contraste(p.onStrong, p.tealDark), greaterThanOrEqualTo(4.5), reason: 'turquoise plein');
        expect(contraste(p.onStrong, p.dangerStrong), greaterThanOrEqualTo(4.5), reason: 'rouge plein');
        expect(contraste(p.onStrong, p.banner1), greaterThanOrEqualTo(4.5), reason: 'bannière');
      });
    }
  });

  testWidgets('switches between light and dark themes from the sign-in page', (
    tester,
  ) async {
    final auth = AuthController()..isRestoring = false;
    await tester.pumpWidget(Yay360App(auth: auth));
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.light,
    );
    await tester.tap(find.byTooltip('Activer le thème sombre'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.dark,
    );
    expect(find.byTooltip('Activer le thème clair'), findsOneWidget);
  });
}
