import 'package:flutter/material.dart';

class SecondaryKpiRowWidget extends StatelessWidget {
  final String resultatNetValue;
  final String tresorerieValue;

  const SecondaryKpiRowWidget({
    super.key,
    required this.resultatNetValue,
    required this.tresorerieValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildItem(
            'Résultat Net',
            resultatNetValue,
            'Bénéfice net',
            Icons.call_made,
            Colors.teal,
            isAvailable: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          // Total Bilan nécessite l'actif immobilisé, non calculable
          // actuellement — on affiche clairement "Non disponible" plutôt
          // qu'une valeur inventée ou approximative présentée comme réelle.
          child: _buildItem(
            'Total Bilan',
            'Non disponible',
            'Actif immo. requis',
            Icons.hourglass_empty,
            Colors.grey,
            isAvailable: false,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildItem(
            'Trésorerie',
            tresorerieValue,
            'Disponible',
            Icons.account_balance_wallet,
            Colors.teal,
            isAvailable: true,
          ),
        ),
      ],
    );
  }

  Widget _buildItem(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color iconColor, {
    required bool isAvailable,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Icon(icon, size: 12, color: iconColor),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isAvailable ? 13 : 11,
              fontWeight: FontWeight.bold,
              color: isAvailable ? Colors.black87 : Colors.grey,
              fontStyle: isAvailable ? FontStyle.normal : FontStyle.italic,
            ),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 9, color: Colors.grey)),
        ],
      ),
    );
  }
}