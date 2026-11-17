// Écran « Rendez-vous » : classement à venir / historique selon la date du jour (fixée), erreurs, formulaire.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:yay360_mobile/data/api_client.dart';
import 'package:yay360_mobile/data/horloge.dart';
import 'package:yay360_mobile/screens/appointments_screen.dart';

import 'outils/fausse_api.dart';

/// Rendez-vous fictifs, construits sur le format réel renvoyé par l'API.
List<Map<String, dynamic>> rendezVous() {
  final modele = (contrat('mes_rendez_vous') as List).first as Map<String, dynamic>;
  Map<String, dynamic> rdv(int id, String dateHeure, String statut, String type) =>
      {...modele, 'id': id, 'dateHeure': dateHeure, 'statut': statut, 'type': type};
  return [
    rdv(1, '2026-11-20T09:00:00', 'CONFIRME', 'ECHOGRAPHIE'),
    rdv(2, '2026-11-17T09:00:00', 'PLANIFIE', 'CONSULTATION_PRENATALE'), // une heure avant « maintenant »
    rdv(3, '2026-11-25T11:00:00', 'ANNULE', 'VACCINATION'),
    rdv(4, '2026-10-30T10:30:00', 'TERMINE', 'EXAMEN_LABORATOIRE'),
  ];
}

Future<void> afficher(WidgetTester tester, FausseApi fausse) async {
  ecranTelephone(tester);
  await tester.pumpWidget(appli(AppointmentsScreen(api: ApiClient(client: fausse.client))));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  tearDown(Horloge.reinitialiser);

  testWidgets('le 17 novembre à 10 h : seul le rendez-vous confirmé du 20 est à venir', (tester) async {
    Horloge.fixer(DateTime(2026, 11, 17, 10));
    await afficher(tester, FausseApi({'/rendez-vous/mes-rendez-vous': (_) => reponseJson(rendezVous())}));

    expect(find.text('À venir (1)'), findsOneWidget);
    expect(find.text('Historique (3)'), findsOneWidget);
    expect(find.text('Échographie'), findsOneWidget);
    expect(find.text('Confirmé'), findsOneWidget);
    // Le rendez-vous planifié à 9 h est passé : il ne doit plus apparaître « à venir »
    expect(find.text('Consultation prénatale'), findsNothing);

    await tester.tap(find.text('Historique (3)'));
    await tester.pumpAndSettle();

    expect(find.text('À confirmer'), findsOneWidget);
    expect(find.text('Annulé'), findsOneWidget);
    expect(find.text('Terminé'), findsOneWidget);
    expect(find.text('Échographie'), findsNothing);
  });

  testWidgets('les mêmes données le 21 novembre : plus aucun rendez-vous à venir', (tester) async {
    Horloge.fixer(DateTime(2026, 11, 21, 8));
    await afficher(tester, FausseApi({'/rendez-vous/mes-rendez-vous': (_) => reponseJson(rendezVous())}));

    expect(find.text('À venir (0)'), findsOneWidget);
    expect(find.text('Historique (4)'), findsOneWidget);
    expect(find.text('Aucun rendez-vous à venir'), findsOneWidget);
  });

  testWidgets('réseau absent : message, puis « Réessayer » recharge la liste', (tester) async {
    Horloge.fixer(DateTime(2026, 11, 17, 10));
    var essais = 0;
    await afficher(tester, FausseApi({
      '/rendez-vous/mes-rendez-vous': (_) {
        essais++;
        if (essais == 1) throw http.ClientException('réseau coupé');
        return reponseJson(rendezVous());
      },
    }));

    expect(find.text('Chargement impossible'), findsOneWidget);
    expect(find.text('Connexion impossible. Vérifiez le réseau et l’adresse de l’API.'), findsOneWidget);

    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();

    expect(find.text('Chargement impossible'), findsNothing);
    expect(find.text('À venir (1)'), findsOneWidget);
  });

  testWidgets('demande de rendez-vous sans date ni heure : refusée avant tout envoi', (tester) async {
    final fausse = FausseApi({'/rendez-vous/mes-rendez-vous': (_) => reponseJson(<Object>[])});
    await afficher(tester, fausse);

    await tester.tap(find.text('Demander un rendez-vous').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Envoyer ma demande'));
    await tester.pumpAndSettle();

    expect(find.text('Choisissez une date et une heure.'), findsOneWidget);
    expect(fausse.appels.where((a) => a.startsWith('POST')), isEmpty);
  });
}
