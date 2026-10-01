import 'package:flutter/material.dart';
import '../models/devis.dart';

class StatutBadge extends StatelessWidget {
  final StatutDevis statut;
  const StatutBadge({super.key, required this.statut});

  Color get _couleur {
    switch (statut) {
      case StatutDevis.brouillon:
        return Colors.grey;
      case StatutDevis.envoye:
        return Colors.blue;
      case StatutDevis.accepte:
        return Colors.green;
      case StatutDevis.refuse:
        return Colors.red;
      case StatutDevis.converti:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _couleur;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statut.label,
        style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}