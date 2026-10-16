import 'package:flutter/material.dart';

const Color _vert = Color(0xFF0D5C52);

String _fcfa(num v) {
  final s = v.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return '$buf FCFA';
}

class PlanTabWidget extends StatelessWidget {
  final Map<String, dynamic> plan;
  final bool isSelected;
  final VoidCallback onTap;

  const PlanTabWidget({
    super.key,
    required this.plan,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = (plan['title'] as String?) ?? '';
    final priceEuro = (plan['price'] as String?) ?? '';
    final amountFcfa = (plan['amountFcfa'] as num?) ?? 0;
    final isPopular = (plan['isPopular'] as bool?) ?? false;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFEDF2F7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _vert : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: _vert.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ]
              : [],
        ),
        child: Column(
          children: [
            if (isPopular)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: _vert,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'LE PLUS CHOISI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSelected ? _vert : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _fcfa(amountFcfa),
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? _vert : Colors.black54,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (priceEuro.isNotEmpty)
              Text(
                priceEuro,
                style: const TextStyle(fontSize: 10, color: Colors.black38),
              ),
          ],
        ),
      ),
    );
  }
}