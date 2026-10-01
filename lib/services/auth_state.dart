import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Erreur d'authentification avec un message prêt à afficher à l'utilisateur.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

/// État d'authentification global de l'application.
/// Utilisation : AuthState.instance.isLoggedIn.value
class AuthState {
  AuthState._internal();
  static final AuthState instance = AuthState._internal();

  // Émulateur Android : 10.0.2.2 = ton PC. Téléphone réel : IP locale du PC.
  // Pour passer en production, remplacer par l'URL Render.
  static const String baseUrl = 'https://mon-api-django-supabase.onrender.com';

  // Endpoint de connexion (core/urls.py : api/v1/ + femi_api/urls.py : auth/token/)
  static const String _loginPath = '/api/v1/auth/token/';

  static const String _tokenKey = 'auth_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Token reçu de l'API (null si non connecté).
  String? token;

  /// true = utilisateur connecté → afficher le Dashboard
  /// false = utilisateur non connecté → afficher le LoginScreen
  final ValueNotifier<bool> isLoggedIn = ValueNotifier<bool>(false);

  /// À appeler dans main() avant runApp pour rester connecté entre deux
  /// ouvertures de l'app.
  Future<void> restoreSession() async {
    token = await _storage.read(key: _tokenKey);
    isLoggedIn.value = token != null;
  }

  /// Connexion via l'API. Lève une [AuthException] en cas d'échec.
  Future<void> login(String identifiant, String password) async {
    final http.Response res;
    try {
      res = await http
          .post(
        Uri.parse('$baseUrl$_loginPath'),
        headers: {'Content-Type': 'application/json'},
        // Le backend attend le champ 'identifiant' (testé avec curl).
        body: jsonEncode({'identifiant': identifiant, 'password': password}),
      )
      // 60 s : le premier appel sur Render (plan gratuit) peut être lent.
          .timeout(const Duration(seconds: 60));
    } on TimeoutException {
      throw AuthException(
          'Le serveur met trop de temps à répondre. Réessayez dans un instant.');
    } on SocketException {
      throw AuthException('Pas de connexion internet.');
    }

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      // Réponse confirmée : { token, utilisateur_id, role, entreprise_id, entreprise_nom }
      final t = data['token'] as String?;
      if (t == null) throw AuthException('Réponse inattendue du serveur.');
      token = t;
      await _storage.write(key: _tokenKey, value: t);
      isLoggedIn.value = true;
    } else if (res.statusCode == 400 || res.statusCode == 401) {
      throw AuthException('Identifiant ou mot de passe incorrect.');
    } else {
      throw AuthException('Erreur serveur (${res.statusCode}).');
    }
  }

  /// Déconnexion : supprime aussi le token stocké localement.
  Future<void> logout() async {
    token = null;
    await _storage.delete(key: _tokenKey);
    isLoggedIn.value = false;
  }
}