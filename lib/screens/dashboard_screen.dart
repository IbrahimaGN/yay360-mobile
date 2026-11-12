import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/models.dart';
import '../state/auth_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/symptom_sheet.dart';

/// Accueil de la patiente et du conjoint : grossesse, actions rapides, prochain
/// rendez-vous, consultations prénatales (OMS) et repère de la semaine.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.auth, required this.onOpenTab});
  final AuthController auth;
  final ValueChanged<int> onOpenTab;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Pregnancy? _pregnancy;
  WeeklyFollowup? _weekly;
  CpnPlan? _plan;
  List<Appointment> _appointments = [];
  bool _loading = true;
  String? _error;

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
    final api = widget.auth.api;
    try {
      _pregnancy = Pregnancy.fromJson(await api.get('/grossesses/ma-grossesse'));
      // Blocs secondaires : leur échec n'empêche pas d'afficher le reste
      try {
        _weekly = WeeklyFollowup.fromJson(await api.get('/grossesses/mon-suivi'));
      } on ApiException {
        _weekly = null;
      }
      try {
        _plan = CpnPlan.fromJson(await api.get('/grossesses/mon-plan-cpn'));
      } on ApiException {
        _plan = null;
      }
    } on ApiException catch (exception) {
      _pregnancy = null;
      _weekly = null;
      _plan = null;
      if (exception.statusCode != 404) _error = exception.message;
    }

    try {
      final records = await api.getList('/rendez-vous/mes-rendez-vous/a-venir');
      _appointments = records.whereType<Map<String, dynamic>>().map(Appointment.fromJson).toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    } on ApiException catch (exception) {
      _error ??= exception.message;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _startPregnancy() async {
    final cree = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => PregnancyForm(api: widget.auth.api),
    );
    if (cree == true) _load();
  }

  Future<void> _reportSymptom() async {
    final pregnancy = _pregnancy;
    if (pregnancy == null) return;
    await reportSymptom(context, api: widget.auth.api, pregnancyId: pregnancy.id);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.yay;
    final session = widget.auth.session!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text('Bonjour, ${session.firstName}',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: p.textMain)),
          const SizedBox(height: 2),
          Text(
            _estFemme ? 'Votre espace de suivi maternel' : 'Le suivi de grossesse que vous partagez',
            style: TextStyle(color: p.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 18),
          if (_error != null) ...[
            _ErreurChargement(message: _error!, onRetry: _load),
            const SizedBox(height: 14),
          ],
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator(semanticsLabel: 'Chargement de votre suivi')),
            )
          else if (_pregnancy == null)
            _SansGrossesse(estFemme: _estFemme, onDeclare: _startPregnancy)
          else ...[
            _CarteGrossesse(pregnancy: _pregnancy!),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionRapide(
                    icone: Icons.calendar_month_outlined,
                    titre: 'Demander un rendez-vous',
                    fond: p.tealSoft,
                    couleur: p.tealInk,
                    onTap: () => widget.onOpenTab(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionRapide(
                    icone: Icons.warning_amber_rounded,
                    titre: 'Signaler un symptôme',
                    fond: p.dangerSoft,
                    couleur: p.danger,
                    onTap: _reportSymptom,
                  ),
                ),
              ],
            ),
          ],
          if (!_loading) ...[
            SectionHeading('Prochain rendez-vous',
                action: _appointments.isEmpty ? null : 'Tout voir', onAction: () => widget.onOpenTab(2)),
            if (_appointments.isEmpty)
              MessagePanel(
                icon: Icons.event_available_outlined,
                title: 'Pas de rendez-vous à venir',
                message: 'Pensez à organiser votre prochaine consultation prénatale.',
                action: 'Demander un rendez-vous',
                onAction: () => widget.onOpenTab(2),
              )
            else
              _CarteRendezVous(appointment: _appointments.first),
            if (_plan != null && _plan!.contacts.isNotEmpty) ...[
              const SectionHeading('Consultations prénatales'),
              _CartePlanCpn(plan: _plan!),
            ],
            if (_pregnancy != null) ...[
              SectionHeading('Conseils de la semaine', action: 'Voir mon suivi', onAction: () => widget.onOpenTab(1)),
              _CarteSemaine(weekly: _weekly, onTap: () => widget.onOpenTab(1)),
            ],
            const SizedBox(height: 16),
            const YayNotice(kind: NoticeKind.warning, message: messageUrgence),
            const SizedBox(height: 14),
            Text(
              'YAY360 complète le suivi médical, mais ne remplace jamais l’avis d’un professionnel de santé.',
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textMuted, fontSize: 12, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

// ==================== Grossesse ====================

class _CarteGrossesse extends StatelessWidget {
  const _CarteGrossesse({required this.pregnancy});
  final Pregnancy pregnancy;

  @override
  Widget build(BuildContext context) {
    final p = context.yay;
    final semaine = pregnancy.week ?? 0;
    final couleur = pregnancy.atRisk ? p.viz2 : p.viz1;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.borderLight, width: 1.5),
      ),
      child: Row(
        children: [
          ProgressRing(
            value: semaine / 40,
            color: couleur,
            semanticsLabel: 'Semaine $semaine sur 40',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$semaine', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600, color: p.tealInk, height: 1)),
                Text('sur 40 sem.', style: TextStyle(fontSize: 11, color: p.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ma grossesse', style: TextStyle(fontSize: 13, color: p.textMuted, fontWeight: FontWeight.w500)),
                Text(trimesterLabel(pregnancy.trimester),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: p.textMain)),
                if (pregnancy.atRisk) ...[
                  const SizedBox(height: 6),
                  StatusPill('Suivi renforcé', background: p.orangeSoft, foreground: p.orangeInk, icon: Icons.shield_outlined),
                ],
                const SizedBox(height: 10),
                if (pregnancy.dueDate != null)
                  _Fait(icone: Icons.event_outlined, texte: 'Terme estimé : ${frenchDate(pregnancy.dueDate)}'),
                if (pregnancy.termStart != null && pregnancy.termEnd != null) ...[
                  const SizedBox(height: 4),
                  _Fait(
                    icone: Icons.date_range_outlined,
                    texte: 'À terme entre le ${frenchDate(pregnancy.termStart)} et le ${frenchDate(pregnancy.termEnd)}',
                  ),
                ],
                if (pregnancy.daysRemaining != null) ...[
                  const SizedBox(height: 4),
                  _Fait(icone: Icons.hourglass_bottom, texte: '${pregnancy.daysRemaining} jours restants'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Fait extends StatelessWidget {
  const _Fait({required this.icone, required this.texte});
  final IconData icone;
  final String texte;

  @override
  Widget build(BuildContext context) {
    final p = context.yay;
    return Row(
      children: [
        Icon(icone, size: 15, color: p.tealInk),
        const SizedBox(width: 6),
        Expanded(child: Text(texte, style: TextStyle(fontSize: 13, color: p.textMain))),
      ],
    );
  }
}

class _SansGrossesse extends StatelessWidget {
  const _SansGrossesse({required this.estFemme, required this.onDeclare});
  final bool estFemme;
  final VoidCallback onDeclare;

  @override
  Widget build(BuildContext context) {
    final p = context.yay;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.borderLight, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: p.orangeSoft, shape: BoxShape.circle),
            child: Icon(Icons.favorite_border, color: p.orangeInk),
          ),
          const SizedBox(height: 12),
          Text(estFemme ? 'Votre suivi commence ici' : 'En attente de la déclaration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: p.textMain)),
          const SizedBox(height: 4),
          Text(
            estFemme
                ? 'Déclarez votre grossesse pour obtenir votre calendrier et les repères de chaque semaine.'
                : 'La grossesse apparaîtra ici dès que la future maman l’aura déclarée depuis son compte.',
            style: TextStyle(fontSize: 14, color: p.textMuted, height: 1.5),
          ),
          if (estFemme) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onDeclare,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Déclarer ma grossesse'),
            ),
          ],
        ],
      ),
    );
  }
}

// ==================== Actions rapides ====================

class _ActionRapide extends StatelessWidget {
  const _ActionRapide({required this.icone, required this.titre, required this.fond, required this.couleur, required this.onTap});
  final IconData icone;
  final String titre;
  final Color fond;
  final Color couleur;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.yay;
    return Semantics(
      button: true,
      child: Material(
        color: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: p.borderLight, width: 1.5),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icone, color: couleur, size: 22),
                ),
                const SizedBox(height: 10),
                Text(titre, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.textMain, height: 1.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== Rendez-vous ====================

class _CarteRendezVous extends StatelessWidget {
  const _CarteRendezVous({required this.appointment});
  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final p = context.yay;
    final (libelle, fond, texte) = appointmentStatus(context, appointment.status);
    final heure = '${appointment.dateTime.hour.toString().padLeft(2, '0')}h${appointment.dateTime.minute.toString().padLeft(2, '0')}';
    return ContentCard(
      child: Row(
        children: [
          DateBlock(appointment.dateTime),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appointmentType(appointment.type),
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: p.textMain)),
                const SizedBox(height: 2),
                Text(
                  [heure, if (appointment.facility?.isNotEmpty == true) appointment.facility!].join(' · '),
                  style: TextStyle(color: p.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 8),
                StatusPill(libelle, background: fond, foreground: texte),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== Plan CPN (OMS) ====================

class _CartePlanCpn extends StatelessWidget {
  const _CartePlanCpn({required this.plan});
  final CpnPlan plan;

  @override
  Widget build(BuildContext context) {
    final p = context.yay;
    return ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${plan.done} sur ${plan.contacts.length} consultations réalisées',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: p.textMain),
          ),
          if (plan.late > 0) ...[
            const SizedBox(height: 6),
            StatusPill('${plan.late} en retard', background: p.dangerSoft, foreground: p.danger, icon: Icons.schedule),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              for (final c in plan.contacts) Expanded(child: _PointCpn(contact: c)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _Legende(couleur: p.tealDark, plein: true, texte: 'Réalisée'),
              _Legende(couleur: p.orange, plein: true, texte: 'Planifiée'),
              _Legende(couleur: p.danger, plein: false, texte: 'En retard'),
              _Legende(couleur: p.borderStrong, plein: false, texte: 'À venir'),
            ],
          ),
          if (plan.reference?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(plan.reference!, style: TextStyle(fontSize: 12, color: p.textMuted)),
          ],
        ],
      ),
    );
  }
}

class _PointCpn extends StatelessWidget {
  const _PointCpn({required this.contact});
  final CpnContact contact;

  @override
  Widget build(BuildContext context) {
    final p = context.yay;
    final (fond, bord, texte, libelle) = switch (contact.status) {
      'REALISE' => (p.tealDark, p.tealDark, p.onStrong, 'réalisée'),
      'PLANIFIE' => (p.orange, p.orangeLine, p.onAccent, 'planifiée'),
      'EN_RETARD' => (p.surface, p.danger, p.danger, 'en retard'),
      _ => (p.surface, p.borderStrong, p.textMuted, 'à venir'),
    };
    return Semantics(
      label: 'Consultation ${contact.number}, ${contact.targetWeek} semaines, $libelle',
      excludeSemantics: true,
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: fond, shape: BoxShape.circle, border: Border.all(color: bord, width: 1.5)),
            child: Center(
              child: contact.status == 'REALISE'
                  ? Icon(Icons.check, size: 16, color: texte)
                  : Text('${contact.number}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: texte)),
            ),
          ),
          const SizedBox(height: 4),
          Text('${contact.targetWeek}', style: TextStyle(fontSize: 11, color: p.textMuted)),
        ],
      ),
    );
  }
}

class _Legende extends StatelessWidget {
  const _Legende({required this.couleur, required this.plein, required this.texte});
  final Color couleur;
  final bool plein;
  final String texte;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: plein ? couleur : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: couleur, width: 1.5),
        ),
      ),
      const SizedBox(width: 5),
      Text(texte, style: TextStyle(fontSize: 12, color: context.yay.textMuted)),
    ],
  );
}

// ==================== Semaine ====================

class _CarteSemaine extends StatelessWidget {
  const _CarteSemaine({required this.weekly, required this.onTap});
  final WeeklyFollowup? weekly;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.yay;
    final w = weekly;
    final items = <(IconData, String, String?, Color, Color)>[
      (Icons.child_care_outlined, 'Le bébé', w?.babyDevelopment, p.tealSoft, p.tealInk),
      (Icons.person_outline, 'Pour vous', w?.motherChanges, p.orangeSoft, p.orangeInk),
      (Icons.flag_outlined, 'Objectifs santé', w?.healthGoals, p.lilacSoft, p.lilacInk),
    ].where((e) => e.$3?.isNotEmpty == true).toList();
    if (items.isEmpty) {
      return MessagePanel(
        icon: Icons.auto_awesome_outlined,
        title: 'Votre repère de la semaine',
        message: 'Les conseils de votre semaine s’afficheront ici dès qu’ils seront disponibles.',
        action: 'Voir mon suivi',
        onAction: onTap,
      );
    }
    return ContentCard(
      child: Column(
        children: [
          for (final (i, e) in items.indexed) ...[
            if (i > 0) const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: e.$4, borderRadius: BorderRadius.circular(10)),
                  child: Icon(e.$1, size: 19, color: e.$5),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.$2, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: p.textMain)),
                      Text(e.$3!, maxLines: 3, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: p.textMuted, height: 1.5)),
                    ],
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

class _ErreurChargement extends StatelessWidget {
  const _ErreurChargement({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      YayNotice(kind: NoticeKind.error, title: 'Chargement incomplet', message: message),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh, size: 18), label: const Text('Réessayer')),
      ),
    ],
  );
}

// ==================== Déclaration de la grossesse ====================

class PregnancyForm extends StatefulWidget {
  const PregnancyForm({super.key, required this.api});
  final ApiClient api;

  @override
  State<PregnancyForm> createState() => PregnancyFormState();
}

class PregnancyFormState extends State<PregnancyForm> {
  DateTime? _period;
  int _previousPregnancies = 0;
  bool _sending = false;
  String? _error;

  Future<void> _selectPeriod() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _period ?? DateTime(now.year, now.month - 2, now.day),
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      locale: const Locale('fr', 'FR'),
      helpText: 'Premier jour des dernières règles',
    );
    if (date != null) setState(() => _period = date);
  }

  Future<void> _submit() async {
    if (_period == null) {
      setState(() => _error = 'Choisissez la date des dernières règles.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final d = _period!;
      await widget.api.post('/grossesses', {
        'dateDernieresRegles':
            '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
        'nombreGrossessesPrecedentes': _previousPregnancies,
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (exception) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = exception.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.yay;
    return FeuilleModale(
      children: [
        Text('Déclarer ma grossesse', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: p.textMain)),
        const SizedBox(height: 4),
        Text(
          'La date des dernières règles suffit pour calculer votre terme et votre calendrier.',
          style: TextStyle(color: p.textMuted, height: 1.5, fontSize: 13),
        ),
        const SizedBox(height: 18),
        InkWell(
          onTap: _selectPeriod,
          borderRadius: BorderRadius.circular(14),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Premier jour des dernières règles',
              prefixIcon: Icon(Icons.event_outlined),
              suffixIcon: Icon(Icons.calendar_month_outlined),
            ),
            isEmpty: _period == null,
            child: Text(_period == null ? '' : frenchDate(_period), style: TextStyle(color: p.textMain, fontSize: 15)),
          ),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<int>(
          initialValue: _previousPregnancies,
          decoration: const InputDecoration(
            labelText: 'Grossesses précédentes',
            prefixIcon: Icon(Icons.family_restroom_outlined),
          ),
          items: List.generate(11, (i) => DropdownMenuItem(value: i, child: Text('$i'))),
          onChanged: (value) => setState(() => _previousPregnancies = value ?? 0),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          YayNotice(kind: NoticeKind.error, message: _error!),
        ],
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _sending ? null : _submit,
          child: Text(_sending ? 'Enregistrement…' : 'Enregistrer ma grossesse'),
        ),
      ],
    );
  }
}
