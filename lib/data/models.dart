class UserSession {
  const UserSession({
    required this.token,
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  final String token;
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;

  factory UserSession.fromJson(Map<String, dynamic> json) => UserSession(
    token: json['token'] as String,
    id: (json['id'] as num).toInt(),
    email: json['email'] as String,
    firstName: json['prenom'] as String,
    lastName: json['nom'] as String,
    role: json['role'] as String,
  );

  Map<String, dynamic> toJson() => {
    'token': token,
    'id': id,
    'email': email,
    'prenom': firstName,
    'nom': lastName,
    'role': role,
  };
}

class Pregnancy {
  const Pregnancy({
    required this.id,
    required this.status,
    this.week,
    this.trimester,
    this.dueDate,
    this.termStart,
    this.termEnd,
    this.periodDate,
    this.daysRemaining,
    this.atRisk = false,
  });

  final int id;
  final String status;
  final int? week;
  final String? trimester;
  /// Terme estimé (règle de Naegele : dernières règles + 280 jours), pas une date certaine.
  final DateTime? dueDate;

  /// Période d'accouchement à terme : 37 SA + 0 j à 41 SA + 6 j.
  final DateTime? termStart;
  final DateTime? termEnd;
  final DateTime? periodDate;
  final int? daysRemaining;
  final bool atRisk;

  factory Pregnancy.fromJson(Map<String, dynamic> json) => Pregnancy(
    id: (json['id'] as num).toInt(),
    status: json['statut'] as String? ?? 'EN_COURS',
    week: (json['semaineActuelle'] as num?)?.toInt(),
    trimester: json['trimestre'] as String?,
    dueDate: _date(json['datePrevueAccouchement']),
    termStart: _date(json['debutPeriodeTerme']),
    termEnd: _date(json['finPeriodeTerme']),
    periodDate: _date(json['dateDernieresRegles']),
    daysRemaining: (json['joursRestants'] as num?)?.toInt(),
    atRisk: json['grossesseARisque'] as bool? ?? false,
  );
}

class WeeklyFollowup {
  const WeeklyFollowup({
    this.week,
    this.trimester,
    this.dueDate,
    this.daysRemaining,
    this.babyDevelopment,
    this.motherChanges,
    this.healthGoals,
    this.foodAdvice,
    this.hydrationAdvice,
    this.exercise,
    this.sleepAdvice,
    this.precautions,
    this.warningSigns,
    this.warning,
  });

  final int? week;
  final String? trimester;
  final DateTime? dueDate;
  final int? daysRemaining;
  final String? babyDevelopment;
  final String? motherChanges;
  final String? healthGoals;
  final String? foodAdvice;
  final String? hydrationAdvice;
  final String? exercise;
  final String? sleepAdvice;
  final String? precautions;
  final String? warningSigns;
  final String? warning;

  factory WeeklyFollowup.fromJson(Map<String, dynamic> json) => WeeklyFollowup(
    week: (json['semaineActuelle'] as num?)?.toInt(),
    trimester: json['trimestre'] as String?,
    dueDate: _date(json['datePrevueAccouchement']),
    daysRemaining: (json['joursRestants'] as num?)?.toInt(),
    babyDevelopment: json['developpementBebe'] as String?,
    motherChanges: json['changementsMere'] as String?,
    healthGoals: json['objectifsSante'] as String?,
    foodAdvice: json['conseilsAlimentation'] as String?,
    hydrationAdvice: json['conseilsHydratation'] as String?,
    exercise: json['exercicesPhysiques'] as String?,
    sleepAdvice: json['conseilsSommeil'] as String?,
    precautions: json['precautions'] as String?,
    warningSigns: json['signesAlerte'] as String?,
    warning: json['avertissement'] as String?,
  );
}

class Appointment {
  const Appointment({
    required this.id,
    required this.dateTime,
    required this.type,
    required this.status,
    this.professional,
    this.facility,
    this.reason,
  });

  final int id;
  final DateTime dateTime;
  final String type;
  final String status;
  final String? professional;
  final String? facility;
  final String? reason;

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: (json['id'] as num).toInt(),
    dateTime: DateTime.parse(json['dateHeure'] as String),
    type: json['type'] as String? ?? 'CONSULTATION_PRENATALE',
    status: json['statut'] as String? ?? 'PLANIFIE',
    professional: json['professionnelNomComplet'] as String?,
    facility: json['etablissementNom'] as String?,
    reason: json['motif'] as String?,
  );
}

/// Un des 8 contacts prénatals recommandés par l'OMS (calculé par l'API).
class CpnContact {
  const CpnContact({required this.number, required this.targetWeek, required this.status, this.targetDate});
  final int number;
  final int targetWeek;
  /// REALISE, PLANIFIE, EN_RETARD ou A_VENIR.
  final String status;
  final DateTime? targetDate;

  factory CpnContact.fromJson(Map<String, dynamic> json) => CpnContact(
    number: (json['numero'] as num).toInt(),
    targetWeek: (json['semaineCible'] as num).toInt(),
    status: json['statut'] as String? ?? 'A_VENIR',
    targetDate: _date(json['dateCible']),
  );
}

class CpnPlan {
  const CpnPlan({required this.contacts, required this.done, required this.late, this.reference});
  final List<CpnContact> contacts;
  final int done;
  final int late;
  final String? reference;

  factory CpnPlan.fromJson(Map<String, dynamic> json) => CpnPlan(
    contacts: (json['contacts'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(CpnContact.fromJson)
        .toList(),
    done: (json['nombreRealises'] as num?)?.toInt() ?? 0,
    late: (json['nombreEnRetard'] as num?)?.toInt() ?? 0,
    reference: json['reference'] as String?,
  );
}

/// Libellé du trimestre renvoyé par l'API (T1, T2, T3).
String trimesterLabel(String? value) => switch (value) {
  'T1' => '1er trimestre',
  'T2' => '2e trimestre',
  'T3' => '3e trimestre',
  null || '' => 'Suivi prénatal',
  _ => value,
};

DateTime? _date(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
