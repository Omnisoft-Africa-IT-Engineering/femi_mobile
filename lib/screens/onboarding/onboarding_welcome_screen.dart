import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../auth/sign_up_screen.dart';

/// Premier écran vu par un utilisateur non connecté : présente Femi,
/// puis propose de créer un compte ou de se connecter.
class OnboardingWelcomeScreen extends StatelessWidget {
  const OnboardingWelcomeScreen({super.key});

  static const Color _bgColor = Color(0xFFF7F9FC);
  static const Color _accentTeal = Color(0xFF80F2DD);
  static const Color _darkGreen = Color(0xFF0D5C52);
  static const Color _primaryBlue = Color(0xFF1565D8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(),

              // Logo
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: _accentTeal,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(Icons.auto_awesome, color: _darkGreen, size: 44),
              ),
              const SizedBox(height: 28),

              const Text(
                'Femi',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Votre assistant comptable intelligent pour piloter\nvotre activité en toute simplicité.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.4),
              ),
              const SizedBox(height: 36),

              // Points forts
              _buildHighlight(
                icon: Icons.receipt_long_outlined,
                text: 'Registre journalier, Grand livre, Bilan et bien plus',
              ),
              const SizedBox(height: 16),
              _buildHighlight(
                icon: Icons.chat_bubble_outline,
                text: 'Un assistant IA pour répondre à vos questions comptables',
              ),
              const SizedBox(height: 16),
              _buildHighlight(
                icon: Icons.picture_as_pdf_outlined,
                text: 'Exportez vos documents comptables en PDF, à tout moment',
              ),

              const Spacer(),

              // Bouton principal
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignUpScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Créer un compte',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Bouton secondaire
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _darkGreen,
                    side: const BorderSide(color: _darkGreen, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Se connecter',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlight({required IconData icon, required String text}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _accentTeal.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _darkGreen, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13.5, color: Colors.black87, height: 1.3),
          ),
        ),
      ],
    );
  }
}