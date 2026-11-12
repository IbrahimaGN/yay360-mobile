import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:yay360_mobile/data/api_client.dart';
import 'package:yay360_mobile/screens/appointments_screen.dart';
import 'package:yay360_mobile/screens/dashboard_screen.dart';
import 'package:yay360_mobile/theme.dart';
import 'package:yay360_mobile/widgets/symptom_sheet.dart';

/// API factice : aucun appel réseau réel pendant les tests.
ApiClient apiFactice() => ApiClient(client: MockClient((_) async => http.Response('{}', 200)));

Widget application(Widget contenu) => MaterialApp(
      theme: YayTheme.light,
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(body: contenu),
    );

void main() {
  testWidgets('le formulaire de rendez-vous s’affiche dans une feuille modale', (tester) async {
    await tester.pumpWidget(application(BookingSheet(api: apiFactice())));

    expect(find.text('Demander un rendez-vous'), findsOneWidget);
    expect(find.text('Envoyer ma demande'), findsOneWidget);
  });

  testWidgets('la déclaration de grossesse exige la date des dernières règles', (tester) async {
    await tester.pumpWidget(application(PregnancyForm(api: apiFactice())));
    expect(find.text('Déclarer ma grossesse'), findsWidgets);

    final bouton = find.byType(FilledButton);
    await tester.ensureVisible(bouton);
    await tester.tap(bouton);
    await tester.pump();

    expect(find.text('Choisissez la date des dernières règles.'), findsOneWidget);
  });

  testWidgets('le signalement d’un symptôme s’ouvre en feuille modale', (tester) async {
    await tester.pumpWidget(application(Builder(
      builder: (context) => TextButton(
        onPressed: () => reportSymptom(context, api: apiFactice(), pregnancyId: 1),
        child: const Text('Ouvrir'),
      ),
    )));

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Signaler un symptôme'), findsOneWidget);
  });
}
