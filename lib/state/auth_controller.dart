import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../data/api_client.dart';
import '../data/models.dart';

class AuthController extends ChangeNotifier {
  /// [client] : client HTTP de remplacement (tests). Par défaut, le vrai réseau.
  AuthController({this.client});

  final http.Client? client;
  late final ApiClient api = ApiClient(client: client, onUnauthorized: _sessionExpired);

  UserSession? session;
  bool isRestoring = true;
  bool isSubmitting = false;
  String? error;

  void _sessionExpired() {
    session = null;
    notifyListeners();
  }

  /// Au démarrage : reprend la session enregistrée. Avec « rester connectée », le jeton de session
  /// est échangé contre un nouveau (rotation), ce qui prolonge la session de 30 jours.
  Future<void> restoreSession() async {
    try {
      final saved = await api.readSession();
      final refreshToken = saved?.refreshToken;
      if (saved != null && refreshToken != null) {
        try {
          final renewed = await api.mobileRefresh(refreshToken);
          await api.saveSession(renewed);
          session = renewed;
        } on ApiException catch (exception) {
          if (exception.statusCode == 401) {
            // Session expirée ou révoquée : retour à l'écran de connexion
            await api.clearSession();
            session = null;
          } else {
            // Hors connexion : on garde la session enregistrée, elle sera renouvelée plus tard
            session = saved;
          }
        }
      } else {
        session = saved;
      }
    } on Exception {
      session = null;
      error = 'Impossible de restaurer la session enregistrée.';
    } finally {
      isRestoring = false;
      notifyListeners();
    }
  }

  // ==================== Connexion par téléphone et PIN ====================

  /// Étape « numéro » : `PIN`, `CODE_ENVOYE` ou `INSCRIPTION`. Null en cas d'erreur ([error] renseigné).
  Future<MobileStart?> startWithPhone(String phone, {bool forgotPin = false}) =>
      _step(() => forgotPin ? api.mobileForgotPin(phone) : api.mobileStart(phone));

  Future<MobileStart?> registerWithPhone(Map<String, dynamic> values) => _step(() => api.mobileRegister(values));

  /// Renvoie le jeton qui permet de définir le PIN, ou null si le code est refusé.
  Future<String?> verifyCode(String phone, String code) => _step(() => api.mobileVerifyCode(phone, code));

  Future<bool> setPin(String pinToken, String pin, {required bool stayConnected}) => _authenticate(
    () => api.mobileSetPin(pinToken, pin, stayConnected: stayConnected),
    persist: stayConnected,
  );

  Future<bool> loginWithPin(String phone, String pin, {required bool stayConnected}) => _authenticate(
    () => api.mobileLoginPin(phone, pin, stayConnected: stayConnected),
    persist: stayConnected,
  );

  // ==================== Connexion par e-mail (conservée) ====================

  Future<bool> login(String email, String password) => _authenticate(() async {
    final result = await api.login(email.trim(), password);
    if (result.role != 'FEMME_ENCEINTE' && result.role != 'CONJOINT') {
      throw const ApiException(
        'Cette application est réservée aux femmes enceintes et à leur conjoint.',
      );
    }
    return result;
  });

  Future<bool> register(Map<String, dynamic> values) =>
      _authenticate(() => api.register(values));

  Future<bool> acceptInvitation(Map<String, dynamic> values) =>
      _authenticate(() => api.acceptInvitation(values));

  Future<T?> _step<T>(Future<T> Function() action) async {
    isSubmitting = true;
    error = null;
    notifyListeners();
    try {
      return await action();
    } on ApiException catch (exception) {
      error = exception.message;
      return null;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> _authenticate(Future<UserSession> Function() action, {bool persist = true}) async {
    isSubmitting = true;
    error = null;
    notifyListeners();
    try {
      final result = await action();
      await api.saveSession(result, persist: persist);
      session = result;
      return true;
    } on ApiException catch (exception) {
      error = exception.message;
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  /// Déconnexion : la session longue est révoquée côté serveur, puis effacée du téléphone.
  Future<void> logout() async {
    final refreshToken = session?.refreshToken;
    if (refreshToken != null) {
      try {
        await api.mobileLogout(refreshToken);
      } on ApiException {
        // Hors connexion : la session est tout de même effacée de l'appareil
      }
    }
    await api.clearSession();
    session = null;
    error = null;
    notifyListeners();
  }
}
