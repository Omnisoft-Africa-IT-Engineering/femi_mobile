import 'package:flutter/material.dart';
import '../../services/auth_state.dart';
import '../auth/login_screen.dart';
import '../../main.dart' show MainNavigationScreen;

/// Portail d'authentification : affiche automatiquement LoginScreen ou
/// MainNavigationScreen selon AuthState.instance.isLoggedIn.
///
/// Ce widget écoute AuthState en temps réel : dès que login()/logout() est
/// appelé quelque part dans l'app, l'écran affiché change automatiquement,
/// sans navigation manuelle à gérer.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AuthState.instance.isLoggedIn,
      builder: (context, isLoggedIn, _) {
        return isLoggedIn
            ? const MainNavigationScreen()
            : const LoginScreen();
      },
    );
  }
}