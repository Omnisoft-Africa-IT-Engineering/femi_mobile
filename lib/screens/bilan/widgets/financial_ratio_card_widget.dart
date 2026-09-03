import 'package:flutter/material.dart';

class FinancialRatioCardWidget extends StatelessWidget {
  final String title;
  final String percentage;
  final double progressValue;
  final String normText;
  final String capitalText;

  const FinancialRatioCardWidget({
    super.key,
    required this.title,
    required this.percentage,
    required this.progressValue,
    required this.normText,
    required this.capitalText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const Text('(Capitaux Propres / Total Bilan)', style: TextStyle(color: Colors.grey, fontSize: 9)),
                ],
              ),
              Text(percentage, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F9D58))),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0F172A)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(normText, style: const TextStyle(color: Color(0xFF0F9D58), fontSize: 9, fontWeight: FontWeight.bold)),
              Text(capitalText, style: const TextStyle(color: Colors.grey, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }
}