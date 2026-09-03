import 'package:flutter/material.dart';

class SecondaryKpiRowWidget extends StatelessWidget {
  const SecondaryKpiRowWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildItem('Résultat...', '+18 3...', 'Bénéfice net', Icons.call_made, Colors.teal),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildItem('Total Bi...', '89 20...', 'Équilibré A=P', Icons.hourglass_empty, Colors.grey),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildItem('Trésor...', '12 40...', 'Disponible', Icons.account_balance_wallet, Colors.teal),
        ),
      ],
    );
  }

  Widget _buildItem(String title, String value, String subtitle, IconData icon, Color iconColor) {
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
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 9, color: Colors.grey)),
        ],
      ),
    );
  }
}