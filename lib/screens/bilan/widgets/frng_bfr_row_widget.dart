import 'package:flutter/material.dart';

class FrngBfrRowWidget extends StatelessWidget {
  const FrngBfrRowWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildCard('FRNG (FONDS DE ROUL.)', '+15 800 000', 'Sécurité financière solide', Colors.teal),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCard('BFR (BESOIN EN FONDS)', '9 400 000', 'Couvert par le FRNG (TN>0)', Colors.teal),
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
}