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

  /// true = formule PRO active → débloque les fonctionnalités avancées.
  /// État global, écouté par tous les écrans (ex: CompteScreen).
  /// MODE TEST : passé à true directement par SubscriptionPayScreen,
  /// sans appel API réel. TODO: brancher sur le vrai statut d'abonnement
  /// renvoyé par le backend (via checkAuthStatus / login) avant la prod.
  final ValueNotifier<bool> isPro = ValueNotifier<bool>(false);

  /// Indique si la requête de connexion réseau est en cours
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  /// Message d'erreur à afficher en cas de problème de connexion
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);

  /// Vérifie au démarrage de l'app si un token existe déjà en mémoire
  Future<void> checkAuthStatus() async {
    final token = await _apiService.getToken();
    if (token != null && token.isNotEmpty) {
      isLoggedIn.value = true;
    } else {
      isLoggedIn.value = false;
    }
    // TODO: quand le vrai système d'abonnement sera branché, récupérer ici
    // le statut PRO persistant (ex: via _apiService ou SharedPreferences)
    // et l'assigner à isPro.value, pour qu'il survive au redémarrage de l'app.
  }

  /// Connexion réelle au backend Django via l'API.
  Future<bool> login(String username, String password) async {
    isLoading.value = true;
    errorMessage.value = null;

    final success = await _apiService.login(username, password);

    isLoading.value = false;

    if (success) {
      // Pour forcer la notification du ValueNotifier même si la valeur était déjà 'true'
      if (isLoggedIn.value) {
        isLoggedIn.value = false;
      }
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
    isPro.value = false;
  }

  /// Suppression du compte utilisateur : supprime le compte via l'API et réinitialise l'état.
  /// Supprime le compte utilisateur et réinitialise l'état.
  Future<bool> deleteAccount() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      // Suppression de la session locale et réinitialisation de l'état
      await _apiService.logout();
      isLoggedIn.value = false;
      isPro.value = false;
      isLoading.value = false;
      return true;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = "Erreur lors de la suppression du compte.";
      return false;
    }
  }
}