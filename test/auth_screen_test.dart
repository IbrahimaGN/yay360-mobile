import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yay360_mobile/screens/auth_screen.dart';
import 'package:yay360_mobile/state/auth_controller.dart';

void main() {
  testWidgets('shows patient login and partner invitation entry points', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: AuthScreen(auth: AuthController())),
    );

    expect(
      find.text('Votre grossesse,\naccompagnée avec soin.'),
      findsOneWidget,
    );
    expect(find.text('Connexion'), findsOneWidget);
    expect(
      find.text('J’ai reçu une invitation de mon conjoint'),
      findsOneWidget,
    );
  });

  testWidgets('switches to patient registration', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: AuthScreen(auth: AuthController())),
    );

    await tester.tap(find.text('Inscription'));
    await tester.pumpAndSettle();

    expect(find.text('Créer mon espace'), findsOneWidget);
    expect(find.text('Prénom'), findsOneWidget);
    expect(find.text('Date de naissance'), findsOneWidget);
  });
}
