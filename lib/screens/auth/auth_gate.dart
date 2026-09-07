import 'package:flutter/material.dart';
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

  Future<void> _initAuth() async {
    await AuthState.instance.checkAuthStatus();
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