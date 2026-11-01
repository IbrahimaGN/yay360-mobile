import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'models.dart';

class ApiException implements Exception {
  const ApiException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client, this.onUnauthorized})
    : _client = client ?? http.Client();

  static const _configuredApiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static final apiBaseUrl = _configuredApiBaseUrl.isNotEmpty
      ? _configuredApiBaseUrl
      : kIsWeb
      ? 'http://localhost:8080'
      : 'http://10.0.2.2:8080';
  static const _tokenKey = 'yay360.auth.token';
  static const _sessionKey = 'yay360.auth.session';

  final http.Client _client;
  final void Function()? onUnauthorized;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<UserSession?> readSession() async {
    final raw = await _storage.read(key: _sessionKey);
    if (raw == null) return null;
    try {
      return UserSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      await clearSession();
      return null;
    } on TypeError {
      await clearSession();
      return null;
    }
  }

  Future<void> saveSession(UserSession session) async {
    await _storage.write(key: _tokenKey, value: session.token);
    await _storage.write(key: _sessionKey, value: jsonEncode(session.toJson()));
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _sessionKey);
  }

  Future<UserSession> login(String email, String password) async {
    final result = await post('/auth/login', {
      'email': email,
      'password': password,
    });
    return UserSession.fromJson(result);
  }

  Future<UserSession> register(Map<String, dynamic> values) async {
    final result = await post('/auth/register', values);
    return UserSession.fromJson(result);
  }

  Future<UserSession> acceptInvitation(Map<String, dynamic> values) async {
    final result = await post('/auth/accept-invitation-conjoint', values);
    return UserSession.fromJson(result);
  }

  Future<Map<String, dynamic>> get(String path) => _request('GET', path);

  Future<List<dynamic>> getList(String path) async {
    final result = await _request('GET', path);
    if (result['_list'] is List<dynamic>) {
      return result['_list'] as List<dynamic>;
    }
    throw const ApiException('Réponse inattendue du serveur.');
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) =>
      _request('POST', path, body: body);

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$apiBaseUrl$path');
    final token = await readToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    late http.Response response;
    try {
      if (method == 'GET') {
        response = await _client
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 20));
      } else if (method == 'POST') {
        response = await _client
            .post(uri, headers: headers, body: jsonEncode(body))
            .timeout(const Duration(seconds: 30));
      } else {
        throw ArgumentError.value(method, 'method');
      }
    } on http.ClientException {
      throw const ApiException(
        'Connexion impossible. Vérifiez le réseau et l’adresse de l’API.',
      );
    } on FormatException {
      throw const ApiException('Adresse de l’API invalide.');
    } on TimeoutException {
      throw const ApiException(
        'Le serveur met trop de temps à répondre. Réessayez.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _errorMessage(response.body);
      if (response.statusCode == 401 && token != null) {
        await clearSession();
        onUnauthorized?.call();
      }
      throw ApiException(message, response.statusCode);
    }

    if (response.bodyBytes.isEmpty) return <String, dynamic>{};
    late dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const ApiException('Le serveur a renvoyé une réponse illisible.');
    }
    if (decoded is List<dynamic>) return {'_list': decoded};
    if (decoded is Map<String, dynamic>) return decoded;
    throw const ApiException('Réponse inattendue du serveur.');
  }

  String _errorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'] ?? decoded['error'];
        if (message is String && message.isNotEmpty) return message;
        final errors = decoded['errors'];
        if (errors is List && errors.isNotEmpty) return errors.join('\n');
      }
    } on FormatException {
      // The API may return an empty or non-JSON error body.
    }
    return 'La demande a échoué. Réessayez dans quelques instants.';
  }
}
