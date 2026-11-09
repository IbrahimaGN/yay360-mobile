import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:yay360_mobile/data/models.dart';
import 'package:yay360_mobile/screens/followup_screen.dart';
import 'package:yay360_mobile/state/auth_controller.dart';

/// Fausse API : grossesse en cours fictive et dossier PDF factice.
MockClient api(List<String> appels) => MockClient((request) async {
  appels.add(request.url.path);
  final path = request.url.path;
  if (path.endsWith('/export-pdf')) {
    return http.Response.bytes(utf8.encode('%PDF-fictif'), 200, headers: {'content-type': 'application/pdf'});
  }
  final corps = path.endsWith('/ma-grossesse')
      ? {'id': 3, 'statut': 'EN_COURS', 'semaineActuelle': 24, 'trimestre': 'T2'}
      : path.endsWith('/mon-suivi')
      ? {'semaineActuelle': 24}
      : <dynamic>[];
  return http.Response(jsonEncode(corps), 200, headers: {'content-type': 'application/json; charset=utf-8'});
});

AuthController session(String role, MockClient client) => AuthController(client: client)
  ..session = UserSession(token: 'jwt', id: 1, email: 'demo@exemple.sn', firstName: 'Awa', lastName: 'Démo', role: role);

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('la patiente partage son dossier PDF', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    addTearDown(tester.view.reset);
    final appels = <String>[];
    Uint8List? partage;
    String? nom;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FollowupScreen(
          auth: session('FEMME_ENCEINTE', api(appels)),
          partager: (contenu, fichier) async {
            partage = contenu;
            nom = fichier;
          },
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mon dossier en PDF'));
    await tester.pumpAndSettle();

    expect(appels, contains('/grossesses/ma-grossesse/export-pdf'));
    expect(utf8.decode(partage!), '%PDF-fictif');
    expect(nom, matches(RegExp(r'^yay360-dossier-grossesse-\d{4}-\d{2}-\d{2}\.pdf$')));
  });

  testWidgets('le conjoint ne voit pas l’export du dossier', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: FollowupScreen(auth: session('CONJOINT', api([])))),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Mon dossier en PDF'), findsNothing);
  });
}
