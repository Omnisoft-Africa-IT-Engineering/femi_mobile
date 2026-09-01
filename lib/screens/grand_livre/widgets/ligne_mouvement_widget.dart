import 'package:flutter/material.dart';

class LigneMouvementWidget extends StatelessWidget {
  /// Map contenant les informations du mouvement.
  /// Structure attendue :
  /// {
  ///   'date': '12 Oct 2023',
  ///   'libelle': 'Facture F-2023-089',
  ///   'montant': '500 000 XOF',
  ///   'montantColor': Colors.green, // Optionnel
  /// }
  final Map<String, dynamic> mouvement;

  const LigneMouvementWidget({
    super.key,
    required this.mouvement,
  });

  @override
  Widget build(BuildContext context) {
    final String date = (mouvement['date'] as String?) ?? '';
    final String libelle = (mouvement['libelle'] as String?) ?? '';
    final String montant = (mouvement['montant'] as String?) ?? '';
    final Color montantColor =
        (mouvement['montantColor'] as Color?) ?? const Color(0xFF00695C);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (date.isNotEmpty) ...[
                  Text(
                    date,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  libelle,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            montant,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: montantColor,
            ),
          ),
        ],
      ),
    );
  }
}