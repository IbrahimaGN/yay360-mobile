import 'package:flutter_test/flutter_test.dart';
import 'package:yay360_mobile/widgets/symptom_sheet.dart';

void main() {
  test('les symptômes proposés sont exactement ceux acceptés par l’API (DeclarerSymptomeRequest)', () {
    // Copie de l'expression régulière du backend : à mettre à jour avec elle.
    const acceptesParLApi = {
      'SAIGNEMENTS', 'DOULEURS_ABDOMINALES', 'PERTE_LIQUIDE', 'DIMINUTION_MOUVEMENTS_BEBE', 'FIEVRE_ELEVEE',
      'MAUX_DE_TETE_INTENSES', 'OEDEMES_SOUDAINS', 'VOMISSEMENTS_SEVERES', 'TROUBLES_VISUELS', 'CONVULSIONS',
      'DIFFICULTES_RESPIRATOIRES', 'AUTRE',
    };

    expect(symptomes.keys.toSet(), acceptesParLApi);
  });

  test('les difficultés respiratoires figurent dans le message d’urgence', () {
    expect(symptomes['DIFFICULTES_RESPIRATOIRES'], 'Difficultés à respirer');
    expect(messageUrgence, contains('difficultés à respirer'));
  });
}
