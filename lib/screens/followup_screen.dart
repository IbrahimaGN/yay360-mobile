import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class FollowupScreen extends StatefulWidget {
  const FollowupScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<FollowupScreen> createState() => _FollowupScreenState();
}

class _FollowupScreenState extends State<FollowupScreen> {
  WeeklyFollowup? _followup;
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
      _followup = WeeklyFollowup.fromJson(
        await widget.api.get('/grossesses/mon-suivi'),
      );
    } on ApiException catch (exception) {
      _error = exception.message;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: _load,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      children: [
        Text(
          'Mon suivi',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: context.yayInk,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Des repères pour vivre chaque étape avec confiance.',
          style: TextStyle(color: context.yayMuted),
        ),
        const SizedBox(height: 20),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          MessagePanel(
            icon: Icons.info_outline,
            title: 'Suivi indisponible',
            message: _error!,
            action: 'Réessayer',
            onAction: _load,
          )
        else if (_followup == null)
          const MessagePanel(
            icon: Icons.favorite_outline,
            title: 'Aucun suivi en cours',
            message:
                'Déclarez votre grossesse depuis l’accueil pour voir les repères hebdomadaires.',
          )
        else ...[
          _WeekHeader(followup: _followup!),
          if (_followup!.babyDevelopment != null)
            _FollowupCard(
              icon: Icons.child_care_outlined,
              title: 'Le développement de bébé',
              content: _followup!.babyDevelopment!,
              color: context.yayRoseContainer,
              iconColor: YayColors.rose,
            ),
          if (_followup!.motherChanges != null)
            _FollowupCard(
              icon: Icons.spa_outlined,
              title: 'Les changements de votre corps',
              content: _followup!.motherChanges!,
              color: context.yayTealContainer,
              iconColor: YayColors.green,
            ),
          if (_followup!.healthGoals != null)
            _FollowupCard(
              icon: Icons.checklist_outlined,
              title: 'Vos objectifs santé',
              content: _followup!.healthGoals!,
              color: context.yayWarningContainer,
              iconColor: const Color(0xFFB68737),
            ),
          if (_followup!.foodAdvice != null)
            _FollowupCard(
              icon: Icons.restaurant_outlined,
              title: 'Alimentation',
              content: _followup!.foodAdvice!,
              color: context.yayWarningContainer,
              iconColor: const Color(0xFFB68737),
            ),
          if (_followup!.hydrationAdvice != null)
            _FollowupCard(
              icon: Icons.water_drop_outlined,
              title: 'Hydratation',
              content: _followup!.hydrationAdvice!,
              color: context.yayTealContainer,
              iconColor: YayColors.green,
            ),
          if (_followup!.exercise != null)
            _FollowupCard(
              icon: Icons.directions_walk_outlined,
              title: 'Activité physique',
              content: _followup!.exercise!,
              color: context.yayRoseContainer,
              iconColor: YayColors.rose,
            ),
          if (_followup!.sleepAdvice != null)
            _FollowupCard(
              icon: Icons.bedtime_outlined,
              title: 'Sommeil',
              content: _followup!.sleepAdvice!,
              color: context.yayTealContainer,
              iconColor: YayColors.green,
            ),
          if (_followup!.precautions != null)
            _FollowupCard(
              icon: Icons.health_and_safety_outlined,
              title: 'Précautions',
              content: _followup!.precautions!,
              color: context.yayWarningContainer,
              iconColor: const Color(0xFFB68737),
            ),
          if (_followup!.warningSigns != null)
            _FollowupCard(
              icon: Icons.warning_amber_rounded,
              title: 'Signes à surveiller',
              content: _followup!.warningSigns!,
              color: context.yayRoseContainer,
              iconColor: YayColors.roseDark,
            ),
          ContentCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.medical_information_outlined,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 20,
                ),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Ces informations sont générales et ne remplacent jamais l’avis d’un professionnel de santé.',
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
      ],
    ),
  );
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({required this.followup});
  final WeeklyFollowup followup;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      color: YayColors.green,
    ),
    child: Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${followup.week ?? '—'}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 25,
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SEMAINE DE GROSSESSE',
                style: TextStyle(
                  color: Color(0xFFE9AFB9),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                followup.trimester ?? 'Votre semaine',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              if (followup.dueDate != null)
                Text(
                  'Date prévue : ${frenchDate(followup.dueDate)}',
                  style: const TextStyle(
                    color: Color(0xFFD6E4DA),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _FollowupCard extends StatelessWidget {
  const _FollowupCard({
    required this.icon,
    required this.title,
    required this.content,
    required this.color,
    required this.iconColor,
  });
  final IconData icon;
  final String title;
  final String content;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: iconColor, size: 19),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: context.yayInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              color: context.yayMuted,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    ),
  );
}
