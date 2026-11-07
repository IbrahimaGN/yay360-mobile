import 'package:flutter/material.dart';

import '../state/auth_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Connexion, inscription de la patiente et accès au compte conjoint (sur invitation).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.auth, this.onToggleTheme});

  final AuthController auth;
  final VoidCallback? onToggleTheme;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _dateOfBirth = TextEditingController();
  bool _registerMode = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _dateOfBirth.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = _registerMode
        ? await widget.auth.register({
            'prenom': _firstName.text.trim(),
            'nom': _lastName.text.trim(),
            'email': _email.text.trim(),
            'password': _password.text,
            'telephone': normalizePhone(_phone.text),
            'dateNaissance': _dateOfBirth.text,
            'role': 'FEMME_ENCEINTE',
          })
        : await widget.auth.login(_email.text.trim(), _password.text);
    if (!mounted) return;
    if (!ok) setState(() {});
  }

  Future<void> _pickBirthDate() async {
    final today = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(today.year - 25),
      firstDate: DateTime(1920),
      lastDate: DateTime(today.year - 16, today.month, today.day),
      locale: const Locale('fr', 'FR'),
      helpText: 'Votre date de naissance',
    );
    if (date != null) {
      _dateOfBirth.text = isoDate(date);
      setState(() {});
    }
  }

  Future<void> _openPartnerInvitation() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _PartnerInvitationSheet(auth: widget.auth),
    );
    if (result == true && mounted) setState(() {});
  }

  void _changerMode(bool inscription) => setState(() {
    _registerMode = inscription;
    widget.auth.error = null;
  });

  @override
  Widget build(BuildContext context) {
    final p = context.yay;
    final sombre = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 28 + bottomInset),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── En-tête ────────────────────────────────────────────
                  Row(
                    children: [
                      const Expanded(child: Align(alignment: Alignment.centerLeft, child: YayBrand())),
                      IconButton(
                        tooltip: sombre ? 'Activer le thème clair' : 'Activer le thème sombre',
                        onPressed: widget.onToggleTheme,
                        icon: Icon(sombre ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _Hero(),
                  const SizedBox(height: 18),

                  // ── Carte du formulaire ───────────────────────────────
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: p.borderLight, width: 1.5),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ModeTabs(
                            inscription: _registerMode,
                            onChanged: _changerMode,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _registerMode ? 'Créez votre espace' : 'Accédez à votre espace',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: p.textMain),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _registerMode
                                ? 'Future maman : suivez votre grossesse et vos rendez-vous.'
                                : 'Avec l’adresse e-mail de votre compte.',
                            style: TextStyle(fontSize: 13, color: p.textMuted, height: 1.45),
                          ),
                          const SizedBox(height: 18),
                          if (_registerMode) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _nameField(_firstName, 'Prénom', 'Fatou')),
                                const SizedBox(width: 10),
                                Expanded(child: _nameField(_lastName, 'Nom', 'Ndiaye')),
                              ],
                            ),
                            const SizedBox(height: 14),
                          ],
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            textInputAction: TextInputAction.next,
                            validator: validateEmail,
                            decoration: const InputDecoration(
                              labelText: 'Adresse e-mail',
                              hintText: 'nom@exemple.sn',
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                          ),
                          if (_registerMode) ...[
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              autofillHints: const [AutofillHints.telephoneNumber],
                              validator: validatePhone,
                              decoration: const InputDecoration(
                                labelText: 'Téléphone',
                                hintText: '+221 77 000 00 00',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _dateOfBirth,
                              readOnly: true,
                              onTap: _pickBirthDate,
                              validator: (value) => value == null || value.isEmpty
                                  ? 'Choisissez votre date de naissance.'
                                  : null,
                              decoration: const InputDecoration(
                                labelText: 'Date de naissance',
                                hintText: 'AAAA-MM-JJ',
                                prefixIcon: Icon(Icons.cake_outlined),
                                suffixIcon: Icon(Icons.calendar_month_outlined),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _password,
                            obscureText: _hidePassword,
                            autofillHints: [_registerMode ? AutofillHints.newPassword : AutofillHints.password],
                            onFieldSubmitted: (_) => _submit(),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Saisissez votre mot de passe.';
                              if (_registerMode && !PasswordRules.valide(value)) return PasswordRules.aide;
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              hintText: _registerMode ? '8 caractères minimum' : 'Votre mot de passe',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _hidePassword ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
                                style: IconButton.styleFrom(backgroundColor: Colors.transparent, side: BorderSide.none),
                                onPressed: () => setState(() => _hidePassword = !_hidePassword),
                                icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                              ),
                            ),
                          ),
                          if (_registerMode) ...[
                            const SizedBox(height: 10),
                            PasswordRules(controller: _password),
                          ],
                          if (widget.auth.error != null) ...[
                            const SizedBox(height: 14),
                            YayNotice(kind: NoticeKind.error, message: widget.auth.error!),
                          ],
                          const SizedBox(height: 18),
                          FilledButton(
                            onPressed: widget.auth.isSubmitting ? null : _submit,
                            child: widget.auth.isSubmitting
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: p.textMuted),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(_registerMode ? 'Création…' : 'Connexion en cours…'),
                                    ],
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(_registerMode ? 'Créer mon espace' : 'Se connecter'),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward, size: 18),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Conjoint ──────────────────────────────────────────
                  if (!_registerMode) ...[
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: _openPartnerInvitation,
                      icon: const Icon(Icons.favorite_border),
                      label: const Text('J’ai reçu une invitation de mon conjoint'),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const YayNotice(
                    kind: NoticeKind.info,
                    message: 'Conjoint : utilisez le code d’invitation reçu. '
                        'Professionnels de santé : connectez-vous sur le portail web.',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'YAY360 accompagne votre suivi et ne remplace pas l’avis d’un professionnel de santé.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.textMuted, fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _nameField(TextEditingController controller, String label, String hint) => TextFormField(
    controller: controller,
    textCapitalization: TextCapitalization.words,
    textInputAction: TextInputAction.next,
    validator: (value) =>
        value == null || value.trim().length < 2 ? 'Au moins 2 caractères.' : null,
    decoration: InputDecoration(labelText: label, hintText: hint),
  );
}

// ==================== Outils de saisie (partagés avec l'invitation) ====================

String normalizePhone(String value) => value.replaceAll(RegExp(r'[\s().-]'), '');

String isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) return 'Saisissez votre e-mail.';
  if (!value.contains('@') || !value.contains('.')) return 'Adresse e-mail invalide.';
  return null;
}

/// Mobile sénégalais : +221 puis 70, 71, 75, 76, 77 ou 78, puis 7 chiffres (comme l'API).
String? validatePhone(String? value) {
  if (value == null || value.trim().isEmpty) return 'Saisissez votre téléphone.';
  if (!RegExp(r'^\+221(70|71|75|76|77|78)\d{7}$').hasMatch(normalizePhone(value))) {
    return 'Format attendu : +221 77 000 00 00.';
  }
  return null;
}

// ==================== Bandeau d'accueil ====================

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final p = context.yay;
    // Dégradé foncé : le texte blanc garde au moins 4,5:1 partout
    final fin = Color.lerp(p.banner1, Colors.black, 0.25)!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [p.banner1, fin],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Décor
            Positioned(right: -30, top: -40, child: _Rond(130, Colors.white.withValues(alpha: 0.10))),
            Positioned(right: 26, bottom: -26, child: _Rond(64, p.orange.withValues(alpha: 0.9))),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: const Text(
                      'Santé maternelle · Sénégal',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Votre grossesse,\naccompagnée avec soin.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.only(right: 70),
                    child: Text(
                      'Des repères utiles, un suivi organisé et vos proches à vos côtés.',
                      style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Rond extends StatelessWidget {
  const _Rond(this.taille, this.couleur);
  final double taille;
  final Color couleur;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(width: taille, height: taille, decoration: BoxDecoration(color: couleur, shape: BoxShape.circle)),
  );
}

// ==================== Onglets Connexion / Inscription ====================

class _ModeTabs extends StatelessWidget {
  const _ModeTabs({required this.inscription, required this.onChanged});
  final bool inscription;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.yay;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.borderLight, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(child: _Onglet(titre: 'Connexion', actif: !inscription, onTap: () => onChanged(false))),
          const SizedBox(width: 4),
          Expanded(child: _Onglet(titre: 'Inscription', actif: inscription, onTap: () => onChanged(true))),
        ],
      ),
    );
  }
}

class _Onglet extends StatelessWidget {
  const _Onglet({required this.titre, required this.actif, required this.onTap});
  final String titre;
  final bool actif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.yay;
    return Semantics(
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
                titre,
                style: TextStyle(
                  color: actif ? p.onStrong : p.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== Compte conjoint (invitation) ====================

class _PartnerInvitationSheet extends StatefulWidget {
  const _PartnerInvitationSheet({required this.auth});
  final AuthController auth;

  @override
  State<_PartnerInvitationSheet> createState() => _PartnerInvitationSheetState();
}

class _PartnerInvitationSheetState extends State<_PartnerInvitationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _token = TextEditingController();
  final _email = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _birth = TextEditingController();
  final _password = TextEditingController();
  bool _sending = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _token.dispose();
    _email.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _birth.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final today = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(today.year - 30),
      firstDate: DateTime(1920),
      lastDate: today.subtract(const Duration(days: 1)),
      locale: const Locale('fr', 'FR'),
      helpText: 'Votre date de naissance',
    );
    if (date != null) {
      _birth.text = isoDate(date);
      setState(() {});
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    final success = await widget.auth.acceptInvitation({
      'token': _token.text.trim(),
      'email': _email.text.trim(),
      'prenom': _firstName.text.trim(),
      'nom': _lastName.text.trim(),
      'password': _password.text,
      'telephone': normalizePhone(_phone.text),
      'dateNaissance': _birth.text,
    });
    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _sending = false;
        _error = widget.auth.error;
      });
    }
  }

  String? _requis(String? value) => value == null || value.trim().isEmpty ? 'Champ requis.' : null;

  @override
  Widget build(BuildContext context) {
    final p = context.yay;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: p.orangeSoft, borderRadius: BorderRadius.circular(14)),
                    child: Icon(Icons.favorite_border, color: p.orangeInk),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Rejoindre le dossier familial',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: p.textMain),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Saisissez le code et l’adresse e-mail indiqués dans l’invitation reçue.',
                style: TextStyle(color: p.textMuted, height: 1.5, fontSize: 13),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _token,
                validator: _requis,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Code d’invitation',
                  helperText: 'Valable 72 heures, à usage unique.',
                  prefixIcon: Icon(Icons.key_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                validator: validateEmail,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'E-mail invité',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstName,
                      validator: _requis,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Prénom'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _lastName,
                      validator: _requis,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Nom'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                validator: validatePhone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  hintText: '+221 77 000 00 00',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _birth,
                readOnly: true,
                onTap: _selectDate,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Choisissez votre date de naissance.' : null,
                decoration: const InputDecoration(
                  labelText: 'Date de naissance',
                  prefixIcon: Icon(Icons.cake_outlined),
                  suffixIcon: Icon(Icons.calendar_month_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: _hidePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Champ requis.';
                  return PasswordRules.valide(value) ? null : PasswordRules.aide;
                },
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: _hidePassword ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
                    style: IconButton.styleFrom(backgroundColor: Colors.transparent, side: BorderSide.none),
                    onPressed: () => setState(() => _hidePassword = !_hidePassword),
                    icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              PasswordRules(controller: _password),
              if (_error != null) ...[
                const SizedBox(height: 14),
                YayNotice(kind: NoticeKind.error, message: _error!),
              ],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _sending ? null : _submit,
                child: _sending
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: p.textMuted),
                          ),
                          const SizedBox(width: 10),
                          const Text('Création…'),
                        ],
                      )
                    : const Text('Créer mon compte conjoint'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
