import 'package:flutter/foundation.dart';
import '../services/femi_api_service.dart';

/// État d'authentification global de l'application connectée au backend Django.
class AuthState {
  AuthState._internal();
  static final AuthState instance = AuthState._internal();

  final FemiApiService _apiService = FemiApiService();

  /// true = utilisateur connecté → afficher le Dashboard
  /// false = utilisateur non connecté → afficher le LoginScreen
  final ValueNotifier<bool> isLoggedIn = ValueNotifier<bool>(false);

  /// Indique si la requête de connexion réseau est en cours
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  /// Message d'erreur à afficher en cas de problème de connexion
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);

  /// Vérifie au démarrage de l'app si un token existe déjà en mémoire
  Future<void> checkAuthStatus() async {
    final token = await _apiService.getToken();
    if (token != null) {
      isLoggedIn.value = true;
    }
  }

  /// Connexion réelle au backend Django via l'API.
  Future<bool> login(String username, String password) async {
    isLoading.value = true;
    errorMessage.value = null;

    final success = await _apiService.login(username, password);

    isLoading.value = false;

    if (success) {
      isLoggedIn.value = true;
      return true;
    } else {
      errorMessage.value = "Identifiants incorrects ou serveur indisponible.";
      return false;
    }
  }

  /// Déconnexion : supprime le token du stockage sécurisé et réinitialise l'état.
  Future<void> logout() async {
    await _apiService.logout();
    isLoggedIn.value = false;
  }
}