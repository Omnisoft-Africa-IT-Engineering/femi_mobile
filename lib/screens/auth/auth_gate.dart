import 'package:flutter/foundation.dart'; // Pour defaultTargetPlatform
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Pour récupérer le token FCM
import '../../services/femi_api_service.dart'; // Ajuste le chemin selon ton projet
import '../../states/auth_state.dart';
///import '../auth/login_screen.dart';
import '../onboarding/onboarding_welcome_screen.dart';
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
            color: Color(0xFF1565D8),
          ),
        ),
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: AuthState.instance.isLoggedIn,
      builder: (context, isLoggedIn, _) {
        return isLoggedIn
            ? const MainNavigationScreen()
            : const OnboardingWelcomeScreen();
      },
    );
  }
}