import 'package:flutter/material.dart';

import '../theme.dart';

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: context.yay.textMain,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              action!,
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
          ),
      ],
    ),
  );
}

class ContentCard extends StatelessWidget {
  const ContentCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: padding, child: child),
  );
}

class MessagePanel extends StatelessWidget {
  const MessagePanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => ContentCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 23),
        const SizedBox(height: 11),
        Text(
          title,
          style: TextStyle(color: context.yay.textMain, fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 5),
        Text(
          message,
          style: TextStyle(color: context.yay.textMuted, height: 1.5, fontSize: 14),
        ),
        if (action != null) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: Text(action!),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.secondary,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ],
    ),
  );
}

/// Type d'encadré : la couleur porte le sens, l'icône le répète (jamais la couleur seule).
enum NoticeKind { info, error, warning, success }

/// Encadré de message (équivalent des `.pro-notice` du portail web).
class YayNotice extends StatelessWidget {
  const YayNotice({super.key, required this.kind, required this.message, this.title});
  final NoticeKind kind;
  final String message;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final p = context.yay;
    final (fond, bord, texte, icone) = switch (kind) {
      NoticeKind.info => (p.tealSofter, p.tealLine, p.textMain, Icons.info_outline),
      NoticeKind.error => (p.dangerSoft, p.dangerLine, p.danger, Icons.error_outline),
      NoticeKind.warning => (p.warningSoft, p.warningLine, p.warning, Icons.warning_amber_rounded),
      NoticeKind.success => (p.successSoft, p.successLine, p.success, Icons.check_circle_outline),
    };
    final accent = kind == NoticeKind.info ? p.tealInk : texte;
    return Semantics(
      liveRegion: kind == NoticeKind.error,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: fond,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: bord, width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, size: 20, color: accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Text(title!, style: TextStyle(color: texte, fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                  ],
                  Text(message, style: TextStyle(color: texte, fontSize: 13, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Règles du mot de passe (identiques à l'API : 8 à 100 caractères, une lettre et un chiffre),
/// cochées au fil de la saisie.
class PasswordRules extends StatelessWidget {
  const PasswordRules({super.key, required this.controller});
  final TextEditingController controller;

  static bool longueur(String v) => v.length >= 8;
  static bool lettre(String v) => RegExp(r'[A-Za-z]').hasMatch(v);
  static bool chiffre(String v) => RegExp(r'\d').hasMatch(v);
  static bool valide(String v) => longueur(v) && v.length <= 100 && lettre(v) && chiffre(v);
  static const aide = '8 caractères minimum, avec au moins une lettre et un chiffre.';

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<TextEditingValue>(
    valueListenable: controller,
    builder: (context, value, _) {
      final v = value.text;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _Regle('8 caractères', longueur(v)),
          _Regle('Une lettre', lettre(v)),
          _Regle('Un chiffre', chiffre(v)),
        ],
      );
    },
  );
}

class _Regle extends StatelessWidget {
  const _Regle(this.libelle, this.ok);
  final String libelle;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final p = context.yay;
    return Semantics(
      label: '$libelle : ${ok ? 'respecté' : 'à respecter'}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: ok ? p.successSoft : p.surface2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: ok ? p.successLine : p.borderStrong, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ok ? Icons.check : Icons.circle_outlined, size: 14, color: ok ? p.success : p.textMuted),
            const SizedBox(width: 5),
            Text(libelle, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: ok ? p.success : p.textMuted)),
          ],
        ),
      ),
    );
  }
}

/// Anneau d'avancement (ex. semaines sur 40). Purement visuel : [semanticsLabel] porte l'information.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    required this.color,
    required this.semanticsLabel,
    this.size = 112,
    this.stroke = 11,
    this.child,
  });
  final double value;
  final Color color;
  final String semanticsLabel;
  final double size;
  final double stroke;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticsLabel,
    excludeSemantics: true,
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _AnneauPainter(value.clamp(0, 1).toDouble(), color, context.yay.vizTrack, stroke),
        child: Center(child: child),
      ),
    ),
  );
}

class _AnneauPainter extends CustomPainter {
  _AnneauPainter(this.value, this.color, this.track, this.stroke);
  final double value;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final zone = rect.deflate(stroke / 2);
    final fond = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(zone, 0, 6.2832, false, fond);
    if (value > 0) canvas.drawArc(zone, -1.5708, 6.2832 * value, false, arc);
  }

  @override
  bool shouldRepaint(_AnneauPainter old) =>
      old.value != value || old.color != color || old.track != track;
}

/// Pastille de statut (texte + fond teinté).
class StatusPill extends StatelessWidget {
  const StatusPill(this.text, {super.key, required this.background, required this.foreground, this.icon});
  final String text;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 14, color: foreground), const SizedBox(width: 4)],
        Text(text, style: TextStyle(color: foreground, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

/// Statut d'un rendez-vous : libellé et couleurs.
(String, Color, Color) appointmentStatus(BuildContext context, String status) {
  final p = context.yay;
  return switch (status) {
    'CONFIRME' => ('Confirmé', p.tealSoft, p.tealInk),
    'PLANIFIE' => ('À confirmer', p.orangeSoft, p.orangeInk),
    'TERMINE' => ('Terminé', p.successSoft, p.success),
    'ANNULE' => ('Annulé', p.surface2, p.textMuted),
    'ABSENT' => ('Absente', p.dangerSoft, p.danger),
    _ => (status, p.surface2, p.textMuted),
  };
}

const _moisCourts = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];

/// Bloc date compact (jour + mois court), pour les listes de rendez-vous.
class DateBlock extends StatelessWidget {
  const DateBlock(this.date, {super.key});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final p = context.yay;
    return ExcludeSemantics(
      child: Container(
        width: 52,
        height: 56,
        decoration: BoxDecoration(color: p.tealSoft, borderRadius: BorderRadius.circular(14)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${date.day}', style: TextStyle(color: p.tealInk, fontWeight: FontWeight.w600, fontSize: 19, height: 1.1)),
            Text(_moisCourts[date.month - 1].toUpperCase(),
                style: TextStyle(color: p.tealInk, fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

/// Logo dans sa pastille blanche + « YaY°360 ».
class YayBrand extends StatelessWidget {
  const YayBrand({super.key, this.size = 42});
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'YAY360',
    excludeSemantics: true,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: ClipOval(child: Image.asset('assets/images/yay360-logo.png', fit: BoxFit.cover)),
        ),
        const SizedBox(width: 10),
        Text(
          'YaY°360',
          style: TextStyle(fontSize: size * 0.45, fontWeight: FontWeight.w600, color: context.yay.textMain),
        ),
      ],
    ),
  );
}

String frenchDate(DateTime? date, {bool includeTime = false}) {
  if (date == null) return 'À confirmer';
  const months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];
  final formatted = '${date.day} ${months[date.month - 1]} ${date.year}';
  if (!includeTime) return formatted;
  return '$formatted à ${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}';
}

String appointmentType(String value) => switch (value) {
  'CONSULTATION_PRENATALE' => 'Consultation prénatale',
  'ECHOGRAPHIE' => 'Échographie',
  'VACCINATION' => 'Vaccination',
  'EXAMEN_LABORATOIRE' => 'Examen de laboratoire',
  _ => 'Autre rendez-vous',
};

/// Contenu d'une feuille modale de formulaire : remonte au-dessus du clavier et défile si besoin.
class FeuilleModale extends StatelessWidget {
  const FeuilleModale({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      ),
    );
  }
}
