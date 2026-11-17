// Écran d'accueil : affichage de la grossesse à partir des réponses réelles de l'API, cas sans grossesse,
// erreurs de chargement, et parcours complet de signalement d'un symptôme (accueil, formulaire, résultat).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:yay360_mobile/data/horloge.dart';
import 'package:yay360_mobile/screens/dashboard_screen.dart';

import 'outils/fausse_api.dart';

/// Toutes les routes de l'accueil, avec les réponses capturées sur l'API.
Map<String, RouteApi> routesAccueil() => {
  'GET /grossesses/ma-grossesse': (_) => reponseJson(contrat('ma_grossesse')),
  'GET /grossesses/mon-suivi': (_) => reponseJson(contrat('mon_suivi')),
  'GET /grossesses/mon-plan-cpn': (_) => reponseJson(contrat('mon_plan_cpn')),
  'GET /rendez-vous/mes-rendez-vous/a-venir': (_) => reponseJson([
    {...(contrat('mes_rendez_vous') as List).first as Map<String, dynamic>,
      'dateHeure': '2026-11-20T09:30:00', 'statut': 'CONFIRME', 'type': 'ECHOGRAPHIE'},
  ]),
};

Future<List<int>> afficher(WidgetTester tester, FausseApi fausse, {String role = 'FEMME_ENCEINTE'}) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(1200, 6000); // l'accueil est long : tout doit être construit
  addTearDown(tester.view.reset);
  final onglets = <int>[];
  await tester.pumpWidget(appli(DashboardScreen(auth: connecte(fausse.client, role: role), onOpenTab: onglets.add)));
  await tester.pumpAndSettle();
  return onglets;
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    Horloge.fixer(DateTime(2026, 11, 17, 10));
  });
  tearDown(Horloge.reinitialiser);

  testWidgets('grossesse en cours : semaine, terme, suivi renforcé, plan OMS et prochain rendez-vous', (tester) async {
    final semantique = tester.ensureSemantics(); // libellés lus par TalkBack et VoiceOver
    final onglets = await afficher(tester, FausseApi(routesAccueil()));
    final plan = contrat('mon_plan_cpn') as Map<String, dynamic>;

    expect(find.text('Bonjour, Awa'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Semaine 26 sur 40')), findsOneWidget);
    semantique.dispose();
    expect(find.text('2e trimestre'), findsOneWidget);
    expect(find.text('Suivi renforcé'), findsOneWidget);
    expect(find.text('Terme estimé : 27 février 2027'), findsOneWidget);
    expect(find.text('${plan['nombreRealises']} sur 8 consultations réalisées'), findsOneWidget);
    expect(find.text('Échographie'), findsOneWidget);
    expect(find.text('Le bébé'), findsOneWidget);
    expect(find.text('Chargement incomplet'), findsNothing);

    await tester.tap(find.text('Demander un rendez-vous'));
    await tester.tap(find.text('Voir mon suivi'));
    expect(onglets, [2, 1]);
  });

  testWidgets('sans grossesse déclarée : la patiente est invitée à la déclarer', (tester) async {
    final routes = routesAccueil()..remove('GET /grossesses/ma-grossesse'); // l'API répond 404
    await afficher(tester, FausseApi(routes));

    expect(find.text('Votre suivi commence ici'), findsOneWidget);
    expect(find.text('Déclarer ma grossesse'), findsOneWidget);
    expect(find.text('Chargement incomplet'), findsNothing, reason: 'un 404 n’est pas une erreur ici');
  });

  testWidgets('sans grossesse déclarée : le conjoint attend, sans pouvoir la déclarer', (tester) async {
    final routes = routesAccueil()..remove('GET /grossesses/ma-grossesse');
    await afficher(tester, FausseApi(routes), role: 'CONJOINT');

    expect(find.text('En attente de la déclaration'), findsOneWidget);
    expect(find.text('Déclarer ma grossesse'), findsNothing);
  });

  testWidgets('conseils de la semaine indisponibles : le reste de l’accueil s’affiche', (tester) async {
    final routes = routesAccueil()
      ..['GET /grossesses/mon-suivi'] = (_) => reponseJson({'message': 'Erreur interne'}, 500);
    await afficher(tester, FausseApi(routes));

    expect(find.text('2e trimestre'), findsOneWidget);
    expect(find.text('Votre repère de la semaine'), findsOneWidget);
    expect(find.text('Chargement incomplet'), findsNothing);
  });

  testWidgets('réseau absent : message d’erreur, puis « Réessayer » affiche la grossesse', (tester) async {
    var horsLigne = true;
    final routes = routesAccueil().map((cle, route) => MapEntry(cle, (http.Request r) {
      if (horsLigne) throw http.ClientException('réseau coupé');
      return route(r);
    }));
    await afficher(tester, FausseApi(routes));

    expect(find.text('Chargement incomplet'), findsOneWidget);
    expect(find.text('Connexion impossible. Vérifiez le réseau et l’adresse de l’API.'), findsOneWidget);

    horsLigne = false;
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();

    expect(find.text('Chargement incomplet'), findsNothing);
    expect(find.text('2e trimestre'), findsOneWidget);
  });

  testWidgets('signalement en trois écrans : accueil, formulaire, résultat du triage', (tester) async {
    Map<String, dynamic>? envoye;
    final routes = routesAccueil()
      ..['POST /alertes'] = (r) {
        envoye = jsonDecode(r.body) as Map<String, dynamic>;
        return reponseJson(contrat('alerte'), 201);
      };
    await afficher(tester, FausseApi(routes));

    // Écran 1 : accueil
    await tester.tap(find.text('Signaler un symptôme'));
    await tester.pumpAndSettle();
    // Écran 2 : formulaire
    expect(find.text('Quel symptôme ressentez-vous ?'), findsOneWidget);
    await tester.tap(find.text('Maux de tête intenses'));
    await tester.ensureVisible(find.text('Transmettre le signalement'));
    await tester.tap(find.text('Transmettre le signalement'));
    await tester.pumpAndSettle();
    // Écran 3 : résultat
    final alerte = contrat('alerte') as Map<String, dynamic>;
    expect(envoye, {'grossesseId': 1, 'typeSymptome': 'MAUX_DE_TETE_INTENSES'});
    expect(find.text('Urgence'), findsOneWidget);
    expect(find.text('Niveau Urgent'), findsOneWidget);
    expect(find.text(alerte['recommandation'] as String), findsOneWidget);
    expect(find.text(alerte['avertissement'] as String), findsOneWidget);
  });
}
