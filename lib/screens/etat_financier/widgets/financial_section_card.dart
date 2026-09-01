import 'package:flutter/material.dart';

class FinancialItem {
  final String label;
  final String amount;
  final bool isTotal;

  const FinancialItem({
    required this.label,
    required this.amount,
    this.isTotal = false,
  });
}

class FinancialSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<FinancialItem> items;

  const FinancialSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête de la section
        Row(
          children: [
            Icon(icon, color: Colors.black, size: 22),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Carte contenant les données
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: items.map((item) => _buildRowItem(item)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRowItem(FinancialItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.label,
                style: TextStyle(
                  fontSize: item.isTotal ? 15 : 14,
                  fontWeight: item.isTotal ? FontWeight.bold : FontWeight.normal,
                  color: item.isTotal ? Colors.black : Colors.grey.shade800,
                ),
              ),
              Text(
                item.amount,
                style: TextStyle(
                  fontSize: item.isTotal ? 15 : 14,
                  fontWeight: item.isTotal ? FontWeight.bold : FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          if (!item.isTotal) ...[
            const SizedBox(height: 8),
            Divider(color: Colors.grey.shade100, height: 1),
          ],
        ],
      ),
    );
  }
}