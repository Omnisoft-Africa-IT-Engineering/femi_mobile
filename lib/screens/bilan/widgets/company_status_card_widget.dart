import 'package:flutter/material.dart';

class CompanyStatusCardWidget extends StatelessWidget {
  final String companyName;
  final String ccNumber;
  // Aucune vérification de certification n'existe dans le système
  // actuellement — ce badge ne doit s'afficher que si un jour une vraie
  // source vérifie ce statut. Par défaut : false, badge masqué.
  final bool isCertified;

  const CompanyStatusCardWidget({
    super.key,
    required this.companyName,
    required this.ccNumber,
    this.isCertified = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFD3E3FD),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.account_balance, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  companyName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'N° CC : $ccNumber',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
          ),
          // Badge affiché uniquement si isCertified est explicitement true —
          // jamais par défaut, puisque rien ne vérifie ce statut aujourd'hui.
          if (isCertified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF005AC1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text('Certifié', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}