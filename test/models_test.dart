import 'package:flutter_test/flutter_test.dart';
import 'package:yay360_mobile/data/models.dart';

void main() {
  group('UserSession', () {
    test('lit et sérialise la réponse de connexion de l’API', () {
      final session = UserSession.fromJson({
        'token': 'jwt-token',
        'id': 12,
        'email': 'fatou@example.sn',
        'prenom': 'Fatou',
        'nom': 'Ndiaye',
        'role': 'FEMME_ENCEINTE',
      });

      expect(session.firstName, 'Fatou');
      expect(session.role, 'FEMME_ENCEINTE');
      expect(UserSession.fromJson(session.toJson()).token, 'jwt-token');
    });
  });

  group('Suivi prénatal', () {
    test('lit la grossesse et ses dates calculées par l’API', () {
      final pregnancy = Pregnancy.fromJson({
        'id': 4,
        'statut': 'EN_COURS',
        'semaineActuelle': 18,
        'dateDernieresRegles': '2026-01-01',
        'datePrevueAccouchement': '2026-10-08',
        'joursRestants': 60,
        'grossesseARisque': false,
      });

      expect(pregnancy.week, 18);
      expect(pregnancy.dueDate, DateTime(2026, 10, 8));
      expect(pregnancy.daysRemaining, 60);
    });

    test('lit le contenu du suivi hebdomadaire et l’avertissement médical', () {
      final followup = WeeklyFollowup.fromJson({
        'semaineActuelle': 18,
        'trimestre': 'Deuxième trimestre',
        'developpementBebe': 'Bébé grandit.',
        'signesAlerte': 'Contactez un professionnel.',
        'avertissement': 'Ces conseils ne remplacent pas un avis médical.',
      });

      expect(followup.week, 18);
      expect(followup.babyDevelopment, 'Bébé grandit.');
      expect(followup.warning, contains('avis médical'));
    });
  });
}
