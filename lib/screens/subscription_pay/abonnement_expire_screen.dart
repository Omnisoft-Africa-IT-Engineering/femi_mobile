import 'package:flutter/material.dart';
import '../../states/auth_state.dart';
import 'subscription_pay_screen.dart';

import '../../theme/app_colors.dart';
/// Écran affiché à la place de toute l'app quand l'essai gratuit ou
/// l'abonnement est expiré.
class AbonnementExpireScreen extends StatelessWidget {
  /// Relit l'état de l'abonnement côté serveur.
  final Future<void> Function() onRecheck;

  const AbonnementExpireScreen({super.key, required this.onRecheck});

  static const Color _primaryColor = AppColors.vert;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 72, color: _primaryColor),
              const SizedBox(height: 24),
              const Text(
                'Votre accès Femi est terminé',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Votre essai gratuit ou votre abonnement a expiré. '
                'Choisissez une offre pour continuer à utiliser Femi.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SubscriptionPayScreen(),
                      ),
                    );
                    await onRecheck();
                  },
                  child: const Text('Voir les offres'),
                ),
              ),
              TextButton(
                onPressed: onRecheck,
                child: const Text("J'ai déjà payé, actualiser"),
              ),
              TextButton(
                onPressed: () => AuthState.instance.logout(),
                child: const Text('Se déconnecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
