import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../data/api_client.dart';
import '../data/models.dart';
import '../state/auth_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/symptom_sheet.dart';

/// Suivi prénatal : repères de la semaine, signalement d'un symptôme et historique des signalements.
/// Remet un fichier à l'utilisatrice (feuille de partage du système : enregistrer, ouvrir, envoyer).
typedef PartagerFichier = Future<void> Function(Uint8List contenu, String nomFichier);

Future<void> partagerAvecLeSysteme(Uint8List contenu, String nomFichier) async {
  await SharePlus.instance.share(ShareParams(
    files: [XFile.fromData(contenu, mimeType: 'application/pdf', name: nomFichier)],
    fileNameOverrides: [nomFichier],
    subject: 'Mon dossier de grossesse YAY360',
  ));
}

class FollowupScreen extends StatefulWidget {
  const FollowupScreen({super.key, required this.auth, this.partager = partagerAvecLeSysteme});
  final AuthController auth;

  /// Remplaçable dans les tests (le partage passe par un canal natif).
  final PartagerFichier partager;

  @override
  State<FollowupScreen> createState() => _FollowupScreenState();
}

class _FollowupScreenState extends State<FollowupScreen> {
  Pregnancy? _pregnancy;
  WeeklyFollowup? _followup;
  List<Map<String, dynamic>> _alertes = [];
  bool _loading = true;
  String? _error;

  ApiClient get _api => widget.auth.api;
  bool _exportEnCours = false;

  /// Dossier PDF de la grossesse en cours : à montrer à un soignant, il remplace le carnet égaré.
  Future<void> _exporterDossier() async {
    setState(() => _exportEnCours = true);
    final messager = ScaffoldMessenger.of(context);
    try {
      final pdf = await _api.getBytes('/grossesses/ma-grossesse/export-pdf');
      final jour = DateTime.now().toIso8601String().substring(0, 10);
      await widget.partager(pdf, 'yay360-dossier-grossesse-$jour.pdf');
    } on ApiException catch (exception) {
      messager.showSnackBar(SnackBar(content: Text(exception.message)));
    } finally {
      if (mounted) setState(() => _exportEnCours = false);
    }
  }
  bool get _estFemme => widget.auth.session?.role == 'FEMME_ENCEINTE';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _pregnancy = Pregnancy.fromJson(await _api.get('/grossesses/ma-grossesse'));
      _followup = WeeklyFollowup.fromJson(await _api.get('/grossesses/mon-suivi'));
    } on ApiException catch (exception) {
      // 404 : aucune grossesse en cours, ce n'est pas une erreur
      if (exception.statusCode != 404) _error = exception.message;
      if (_pregnancy == null) _followup = null;
    }
    await _chargerAlertes();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _chargerAlertes() async {
    try {
      _alertes = (await _api.getList('/alertes/mes-alertes')).whereType<Map<String, dynamic>>().toList();
    } on ApiException {
      _alertes = [];
    }
  }

  Future<void> _signaler() async {
    final grossesse = _pregnancy;
    if (grossesse == null) return;
    final envoye = await reportSymptom(context, api: _api, pregnancyId: grossesse.id);
    if (envoye) {
      await _chargerAlertes();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.yay;
    final f = _followup;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        children: [
          Text(_estFemme ? 'Mon suivi' : 'Suivi prénatal',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: p.textMain)),
          const SizedBox(height: 2),
          Text('Des repères pour vivre chaque étape avec confiance.', style: TextStyle(color: p.textMuted, fontSize: 14)),
          const SizedBox(height: 18),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator(semanticsLabel: 'Chargement du suivi')),
            )
          else if (_error != null)
            MessagePanel(
              icon: Icons.cloud_off_outlined,
              title: 'Suivi indisponible',
              message: _error!,
              action: 'Réessayer',
              onAction: _load,
            )
          else if (_pregnancy == null)
            MessagePanel(
              icon: Icons.favorite_outline,
              title: 'Aucun suivi en cours',
              message: _estFemme
                  ? 'Déclarez votre grossesse depuis l’accueil pour voir les repères de chaque semaine.'
                  : 'Les repères s’afficheront dès que la future maman aura déclaré sa grossesse.',
            )
          else ...[
            _EnteteSemaine(pregnancy: _pregnancy!, followup: f),
            const SizedBox(height: 12),
            _CarteSignaler(onTap: _signaler),
            if (_estFemme) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _exportEnCours ? null : _exporterDossier,
                icon: _exportEnCours
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.picture_as_pdf_outlined),
                label: Text(_exportEnCours ? 'Préparation du dossier…' : 'Mon dossier en PDF'),
              ),
            ],
            if (f != null) ...[
              _Groupe(titre: 'Cette semaine', fiches: [
                _Fiche(Icons.child_care_outlined, 'Le développement du bébé', f.babyDevelopment, _Ton.teal),
                _Fiche(Icons.spa_outlined, _estFemme ? 'Les changements de votre corps' : 'Les changements chez la maman',
                    f.motherChanges, _Ton.orange),
                _Fiche(Icons.flag_outlined, 'Vos objectifs santé', f.healthGoals, _Ton.lilas),
              ]),
              _Groupe(titre: 'Au quotidien', fiches: [
                _Fiche(Icons.restaurant_outlined, 'Alimentation', f.foodAdvice, _Ton.orange),
                _Fiche(Icons.water_drop_outlined, 'Hydratation', f.hydrationAdvice, _Ton.teal),
                _Fiche(Icons.directions_walk_outlined, 'Activité physique', f.exercise, _Ton.lilas),
                _Fiche(Icons.bedtime_outlined, 'Sommeil', f.sleepAdvice, _Ton.teal),
              ]),
              _Groupe(titre: 'Vigilance', fiches: [
                _Fiche(Icons.health_and_safety_outlined, 'Précautions', f.precautions, _Ton.orange),
                _Fiche(Icons.warning_amber_rounded, 'Signes à surveiller', f.warningSigns, _Ton.danger),
              ]),
            ],
            SectionHeading(_estFemme ? 'Mes signalements' : 'Signalements'),
            if (_alertes.isEmpty)
              const MessagePanel(
                icon: Icons.check_circle_outline,
                title: 'Aucun signalement',
                message: 'Les symptômes signalés et leur prise en charge apparaîtront ici.',
              )
            else
              for (final a in _alertes.take(10)) ...[
                _LigneSignalement(alerte: a),
                const SizedBox(height: 8),
              ],
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: p.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    f?.warning?.isNotEmpty == true
                        ? f!.warning!
                        : 'Ces informations sont générales et ne remplacent jamais l’avis d’un professionnel de santé.',
                    style: TextStyle(color: p.textMuted, fontSize: 12, height: 1.5),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ==================== En-tête de la semaine ====================

class _EnteteSemaine extends StatelessWidget {
  const _EnteteSemaine({required this.pregnancy, required this.followup});
  final Pregnancy pregnancy;
  final WeeklyFollowup? followup;

  @override
  Widget build(BuildContext context) {
    final p = context.yay;
    final semaine = followup?.week ?? pregnancy.week ?? 0;
    final terme = followup?.dueDate ?? pregnancy.dueDate;
    final fin = Color.lerp(p.banner1, Colors.black, 0.25)!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(colors: [p.banner1, fin], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Row(
        children: [
          Semantics(
            label: 'Semaine $semaine',
            excludeSemantics: true,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$semaine', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w600, height: 1)),
                  const Text('SA', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Semaine $semaine', style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w600)),
                Text(trimesterLabel(followup?.trimester ?? pregnancy.trimester),
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
                if (terme != null)
                  Text('Terme estimé : ${frenchDate(terme)}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                if (pregnancy.atRisk) ...[
                  const SizedBox(height: 6),
                  StatusPill('Suivi renforcé', background: p.orange, foreground: p.onAccent, icon: Icons.shield_outlined),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CarteSignaler extends StatelessWidget {
  const _CarteSignaler({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.yay;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.dangerSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.dangerLine, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: p.danger),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Un symptôme inhabituel ?',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: p.textMain)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Signalez-le : il est classé par des règles validées et transmis à votre équipe de santé.',
              style: TextStyle(fontSize: 13, color: p.textMuted, height: 1.45)),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: p.dangerStrong,
              foregroundColor: p.onStrong,
              side: BorderSide(color: p.dangerStrong, width: 1.5),
              minimumSize: const Size(64, 46),
            ),
            onPressed: onTap,
            icon: const Icon(Icons.add_alert_outlined, size: 18),
            label: const Text('Signaler un symptôme'),
          ),
        ],
      ),
    );
  }
}

// ==================== Fiches de la semaine ====================

enum _Ton { teal, orange, lilas, danger }

class _Fiche {
  const _Fiche(this.icone, this.titre, this.contenu, this.ton);
  final IconData icone;
  final String titre;
  final String? contenu;
  final _Ton ton;
}

class _Groupe extends StatelessWidget {
  const _Groupe({required this.titre, required this.fiches});
  final String titre;
  final List<_Fiche> fiches;

  @override
  Widget build(BuildContext context) {
    final visibles = fiches.where((f) => f.contenu?.trim().isNotEmpty == true).toList();
    if (visibles.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeading(titre),
        for (final (i, f) in visibles.indexed) ...[
          if (i > 0) const SizedBox(height: 10),
          _CarteFiche(fiche: f),
        ],
      ],
    );
  }
}

class _CarteFiche extends StatelessWidget {
  const _CarteFiche({required this.fiche});
  final _Fiche fiche;

  @override
  Widget build(BuildContext context) {
    final p = context.yay;
    final (fond, couleur) = switch (fiche.ton) {
      _Ton.teal => (p.tealSoft, p.tealInk),
      _Ton.orange => (p.orangeSoft, p.orangeInk),
      _Ton.lilas => (p.lilacSoft, p.lilacInk),
      _Ton.danger => (p.dangerSoft, p.danger),
    };
    final danger = fiche.ton == _Ton.danger;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: danger ? p.dangerSoft : p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: danger ? p.dangerLine : p.borderLight, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: danger ? p.surface : fond, borderRadius: BorderRadius.circular(12)),
            child: Icon(fiche.icone, size: 20, color: couleur),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fiche.titre, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: p.textMain)),
                const SizedBox(height: 4),
                Text(fiche.contenu!, style: TextStyle(fontSize: 14, color: p.textMuted, height: 1.55)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== Signalements ====================

class _LigneSignalement extends StatelessWidget {
  const _LigneSignalement({required this.alerte});
  final Map<String, dynamic> alerte;

  @override
  Widget build(BuildContext context) {
    final p = context.yay;
    final niveau = alerte['niveauGravite'] as String?;
    final type = alerte['typeSymptome'] as String? ?? 'AUTRE';
    final libelle = type == 'CONSTANTES_ANORMALES'
        ? 'Constantes anormales (consultation)'
        : symptomes[type] ?? 'Autre symptôme';
    final date = DateTime.tryParse(alerte['dateDeclaration'] as String? ?? '');
    final (fondIcone, couleurIcone) = switch (niveau) {
      'URGENT' => (p.dangerSoft, p.danger),
      'ELEVE' => (p.warningSoft, p.warning),
      _ => (p.tealSoft, p.tealInk),
    };
    final (statut, fondStatut, texteStatut) = switch (alerte['statut'] as String?) {
      'RESOLUE' => ('Résolue', p.successSoft, p.success),
      'PRISE_EN_CHARGE' => ('Prise en charge', p.tealSoft, p.tealInk),
      _ => ('Nouvelle', p.orangeSoft, p.orangeInk),
    };
    return Semantics(
      button: true,
      label: '$libelle, niveau ${niveauLabel(niveau)}, $statut',
      excludeSemantics: true,
      child: Material(
        color: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: p.borderLight, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => showDialog<void>(context: context, builder: (_) => TriageDialog(alerte: alerte)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: fondIcone, borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.warning_amber_rounded, color: couleurIcone, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(libelle, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: p.textMain)),
                      Text(
                        [
                          if (niveau != null) 'Niveau ${niveauLabel(niveau).toLowerCase()}',
                          if (date != null) frenchDate(date),
                        ].join(' · '),
                        style: TextStyle(fontSize: 12, color: p.textMuted),
                      ),
                      const SizedBox(height: 6),
                      StatusPill(statut, background: fondStatut, foreground: texteStatut),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: p.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
