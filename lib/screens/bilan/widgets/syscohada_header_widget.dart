import 'package:flutter/material.dart';

class SyscohadaHeaderWidget extends StatelessWidget {
  const SyscohadaHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4EA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified, size: 14, color: Color(0xFF0F9D58)),
                  SizedBox(width: 4),
                  Text(
                    'SYSCOHADA RÉVISÉ',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F9D58)),
                  ),
                ],
              ),
            ),
            const Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text('Audité AUDCIF', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'États Financiers',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        const Text(
          'Système Normal & Allégé PME/PMI • Clos au 31 Déc. 2023',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}