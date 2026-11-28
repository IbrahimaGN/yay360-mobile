import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:yay360_mobile/screens/auth_screen.dart';
import 'package:yay360_mobile/state/auth_controller.dart';

/// Session fictive renvoyée par la fausse API (données de démonstration).
Map<String, dynamic> session({String? refresh}) => {
  'token': 'jwt-fictif',
  'id': 7,
  'email': 'awa.demo@exemple.sn',
  'nom': 'Ndiaye',
  'prenom': 'Awa',
  'role': 'FEMME_ENCEINTE',
  'motDePasseTemporaire': false,
  'jetonRafraichissement': refresh,
};

http.Response json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8'});

Widget app(AuthController auth) => MaterialApp(
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  supportedLocales: const [Locale('fr', 'FR')],
  home: AuthScreen(auth: auth),
);

/// Fait défiler jusqu'à l'élément (écran de test de 800 × 600) puis le touche.
Future<void> appuyer(WidgetTester tester, String texte) async {
  final cible = find.text(texte);
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('accueil : connexion par téléphone, onglet e-mail et invitation du conjoint', (tester) async {
    await tester.pumpWidget(app(AuthController()));

    expect(find.text('Votre grossesse,\naccompagnée avec soin.'), findsOneWidget);
    expect(find.text('Numéro de téléphone'), findsOneWidget);
    expect(find.text('Téléphone'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('J’ai reçu une invitation de mon conjoint'), findsOneWidget);

    await appuyer(tester, 'E-mail');
    expect(find.text('Adresse e-mail'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);
  });

  testWidgets('compte avec PIN : téléphone puis PIN, sans « rester connectée » rien n’est enregistré', (tester) async {
    final requetes = <http.Request>[];
    final auth = AuthController(client: MockClient((request) async {
      requetes.add(request);
      if (request.url.path.endsWith('/auth/mobile/demarrer')) {
        return json({'etape': 'PIN', 'message': 'Saisissez votre code PIN.'});
      }
      if (request.url.path.endsWith('/auth/mobile/connexion')) return json(session());
      return json({'message': 'inattendu'}, 500);
    }));
    await tester.pumpWidget(app(auth));

    await tester.enterText(find.byType(TextFormField).first, '+221 77 000 00 01');
    await appuyer(tester, 'Continuer');

    expect(find.text('Bon retour !'), findsOneWidget);
    expect(find.text('PIN oublié ?'), findsOneWidget);
    await appuyer(tester, 'Rester connectée sur ce téléphone'); // décoche
    await tester.enterText(find.widgetWithText(TextFormField, 'Code PIN'), '2580');
    await appuyer(tester, 'Se connecter');

    final corps = jsonDecode(requetes.last.body) as Map<String, dynamic>;
    expect(corps, {'telephone': '+221770000001', 'pin': '2580', 'resterConnecte': false});
    expect(auth.session?.firstName, 'Awa');
    expect(await auth.api.readSession(), isNull); // non persistée
  });

  testWidgets('nouveau numéro : inscription, code reçu par e-mail, puis PIN (refus d’un PIN trop simple)', (tester) async {
    final auth = AuthController(client: MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/demarrer')) return json({'etape': 'INSCRIPTION'});
      if (path.endsWith('/inscription')) return json({'etape': 'CODE_ENVOYE', 'emailMasque': 'f****@exemple.sn'});
      if (path.endsWith('/verifier-code')) return json({'jetonPin': 'jeton-pin'});
      if (path.endsWith('/auth/mobile/pin')) return json(session(refresh: 'refresh-1'));
      return json({'message': 'inattendu'}, 500);
    }));
    await tester.pumpWidget(app(auth));

    await tester.enterText(find.byType(TextFormField).first, '+221770000002');
    await appuyer(tester, 'Continuer');
    expect(find.text('Créez votre espace'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Prénom'), 'Fatou');
    await tester.enterText(find.widgetWithText(TextFormField, 'Nom'), 'Diop');
    await tester.enterText(find.widgetWithText(TextFormField, 'Adresse e-mail'), 'fatou@exemple.sn');
    // Date de naissance : ouverture du calendrier et validation de la date proposée
    await appuyer(tester, 'Date de naissance');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await appuyer(tester, 'Recevoir mon code');

    expect(find.textContaining('f****@exemple.sn'), findsOneWidget);
    expect(find.textContaining('Renvoyer le code ('), findsOneWidget); // délai de 60 s
    await tester.enterText(find.widgetWithText(TextFormField, 'Code de vérification'), '123456');
    await appuyer(tester, 'Valider le code');
    expect(find.text('Choisissez votre code PIN'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Nouveau code PIN'), '1234');
    await tester.enterText(find.widgetWithText(TextFormField, 'Confirmez le code PIN'), '1234');
    await appuyer(tester, 'Valider mon PIN');
    expect(find.textContaining('Trop facile à deviner'), findsOneWidget);
    expect(auth.session, isNull);

    await tester.enterText(find.widgetWithText(TextFormField, 'Nouveau code PIN'), '2580');
    await tester.enterText(find.widgetWithText(TextFormField, 'Confirmez le code PIN'), '2580');
    await appuyer(tester, 'Valider mon PIN');

    expect(auth.session?.refreshToken, 'refresh-1');
    expect((await auth.api.readSession())?.refreshToken, 'refresh-1'); // « rester connectée » : persistée
    // Ne pas laisser le minuteur de renvoi actif après le test
    await tester.pumpWidget(const SizedBox());
  });

  test('au démarrage, la session longue est renouvelée par rotation du jeton', () async {
    FlutterSecureStorage.setMockInitialValues({
      'yay360.auth.token': 'jwt-ancien',
      'yay360.auth.session': jsonEncode(session(refresh: 'refresh-ancien')..['token'] = 'jwt-ancien'),
    });
    String? jetonEnvoye;
    final auth = AuthController(client: MockClient((request) async {
      jetonEnvoye = (jsonDecode(request.body) as Map<String, dynamic>)['jetonRafraichissement'] as String?;
      return json(session(refresh: 'refresh-nouveau'));
    }));

    await auth.restoreSession();

    expect(jetonEnvoye, 'refresh-ancien');
    expect(auth.session?.refreshToken, 'refresh-nouveau');
    expect((await auth.api.readSession())?.refreshToken, 'refresh-nouveau');
  });

  test('session longue révoquée ou expirée : retour à la connexion', () async {
    FlutterSecureStorage.setMockInitialValues({
      'yay360.auth.session': jsonEncode(session(refresh: 'refresh-revoque')),
    });
    final auth = AuthController(client: MockClient((_) async => json({'message': 'Session expirée'}, 401)));

    await auth.restoreSession();

    expect(auth.session, isNull);
    expect(await auth.api.readSession(), isNull);
  });

  test('validatePin applique la même règle que l’API', () {
    expect(validatePin('2580'), isNull);
    for (final faible in ['0000', '1234', '4321', '7777', '6789', '12a4', '123']) {
      expect(validatePin(faible), isNotNull, reason: faible);
    }
  });
}
