import 'package:flutter/material.dart';
import '../../services/auth_state.dart';
import '../onboarding/onboarding_welcome_screen.dart';
import '../../main.dart' show MainNavigationScreen;

/// Portail d'authentification : affiche automatiquement l'écran d'accueil
/// (onboarding) ou MainNavigationScreen selon AuthState.instance.isLoggedIn.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
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