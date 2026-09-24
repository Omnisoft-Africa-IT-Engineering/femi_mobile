import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/femi_api_service.dart';

/// État d'authentification global de l'application connectée au backend Django.
class AuthState {
  AuthState._internal();
  static final AuthState instance = AuthState._internal();

  final FemiApiService _apiService = FemiApiService();

  final ValueNotifier<bool> isLoggedIn = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isPro = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);

  Future<void> refreshIsProFromBackend() async {
    final profile = await _apiService.getUserProfile();
    if (profile == null) return;

    final detected = _extractIsPro(profile);
    if (detected != null) {
      isPro.value = detected;
    } else {
      debugPrint(
        '⚠️ Impossible de déterminer le statut Pro depuis /auth/profile/ '
        '— aucun champ reconnu dans la réponse : $profile.',
      );
    }
  }

  bool? _extractIsPro(Map<String, dynamic> profile) {
    for (final key in ['is_pro', 'isPro', 'is_premium', 'pro']) {
      final value = profile[key];
      if (value is bool) return value;
      if (value is String) {
        final lower = value.toLowerCase();
        if (lower == 'true' || lower == 'false') return lower == 'true';
      }
    }

    final planValue = profile['plan'] ??
        profile['subscription_status'] ??
        profile['subscription_plan'] ??
        profile['abonnement'];

    if (planValue != null) {
      final lower = planValue.toString().toLowerCase();
      return lower == 'pro' ||
          lower == 'business' ||
          lower == 'micro' ||
          lower == 'active' ||
          lower == 'actif' ||
          lower == 'premium';
    }

    return null;
  }

  Future<void> checkAuthStatus() async {
    final token = await _apiService.getToken();
    if (token != null && token.isNotEmpty) {
      isLoggedIn.value = true;
      await refreshIsProFromBackend();
    } else {
      isLoggedIn.value = false;
    }
  }

  Future<bool> login(String username, String password) async {
    isLoading.value = true;
    errorMessage.value = null;

    final success = await _apiService.login(username, password);

    isLoading.value = false;

    if (success) {
      if (isLoggedIn.value) isLoggedIn.value = false;
      isLoggedIn.value = true;
      await refreshIsProFromBackend();
      return true;
    } else {
      errorMessage.value = "Identifiants incorrects ou serveur indisponible.";
      return false;
    }
  }

  /// Connexion / inscription via Google
  /// Connexion / inscription via Google
/// Connexion / inscription via Google.
///
/// Retourne :
///
/// {
///   "success": true/false,
///   "is_new_user": true/false,
///   "google_data": {...}
/// }
///
/// Pour un nouvel utilisateur, aucun compte Django n'est encore créé.
/// Le formulaire d'inscription doit ensuite être affiché.

Future<Map<String, dynamic>> loginWithGoogle() async {
  isLoading.value = true;
  errorMessage.value = null;

  try {
    const String webClientId =
        '924074246865-e085gto40c946rm9abebo9sv89u7g0di.apps.googleusercontent.com';

    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      clientId: kIsWeb ? webClientId : null,
      serverClientId: kIsWeb ? null : webClientId,
    );

    // ==========================================================
    // 1. Ouvrir Google
    // ==========================================================

    final GoogleSignInAccount? account =
        await googleSignIn.signIn();

    if (account == null) {
      isLoading.value = false;

      return {
        'success': false,
        'is_new_user': false,
      };
    }

    // ==========================================================
    // 2. Récupérer l'authentification Google
    // ==========================================================

    final GoogleSignInAuthentication auth =
        await account.authentication;

    final String? tokenToSend =
        auth.idToken ?? auth.accessToken;

    if (tokenToSend == null) {
      isLoading.value = false;

      errorMessage.value =
          "Impossible d'obtenir le token Google.";

      return {
        'success': false,
        'is_new_user': false,
      };
    }

    // ==========================================================
    // 3. Envoyer le token à Django
    // ==========================================================

    final data =
        await _apiService.googleLogin(tokenToSend);

    if (data == null) {
      isLoading.value = false;

      errorMessage.value =
          "Échec de la connexion Google.";

      return {
        'success': false,
        'is_new_user': false,
      };
    }

    // ==========================================================
    // 4. NOUVEL UTILISATEUR
    // ==========================================================

    if (data['is_new_user'] == true) {
      isLoading.value = false;

      debugPrint(
        '🆕 Google : nouvel utilisateur.',
      );

      return {
        'success': true,
        'is_new_user': true,
        'google_data': data['google_data'],
      };
    }

    // ==========================================================
    // 5. UTILISATEUR EXISTANT
    // ==========================================================

    if (data['is_new_user'] == false) {
      isLoading.value = false;

      if (isLoggedIn.value) {
        isLoggedIn.value = false;
      }

      isLoggedIn.value = true;

      await refreshIsProFromBackend();

      return {
        'success': true,
        'is_new_user': false,
      };
    }

    // ==========================================================
    // 6. Réponse inattendue
    // ==========================================================

    isLoading.value = false;

    errorMessage.value =
        "Réponse inattendue du serveur.";

    return {
      'success': false,
      'is_new_user': false,
    };

  } catch (e) {
    isLoading.value = false;

    errorMessage.value =
        "Erreur Google : $e";

    debugPrint(
      'loginWithGoogle error: $e',
    );

    return {
      'success': false,
      'is_new_user': false,
    };
  }
}
  Future<bool> register({
    required String username,
    required String password,
    required String nomEntreprise,
    String? nomComplet,
    String? email,
    String? telephoneWhatsapp,
    String? secteurNom,
    String? devise,
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
      if (isLoggedIn.value) isLoggedIn.value = false;
      isLoggedIn.value = true;
      await refreshIsProFromBackend();
      return true;
    } else {
      errorMessage.value =
          "Impossible de créer le compte (nom d'utilisateur déjà pris, ou erreur serveur).";
      return false;
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    isLoggedIn.value = false;
    isPro.value = false;
  }

  Future<bool> deleteAccount() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      await _apiService.logout();
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
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