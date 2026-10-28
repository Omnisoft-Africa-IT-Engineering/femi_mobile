import 'package:flutter/material.dart';

import '../models/produit.dart';

Color couleurStatutStock(StatutStock statut) {
  switch (statut) {
    case StatutStock.ok:
      return const Color(0xFF0D5C52);
    case StatutStock.alerte:
      return const Color(0xFFD97706);
    case StatutStock.rupture:
      return const Color(0xFFDC2626);
  }
}

String libelleStatutStock(StatutStock statut) {
  switch (statut) {
    case StatutStock.ok:
      return 'En stock';
    case StatutStock.alerte:
      return 'Stock bas';
    case StatutStock.rupture:
      return 'Rupture';
  }
}

class StatutStockBadge extends StatelessWidget {
  final StatutStock statut;
  const StatutStockBadge({super.key, required this.statut});

  @override
  Widget build(BuildContext context) {
    final couleur = couleurStatutStock(statut);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        libelleStatutStock(statut),
        style: TextStyle(
          color: couleur,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
