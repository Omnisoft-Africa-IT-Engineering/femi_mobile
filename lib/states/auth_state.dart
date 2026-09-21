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
  /// Resynchronisé depuis le vrai profil Django (voir
  /// refreshIsProFromBackend) au démarrage, après login, après register,
  /// et après un paiement réussi — ce n'est donc plus une valeur purement
  /// locale qui pourrait se désynchroniser de la vérité serveur.
  final ValueNotifier<bool> isPro = ValueNotifier<bool>(false);

  /// Indique si la requête de connexion réseau est en cours
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  /// Message d'erreur à afficher en cas de problème de connexion
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);

  /// Relit le profil utilisateur réel depuis Django (GET /auth/profile/)
  /// et met à jour isPro en fonction du champ renvoyé par le backend.
  ///
  /// ⚠️ Le nom exact du champ (is_pro ? plan ? subscription_status ?)
  /// n'est pas encore confirmé côté Django — cette méthode essaie
  /// plusieurs noms plausibles. À AJUSTER dès que le champ réel est
  /// connu : il suffit de compléter/corriger _extractIsPro ci-dessous,
  /// rien d'autre à changer dans l'app.
  ///
  /// Si aucun champ reconnu n'est trouvé dans la réponse, isPro n'est PAS
  /// modifié (on ne force pas à false par erreur d'interprétation).
  Future<void> refreshIsProFromBackend() async {
    final profile = await _apiService.getUserProfile();
    if (profile == null) return;

    final detected = _extractIsPro(profile);
    if (detected != null) {
      isPro.value = detected;
    } else {
      debugPrint(
        '⚠️ Impossible de déterminer le statut Pro depuis /auth/profile/ '
        '— aucun champ reconnu dans la réponse : $profile. '
        'Vérifiez le nom exact du champ côté Django et ajustez '
        '_extractIsPro dans auth_state.dart.',
      );
    }
  }

  bool? _extractIsPro(Map<String, dynamic> profile) {
    // Champs booléens directs les plus probables.
    for (final key in ['is_pro', 'isPro', 'is_premium', 'pro']) {
      final value = profile[key];
      if (value is bool) return value;
      if (value is String) {
        final lower = value.toLowerCase();
        if (lower == 'true' || lower == 'false') return lower == 'true';
      }
    }

    // Champs "plan" / "subscription_status" (chaîne de caractères).
    final planValue = profile['plan'] ??
        profile['subscription_status'] ??
        profile['subscription_plan'] ??
        profile['abonnement'];

    if (planValue != null) {
      final lower = planValue.toString().toLowerCase();
      // 'micro' est un plan payant lui aussi (pas juste gratuit) — à
      // ajuster si "gratuit"/"free" doit être distingué d'un vrai palier.
      return lower == 'pro' ||
          lower == 'business' ||
          lower == 'micro' ||
          lower == 'active' ||
          lower == 'actif' ||
          lower == 'premium';
    }

    return null;
  }

  /// Vérifie au démarrage de l'app si un token existe déjà en mémoire,
  /// et si oui, resynchronise isPro avec le vrai statut Django.
  Future<void> checkAuthStatus() async {
    final token = await _apiService.getToken();
    if (token != null && token.isNotEmpty) {
      isLoggedIn.value = true;
      await refreshIsProFromBackend();
    } else {
      isLoggedIn.value = false;
    }
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
      await refreshIsProFromBackend();
      return true;
    } else {
      errorMessage.value = "Identifiants incorrects ou serveur indisponible.";
      return false;
    }
  }

  /// Inscription : crée l'entreprise + l'utilisateur, puis connecte
  /// automatiquement (même comportement que login()).
  Future<bool> register({
    required String username,
    required String password,
    required String nomEntreprise,
    String? nomComplet,
    String? email,
    String? telephoneWhatsapp,
    String? secteurNom,
    String? devise,
    // Forme juridique — INDIVIDUEL/SARL/SA/AUTRE — relayée telle quelle
    // à FemiApiService.register(), qui l'inclut dans le body si fournie.
    String? typeEntreprise,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;

    final success = await _apiService.register(
      username: username,
      password: password,
      nomEntreprise: nomEntreprise,
      nomComplet: nomComplet,
      email: email,
      telephoneWhatsapp: telephoneWhatsapp,
      secteurNom: secteurNom,
      devise: devise,
      typeEntreprise: typeEntreprise,
    );

    isLoading.value = false;

    if (success) {
      if (isLoggedIn.value) {
        isLoggedIn.value = false;
      }
      isLoggedIn.value = true;
      // Un utilisateur qui vient de s'inscrire n'a normalement pas encore
      // de formule payante (sauf si le paiement a eu lieu juste avant cet
      // appel, comme dans le flux onboarding → SubscriptionPayScreen : dans
      // ce cas c'est activatePlan(), appelé séparément là-bas, qui fera
      // foi). On resynchronise quand même par cohérence avec login().
      await refreshIsProFromBackend();
      return true;
    } else {
      errorMessage.value = "Impossible de créer le compte (nom d'utilisateur déjà pris, ou erreur serveur).";
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