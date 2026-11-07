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

  Future<void> restoreSession() async {
    try {
      session = await api.readSession();
    } on Exception {
      session = null;
      error = 'Impossible de restaurer la session enregistrée.';
    } finally {
      isRestoring = false;
      notifyListeners();
    }
  }

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

  Future<bool> _authenticate(Future<UserSession> Function() action) async {
    isSubmitting = true;
    error = null;
    notifyListeners();
    try {
      final result = await action();
      await api.saveSession(result);
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

  Future<void> logout() async {
    await api.clearSession();
    session = null;
    error = null;
    notifyListeners();
  }
}
