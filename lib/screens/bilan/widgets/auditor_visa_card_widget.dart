import 'package:flutter/material.dart';

class AuditorVisaCardWidget extends StatelessWidget {
  const AuditorVisaCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF4FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.verified_user_outlined, color: Color(0xFF0F9D58), size: 18),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cabinet Conseil & Audit ONEC...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                Text('Rapport de commissariat sans réserve', style: TextStyle(color: Colors.grey, fontSize: 10)),
                Text('Visa N° CI-2023-9942', style: TextStyle(color: Color(0xFF005AC1), fontSize: 9, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}