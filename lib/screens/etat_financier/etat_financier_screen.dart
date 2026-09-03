import 'package:flutter/material.dart';
import '../../services/pdf_export_service.dart';
// Imports des widgets modulaires
import 'widgets/total_bilan_card.dart';
import 'widgets/financial_section_card.dart';

class EtatFinancierScreen extends StatelessWidget {
  const EtatFinancierScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final actifItems = <FinancialItem>[
      const FinancialItem(label: 'Actif Immobilisé', amount: '65 350 000'),
      const FinancialItem(label: 'Actif Circulant', amount: '58 100 000'),
      const FinancialItem(label: 'Trésorerie Actif', amount: '21 800 000'),
      const FinancialItem(
          label: 'Total Actif', amount: '145 250 000', isTotal: true),
    ];

    final passifItems = <FinancialItem>[
      const FinancialItem(label: 'Capitaux Propres', amount: '82 400 000'),
      const FinancialItem(label: 'Dettes Financières', amount: '25 000 000'),
      const FinancialItem(label: 'Passif Circulant', amount: '36 300 000'),
      const FinancialItem(label: 'Trésorerie Passif', amount: '1 550 000'),
      const FinancialItem(
          label: 'Total Passif', amount: '145 250 000', isTotal: true),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Compte',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.black,
              radius: 18,
              child: Icon(Icons.person_outline, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre + Bouton PDF
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ÉTAT FINANCIER SYSCOHADA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Bilan Comptable',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B75BC),
                    elevation: 0,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    PdfExportService.exportBilan(
                      totalAmount: '145 250 000',
                      actifs: actifItems
                          .map((i) => {'label': i.label, 'amount': i.amount})
                          .toList(),
                      passifs: passifItems
                          .map((i) => {'label': i.label, 'amount': i.amount})
                          .toList(),
                    );
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.picture_as_pdf_outlined,
                          color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'PDF',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Exercice clos au 31 Décembre 2023',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),

            // 1. Carte de synthèse Total Bilan
            const TotalBilanCard(totalAmount: '145,2 M'),

            const SizedBox(height: 24),

            // 2. Section ACTIF (Emplois)
            FinancialSectionCard(
              icon: Icons.account_balance_outlined,
              title: 'Actif (Emplois)',
              items: actifItems,
            ),

            const SizedBox(height: 24),

            // 3. Section PASSIF (Ressources)
            FinancialSectionCard(
              icon: Icons.subtitles_outlined,
              title: 'Passif (Ressources)',
              items: passifItems,
            ),

            const SizedBox(height: 24),

            // 4. Bouton Générer l'analyse Femi
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006654),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {},
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Générer l\'analyse Femi',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}