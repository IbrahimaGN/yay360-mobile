import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yay360_mobile/app.dart';
import 'package:yay360_mobile/state/auth_controller.dart';
import 'package:yay360_mobile/theme.dart';

void main() {
  test('defines matching light and dark YAY360 palettes', () {
    expect(YayTheme.light.brightness, Brightness.light);
    expect(YayTheme.light.colorScheme.primary, YayColors.rose);
    expect(YayTheme.light.colorScheme.secondary, YayColors.teal);
    expect(YayTheme.dark.brightness, Brightness.dark);
    expect(YayTheme.dark.colorScheme.error, YayColors.urgent);
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
