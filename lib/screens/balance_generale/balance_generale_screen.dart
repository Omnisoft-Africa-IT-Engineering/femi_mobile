import 'package:flutter/material.dart';
import 'widgets/balance_account_table.dart';

class BalanceGeneraleScreen extends StatelessWidget {
  const BalanceGeneraleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Données mockées — à remplacer par un appel API une fois le backend prêt
    const rows = [
      BalanceRowData(
        numero: '401000',
        libelle: 'Fournisseurs',
        debit: '2 100 000',
        credit: '9 400 000',
        solde: '7 300 000',
        soldeDebiteur: false,
      ),
      BalanceRowData(
        numero: '411000',
        libelle: 'Clients',
        debit: '14 800 000',
        credit: '3 200 000',
        solde: '11 600 000',
        soldeDebiteur: true,
      ),
      BalanceRowData(
        numero: '512000',
        libelle: 'Banque',
        debit: '21 800 000',
        credit: '0',
        solde: '21 800 000',
        soldeDebiteur: true,
      ),
      BalanceRowData(
        numero: '601000',
        libelle: 'Achats de marchandises',
        debit: '35 600 000',
        credit: '0',
        solde: '35 600 000',
        soldeDebiteur: true,
      ),
      BalanceRowData(
        numero: '701000',
        libelle: 'Ventes de marchandises',
        debit: '0',
        credit: '58 900 000',
        solde: '58 900 000',
        soldeDebiteur: false,
      ),
      BalanceRowData(
        numero: '661000',
        libelle: 'Charges de personnel',
        debit: '12 400 000',
        credit: '0',
        solde: '12 400 000',
        soldeDebiteur: true,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Balance Générale',
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
            const BalanceAccountTable(rows: rows),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}