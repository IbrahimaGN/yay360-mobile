import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/api_client.dart';
import '../state/auth_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Mon espace : profil, invitation du conjoint (côté patiente) ou accès partagé (côté conjoint), déconnexion.
class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key, required this.auth});
  final AuthController auth;

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

/// Réponse de l'API à la création d'une invitation.
class _Invitation {
  const _Invitation({required this.message, required this.code, required this.email, this.expiration, required this.emailEnvoye});
  final String message;
  final String code;
  final String email;
  final DateTime? expiration;
  final bool emailEnvoye;
}

class _FamilyScreenState extends State<FamilyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sending = false;
  String? _error;
  _Invitation? _invitation;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _email.text.trim();
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final r = await widget.auth.api.post('/famille/inviter-conjoint', {'email': email});
      if (!mounted) return;
      setState(() {
        _sending = false;
        _email.clear();
        _invitation = _Invitation(
          message: r['message'] as String? ?? 'Invitation créée.',
          code: r['code'] as String? ?? '',
          email: email,
          expiration: DateTime.tryParse(r['dateExpiration'] as String? ?? ''),
          emailEnvoye: r['emailEnvoye'] as bool? ?? false,
        );
      });
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = exception.message;
      });
    }
  }

  Future<void> _copier(String texte, String confirmation) async {
    await Clipboard.setData(ClipboardData(text: texte));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(confirmation)));
  }

  String _messagePret(_Invitation i) =>
      'Je t’invite à suivre ma grossesse sur YAY360. Dans l’application, touche '
      '« J’ai reçu une invitation de mon conjoint », puis saisis le code ${i.code} '
      'avec l’adresse ${i.email}. Le code est valable 72 heures.';

  @override
  Widget build(BuildContext context) {
    final p = context.yay;
    final session = widget.auth.session!;
    final estFemme = session.role == 'FEMME_ENCEINTE';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      children: [
        Text('Mon espace', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: p.textMain)),
        const SizedBox(height: 2),
        Text('Votre profil et votre dossier familial.', style: TextStyle(color: p.textMuted, fontSize: 14)),
        const SizedBox(height: 18),

        // ── Profil ─────────────────────────────────────────────
        ContentCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: p.tealDark,
                child: Text(
                  session.firstName.isNotEmpty ? session.firstName[0].toUpperCase() : 'Y',
                  style: TextStyle(color: p.onStrong, fontSize: 21, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${session.firstName} ${session.lastName}',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: p.textMain)),
                    Text(session.email, style: TextStyle(color: p.textMuted, fontSize: 13)),
                    const SizedBox(height: 6),
                    StatusPill(
                      estFemme ? 'Future maman' : 'Conjoint',
                      background: estFemme ? p.orangeSoft : p.lilacSoft,
                      foreground: estFemme ? p.orangeInk : p.lilacInk,
                      icon: estFemme ? Icons.favorite_border : Icons.people_outline,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        if (estFemme) ...[
          const SectionHeading('Inviter votre conjoint'),
          ContentCard(
            child: _invitation == null ? _formulaire(p) : _resultat(p, _invitation!),
          ),
          const SectionHeading('Comment ça marche'),
          ContentCard(
            child: Column(
              children: [
                const _Etape(1, 'Vous créez l’invitation', 'avec l’adresse e-mail de votre conjoint.'),
                const SizedBox(height: 12),
                const _Etape(2, 'Vous lui transmettez le code', 'par SMS ou WhatsApp, s’il n’a pas reçu d’e-mail.'),
                const SizedBox(height: 12),
                const _Etape(3, 'Il crée son compte', 'et rejoint votre dossier familial.'),
              ],
            ),
          ),
          const SectionHeading('Ce que votre conjoint pourra voir'),
          const _ListeAcces(items: [
            (Icons.favorite_border, 'Le suivi prénatal de votre grossesse'),
            (Icons.calendar_month_outlined, 'Les rendez-vous et les conseils de la semaine'),
            (Icons.warning_amber_rounded, 'Signaler un symptôme ou demander un rendez-vous pour vous'),
            (Icons.shield_outlined, 'Uniquement votre dossier, jamais celui d’une autre patiente'),
          ]),
        ] else ...[
          const SectionHeading('Votre accès au dossier partagé'),
          const _ListeAcces(items: [
            (Icons.favorite_border, 'Suivi prénatal : avancement, consultations prénatales, conseils de la semaine'),
            (Icons.calendar_month_outlined, 'Rendez-vous : consulter et demander un rendez-vous'),
            (Icons.warning_amber_rounded, 'Signaler un symptôme pour la future maman'),
            (Icons.shield_outlined, 'Le lien entre vos comptes est créé par l’invitation'),
          ]),
        ],

        const SectionHeading('Confidentialité'),
        const YayNotice(
          kind: NoticeKind.info,
          message: 'Votre session est conservée dans le stockage sécurisé de cet appareil. '
              'Déconnectez-vous si vous partagez le téléphone.',
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: _confirmLogout,
          icon: const Icon(Icons.logout),
          label: const Text('Se déconnecter'),
          style: OutlinedButton.styleFrom(
            foregroundColor: p.danger,
            side: BorderSide(color: p.dangerLine, width: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _formulaire(YayPalette p) => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Il créera son propre compte avec le code d’invitation et suivra votre grossesse avec vous.',
          style: TextStyle(color: p.textMuted, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          validator: (v) {
            final e = v?.trim() ?? '';
            if (e.isEmpty) return 'Saisissez l’adresse e-mail de votre conjoint.';
            if (!e.contains('@') || !e.contains('.')) return 'Adresse e-mail invalide.';
            return null;
          },
          onFieldSubmitted: (_) => _invite(),
          decoration: const InputDecoration(
            labelText: 'Adresse e-mail du conjoint',
            hintText: 'conjoint@exemple.sn',
            prefixIcon: Icon(Icons.mail_outline),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          YayNotice(kind: NoticeKind.error, message: _error!),
        ],
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _sending ? null : _invite,
          icon: const Icon(Icons.send_outlined, size: 18),
          label: Text(_sending ? 'Création de l’invitation…' : 'Créer une invitation'),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.shield_outlined, size: 15, color: p.tealInk),
            const SizedBox(width: 6),
            Expanded(child: Text('Code à usage unique, valable 72 heures.', style: TextStyle(fontSize: 12, color: p.textMuted))),
          ],
        ),
      ],
    ),
  );

  Widget _resultat(YayPalette p, _Invitation i) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      YayNotice(kind: NoticeKind.success, message: i.message),
      if (!i.emailEnvoye && i.code.isNotEmpty) ...[
        const SizedBox(height: 14),
        Semantics(
          label: 'Code d’invitation : ${i.code.split('').join(' ')}',
          excludeSemantics: true,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: p.orangeSoft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: p.orange, width: 1.5),
            ),
            child: Column(
              children: [
                Text('CODE D’INVITATION',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: p.orangeInk)),
                const SizedBox(height: 6),
                SelectableText(i.code,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: 2, color: p.textMain)),
                if (i.expiration != null) ...[
                  const SizedBox(height: 4),
                  Text('Valable jusqu’au ${frenchDate(i.expiration, includeTime: true)}',
                      style: TextStyle(fontSize: 12, color: p.textMuted)),
                ],
                const SizedBox(height: 4),
                Text('Pour ${i.email}', style: TextStyle(fontSize: 12, color: p.textMuted)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _copier(_messagePret(i), 'Message copié : collez-le dans un SMS ou WhatsApp.'),
          icon: const Icon(Icons.content_copy, size: 18),
          label: const Text('Copier le message à envoyer'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _copier(i.code, 'Code copié.'),
          icon: const Icon(Icons.key_outlined, size: 18),
          label: const Text('Copier le code seul'),
        ),
      ],
      const SizedBox(height: 6),
      TextButton(
        onPressed: () => setState(() {
          _invitation = null;
          _error = null;
        }),
        child: const Text('Inviter une autre adresse'),
      ),
    ],
  );

  Future<void> _confirmLogout() async {
    final p = context.yay;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.logout, color: p.danger),
        title: const Text('Se déconnecter ?'),
        content: const Text('Votre session sécurisée sera supprimée de cet appareil.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: p.dangerStrong,
              foregroundColor: p.onStrong,
              side: BorderSide(color: p.dangerStrong, width: 1.5),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
    if (confirm == true) await widget.auth.logout();
  }
}

class _Etape extends StatelessWidget {
  const _Etape(this.numero, this.titre, this.detail);
  final int numero;
  final String titre;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final p = context.yay;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: p.tealDark,
          child: Text('$numero', style: TextStyle(color: p.onStrong, fontWeight: FontWeight.w600, fontSize: 14)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titre, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: p.textMain)),
              Text(detail, style: TextStyle(fontSize: 13, color: p.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ListeAcces extends StatelessWidget {
  const _ListeAcces({required this.items});
  final List<(IconData, String)> items;

  @override
  Widget build(BuildContext context) {
    final p = context.yay;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.tealSofter,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.tealLine, width: 1.5),
      ),
      child: Column(
        children: [
          for (final (i, (icone, texte)) in items.indexed) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icone, size: 18, color: p.tealInk),
                const SizedBox(width: 10),
                Expanded(child: Text(texte, style: TextStyle(fontSize: 14, color: p.textMain, height: 1.45))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
