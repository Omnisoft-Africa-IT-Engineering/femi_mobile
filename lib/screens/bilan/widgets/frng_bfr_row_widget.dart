import 'package:flutter/material.dart';

class FrngBfrRowWidget extends StatelessWidget {
  /// Quand false, les deux cartes affichent un état "indisponible" au
  /// lieu de valeurs chiffrées inventées, car le calcul du FRNG/BFR
  /// nécessite un vrai bilan (actif immobilisé vs circulant) que le
  /// modèle actuel ne fournit pas encore.
  final bool isAvailable;
  final String frngValue;
  final String frngSubtitle;
  final String bfrValue;
  final String bfrSubtitle;

  const FrngBfrRowWidget({
    super.key,
    this.isAvailable = true,
    this.frngValue = '+15 800 000',
    this.frngSubtitle = 'Sécurité financière solide',
    this.bfrValue = '9 400 000',
    this.bfrSubtitle = 'Couvert par le FRNG (TN>0)',
  });

  @override
  Widget build(BuildContext context) {
    if (!isAvailable) {
      return Row(
        children: [
          Expanded(child: _buildUnavailableCard('FRNG (FONDS DE ROUL.)')),
          const SizedBox(width: 8),
          Expanded(child: _buildUnavailableCard('BFR (BESOIN EN FONDS)')),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildCard('FRNG (FONDS DE ROUL.)', frngValue, frngSubtitle, Colors.teal),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCard('BFR (BESOIN EN FONDS)', bfrValue, bfrSubtitle, Colors.teal),
        ),
      ],
    );
  }

  Widget _buildCard(String title, String value, String subtitle, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: valueColor)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 8)),
        ],
      ),
    );
  }

  Widget _buildUnavailableCard(String title) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('—', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF94A3B8))),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.lock_outline, size: 10, color: Colors.grey),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  'Module comptable requis',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}