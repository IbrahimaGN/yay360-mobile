import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
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
    try {
      final result = await widget.api.getList('/rendez-vous/mes-rendez-vous');
      _appointments =
          result
              .whereType<Map<String, dynamic>>()
              .map(Appointment.fromJson)
              .toList()
            ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    } on ApiException catch (exception) {
      _error = exception.message;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _book() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BookingSheet(api: widget.api),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: _load,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mes rendez-vous',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.yayInk,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Le suivi prénatal, plus facile à organiser.',
                    style: TextStyle(color: context.yayMuted),
                  ),
                ],
              ),
            ),
            IconButton.filled(
              onPressed: _book,
              tooltip: 'Prendre rendez-vous',
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SectionHeading('À venir'),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          MessagePanel(
            icon: Icons.wifi_off_outlined,
            title: 'Chargement impossible',
            message: _error!,
            action: 'Réessayer',
            onAction: _load,
          )
        else if (_appointments.isEmpty)
          MessagePanel(
            icon: Icons.event_available_outlined,
            title: 'Aucun rendez-vous pour le moment',
            message:
                'Ajoutez votre prochaine consultation pour garder votre suivi organisé.',
            action: 'Prendre rendez-vous',
            onAction: _book,
          )
        else
          ..._appointments.map(
            (appointment) => Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: _AppointmentTile(appointment: appointment),
            ),
          ),
        const SizedBox(height: 14),
        ContentCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.secondary,
                size: 20,
              ),
              SizedBox(width: 11),
              Expanded(
                child: Text(
                  'Les demandes sont transmises à votre équipe de santé. Contactez directement votre centre pour toute confirmation urgente.',
                  style: TextStyle(
                    color: context.yayMuted,
                    fontSize: 12,
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile({required this.appointment});
  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final isCancelled = appointment.status == 'ANNULE';
    return ContentCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 53,
            height: 59,
            decoration: BoxDecoration(
              color: isCancelled
                  ? context.yayRoseContainer
                  : context.yayTealContainer,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${appointment.dateTime.day}',
                  style: TextStyle(
                    color: isCancelled
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSecondaryContainer,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${appointment.dateTime.month}/${appointment.dateTime.year}',
                  style: TextStyle(color: context.yayMuted, fontSize: 9),
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
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  frenchDate(appointment.dateTime, includeTime: true),
                  style: TextStyle(color: context.yayMuted, fontSize: 12),
                ),
                if (appointment.facility?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    appointment.facility!,
                    style: TextStyle(color: context.yayMuted, fontSize: 11),
                  ),
                ],
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isCancelled
                        ? context.yayRoseContainer
                        : context.yayTealContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _status(appointment.status),
                    style: TextStyle(
                      color: isCancelled
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSecondaryContainer,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _status(String status) => switch (status) {
    'CONFIRME' => 'Confirmé',
    'PLANIFIE' => 'Planifié',
    'TERMINE' => 'Terminé',
    'ANNULE' => 'Annulé',
    'ABSENT' => 'Absent',
    _ => status,
  };
}

class _BookingSheet extends StatefulWidget {
  const _BookingSheet({required this.api});
  final ApiClient api;

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  static const _types = {
    'CONSULTATION_PRENATALE': 'Consultation prénatale',
    'ECHOGRAPHIE': 'Échographie',
    'VACCINATION': 'Vaccination',
    'EXAMEN_LABORATOIRE': 'Examen de laboratoire',
    'AUTRE': 'Autre',
  };
  final _reason = TextEditingController();
  String _type = 'CONSULTATION_PRENATALE';
  DateTime? _dateTime;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      locale: const Locale('fr', 'FR'),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time != null) {
      setState(
        () => _dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (_dateTime == null || !_dateTime!.isAfter(DateTime.now())) {
      setState(
        () => _error = 'Choisissez une date et une heure dans le futur.',
      );
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    final date = _dateTime!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.api.post('/rendez-vous', {
        'dateHeure':
            '${date.year.toString().padLeft(4, '0')}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}T'
            '${date.hour.toString().padLeft(2, '0')}:'
            '${date.minute.toString().padLeft(2, '0')}:00',
        'type': _type,
        'motif': _reason.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context, true);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Votre demande de rendez-vous a été enregistrée.'),
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
              'Prendre rendez-vous',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: context.yayInk,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choisissez un créneau souhaité et votre type de consultation.',
              style: TextStyle(color: context.yayMuted, height: 1.5),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _selectDateTime,
              icon: const Icon(Icons.event_outlined),
              label: Text(
                _dateTime == null
                    ? 'Choisir une date et une heure'
                    : frenchDate(_dateTime, includeTime: true),
              ),
            ),
            const SizedBox(height: 13),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Type de rendez-vous',
              ),
              items: _types.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _type = value ?? _type),
            ),
            const SizedBox(height: 13),
            TextField(
              controller: _reason,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Motif (facultatif)',
              ),
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
                  : const Text('Envoyer ma demande'),
            ),
          ],
        ),
      ),
    ),
  );
}
