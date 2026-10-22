import 'package:flutter/material.dart';

const Color _vert = Color(0xFF0D5C52);
const Color _vertClair = Color(0xFFEAF6F3);

class PaymentOptionCardWidget extends StatelessWidget {
  final int index;
  final int groupValue;
  final IconData icon;
  final String title;
  final String subtitle;
  final ValueChanged<int?> onChanged;

  const PaymentOptionCardWidget({
    super.key,
    required this.index,
    required this.groupValue,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == groupValue;

    return InkWell(
      onTap: () => onChanged(index),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _vert : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _vertClair,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: _vert),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Radio<int>(
              value: index,
              groupValue: groupValue,
              activeColor: _vert,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}