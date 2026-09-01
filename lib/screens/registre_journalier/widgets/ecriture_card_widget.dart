import 'package:flutter/material.dart';

class EcritureCardWidget extends StatelessWidget {
  final Map<String, dynamic> ecriture;

  const EcritureCardWidget({
    super.key,
    required this.ecriture,
  });

  @override
  Widget build(BuildContext context) {
    final id = (ecriture['id'] as String?) ?? '';
    final time = (ecriture['time'] as String?) ?? '';
    final title = (ecriture['title'] as String?) ?? '';
    final lines = (ecriture['lines'] as List<Map<String, dynamic>>?) ?? [];
    final bottomLine = ecriture['bottomLine'] as Map<String, dynamic>?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête ID + Heure
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                id,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Titre
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          // Lignes comptables
          ...lines.map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildLineRow(line),
              )),

          // Ligne séparatrice et ligne inférieure si présente
          if (bottomLine != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4.0),
              child: Divider(color: Color(0xFFF1F5F9), thickness: 1),
            ),
            const SizedBox(height: 4),
            _buildLineRow(bottomLine),
          ],
        ],
      ),
    );
  }

  Widget _buildLineRow(Map<String, dynamic> line) {
    final dotColor = (line['dotColor'] as Color?) ?? Colors.black26;
    final codeName = (line['codeName'] as String?) ?? '';
    final amount = (line['amount'] as String?) ?? '';
    final amountColor = line['amountColor'] as Color?;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            codeName,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: amountColor ?? const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}