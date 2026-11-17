// Navigation principale : quatre onglets, passage d'un écran à l'autre, raccourcis de l'accueil, thème.
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yay360_mobile/data/horloge.dart';
import 'package:yay360_mobile/screens/mobile_shell.dart';
import 'package:yay360_mobile/theme.dart';

import 'outils/fausse_api.dart';

FausseApi apiComplete() => FausseApi({
  'GET /grossesses/ma-grossesse': (_) => reponseJson(contrat('ma_grossesse')),
  'GET /grossesses/mon-suivi': (_) => reponseJson(contrat('mon_suivi')),
  'GET /grossesses/mon-plan-cpn': (_) => reponseJson(contrat('mon_plan_cpn')),
  'GET /rendez-vous/mes-rendez-vous/a-venir': (_) => reponseJson(<Object>[]),
  'GET /rendez-vous/mes-rendez-vous': (_) => reponseJson(contrat('mes_rendez_vous')),
  'GET /alertes/mes-alertes': (_) => reponseJson([contrat('alerte')]),
});

Future<void> afficher(WidgetTester tester, {VoidCallback? onToggleTheme}) async {
  ecranTelephone(tester);
  await tester.pumpWidget(MaterialApp(
    theme: YayTheme.light,
    home: MobileShell(auth: connecte(apiComplete().client), onToggleTheme: onToggleTheme),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    Horloge.fixer(DateTime(2026, 11, 17, 10));
  });
  tearDown(Horloge.reinitialiser);

  testWidgets('quatre onglets ; l’accueil est affiché au démarrage', (tester) async {
    await afficher(tester);

    for (final onglet in ['Accueil', 'Suivi', 'Rendez-vous', 'Famille']) {
      expect(find.widgetWithText(NavigationDestination, onglet), findsOneWidget);
    }
    expect(find.text('Bonjour, Awa'), findsOneWidget);
    expect(find.text('Mes rendez-vous'), findsNothing);
  });

  testWidgets('chaque onglet affiche son écran', (tester) async {
    await afficher(tester);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Rendez-vous'));
    await tester.pumpAndSettle();
    expect(find.text('Mes rendez-vous'), findsOneWidget);
    expect(find.text('Bonjour, Awa'), findsNothing);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Famille'));
    await tester.pumpAndSettle();
    expect(find.text('Mon espace'), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Accueil'));
    await tester.pumpAndSettle();
    expect(find.text('Bonjour, Awa'), findsOneWidget);
  });

  testWidgets('le raccourci « Demander un rendez-vous » de l’accueil ouvre l’onglet Rendez-vous', (tester) async {
    await afficher(tester);

    await tester.tap(find.text('Demander un rendez-vous').first);
    await tester.pumpAndSettle();

    expect(find.text('Mes rendez-vous'), findsOneWidget);
  });

  testWidgets('le bouton de thème prévient l’application', (tester) async {
    var bascules = 0;
    await afficher(tester, onToggleTheme: () => bascules++);

    await tester.tap(find.byTooltip('Activer le thème sombre'));
    expect(bascules, 1);
  });
}
