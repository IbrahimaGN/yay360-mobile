import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Rendez-vous de la patiente (et du conjoint) : à venir, historique, demande d'un rendez-vous.
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<Appointment> _appointments = [];
  bool _loading = true;
  bool _historique = false;
  String? _error;

  static bool _actif(Appointment a) => a.status == 'PLANIFIE' || a.status == 'CONFIRME';

  /// À venir : rendez-vous actifs dont l'heure n'est pas passée, du plus proche au plus lointain.
  List<Appointment> get _aVenir {
    final maintenant = DateTime.now();
    return _appointments.where((a) => _actif(a) && a.dateTime.isAfter(maintenant)).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  /// Historique : tout le reste, du plus récent au plus ancien.
  List<Appointment> get _passes {
    final avenir = _aVenir.toSet();
    return _appointments.where((a) => !avenir.contains(a)).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

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
      final result = await widget.api.getList('/rendez-vous/mes-rendez-vous');
      _appointments = result.whereType<Map<String, dynamic>>().map(Appointment.fromJson).toList();
    } on ApiException catch (exception) {
      _error = exception.message;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _book() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BookingSheet(api: widget.api),
    );
    if (result == true) {
      setState(() => _historique = false);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demande envoyée : votre établissement confirmera la date.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.yay;
    final liste = _historique ? _passes : _aVenir;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        children: [
          Text('Mes rendez-vous', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: p.textMain)),
          const SizedBox(height: 2),
          Text('Le suivi prénatal, plus facile à organiser.', style: TextStyle(color: p.textMuted, fontSize: 14)),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _book,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Demander un rendez-vous'),
          ),
          const SizedBox(height: 16),
          _Onglets(
            historique: _historique,
            nbAVenir: _loading ? null : _aVenir.length,
            nbPasses: _loading ? null : _passes.length,
            onChanged: (h) => setState(() => _historique = h),
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator(semanticsLabel: 'Chargement des rendez-vous')),
            )
          else if (_error != null)
            MessagePanel(
              icon: Icons.cloud_off_outlined,
              title: 'Chargement impossible',
              message: _error!,
              action: 'Réessayer',
              onAction: _load,
            )
          else if (liste.isEmpty)
            _historique
                ? const MessagePanel(
                    icon: Icons.history,
                    title: 'Aucun rendez-vous passé',
                    message: 'Vos rendez-vous terminés ou annulés apparaîtront ici.',
                  )
                : MessagePanel(
                    icon: Icons.event_available_outlined,
                    title: 'Aucun rendez-vous à venir',
                    message: 'Demandez votre prochaine consultation pour garder votre suivi organisé.',
                    action: 'Demander un rendez-vous',
                    onAction: _book,
                  )
          else
            for (final a in liste) ...[
              _AppointmentTile(appointment: a, passe: _historique),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 8),
          const YayNotice(
            kind: NoticeKind.info,
            message: 'Les demandes sont transmises à votre établissement, qui confirme la date. '
                'Pour toute urgence, contactez-le directement.',
          ),
        ],
      ),
    );
  }
}

class _Onglets extends StatelessWidget {
  const _Onglets({required this.historique, required this.nbAVenir, required this.nbPasses, required this.onChanged});
  final bool historique;
  final int? nbAVenir;
  final int? nbPasses;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.yay;
    Widget onglet(String titre, int? nombre, bool actif, VoidCallback onTap) => Expanded(
      child: Semantics(
        button: true,
        selected: actif,
        child: Material(
          color: actif ? p.tealDark : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Center(
                child: Text(
                  nombre == null ? titre : '$titre ($nombre)',
                  style: TextStyle(color: actif ? p.onStrong : p.textMuted, fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.borderLight, width: 1.5),
      ),
      child: Row(
        children: [
          onglet('À venir', nbAVenir, !historique, () => onChanged(false)),
          const SizedBox(width: 4),
          onglet('Historique', nbPasses, historique, () => onChanged(true)),
        ],
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile({required this.appointment, required this.passe});
  final Appointment appointment;
  final bool passe;

  @override
  Widget build(BuildContext context) {
    final p = context.yay;
    final (libelle, fond, texte) = appointmentStatus(context, appointment.status);
    final d = appointment.dateTime;
    final heure = '${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';
    final details = [
      heure,
      if (appointment.facility?.isNotEmpty == true) appointment.facility!,
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.borderLight, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Opacity(opacity: passe ? 0.75 : 1, child: DateBlock(d)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appointmentType(appointment.type),
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: p.textMain)),
                const SizedBox(height: 2),
                Text(details, style: TextStyle(color: p.textMuted, fontSize: 13)),
                if (appointment.professional?.isNotEmpty == true)
                  Text(appointment.professional!, style: TextStyle(color: p.textMuted, fontSize: 13)),
                if (appointment.reason?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text('Motif : ${appointment.reason!}',
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: p.textMuted, fontSize: 12, fontStyle: FontStyle.italic)),
                ],
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

// ==================== Demande de rendez-vous ====================

class BookingSheet extends StatefulWidget {
  const BookingSheet({super.key, required this.api});
  final ApiClient api;

  @override
  State<BookingSheet> createState() => BookingSheetState();
}

class BookingSheetState extends State<BookingSheet> {
  static const _types = <(String, String, IconData)>[
    ('CONSULTATION_PRENATALE', 'Consultation prénatale', Icons.medical_services_outlined),
    ('ECHOGRAPHIE', 'Échographie', Icons.monitor_heart_outlined),
    ('VACCINATION', 'Vaccination', Icons.vaccines_outlined),
    ('EXAMEN_LABORATOIRE', 'Examen de laboratoire', Icons.science_outlined),
    ('AUTRE', 'Autre', Icons.event_note_outlined),
  ];
  final _reason = TextEditingController();
  String _type = 'CONSULTATION_PRENATALE';
  DateTime? _date;
  TimeOfDay? _time;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: DateTime(now.year + 1, now.month, now.day),
      locale: const Locale('fr', 'FR'),
      helpText: 'Date souhaitée',
    );
    if (date != null) setState(() => _date = date);
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Heure souhaitée',
    );
    if (time != null) setState(() => _time = time);
  }

  Future<void> _submit() async {
    final d = _date;
    final t = _time;
    if (d == null || t == null) {
      setState(() => _error = 'Choisissez une date et une heure.');
      return;
    }
    final quand = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    if (!quand.isAfter(DateTime.now())) {
      setState(() => _error = 'Choisissez une date et une heure dans le futur.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    String deux(int v) => v.toString().padLeft(2, '0');
    try {
      final motif = _reason.text.trim();
      await widget.api.post('/rendez-vous', {
        'dateHeure': '${quand.year}-${deux(quand.month)}-${deux(quand.day)}T${deux(quand.hour)}:${deux(quand.minute)}:00',
        'type': _type,
        if (motif.isNotEmpty) 'motif': motif,
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
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: p.tealSoft, borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.calendar_month_outlined, color: p.tealInk),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Demander un rendez-vous',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: p.textMain)),
                  Text('Votre établissement confirmera la date.', style: TextStyle(fontSize: 13, color: p.textMuted)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _Choix(
                label: 'Date souhaitée',
                valeur: _date == null ? null : frenchDate(_date),
                icone: Icons.event_outlined,
                onTap: _selectDate,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _Choix(
                label: 'Heure',
                valeur: _time == null ? null : '${_time!.hour.toString().padLeft(2, '0')}h${_time!.minute.toString().padLeft(2, '0')}',
                icone: Icons.schedule,
                onTap: _selectTime,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Type de rendez-vous', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.textMain)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (valeur, libelle, icone) in _types)
              ChoiceChip(
                avatar: Icon(icone, size: 18, color: _type == valeur ? p.onStrong : p.tealInk),
                showCheckmark: false,
                label: Text(libelle),
                selected: _type == valeur,
                onSelected: (_) => setState(() => _type = valeur),
              ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _reason,
          maxLines: 2,
          maxLength: 500,
          decoration: const InputDecoration(labelText: 'Motif (facultatif)', alignLabelWithHint: true),
        ),
        if (_error != null) ...[
          const SizedBox(height: 4),
          YayNotice(kind: NoticeKind.error, message: _error!),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _sending ? null : _submit,
          child: Text(_sending ? 'Envoi…' : 'Envoyer ma demande'),
        ),
      ],
    );
  }
}

/// Champ de choix (date ou heure) ouvrant un sélecteur.
class _Choix extends StatelessWidget {
  const _Choix({required this.label, required this.valeur, required this.icone, required this.onTap});
  final String label;
  final String? valeur;
  final IconData icone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: InputDecorator(
      isEmpty: valeur == null,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icone)),
      child: Text(valeur ?? '', style: TextStyle(color: context.yay.textMain, fontSize: 15)),
    ),
  );
}
