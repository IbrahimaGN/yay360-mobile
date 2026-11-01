import 'package:flutter/material.dart';

import '../state/auth_controller.dart';
import '../theme.dart';

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
            'telephone': _normalizePhone(_phone.text),
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
      _dateOfBirth.text =
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  Future<void> _openPartnerInvitation() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PartnerInvitationSheet(auth: widget.auth),
    );
    if (result == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(22, 20, 22, 28 + bottomInset),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _Brand()),
                      IconButton(
                        tooltip: Theme.of(context).brightness == Brightness.dark
                            ? 'Activer le thème clair'
                            : 'Activer le thème sombre',
                        onPressed: widget.onToggleTheme,
                        icon: Icon(
                          Theme.of(context).brightness == Brightness.dark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        colors: [YayColors.green, Color(0xFF1E3F32)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Eyebrow(text: 'À VOS CÔTÉS, À CHAQUE ÉTAPE'),
                        SizedBox(height: 14),
                        Text(
                          'Votre grossesse,\naccompagnée avec soin.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                            height: 1.16,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Des repères utiles, un suivi organisé et vos proches à vos côtés.',
                          style: TextStyle(
                            color: Color(0xFFD6E4DA),
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _ModeButton(
                          title: 'Connexion',
                          selected: !_registerMode,
                          onTap: () => setState(() {
                            _registerMode = false;
                            widget.auth.error = null;
                          }),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ModeButton(
                          title: 'Inscription',
                          selected: _registerMode,
                          onTap: () => setState(() {
                            _registerMode = true;
                            widget.auth.error = null;
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_registerMode) ...[
                          Row(
                            children: [
                              Expanded(
                                child: _textField(
                                  _firstName,
                                  'Prénom',
                                  'Fatou',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _textField(_lastName, 'Nom', 'Ndiaye'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                        ],
                        _textField(
                          _email,
                          'Adresse e-mail',
                          'vous@exemple.com',
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Saisissez votre e-mail.';
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Adresse e-mail invalide.';
                            }
                            return null;
                          },
                        ),
                        if (_registerMode) ...[
                          const SizedBox(height: 14),
                          _textField(
                            _phone,
                            'Téléphone',
                            '+221 77 000 00 00',
                            keyboardType: TextInputType.phone,
                            validator: _validatePhone,
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
                              suffixIcon: Icon(Icons.calendar_month_outlined),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password,
                          obscureText: _hidePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Saisissez votre mot de passe.';
                            }
                            if (_registerMode &&
                                (value.length < 6 ||
                                    !RegExp(r'[A-Za-z]').hasMatch(value) ||
                                    !RegExp(r'\d').hasMatch(value))) {
                              return '6 caractères minimum, avec une lettre et un chiffre.';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            hintText: _registerMode
                                ? '6 caractères minimum'
                                : 'Votre mot de passe',
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _hidePassword = !_hidePassword,
                              ),
                              icon: Icon(
                                _hidePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),
                        if (_registerMode) ...[
                          const SizedBox(height: 12),
                          Text(
                            'En créant votre espace, vous pourrez suivre les étapes clés de votre grossesse et organiser vos rendez-vous.',
                            style: TextStyle(
                              color: context.yayMuted,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                        if (widget.auth.error != null) ...[
                          const SizedBox(height: 14),
                          _ErrorBox(message: widget.auth.error!),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: widget.auth.isSubmitting ? null : _submit,
                          child: widget.auth.isSubmitting
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _registerMode
                                      ? 'Créer mon espace'
                                      : 'Se connecter',
                                ),
                        ),
                      ],
                    ),
                  ),
                  if (!_registerMode) ...[
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: _openPartnerInvitation,
                      icon: const Icon(Icons.favorite_border),
                      label: const Text(
                        'J’ai reçu une invitation de mon conjoint',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: YayColors.teal,
                        minimumSize: const Size.fromHeight(48),
                        side: BorderSide(color: context.yayBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Text(
                    'YAY360 accompagne votre suivi et ne remplace pas l’avis d’un professionnel de santé.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.yayMuted,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label,
    String hint, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: keyboardType == TextInputType.emailAddress
          ? TextCapitalization.none
          : TextCapitalization.words,
      validator:
          validator ??
          (value) => value == null || value.trim().length < 2
              ? 'Saisissez au moins 2 caractères.'
              : null,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  String _normalizePhone(String value) =>
      value.replaceAll(RegExp(r'[\s().-]'), '');

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Saisissez votre téléphone.';
    }
    if (!RegExp(
      r'^\+221(70|71|75|76|77|78)\d{7}$',
    ).hasMatch(_normalizePhone(value))) {
      return 'Format attendu : +221 77 000 00 00.';
    }
    return null;
  }
}

class _PartnerInvitationSheet extends StatefulWidget {
  const _PartnerInvitationSheet({required this.auth});
  final AuthController auth;

  @override
  State<_PartnerInvitationSheet> createState() =>
      _PartnerInvitationSheetState();
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
    );
    if (date != null) {
      _birth.text =
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
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
      'telephone': _phone.text.replaceAll(RegExp(r'[\s().-]'), ''),
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .9,
        ),
        decoration: BoxDecoration(
          color: context.yayCanvas,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.yayBorder,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Rejoindre le dossier familial',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.yayInk,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Complétez le formulaire avec le token et l’e-mail de l’invitation reçue.',
                    style: TextStyle(color: context.yayMuted, height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  _inviteField(_token, 'Token d’invitation'),
                  const SizedBox(height: 12),
                  _inviteField(
                    _email,
                    'E-mail invité',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _inviteField(_firstName, 'Prénom')),
                      const SizedBox(width: 10),
                      Expanded(child: _inviteField(_lastName, 'Nom')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _inviteField(
                    _phone,
                    'Téléphone',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _birth,
                    readOnly: true,
                    onTap: _selectDate,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Choisissez votre date de naissance.'
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Date de naissance',
                      suffixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _inviteField(
                    _password,
                    'Mot de passe (6 caractères minimum)',
                    obscure: true,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    _ErrorBox(message: _error!),
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
                        : const Text('Créer mon compte conjoint'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inviteField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    bool obscure = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Champ requis.';
        if (label == 'E-mail invité' && !value.contains('@')) {
          return 'E-mail invalide.';
        }
        if (label == 'Téléphone' &&
            !RegExp(
              r'^\+221(70|71|75|76|77|78)\d{7}$',
            ).hasMatch(value.replaceAll(RegExp(r'[\s().-]'), ''))) {
          return 'Format attendu : +221 77 000 00 00.';
        }
        if (obscure &&
            (value.length < 6 ||
                !RegExp(r'[A-Za-z]').hasMatch(value) ||
                !RegExp(r'\d').hasMatch(value))) {
          return '6 caractères minimum, avec une lettre et un chiffre.';
        }
        return null;
      },
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _Brand extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      ClipOval(
        child: Image.asset(
          'assets/images/yay360-logo.png',
          width: 42,
          height: 42,
          fit: BoxFit.cover,
        ),
      ),
      const SizedBox(width: 10),
      Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'YAY',
              style: TextStyle(color: context.yayInk),
            ),
            TextSpan(
              text: '360',
              style: TextStyle(color: YayColors.rose),
            ),
          ],
        ),
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
        ),
      ),
    ],
  );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFFE9AFB9),
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 1,
    ),
  );
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.title,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: selected ? context.yayRoseContainer : context.yaySurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? YayColors.rose.withValues(alpha: .35)
              : context.yayBorder,
        ),
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            color: selected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : context.yayMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: context.yayRoseContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      message,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        fontSize: 13,
      ),
    ),
  );
}
