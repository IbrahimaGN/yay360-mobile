import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/models.dart';
import '../state/auth_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.auth,
    required this.onOpenTab,
  });
  final AuthController auth;
  final ValueChanged<int> onOpenTab;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Pregnancy? _pregnancy;
  WeeklyFollowup? _weekly;
  List<Appointment> _appointments = [];
  bool _loading = true;
  String? _error;

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
      final pregnancyResult = await api.get('/grossesses/ma-grossesse');
      _pregnancy = Pregnancy.fromJson(pregnancyResult);
      try {
        _weekly = WeeklyFollowup.fromJson(
          await api.get('/grossesses/mon-suivi'),
        );
      } on ApiException {
        _weekly = null;
      }
    } on ApiException catch (exception) {
      _pregnancy = null;
      _weekly = null;
      if (exception.statusCode != 404) _error = exception.message;
    }

    try {
      final records = await api.getList('/rendez-vous/mes-rendez-vous/a-venir');
      _appointments =
          records
              .whereType<Map<String, dynamic>>()
              .map(Appointment.fromJson)
              .toList()
            ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    } on ApiException catch (exception) {
      _error ??= exception.message;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _startPregnancy() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PregnancyForm(
        api: widget.auth.api,
        onCreated: () {
          Navigator.pop(context);
          _load();
        },
      ),
    );
  }

  Future<void> _reportSymptom() async {
    final pregnancy = _pregnancy;
    if (pregnancy == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _SymptomForm(api: widget.auth.api, pregnancyId: pregnancy.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.auth.session!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            'Bonjour, ${session.firstName}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: context.yayInk,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Votre espace de suivi maternel',
            style: TextStyle(color: context.yayMuted),
          ),
          const SizedBox(height: 20),
          if (_error != null) ...[
            _ErrorCard(message: _error!, onRetry: _load),
            const SizedBox(height: 15),
          ],
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_pregnancy == null)
            MessagePanel(
              icon: Icons.favorite_outline,
              title: 'Votre suivi commence ici',
              message:
                  'Déclarez votre grossesse pour accéder à votre calendrier et aux repères de chaque semaine.',
              action: 'Déclarer ma grossesse',
              onAction: _startPregnancy,
            )
          else ...[
            _PregnancyCard(pregnancy: _pregnancy!),
            const SizedBox(height: 16),
            if (_weekly?.babyDevelopment?.isNotEmpty == true)
              _WeeklyCard(weekly: _weekly!, onTap: () => widget.onOpenTab(1))
            else
              MessagePanel(
                icon: Icons.auto_awesome_outlined,
                title: 'Votre repère de la semaine',
                message:
                    'Les conseils personnalisés seront affichés ici dès qu’ils seront disponibles.',
                action: 'Voir mon suivi',
                onAction: () => widget.onOpenTab(1),
              ),
            const SizedBox(height: 15),
            _ActionRow(
              onAppointment: () => widget.onOpenTab(2),
              onAlert: _reportSymptom,
            ),
          ],
          const SectionHeading('Prochain rendez-vous'),
          if (_loading)
            const LinearProgressIndicator()
          else if (_appointments.isEmpty)
            MessagePanel(
              icon: Icons.event_available_outlined,
              title: 'Pas de rendez-vous à venir',
              message:
                  'Pensez à organiser votre prochaine consultation prénatale.',
              action: 'Prendre rendez-vous',
              onAction: () => widget.onOpenTab(2),
            )
          else
            _AppointmentCard(appointment: _appointments.first),
          const SectionHeading('Vos repères YAY360'),
          const _FeatureTile(
            icon: Icons.favorite_outline,
            color: YayColors.rose,
            title: 'Un suivi à votre rythme',
            subtitle:
                'Des étapes et des informations adaptées à votre grossesse.',
          ),
          const SizedBox(height: 10),
          const _FeatureTile(
            icon: Icons.people_outline,
            color: YayColors.green,
            title: 'Ensemble dans cette aventure',
            subtitle:
                'Votre conjoint peut être invité à rejoindre le dossier familial.',
          ),
          const SizedBox(height: 14),
          Text(
            'YAY360 complète le suivi médical, mais ne remplace jamais l’avis d’un professionnel de santé.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.yayMuted,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PregnancyCard extends StatelessWidget {
  const _PregnancyCard({required this.pregnancy});
  final Pregnancy pregnancy;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(21),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(19),
      gradient: const LinearGradient(
        colors: [YayColors.green, Color(0xFF1E3F32)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: YayColors.green.withValues(alpha: .17),
          blurRadius: 22,
          offset: const Offset(0, 9),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.spa_outlined, color: Color(0xFFE9AFB9), size: 18),
            SizedBox(width: 8),
            Text(
              'VOTRE GROSSESSE',
              style: TextStyle(
                color: Color(0xFFE9AFB9),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${pregnancy.week ?? '—'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 53,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 7, left: 8),
              child: Text(
                'semaines',
                style: TextStyle(color: Color(0xFFD6E4DA), fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: LinearProgressIndicator(
            value: ((pregnancy.week ?? 0).clamp(0, 40)) / 40,
            minHeight: 7,
            backgroundColor: Colors.white.withValues(alpha: .2),
            valueColor: const AlwaysStoppedAnimation(YayColors.rose),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                pregnancy.trimester ?? 'Votre suivi prénatal',
                style: const TextStyle(color: Color(0xFFE4EEE6), fontSize: 12),
              ),
            ),
            if (pregnancy.daysRemaining != null)
              Text(
                '${pregnancy.daysRemaining} jours restants',
                style: const TextStyle(
                  color: Color(0xFFE4EEE6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        if (pregnancy.dueDate != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.event_outlined,
                  color: Colors.white70,
                  size: 17,
                ),
                const SizedBox(width: 9),
                Text(
                  'Date prévue : ${frenchDate(pregnancy.dueDate)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

class _WeeklyCard extends StatelessWidget {
  const _WeeklyCard({required this.weekly, required this.onTap});
  final WeeklyFollowup weekly;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ContentCard(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.yayRoseContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: YayColors.rose,
                size: 19,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cette semaine${weekly.week == null ? '' : ' · Semaine ${weekly.week}'}',
                    style: TextStyle(
                      color: context.yayInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    weekly.trimester ?? 'Un repère pour vous',
                    style: TextStyle(color: context.yayMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          weekly.babyDevelopment ?? '',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: context.yayMuted, fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.secondary,
            padding: EdgeInsets.zero,
          ),
          icon: const Icon(Icons.arrow_forward, size: 16),
          label: const Text('Découvrir mon suivi'),
        ),
      ],
    ),
  );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.onAppointment, required this.onAlert});
  final VoidCallback onAppointment;
  final VoidCallback onAlert;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _ActionButton(
          icon: Icons.calendar_month_outlined,
          title: 'Rendez-vous',
          subtitle: 'Organiser mon suivi',
          onTap: onAppointment,
        ),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: _ActionButton(
          icon: Icons.health_and_safety_outlined,
          title: 'Signaler',
          subtitle: 'Un symptôme',
          onTap: onAlert,
        ),
      ),
    ],
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: ContentCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, color: YayColors.rose, size: 21),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.yayInk,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(color: context.yayMuted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment});
  final Appointment appointment;

  @override
  Widget build(BuildContext context) => ContentCard(
    child: Row(
      children: [
        Container(
          width: 49,
          height: 53,
          decoration: BoxDecoration(
            color: context.yayTealContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${appointment.dateTime.day}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              Text(
                '${appointment.dateTime.month}/${appointment.dateTime.year}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appointmentType(appointment.type),
                style: TextStyle(
                  color: context.yayInk,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                frenchDate(appointment.dateTime, includeTime: true),
                style: TextStyle(color: context.yayMuted, fontSize: 11),
              ),
              if (appointment.facility?.isNotEmpty == true)
                Text(
                  appointment.facility!,
                  style: TextStyle(color: context.yayMuted, fontSize: 11),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => ContentCard(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        Icon(icon, color: color, size: 23),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.yayInk,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: context.yayMuted,
                  fontSize: 11,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ContentCard(
    child: Row(
      children: [
        Icon(
          Icons.wifi_off_outlined,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: TextStyle(color: context.yayInk, fontSize: 12),
          ),
        ),
        IconButton(
          onPressed: onRetry,
          icon: Icon(
            Icons.refresh,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ],
    ),
  );
}

class _PregnancyForm extends StatefulWidget {
  const _PregnancyForm({required this.api, required this.onCreated});
  final ApiClient api;
  final VoidCallback onCreated;

  @override
  State<_PregnancyForm> createState() => _PregnancyFormState();
}

class _PregnancyFormState extends State<_PregnancyForm> {
  DateTime? _period;
  int _previousPregnancies = 0;
  bool _sending = false;
  String? _error;

  Future<void> _selectPeriod() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year, now.month - 2, now.day),
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      locale: const Locale('fr', 'FR'),
      helpText: 'Premier jour des dernières règles',
    );
    if (date != null) setState(() => _period = date);
  }

  Future<void> _submit() async {
    if (_period == null) {
      setState(() => _error = 'Sélectionnez la date des dernières règles.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.api.post('/grossesses', {
        'dateDernieresRegles':
            '${_period!.year.toString().padLeft(4, '0')}-'
            '${_period!.month.toString().padLeft(2, '0')}-'
            '${_period!.day.toString().padLeft(2, '0')}',
        'nombreGrossessesPrecedentes': _previousPregnancies,
      });
      widget.onCreated();
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
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: Container(
      decoration: BoxDecoration(
        color: context.yayCanvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 25, 22, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Déclarer ma grossesse',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: context.yayInk,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ces informations permettent de calculer votre calendrier de suivi.',
              style: TextStyle(color: context.yayMuted, height: 1.5),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _selectPeriod,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(
                _period == null
                    ? 'Choisir la date des dernières règles'
                    : frenchDate(_period),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              initialValue: _previousPregnancies,
              decoration: const InputDecoration(
                labelText: 'Grossesses précédentes',
              ),
              items: List.generate(
                11,
                (index) =>
                    DropdownMenuItem(value: index, child: Text('$index')),
              ),
              onChanged: (value) =>
                  setState(() => _previousPregnancies = value ?? 0),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _sending ? null : _submit,
              child: _sending
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Enregistrer mon suivi'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SymptomForm extends StatefulWidget {
  const _SymptomForm({required this.api, required this.pregnancyId});
  final ApiClient api;
  final int pregnancyId;

  @override
  State<_SymptomForm> createState() => _SymptomFormState();
}

class _SymptomFormState extends State<_SymptomForm> {
  static const _symptoms = {
    'SAIGNEMENTS': 'Saignements',
    'DOULEURS_ABDOMINALES': 'Douleurs abdominales',
    'PERTE_LIQUIDE': 'Perte de liquide',
    'DIMINUTION_MOUVEMENTS_BEBE': 'Diminution des mouvements du bébé',
    'FIEVRE_ELEVEE': 'Fièvre élevée',
    'MAUX_DE_TETE_INTENSES': 'Maux de tête intenses',
    'OEDEMES_SOUDAINS': 'Œdèmes soudains',
    'VOMISSEMENTS_SEVERES': 'Vomissements sévères',
    'AUTRE': 'Autre',
  };
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
      setState(() => _error = 'Sélectionnez le symptôme à signaler.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.api.post('/alertes', {
        'grossesseId': widget.pregnancyId,
        'typeSymptome': _symptom,
        'description': _description.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Votre signalement a été transmis à l’équipe de suivi.',
          ),
        ),
      );
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
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: Container(
      decoration: BoxDecoration(
        color: context.yayCanvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 25, 22, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Signaler un symptôme',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: context.yayInk,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'En cas de symptôme urgent, recherchez immédiatement une aide médicale.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _symptom,
              decoration: const InputDecoration(labelText: 'Symptôme'),
              items: _symptoms.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _symptom = value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Détails (facultatif)',
                alignLabelWithHint: true,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 17),
            FilledButton(
              onPressed: _sending ? null : _submit,
              child: _sending
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Transmettre le signalement'),
            ),
          ],
        ),
      ),
    ),
  );
}
