import 'package:flutter/material.dart';
import '../models/devis.dart';

class StatutBadge extends StatelessWidget {
  final StatutDevis statut;

  const StatutBadge({super.key, required this.statut});

  Color get _couleur {
    switch (statut) {
      case StatutDevis.brouillon:
        return Colors.grey;
      case StatutDevis.valide:
        return const Color(0xFF1B75BC);
      case StatutDevis.facture:
        return const Color(0xFF006654);
      case StatutDevis.annule:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _couleur;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statut.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}