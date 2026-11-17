// Cas d'erreur du client HTTP : réseau absent, API en veille, session expirée, réponses anormales.
// Chaque erreur doit devenir un message compréhensible (ApiException), jamais un plantage.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:yay360_mobile/data/api_client.dart';
import 'package:yay360_mobile/data/models.dart';

import 'outils/fausse_api.dart';

const session = UserSession(
  token: 'jwt-ancien',
  id: 14,
  email: 'awa.ndiaye.demo@yay360.sn',
  firstName: 'Awa',
  lastName: 'NDIAYE',
  role: 'FEMME_ENCEINTE',
);

Matcher apiException(String message, [int? statut]) => isA<ApiException>()
    .having((e) => e.message, 'message', message)
    .having((e) => e.statusCode, 'statusCode', statut);

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('réseau absent : message de connexion impossible', () async {
    final api = ApiClient(client: MockClient((_) async => throw http.ClientException('réseau coupé')));

    await expectLater(api.get('/grossesses/ma-grossesse'),
        throwsA(apiException('Connexion impossible. Vérifiez le réseau et l’adresse de l’API.')));
  });

  testWidgets('API en veille : abandon après 20 s avec un message, sans bloquer l’écran', (tester) async {
    final api = ApiClient(client: MockClient((_) => Future.delayed(
      const Duration(seconds: 60),
      () => reponseJson({}),
    )));

    final appel = expectLater(api.get('/grossesses/ma-grossesse'),
        throwsA(apiException('Le serveur met trop de temps à répondre. Réessayez.')));
    await tester.pump(const Duration(seconds: 21));
    await appel;
    await tester.pump(const Duration(seconds: 40)); // laisse se terminer la fausse réponse tardive
  });

  test('session expirée sans « rester connectée » : session effacée et retour à la connexion', () async {
    var deconnexions = 0;
    final api = ApiClient(
      client: MockClient((_) async => reponseJson({'message': 'Session expirée'}, 401)),
      onUnauthorized: () => deconnexions++,
    );
    await api.saveSession(session, persist: false);

    await expectLater(api.get('/grossesses/ma-grossesse'), throwsA(apiException('Session expirée', 401)));
    expect(deconnexions, 1);
    expect(await api.readToken(), isNull);
  });

  test('session expirée avec « rester connectée » : jeton renouvelé puis requête rejouée', () async {
    final fausse = FausseApi({
      'POST /auth/mobile/rafraichir': (_) => reponseJson({
        ...session.toJson(),
        'token': 'jwt-nouveau',
        'jetonRafraichissement': 'session-2',
      }),
      'GET /grossesses/ma-grossesse': (requete) => requete.headers['Authorization'] == 'Bearer jwt-nouveau'
          ? reponseJson(contrat('ma_grossesse'))
          : reponseJson({'message': 'Jeton expiré'}, 401),
    });
    var deconnexions = 0;
    final api = ApiClient(client: fausse.client, onUnauthorized: () => deconnexions++);
    await api.saveSession(
      UserSession.fromJson({...session.toJson(), 'jetonRafraichissement': 'session-1'}),
      persist: false,
    );

    final grossesse = Pregnancy.fromJson(await api.get('/grossesses/ma-grossesse'));

    expect(grossesse.id, 1);
    expect(fausse.appels, [
      'GET /grossesses/ma-grossesse',
      'POST /auth/mobile/rafraichir',
      'GET /grossesses/ma-grossesse',
    ]);
    expect(deconnexions, 0);
    expect(await api.readToken(), 'jwt-nouveau');
  });

  test('erreur de l’API : son message est affiché tel quel', () async {
    final api = ApiClient(client: MockClient((requete) async => switch (requete.url.path) {
      '/message' => reponseJson({'message': 'Ce créneau est déjà pris.'}, 409),
      '/liste' => reponseJson({'errors': ['Date obligatoire', 'Type inconnu']}, 400),
      _ => http.Response('<html>Erreur interne</html>', 500),
    }));

    await expectLater(api.post('/message', {}), throwsA(apiException('Ce créneau est déjà pris.', 409)));
    await expectLater(api.post('/liste', {}), throwsA(apiException('Date obligatoire\nType inconnu', 400)));
    await expectLater(api.get('/autre'),
        throwsA(apiException('La demande a échoué. Réessayez dans quelques instants.', 500)));
  });

  test('réponse anormale du serveur : message clair au lieu d’un plantage', () async {
    final api = ApiClient(client: MockClient((requete) async => switch (requete.url.path) {
      '/illisible' => http.Response('<html>proxy</html>', 200),
      '/vide' => http.Response('', 204),
      _ => reponseJson({'id': 1}),
    }));

    await expectLater(api.get('/illisible'), throwsA(apiException('Le serveur a renvoyé une réponse illisible.')));
    expect(await api.get('/vide'), isEmpty);
    await expectLater(api.getList('/objet'), throwsA(apiException('Réponse inattendue du serveur.')));
  });
}
