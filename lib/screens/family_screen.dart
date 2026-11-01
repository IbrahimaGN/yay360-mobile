import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../state/auth_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key, required this.auth});
  final AuthController auth;

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final _email = TextEditingController();
  bool _sending = false;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    final email = _email.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      setState(() {
        _error = 'Saisissez une adresse e-mail valide.';
        _message = null;
      });
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
      _message = null;
    });
    try {
      final response = await widget.auth.api.post('/famille/inviter-conjoint', {
        'email': email,
      });
      if (!mounted) return;
      setState(() {
        _sending = false;
        _email.clear();
        _message =
            response['message'] as String? ??
            'Invitation enregistrée. L’envoi du lien par e-mail doit être configuré par l’administrateur.';
      });
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = exception.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.auth.session!;
    final canInvite = session.role == 'FEMME_ENCEINTE';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      children: [
        Text(
          'Mon espace',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: context.yayInk,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Votre profil et votre dossier familial.',
          style: TextStyle(color: context.yayMuted),
        ),
        const SizedBox(height: 20),
        ContentCard(
          child: Row(
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: context.yayRoseContainer,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    session.firstName.isNotEmpty
                        ? session.firstName[0].toUpperCase()
                        : 'Y',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${session.firstName} ${session.lastName}',
                      style: TextStyle(
                        color: context.yayInk,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.email,
                      style: TextStyle(color: context.yayMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      session.role == 'CONJOINT'
                          ? 'Conjoint · dossier familial partagé'
                          : 'Femme enceinte · espace personnel',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (canInvite) ...[
          const SectionHeading('Partager le suivi avec votre conjoint'),
          Text(
            'Une invitation lui permettra de créer son propre compte et d’accéder à votre dossier familial.',
            style: TextStyle(
              color: context.yayMuted,
              fontSize: 13,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 13),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Adresse e-mail du conjoint',
              hintText: 'conjoint@exemple.com',
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _sending ? null : _invite,
            child: _sending
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Créer une invitation'),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            _Notice(message: _message!, success: true),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            _Notice(message: _error!, success: false),
          ],
          const SizedBox(height: 10),
          Text(
            'À noter : l’envoi automatique des e-mails d’invitation n’est pas encore configuré sur la plateforme.',
            style: TextStyle(
              color: context.yayMuted,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ] else ...[
          const SectionHeading('Votre dossier familial'),
          const MessagePanel(
            icon: Icons.people_outline,
            title: 'Votre accès conjoint est activé',
            message:
                'Vous pouvez consulter le même suivi prénatal et les rendez-vous partagés. Les données du dossier restent accessibles selon vos autorisations.',
          ),
        ],
        const SectionHeading('Votre confidentialité'),
        ContentCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outline,
                color: Theme.of(context).colorScheme.secondary,
                size: 20,
              ),
              SizedBox(width: 11),
              Expanded(
                child: Text(
                  'Votre session est conservée dans le stockage sécurisé de votre appareil. L’assistant IA ne transmet une question à son fournisseur qu’après votre accord explicite.',
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
        const SizedBox(height: 22),
        OutlinedButton.icon(
          onPressed: _confirmLogout,
          icon: const Icon(Icons.logout),
          label: const Text('Se déconnecter'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: Theme.of(context).colorScheme.error,
            side: BorderSide(color: context.yayBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text(
          'Votre session sécurisée sera supprimée de cet appareil.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
    if (confirm == true) await widget.auth.logout();
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message, required this.success});
  final String message;
  final bool success;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: success ? context.yayTealContainer : context.yayRoseContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      message,
      style: TextStyle(
        color: success
            ? Theme.of(context).colorScheme.onSecondaryContainer
            : Theme.of(context).colorScheme.onPrimaryContainer,
        fontSize: 12,
        height: 1.5,
      ),
    ),
  );
}
