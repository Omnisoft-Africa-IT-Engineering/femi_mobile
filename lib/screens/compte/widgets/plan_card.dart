import 'package:flutter/material.dart';

class PlanCard extends StatelessWidget {
  final bool isPro;
  final VoidCallback onUpgradePressed;

  const PlanCard({
    super.key,
    required this.isPro,
    required this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPro
              ? [const Color(0xFF0D9488), const Color(0xFF059669)]
              : [const Color(0xFF1B75BC), const Color(0xFF0D47A1)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPro ? 'Formule PRO Active' : 'Formule Micro',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  isPro
                      ? 'Accès complet aux états financiers et au Grand Livre.'
                      : 'Débloquez les fonctionnalités avancées avec la formule Pro.',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          if (!isPro)
            ElevatedButton(
              onPressed: onUpgradePressed,
              child: const Text('Changer'),
            ),
        ],
      ),
    );
  }
}