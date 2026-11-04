import 'package:flutter/foundation.dart'; // Pour defaultTargetPlatform
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Pour récupérer le token FCM
import '../../services/femi_api_service.dart'; // Ajuste le chemin selon ton projet
import '../../services/abonnement_service.dart';
import '../../states/auth_state.dart';
import '../subscription_pay/abonnement_expire_screen.dart';
///import '../auth/login_screen.dart';
import '../onboarding/onboarding_welcome_screen.dart';
import '../../theme/app_colors.dart';
import '../../main.dart' show MainNavigationScreen;

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  /// Méthode d'enregistrement du token FCM auprès de Django
  Future<void> _registerFcmDevice() async {
    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        String plateforme = defaultTargetPlatform == TargetPlatform.iOS ? 'IOS' : 'ANDROID';
        await FemiApiService().enregistrerAppareil(fcmToken, plateforme);
      }
    } catch (e) {
      debugPrint("Erreur lors de l'enregistrement FCM dans AuthGate : $e");
    }
  }

  Future<void> _initAuth() async {
    await AuthState.instance.checkAuthStatus();

    // Si l'utilisateur est déjà connecté via sa session persistée
    if (AuthState.instance.isLoggedIn.value) {
      _registerFcmDevice(); // Appel asynchrone en arrière-plan
    }

    if (mounted) {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F9FC),
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.vert,
          ),
        ),
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: AuthState.instance.isLoggedIn,
      builder: (context, isLoggedIn, _) {
        return isLoggedIn
            ? const _AbonnementGuard()
            : const OnboardingWelcomeScreen();
      },
    );
  }
}

/// Affiche l'app, ou l'écran « abonnement expiré » quand l'accès est coupé.
/// Le statut est relu à chaque retour de l'app au premier plan.
class _AbonnementGuard extends StatefulWidget {
  const _AbonnementGuard();

  @override
  State<_AbonnementGuard> createState() => _AbonnementGuardState();
}

class _AbonnementGuardState extends State<_AbonnementGuard>
    with WidgetsBindingObserver {
  final AbonnementService _service = AbonnementService();
  bool _chargement = true;
  bool _bloque = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _verifier();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _verifier();
    }
  }

  Future<void> _verifier() async {
    final statut = await _service.getStatut();
    if (!mounted) return;
    setState(() {
      _chargement = false;
      // Statut illisible (réseau) : on garde l'état précédent. Le serveur
      // refuse de toute façon les requêtes d'un abonnement expiré.
      if (statut != null) {
        _bloque = statut.accesBloque;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F9FC),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.vert),
        ),
      );
    }
    if (_bloque) {
      return AbonnementExpireScreen(onRecheck: _verifier);
    }
    return const MainNavigationScreen();
  }
}
