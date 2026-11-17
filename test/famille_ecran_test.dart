// Écran « Famille » : invitation du conjoint (validation, code à transmettre, erreurs), vue du conjoint, déconnexion.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yay360_mobile/data/models.dart';
import 'package:yay360_mobile/screens/family_screen.dart';
import 'package:yay360_mobile/state/auth_controller.dart';
import 'package:yay360_mobile/widgets/common.dart';

import 'outils/fausse_api.dart';

/// Réponse fictive de l'API à une invitation : [emailEnvoye] faux quand aucun e-mail n'a pu partir.
Map<String, dynamic> invitation({required bool emailEnvoye}) => {
  'message': emailEnvoye ? 'Invitation envoyée par e-mail.' : 'Invitation créée. Transmettez le code à votre conjoint.',
  'code': 'K7M2Q9',
  'dateExpiration': '2026-11-20T10:00:00',
  'emailEnvoye': emailEnvoye,
};

Future<void> afficher(WidgetTester tester, AuthController auth) async {
  ecranTelephone(tester);
  tester.view.physicalSize = const Size(1200, 6000); // écran entier, jusqu'au bouton de déconnexion
  await tester.pumpWidget(appli(FamilyScreen(auth: auth)));
  await tester.pumpAndSettle();
}

Future<void> inviter(WidgetTester tester, String email) async {
  await tester.enterText(find.byType(TextFormField), email);
  await tester.tap(find.text('Créer une invitation'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('adresse vide ou invalide : refusée avant tout envoi', (tester) async {
    final fausse = FausseApi({});
    await afficher(tester, connecte(fausse.client));

    await inviter(tester, '');
    expect(find.text('Saisissez l’adresse e-mail de votre conjoint.'), findsOneWidget);
    await inviter(tester, 'ibrahima.fall');
    expect(find.text('Adresse e-mail invalide.'), findsOneWidget);
    expect(fausse.appels, isEmpty);
  });

  testWidgets('e-mail non envoyé : le code s’affiche avec sa date limite et peut être copié', (tester) async {
    String? copie;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (appel) async {
      if (appel.method == 'Clipboard.setData') copie = (appel.arguments as Map)['text'] as String;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    Map<String, dynamic>? envoye;
    final fausse = FausseApi({
      'POST /famille/inviter-conjoint': (r) {
        envoye = jsonDecode(r.body) as Map<String, dynamic>;
        return reponseJson(invitation(emailEnvoye: false), 201);
      },
    });
    await afficher(tester, connecte(fausse.client));

    await inviter(tester, '  ibrahima.fall.demo@yay360.sn ');

    expect(envoye, {'email': 'ibrahima.fall.demo@yay360.sn'});
    expect(find.text('K7M2Q9'), findsOneWidget);
    expect(find.text('Valable jusqu’au ${frenchDate(DateTime(2026, 11, 20, 10), includeTime: true)}'), findsOneWidget);
    expect(find.text('Pour ibrahima.fall.demo@yay360.sn'), findsOneWidget);

    await tester.tap(find.text('Copier le code seul'));
    await tester.pumpAndSettle();
    expect(copie, 'K7M2Q9');
    expect(find.text('Code copié.'), findsOneWidget);
  });

  testWidgets('e-mail envoyé : pas de code affiché, seulement la confirmation', (tester) async {
    await afficher(tester, connecte(FausseApi({
      'POST /famille/inviter-conjoint': (_) => reponseJson(invitation(emailEnvoye: true), 201),
    }).client));

    await inviter(tester, 'ibrahima.fall.demo@yay360.sn');

    expect(find.text('Invitation envoyée par e-mail.'), findsOneWidget);
    expect(find.text('K7M2Q9'), findsNothing);
    expect(find.text('Inviter une autre adresse'), findsOneWidget);
  });

  testWidgets('refus de l’API : son message s’affiche et le formulaire reste disponible', (tester) async {
    await afficher(tester, connecte(FausseApi({
      'POST /famille/inviter-conjoint': (_) =>
          reponseJson({'message': 'Un conjoint est déjà associé à ce dossier.'}, 409),
    }).client));

    await inviter(tester, 'autre.conjoint@exemple.sn');

    expect(find.text('Un conjoint est déjà associé à ce dossier.'), findsOneWidget);
    expect(find.text('Créer une invitation'), findsOneWidget);
  });

  testWidgets('le conjoint voit son accès partagé, sans pouvoir inviter', (tester) async {
    await afficher(tester, connecte(FausseApi({}).client, role: 'CONJOINT', prenom: 'Ibrahima'));

    expect(find.text('Votre accès au dossier partagé'), findsOneWidget);
    expect(find.text('Inviter votre conjoint'), findsNothing);
    expect(find.text('Conjoint'), findsOneWidget);
  });

  testWidgets('déconnexion confirmée : session révoquée côté serveur et effacée du téléphone', (tester) async {
    final fausse = FausseApi({'POST /auth/mobile/deconnexion': (_) => reponseJson(null, 204)});
    final auth = AuthController(client: fausse.client)
      ..session = const UserSession(token: 'jwt-factice', refreshToken: 'session-factice', id: 14,
          email: 'awa.ndiaye.demo@yay360.sn', firstName: 'Awa', lastName: 'NDIAYE', role: 'FEMME_ENCEINTE');
    await afficher(tester, auth);

    await tester.tap(find.text('Se déconnecter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(auth.session, isNotNull, reason: 'annuler ne déconnecte pas');

    await tester.tap(find.text('Se déconnecter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Déconnexion'));
    await tester.pumpAndSettle();

    expect(fausse.appels, ['POST /auth/mobile/deconnexion']);
    expect(auth.session, isNull);
  });
}
