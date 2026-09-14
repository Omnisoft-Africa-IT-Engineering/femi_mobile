import 'package:flutter/material.dart';

class FinancialRatioCardWidget extends StatelessWidget {
  final String title;
  final String percentage;
  final double progressValue;
  final String normText;
  final String capitalText;

  /// Quand false, le pourcentage et la barre de progression ne sont pas
  /// affichés comme des valeurs réelles : la carte montre un message
  /// indiquant que le ratio n'est pas encore calculable, plutôt qu'un
  /// chiffre inventé.
  final bool isAvailable;

  const FinancialRatioCardWidget({
    super.key,
    required this.title,
    required this.percentage,
    required this.progressValue,
    required this.normText,
    required this.capitalText,
    this.isAvailable = true,
  });

  @override
  Widget build(BuildContext context) {
    final Color accentColor = isAvailable ? const Color(0xFF0F9D58) : const Color(0xFF94A3B8);
    final Color progressColor = isAvailable ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1);
    final String displayedPercentage = isAvailable ? percentage : '—';
    final double displayedProgress = isAvailable ? progressValue : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const Text('(Capitaux Propres / Total Bilan)', style: TextStyle(color: Colors.grey, fontSize: 9)),
                ],
              ),
              Text(displayedPercentage, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: accentColor)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: displayedProgress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 8),
          if (isAvailable)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(normText, style: const TextStyle(color: Color(0xFF0F9D58), fontSize: 9, fontWeight: FontWeight.bold)),
                Text(capitalText, style: const TextStyle(color: Colors.grey, fontSize: 9)),
              ],
            )
          else
            Row(
              children: [
                const Icon(Icons.lock_outline, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Données incomplètes — module comptable requis',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}