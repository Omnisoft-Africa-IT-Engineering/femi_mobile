import 'package:flutter/material.dart';
import '../etat_financier/widgets/total_bilan_card.dart';
import 'widgets/balance_account_table.dart';

class BalanceAuxiliaireScreen extends StatelessWidget {
  const BalanceAuxiliaireScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Données mockées — à remplacer par un appel API une fois le backend prêt
    const clientRows = [
      BalanceRowData(
        numero: '411001',
        libelle: 'TechCorp',
        debit: '1 200 000',
        credit: '0',
        solde: '1 200 000',
        soldeDebiteur: true,
      ),
      BalanceRowData(
        numero: '411002',
        libelle: 'Alpha Distribution',
        debit: '3 400 000',
        credit: '900 000',
        solde: '2 500 000',
        soldeDebiteur: true,
      ),
      BalanceRowData(
        numero: '411003',
        libelle: 'SOTOGO SARL',
        debit: '7 900 000',
        credit: '0',
        solde: '7 900 000',
        soldeDebiteur: true,
      ),
    ];

    const fournisseurRows = [
      BalanceRowData(
        numero: '401001',
        libelle: 'Grossiste Import Plus',
        debit: '0',
        credit: '4 100 000',
        solde: '4 100 000',
        soldeDebiteur: false,
      ),
      BalanceRowData(
        numero: '401002',
        libelle: 'Papeterie Centrale',
        debit: '600 000',
        credit: '1 800 000',
        solde: '1 200 000',
        soldeDebiteur: false,
      ),
      BalanceRowData(
        numero: '401003',
        libelle: 'Transport Rapide Togo',
        debit: '0',
        credit: '2 000 000',
        solde: '2 000 000',
        soldeDebiteur: false,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Balance Auxiliaire',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B75BC),
                elevation: 0,
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {},
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
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exercice clos au 31 Décembre 2023',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),

            // Résumé global (réutilise le widget déjà utilisé pour le Bilan)
            const TotalBilanCard(
              totalAmount: '11,6 M',
              statusLabel: 'CLIENTS',
              topLabel: 'TOTAL CLIENTS',
            ),
            const SizedBox(height: 24),

            // Section Clients
            Row(
              children: const [
                Icon(Icons.people_outline, color: Colors.black, size: 22),
                SizedBox(width: 8),
                Text(
                  'Clients',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const BalanceAccountTable(rows: clientRows),

            const SizedBox(height: 24),

            // Section Fournisseurs
            Row(
              children: const [
                Icon(Icons.local_shipping_outlined,
                    color: Colors.black, size: 22),
                SizedBox(width: 8),
                Text(
                  'Fournisseurs',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const BalanceAccountTable(rows: fournisseurRows),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}