// Tests de contrat : les modèles du mobile lisent-ils correctement les réponses RÉELLES de l'API ?
// Les fichiers de test/contrats sont capturés sur l'API (tool/capturer_contrats.py, données fictives).
// Un champ renommé ou supprimé côté Java fait échouer ces tests au lieu de vider l'écran en silence.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yay360_mobile/data/models.dart';
import 'package:yay360_mobile/widgets/common.dart';

import 'outils/fausse_api.dart';

/// Vérifie que la réponse de l'API contient chaque champ lu par le mobile.
void contientLesChamps(Map<String, dynamic> reponse, List<String> champsLus) {
  for (final champ in champsLus) {
    expect(reponse.containsKey(champ), isTrue, reason: 'champ « $champ » absent de la réponse de l’API');
  }
}

void main() {
  test('connexion : la session est lue depuis la réponse de /auth/login', () {
    final brut = contrat('connexion') as Map<String, dynamic>;
    contientLesChamps(brut, ['token', 'id', 'email', 'prenom', 'nom', 'role', 'jetonRafraichissement']);

    final session = UserSession.fromJson(brut);
    expect(session.firstName, brut['prenom']);
    expect(session.lastName, brut['nom']);
    expect(session.role, 'FEMME_ENCEINTE');
    expect(session.id, brut['id']);
  });

  test('connexion mobile : l’étape renvoyée pour un numéro inconnu est comprise', () {
    final brut = contrat('demarrer_numero_inconnu') as Map<String, dynamic>;
    contientLesChamps(brut, ['etape', 'emailMasque', 'message']);

    final etape = MobileStart.fromJson(brut);
    expect(etape.step, 'INSCRIPTION');
    expect(etape.message, isNotEmpty);
  });

  test('grossesse en cours : terme, période à terme, semaine et risque', () {
    final brut = contrat('ma_grossesse') as Map<String, dynamic>;
    contientLesChamps(brut, [
      'id', 'statut', 'semaineActuelle', 'trimestre', 'datePrevueAccouchement', 'debutPeriodeTerme',
      'finPeriodeTerme', 'dateDernieresRegles', 'joursRestants', 'grossesseARisque',
    ]);

    final g = Pregnancy.fromJson(brut);
    expect(g.week, brut['semaineActuelle']);
    expect(trimesterLabel(g.trimester), isNot('Suivi prénatal'));
    expect(g.dueDate, DateTime.parse(brut['datePrevueAccouchement'] as String));
    expect(g.periodDate!.add(const Duration(days: 280)), g.dueDate, reason: 'règle de Naegele');
    expect(g.termStart!.isBefore(g.dueDate!) && g.termEnd!.isAfter(g.dueDate!), isTrue);
    expect(g.daysRemaining, brut['joursRestants']);
    expect(g.atRisk, brut['grossesseARisque']);
  });

  test('suivi de la semaine : conseils et avertissement médical', () {
    final brut = contrat('mon_suivi') as Map<String, dynamic>;
    contientLesChamps(brut, [
      'semaineActuelle', 'trimestre', 'developpementBebe', 'changementsMere', 'objectifsSante',
      'conseilsAlimentation', 'signesAlerte', 'avertissement',
    ]);

    final s = WeeklyFollowup.fromJson(brut);
    expect(s.week, brut['semaineActuelle']);
    expect(s.babyDevelopment, isNotEmpty);
    expect(s.warning, isNotEmpty, reason: 'l’avertissement « pas un diagnostic » doit toujours être fourni');
  });

  test('plan des consultations : les 8 contacts de l’OMS, avec des statuts connus du mobile', () {
    final brut = contrat('mon_plan_cpn') as Map<String, dynamic>;
    contientLesChamps(brut, ['contacts', 'nombreRealises', 'nombreEnRetard', 'reference']);
    contientLesChamps((brut['contacts'] as List).first as Map<String, dynamic>,
        ['numero', 'semaineCible', 'statut', 'dateCible']);

    final plan = CpnPlan.fromJson(brut);
    expect(plan.contacts.map((c) => c.targetWeek), [12, 20, 26, 30, 34, 36, 38, 40]);
    expect(plan.contacts.map((c) => c.status).toSet().difference({'REALISE', 'PLANIFIE', 'EN_RETARD', 'A_VENIR'}),
        isEmpty);
    expect(plan.done, brut['nombreRealises']);
    expect(plan.late, brut['nombreEnRetard']);
  });

  testWidgets('rendez-vous : chaque statut et chaque type renvoyés ont un libellé', (tester) async {
    final brut = (contrat('mes_rendez_vous') as List).cast<Map<String, dynamic>>();
    expect(brut, isNotEmpty);
    for (final r in brut) {
      contientLesChamps(r, ['id', 'dateHeure', 'type', 'statut', 'professionnelNomComplet', 'etablissementNom', 'motif']);
    }

    late BuildContext contexte;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (c) {
      contexte = c;
      return const SizedBox();
    })));
    final rendezVous = brut.map(Appointment.fromJson).toList();
    // Copie des constantes StatutRendezVous et TypeRendezVous du backend : à mettre à jour avec elles.
    const statutsApi = ['PLANIFIE', 'CONFIRME', 'ANNULE', 'TERMINE', 'ABSENT'];
    const typesApi = ['CONSULTATION_PRENATALE', 'ECHOGRAPHIE', 'VACCINATION', 'EXAMEN_LABORATOIRE'];
    for (final statut in {...statutsApi, ...rendezVous.map((r) => r.status)}) {
      final (libelle, _, _) = appointmentStatus(contexte, statut);
      expect(libelle, isNot(statut), reason: 'statut « $statut » sans libellé');
    }
    for (final type in {...typesApi, ...rendezVous.map((r) => r.type)}) {
      expect(appointmentType(type), isNot('Autre rendez-vous'), reason: 'type « $type » sans libellé');
    }
  });

  test('alerte : niveau, conduite, règles appliquées et avertissement pour le dialogue de triage', () {
    final brut = contrat('alerte') as Map<String, dynamic>;
    contientLesChamps(brut, ['niveauGravite', 'recommandation', 'justificationTriage', 'avertissement']);

    expect(['MODERE', 'ELEVE', 'URGENT'], contains(brut['niveauGravite']));
    expect(brut['recommandation'], isNotEmpty);
    expect((brut['justificationTriage'] as List).whereType<String>(), isNotEmpty);
    expect(brut['avertissement'], isNotEmpty);
  });
}
