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
  Future<bool> loginWithGoogle() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      const String webClientId =
          '1056550417087-det0r9cbdnnpvtpjs0kp55psso0avt9f.apps.googleusercontent.com';

      // 1. Initialisation conditionnelle (serverClientId uniquement sur mobile)
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId: kIsWeb ? webClientId : null,
        serverClientId: kIsWeb ? null : webClientId,
      );

      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) {
        isLoading.value = false;
        return false;
      }

      final GoogleSignInAuthentication auth = await account.authentication;

      // 2. Récupération du token
      // Sur Web, auth.idToken contient le token JWT requis si le meta tag ou RenderButton est utilisé,
      // sinon auth.idToken ou auth.accessToken est transmis.
      final String? tokenToSend = auth.idToken ?? auth.accessToken;

      if (tokenToSend == null) {
        errorMessage.value = "Impossible d'obtenir le token Google.";
        isLoading.value = false;
        return false;
      }

      final success = await _apiService.googleLogin(tokenToSend);

      isLoading.value = false;

      if (success) {
        if (isLoggedIn.value) isLoggedIn.value = false;
        isLoggedIn.value = true;
        await refreshIsProFromBackend();
        return true;
      } else {
        errorMessage.value = "Échec de la connexion Google.";
        return false;
      }
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = "Erreur Google : $e";
      debugPrint('loginWithGoogle error: $e');
      return false;
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