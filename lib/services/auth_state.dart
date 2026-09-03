import 'package:flutter/foundation.dart';

/// État d'authentification global de l'application.
///
/// ⚠️ MOCK / TEMPORAIRE : pour l'instant, `login()` ne fait aucune vérification
/// réelle — il simule juste une connexion réussie. Quand le backend Django
/// sera prêt, remplacer le contenu de `login()` par un vrai appel API
/// (via http/dio) qui vérifie l'email/mot de passe et récupère un token.
///
/// Utilisation : AuthState.instance.isLoggedIn.value
class AuthState {
  AuthState._internal();
  static final AuthState instance = AuthState._internal();

  /// true = utilisateur connecté → afficher le Dashboard
  /// false = utilisateur non connecté → afficher le LoginScreen
  final ValueNotifier<bool> isLoggedIn = ValueNotifier<bool>(false);

  /// Simule une connexion réussie.
  /// TODO backend : remplacer par un appel API réel + stockage du token
  /// (ex: via shared_preferences) une fois l'endpoint Django disponible.
  void login() {
    isLoggedIn.value = true;
  }

  /// Simule une déconnexion.
  /// TODO backend : supprimer aussi le token stocké localement.
  void logout() {
    isLoggedIn.value = false;
  }
}