import 'package:flutter/material.dart';

class CompteCardWidget extends StatelessWidget {
  final String code;
  final String nom;
  final String solde;
  final Color soldeColor;
  final Color headerBgColor;
  /// Liste de mouvements représentée par des Map.
  /// Exemple de structure :
  /// {
  ///   'libelle': 'Facture F-2023-089',
  ///   'date': '12 Oct 2023',
  ///   'montant': '500 000 XOF',
  ///   'isDebit': true, // optionnel
  ///   'montantColor': Colors.green, // optionnel
  /// }
  final List<Map<String, dynamic>> mouvements;
  final bool showHistoryButton;
  final VoidCallback? onHistoryPressed;

  const CompteCardWidget({
    super.key,
    required this.code,
    required this.nom,
    required this.solde,
    required this.soldeColor,
    required this.headerBgColor,
    required this.mouvements,
    this.showHistoryButton = true,
    this.onHistoryPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: headerBgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // En-tête de la carte (Code, Nom, Solde)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        code,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      nom,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'SOLDE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      solde,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: soldeColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Liste des mouvements intégrée
          if (mouvements.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: List.generate(mouvements.length, (index) {
                  final mouvement = mouvements[index];
                  final isLast = index == mouvements.length - 1;

                  final String libelle = (mouvement['libelle'] as String?) ?? '';
                  final String date = (mouvement['date'] as String?) ?? '';
                  final String montant = (mouvement['montant'] as String?) ?? '';
                  final Color? montantColor = mouvement['montantColor'] as Color?;

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    libelle,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (date.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      date,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black45,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              montant,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: montantColor ?? Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        const Divider(
                          height: 1,
                          thickness: 1,
                          indent: 14,
                          endIndent: 14,
                          color: Color(0xFFF0F0F0),
                        ),
                    ],
                  );
                }),
              ),
            ),

          // Bouton d'historique ou espacement
          if (showHistoryButton) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextButton(
                onPressed: onHistoryPressed ?? () {},
                child: const Text(
                  'VOIR TOUT L\'HISTORIQUE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ] else
            const SizedBox(height: 12),
        ],
      ),
    );
  }
}