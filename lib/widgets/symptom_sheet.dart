import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../theme.dart';
import 'common.dart';

/// Symptômes acceptés par l'API (mêmes libellés que le portail web).
const symptomes = {
  'SAIGNEMENTS': 'Saignements',
  'DOULEURS_ABDOMINALES': 'Douleurs abdominales intenses',
  'PERTE_LIQUIDE': 'Perte de liquide',
  'DIMINUTION_MOUVEMENTS_BEBE': 'Le bébé bouge moins',
  'FIEVRE_ELEVEE': 'Fièvre élevée',
  'CONVULSIONS': 'Convulsions',
  'DIFFICULTES_RESPIRATOIRES': 'Difficultés à respirer',
  'MAUX_DE_TETE_INTENSES': 'Maux de tête intenses',
  'TROUBLES_VISUELS': 'Troubles de la vue',
  'OEDEMES_SOUDAINS': 'Gonflement soudain (visage, mains)',
  'VOMISSEMENTS_SEVERES': 'Vomissements sévères',
  'AUTRE': 'Autre symptôme',
};

String niveauLabel(String? niveau) => switch (niveau) {
  'URGENT' => 'Urgent',
  'ELEVE' => 'Élevé',
  'MODERE' => 'Modéré',
  _ => niveau ?? '',
};

const messageUrgence =
    'En cas d’urgence (saignements, perte de liquide, convulsions, difficultés à respirer, forte fièvre…), '
    'rendez-vous immédiatement dans la structure de santé la plus proche.';

/// Ouvre le signalement, puis affiche la consigne renvoyée par les règles de triage.
/// Renvoie `true` si un signalement a été transmis.
Future<bool> reportSymptom(BuildContext context, {required ApiClient api, required int pregnancyId}) async {
  final reponse = await showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _SymptomSheet(api: api, pregnancyId: pregnancyId),
  );
  if (reponse != null && context.mounted) {
    await showDialog<void>(context: context, builder: (_) => TriageDialog(alerte: reponse));
  }
  return reponse != null;
}

class _SymptomSheet extends StatefulWidget {
  const _SymptomSheet({required this.api, required this.pregnancyId});
  final ApiClient api;
  final int pregnancyId;

  @override
  State<_SymptomSheet> createState() => _SymptomSheetState();
}

class _SymptomSheetState extends State<_SymptomSheet> {
  final _description = TextEditingController();
  String? _symptom;
  String? _error;
  bool _sending = false;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_symptom == null) {
      setState(() => _error = 'Choisissez le symptôme à signaler.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final description = _description.text.trim();
      final alerte = await widget.api.post('/alertes', {
        'grossesseId': widget.pregnancyId,
        'typeSymptome': _symptom,
        if (description.isNotEmpty) 'description': description,
      });
      if (mounted) Navigator.pop(context, alerte);
    } on ApiException catch (exception) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = '${exception.message} En cas d’urgence, rendez-vous immédiatement dans un établissement de santé.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.yay;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: p.dangerSoft, borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.warning_amber_rounded, color: p.danger),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Signaler un symptôme',
                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: p.textMain)),
                      Text('L’équipe de santé sera prévenue.', style: TextStyle(fontSize: 13, color: p.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const YayNotice(
              kind: NoticeKind.warning,
              message: 'En cas d’urgence, n’attendez pas : rendez-vous immédiatement dans la structure de santé la plus proche.',
            ),
            const SizedBox(height: 16),
            Text('Quel symptôme ressentez-vous ?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.textMain)),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: _symptom,
              onChanged: (v) => setState(() {
                _symptom = v;
                _error = null;
              }),
              child: Column(
                children: [
                  for (final e in symptomes.entries) ...[
                    _SymptomTile(valeur: e.key, libelle: e.value, choisi: _symptom == e.key,
                        onTap: () => setState(() {
                              _symptom = e.key;
                              _error = null;
                            })),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _description,
              maxLines: 3,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Précisions (facultatif)',
                hintText: 'Depuis quand, intensité…',
                alignLabelWithHint: true,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              YayNotice(kind: NoticeKind.error, message: _error!),
            ],
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: p.dangerStrong,
                foregroundColor: p.onStrong,
                side: BorderSide(color: p.dangerStrong, width: 1.5),
              ),
              onPressed: _sending ? null : _submit,
              child: Text(_sending ? 'Transmission…' : 'Transmettre le signalement'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SymptomTile extends StatelessWidget {
  const _SymptomTile({required this.valeur, required this.libelle, required this.choisi, required this.onTap});
  final String valeur;
  final String libelle;
  final bool choisi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.yay;
    return Material(
      color: choisi ? p.dangerSoft : p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: choisi ? p.danger : p.borderStrong, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Row(
            children: [
              Radio<String>(value: valeur),
              Expanded(
                child: Text(libelle,
                    style: TextStyle(
                      fontSize: 14,
                      color: choisi ? p.danger : p.textMain,
                      fontWeight: choisi ? FontWeight.w600 : FontWeight.w400,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Consigne renvoyée par les règles de triage : niveau, conduite à tenir, règles appliquées.
/// Ce n'est pas un diagnostic : l'avertissement de l'API est toujours affiché.
class TriageDialog extends StatelessWidget {
  const TriageDialog({super.key, required this.alerte});
  final Map<String, dynamic> alerte;

  @override
  Widget build(BuildContext context) {
    final p = context.yay;
    final niveau = alerte['niveauGravite'] as String?;
    final urgent = niveau == 'URGENT';
    final recommandation = alerte['recommandation'] as String? ?? '';
    final regles = (alerte['justificationTriage'] as List<dynamic>? ?? []).whereType<String>().toList();
    final avertissement = alerte['avertissement'] as String?;
    return AlertDialog(
      icon: Icon(urgent ? Icons.warning_amber_rounded : Icons.check_circle_outline,
          color: urgent ? p.danger : p.tealInk, size: 32),
      title: Text(urgent ? 'Urgence' : 'Signalement transmis'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (niveau != null)
              StatusPill(
                'Niveau ${niveauLabel(niveau)}',
                background: urgent ? p.dangerStrong : niveau == 'ELEVE' ? p.warningSoft : p.tealSoft,
                foreground: urgent ? p.onStrong : niveau == 'ELEVE' ? p.warning : p.tealInk,
                icon: Icons.rule,
              ),
            const SizedBox(height: 12),
            if (recommandation.isNotEmpty)
              YayNotice(
                kind: urgent ? NoticeKind.error : NoticeKind.info,
                title: 'Conduite recommandée par les règles',
                message: recommandation,
              ),
            if (regles.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Pourquoi ce niveau ?', style: TextStyle(fontWeight: FontWeight.w600, color: p.textMain, fontSize: 14)),
              const SizedBox(height: 6),
              for (final r in regles)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(padding: const EdgeInsets.only(top: 3), child: Icon(Icons.check, size: 14, color: p.tealInk)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(r, style: TextStyle(fontSize: 13, color: p.textMuted, height: 1.45))),
                    ],
                  ),
                ),
            ],
            if (avertissement != null && avertissement.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 14, color: p.textMuted),
                  const SizedBox(width: 6),
                  Expanded(child: Text(avertissement, style: TextStyle(fontSize: 12, color: p.textMuted, height: 1.45))),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('J’ai compris')),
      ],
    );
  }
}
