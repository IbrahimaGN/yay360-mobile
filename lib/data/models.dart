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
    this.periodDate,
    this.daysRemaining,
    this.atRisk = false,
  });

  final int id;
  final String status;
  final int? week;
  final String? trimester;
  final DateTime? dueDate;
  final DateTime? periodDate;
  final int? daysRemaining;
  final bool atRisk;

  factory Pregnancy.fromJson(Map<String, dynamic> json) => Pregnancy(
    id: (json['id'] as num).toInt(),
    status: json['statut'] as String? ?? 'EN_COURS',
    week: (json['semaineActuelle'] as num?)?.toInt(),
    trimester: json['trimestre'] as String?,
    dueDate: _date(json['datePrevueAccouchement']),
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

class AssistantMessage {
  const AssistantMessage(this.role, this.content);

  final String role;
  final String content;

  Map<String, String> toJson() => {'role': role, 'content': content};
}

DateTime? _date(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
