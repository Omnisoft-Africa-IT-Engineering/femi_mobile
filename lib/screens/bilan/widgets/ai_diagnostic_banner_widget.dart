import 'package:flutter/material.dart';

class AiDiagnosticBannerWidget extends StatelessWidget {
  final double marginPercentage;

  const AiDiagnosticBannerWidget({
    super.key,
    required this.marginPercentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.psychology, color: Color(0xFF2DD4BF), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'DIAGNOSTIC FEMI INTELLIGENCE',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.circle, color: Color(0xFF2DD4BF), size: 6),
                  ],
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                    children: [
                      const TextSpan(text: 'Excellente santé financière. L\'entreprise respecte le principe de prudence OHADA avec une marge nette de '),
                      TextSpan(
                        text: '$marginPercentage%',
                        style: const TextStyle(color: Color(0xFF2DD4BF), fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ' et un ratio d\'autonomie bien au-delà du seuil requis.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}