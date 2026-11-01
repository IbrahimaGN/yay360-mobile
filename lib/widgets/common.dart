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
              color: context.yayInk,
              fontWeight: FontWeight.w800,
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
          style: TextStyle(color: context.yayInk, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text(
          message,
          style: TextStyle(color: context.yayMuted, height: 1.5, fontSize: 13),
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
