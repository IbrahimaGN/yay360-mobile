import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/models.dart';
import '../state/auth_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Étapes de la connexion par téléphone.
enum _Etape { telephone, pin, inscription, code, nouveauPin }

/// Connexion par téléphone et PIN (code de vérification envoyé par e-mail), connexion par e-mail
/// et accès au compte conjoint (sur invitation).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.auth, this.onToggleTheme});

  final AuthController auth;
  final VoidCallback? onToggleTheme;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController(text: '+221 ');
  final _pin = TextEditingController();
  final _code = TextEditingController();
  final _newPin = TextEditingController();
  final _confirmPin = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _dateOfBirth = TextEditingController();

  bool _modeEmail = false;
  _Etape _etape = _Etape.telephone;
  bool _stayConnected = true;
  bool _hidePassword = true;
  String? _maskedEmail;
  String? _pinToken;
  DateTime? _resendAt;
  Timer? _ticker;

  String get _phoneValue => normalizePhone(_phone.text);

  @override
  void dispose() {
    _ticker?.cancel();
    for (final c in [_phone, _pin, _code, _newPin, _confirmPin, _firstName, _lastName, _email, _password, _dateOfBirth]) {
      c.dispose();
    }
    super.dispose();
  }

  void _goTo(_Etape etape) => setState(() {
    _etape = etape;
    widget.auth.error = null;
  });

  void _startResendCountdown() {
    _resendAt = DateTime.now().add(const Duration(seconds: 60));
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() {});
      if (DateTime.now().isAfter(_resendAt!)) timer.cancel();
    });
  }

  int get _resendSeconds {
    final at = _resendAt;
    if (at == null) return 0;
    final remaining = at.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  void _onStart(MobileStart? result) {
    if (result == null || !mounted) return setState(() {});
    switch (result.step) {
      case 'PIN':
        _pin.clear();
        _goTo(_Etape.pin);
      case 'CODE_ENVOYE':
        _maskedEmail = result.maskedEmail;
        _code.clear();
        _startResendCountdown();
        _goTo(_Etape.code);
      default:
        _goTo(_Etape.inscription);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = widget.auth;
    if (_modeEmail) {
      await auth.login(_email.text.trim(), _password.text);
      if (mounted) setState(() {});
      return;
    }
    switch (_etape) {
      case _Etape.telephone:
        _onStart(await auth.startWithPhone(_phoneValue));
      case _Etape.pin:
        await auth.loginWithPin(_phoneValue, _pin.text, stayConnected: _stayConnected);
        if (mounted) setState(() {});
      case _Etape.inscription:
        _onStart(await auth.registerWithPhone({
          'prenom': _firstName.text.trim(),
          'nom': _lastName.text.trim(),
          'email': _email.text.trim(),
          'telephone': _phoneValue,
          'dateNaissance': _dateOfBirth.text,
        }));
      case _Etape.code:
        final token = await auth.verifyCode(_phoneValue, _code.text);
        if (token != null && mounted) {
          _pinToken = token;
          _newPin.clear();
          _confirmPin.clear();
          _goTo(_Etape.nouveauPin);
        } else if (mounted) {
          setState(() {});
        }
      case _Etape.nouveauPin:
        await auth.setPin(_pinToken!, _newPin.text, stayConnected: _stayConnected);
        if (mounted) setState(() {});
    }
  }

  Future<void> _forgotPin() async => _onStart(await widget.auth.startWithPhone(_phoneValue, forgotPin: true));

  Future<void> _resendCode() async => _onStart(await widget.auth.startWithPhone(_phoneValue, forgotPin: true));

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

  void _changerMode(bool email) => setState(() {
    _modeEmail = email;
    widget.auth.error = null;
  });

  // ==================== Textes de chaque étape ====================

  (String, String) get _titres {
    if (_modeEmail) return ('Accédez à votre espace', 'Avec l’adresse e-mail et le mot de passe de votre compte.');
    return switch (_etape) {
      _Etape.telephone => ('Accédez à votre espace', 'Avec votre numéro de téléphone.'),
      _Etape.pin => ('Bon retour !', 'Saisissez votre code PIN à 4 chiffres.'),
      _Etape.inscription => (
          'Créez votre espace',
          'Ce numéro est nouveau. Votre code de vérification sera envoyé à votre adresse e-mail.',
        ),
      _Etape.code => (
          'Vérifiez votre identité',
          'Saisissez le code à 6 chiffres envoyé à ${_maskedEmail ?? 'votre adresse e-mail'}. '
              'Pensez à regarder dans les courriers indésirables.',
        ),
      _Etape.nouveauPin => (
          'Choisissez votre code PIN',
          '4 chiffres, à garder secret. Évitez 0000, 1234 ou votre année de naissance.',
        ),
    };
  }

  String get _libelleBouton {
    if (_modeEmail) return 'Se connecter';
    return switch (_etape) {
      _Etape.telephone => 'Continuer',
      _Etape.pin => 'Se connecter',
      _Etape.inscription => 'Recevoir mon code',
      _Etape.code => 'Valider le code',
      _Etape.nouveauPin => 'Valider mon PIN',
    };
  }

  @override
  Widget build(BuildContext context) {
    final p = context.yay;
    final sombre = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final (titre, sousTitre) = _titres;
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
                          if (_modeEmail || _etape == _Etape.telephone) ...[
                            _ModeTabs(gauche: 'Téléphone', droite: 'E-mail', droiteActive: _modeEmail, onChanged: _changerMode),
                            const SizedBox(height: 18),
                          ],
                          Text(titre, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: p.textMain)),
                          const SizedBox(height: 4),
                          Text(sousTitre, style: TextStyle(fontSize: 13, color: p.textMuted, height: 1.45)),
                          const SizedBox(height: 18),
                          ..._champs(),
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
                                      const Text('Patientez…'),
                                    ],
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(_libelleBouton),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward, size: 18),
                                    ],
                                  ),
                          ),
                          ..._liensSecondaires(),
                        ],
                      ),
                    ),
                  ),

                  // ── Conjoint ──────────────────────────────────────────
                  if (!_modeEmail && _etape == _Etape.telephone) ...[
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

  // ==================== Champs de chaque étape ====================

  List<Widget> _champs() {
    if (_modeEmail) {
      return [
        _emailField(),
        const SizedBox(height: 14),
        TextFormField(
          controller: _password,
          obscureText: _hidePassword,
          autofillHints: const [AutofillHints.password],
          onFieldSubmitted: (_) => _submit(),
          validator: (value) => value == null || value.isEmpty ? 'Saisissez votre mot de passe.' : null,
          decoration: InputDecoration(
            labelText: 'Mot de passe',
            hintText: 'Votre mot de passe',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              tooltip: _hidePassword ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
              style: IconButton.styleFrom(backgroundColor: Colors.transparent, side: BorderSide.none),
              onPressed: () => setState(() => _hidePassword = !_hidePassword),
              icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            ),
          ),
        ),
      ];
    }
    return switch (_etape) {
      _Etape.telephone => [
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            validator: validatePhone,
            decoration: const InputDecoration(
              labelText: 'Numéro de téléphone',
              hintText: '+221 77 000 00 00',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
        ],
      _Etape.pin => [
          _numeroRappel(),
          const SizedBox(height: 12),
          _pinField(_pin, 'Code PIN', autofocus: true),
          const SizedBox(height: 6),
          _resterConnectee(),
        ],
      _Etape.inscription => [
          _numeroRappel(),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _nameField(_firstName, 'Prénom', 'Fatou')),
              const SizedBox(width: 10),
              Expanded(child: _nameField(_lastName, 'Nom', 'Ndiaye')),
            ],
          ),
          const SizedBox(height: 14),
          _emailField(),
          const SizedBox(height: 14),
          TextFormField(
            controller: _dateOfBirth,
            readOnly: true,
            onTap: _pickBirthDate,
            validator: (value) => value == null || value.isEmpty ? 'Choisissez votre date de naissance.' : null,
            decoration: const InputDecoration(
              labelText: 'Date de naissance',
              hintText: 'AAAA-MM-JJ',
              prefixIcon: Icon(Icons.cake_outlined),
              suffixIcon: Icon(Icons.calendar_month_outlined),
            ),
          ),
        ],
      _Etape.code => [
          TextFormField(
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            onFieldSubmitted: (_) => _submit(),
            validator: (value) => value != null && RegExp(r'^\d{6}$').hasMatch(value)
                ? null
                : 'Le code contient 6 chiffres.',
            style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              labelText: 'Code de vérification',
              hintText: '000000',
              prefixIcon: Icon(Icons.mark_email_read_outlined),
            ),
          ),
        ],
      _Etape.nouveauPin => [
          _pinField(_newPin, 'Nouveau code PIN', autofocus: true, validator: validatePin),
          const SizedBox(height: 14),
          _pinField(
            _confirmPin,
            'Confirmez le code PIN',
            validator: (value) => value != _newPin.text ? 'Les deux codes PIN sont différents.' : null,
          ),
          const SizedBox(height: 6),
          _resterConnectee(),
        ],
    };
  }

  List<Widget> _liensSecondaires() {
    if (_modeEmail || _etape == _Etape.telephone) return const [];
    final occupe = widget.auth.isSubmitting;
    return [
      const SizedBox(height: 8),
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: occupe ? null : () => _goTo(_Etape.telephone),
            child: const Text('Changer de numéro'),
          ),
          if (_etape == _Etape.pin)
            TextButton(onPressed: occupe ? null : _forgotPin, child: const Text('PIN oublié ?')),
          if (_etape == _Etape.code)
            TextButton(
              onPressed: occupe || _resendSeconds > 0 ? null : _resendCode,
              child: Text(_resendSeconds > 0 ? 'Renvoyer le code (${_resendSeconds}s)' : 'Renvoyer le code'),
            ),
        ],
      ),
    ];
  }

  Widget _numeroRappel() {
    final p = context.yay;
    return Row(
      children: [
        Icon(Icons.phone_outlined, size: 18, color: p.textMuted),
        const SizedBox(width: 8),
        Text(_phone.text.trim(), style: TextStyle(color: p.textMain, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // Material transparent : l'effet visuel du toucher reste visible sur le fond de la carte
  Widget _resterConnectee() => Material(
    type: MaterialType.transparency,
    child: CheckboxListTile(
      value: _stayConnected,
      onChanged: (value) => setState(() => _stayConnected = value ?? false),
      contentPadding: EdgeInsets.zero,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      title: const Text('Rester connectée sur ce téléphone'),
      subtitle: const Text('30 jours, prolongés à chaque ouverture. À éviter sur un téléphone partagé.'),
    ),
  );

  Widget _pinField(
    TextEditingController controller,
    String label, {
    bool autofocus = false,
    FormFieldValidator<String>? validator,
  }) => TextFormField(
    controller: controller,
    autofocus: autofocus,
    obscureText: true,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
    onFieldSubmitted: (_) => _submit(),
    validator: validator ?? (value) => value != null && RegExp(r'^\d{4}$').hasMatch(value) ? null : 'Le PIN contient 4 chiffres.',
    style: const TextStyle(fontSize: 22, letterSpacing: 10, fontWeight: FontWeight.w600),
    decoration: InputDecoration(labelText: label, hintText: '••••', prefixIcon: const Icon(Icons.pin_outlined)),
  );

  Widget _emailField() => TextFormField(
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
  );

  Widget _nameField(TextEditingController controller, String label, String hint) => TextFormField(
    controller: controller,
    textCapitalization: TextCapitalization.words,
    textInputAction: TextInputAction.next,
    validator: (value) =>
        value == null || value.trim().length < 2 ? 'Au moins 2 caractères.' : null,
    decoration: InputDecoration(labelText: label, hintText: hint),
  );
}

/// PIN à 4 chiffres, ni identiques ni qui se suivent (même règle que l'API).
String? validatePin(String? value) {
  if (value == null || !RegExp(r'^\d{4}$').hasMatch(value)) return 'Le PIN contient 4 chiffres.';
  final d = value.codeUnits;
  final identiques = d.toSet().length == 1;
  var croissant = true;
  var decroissant = true;
  for (var i = 1; i < 4; i++) {
    croissant &= d[i] - d[i - 1] == 1;
    decroissant &= d[i - 1] - d[i] == 1;
  }
  return identiques || croissant || decroissant
      ? 'Trop facile à deviner (chiffres identiques ou qui se suivent).'
      : null;
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

// ==================== Onglets Téléphone / E-mail ====================

class _ModeTabs extends StatelessWidget {
  const _ModeTabs({required this.gauche, required this.droite, required this.droiteActive, required this.onChanged});
  final String gauche;
  final String droite;
  final bool droiteActive;
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
          Expanded(child: _Onglet(titre: gauche, actif: !droiteActive, onTap: () => onChanged(false))),
          const SizedBox(width: 4),
          Expanded(child: _Onglet(titre: droite, actif: droiteActive, onTap: () => onChanged(true))),
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
