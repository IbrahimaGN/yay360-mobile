import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:yay360_mobile/data/models.dart';
import 'package:yay360_mobile/state/auth_controller.dart';
import 'package:yay360_mobile/theme.dart';

/// Réponse réelle de l'API, enregistrée dans test/contrats par tool/capturer_contrats.py.
dynamic contrat(String nom) => jsonDecode(File('test/contrats/$nom.json').readAsStringSync());

http.Response reponseJson(Object? corps, [int statut = 200]) => http.Response(
  jsonEncode(corps),
  statut,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

typedef RouteApi = FutureOr<http.Response> Function(http.Request requete);

/// Fausse API : chaque route (« GET /chemin » ou « /chemin ») renvoie la réponse prévue.
/// Les routes absentes répondent 404, comme l'API. Les appels reçus sont conservés dans [appels].
class FausseApi {
  FausseApi(this.routes);

  final Map<String, RouteApi> routes;
  final List<String> appels = [];

  late final MockClient client = MockClient((requete) async {
    final cle = '${requete.method} ${requete.url.path}';
    appels.add(cle);
    final route = routes[cle] ?? routes[requete.url.path];
    if (route == null) return reponseJson({'message': 'Ressource introuvable.'}, 404);
    return route(requete);
  });
}

/// Écran affiché comme dans l'application : thème YAY360 et textes système en français (calendriers…).
Widget appli(Widget ecran) => MaterialApp(
  theme: YayTheme.light,
  locale: const Locale('fr', 'FR'),
  supportedLocales: const [Locale('fr', 'FR')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: Scaffold(body: ecran),
);

/// Taille d'un téléphone courant (400 × 900 points), assez haute pour afficher tout l'écran testé.
void ecranTelephone(WidgetTester tester) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(1200, 2700);
  addTearDown(tester.view.reset);
}

/// Contrôleur déjà connecté, sans passer par l'écran de connexion.
AuthController connecte(http.Client client, {String role = 'FEMME_ENCEINTE', String prenom = 'Awa'}) =>
    AuthController(client: client)
      ..session = UserSession(
        token: 'jwt-factice',
        id: 14,
        email: 'awa.ndiaye.demo@yay360.sn',
        firstName: prenom,
        lastName: 'NDIAYE',
        role: role,
      );
