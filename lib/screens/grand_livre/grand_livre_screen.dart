import 'package:flutter/material.dart';
import 'widgets/compte_card_widget.dart';
import '../../services/pdf_export_service.dart';

class GrandLivreScreen extends StatelessWidget {
  const GrandLivreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Compte',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.black12,
              child: Icon(Icons.person, color: Colors.black87),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre & Bouton PDF
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: Text(
                    'Grand Livre',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B75BC),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    PdfExportService.exportGrandLivre(
                      totalDebit: '12 450 000',
                      totalCredit: '9 800 000',
                      soldeNet: '2 650 000 XOF',
                      comptes: [
                        {
                          'code': '411100',
                          'nom': 'Clients - Komi Services',
                          'solde': '+ 1 200 000 XOF',
                          'mouvements': [
                            {
                              'date': '12 Oct 2023',
                              'libelle': 'Facture F-2023-089',
                              'montant': '500 000',
                            },
                            {
                              'date': '10 Oct 2023',
                              'libelle': 'Règlement avance',
                              'montant': '- 200 000',
                            },
                            {
                              'date': '01 Oct 2023',
                              'libelle': 'Facture F-2023-085',
                              'montant': '900 000',
                            },
                          ],
                        },
                        {
                          'code': '521000',
                          'nom': 'Banque BIAO',
                          'solde': '+ 5 450 000 XOF',
                          'mouvements': [
                            {
                              'date': '14 Oct 2023',
                              'libelle': 'Virement Fournisseur X',
                              'montant': '- 1 500 000',
                            },
                            {
                              'date': '12 Oct 2023',
                              'libelle': 'Encaissement Client Y',
                              'montant': '2 000 000',
                            },
                          ],
                        },
                        {
                          'code': '601000',
                          'nom': 'Achats Marchandises',
                          'solde': '4 000 000 XOF',
                          'mouvements': [
                            {
                              'date': '05 Oct 2023',
                              'libelle': 'Achat Stock Mensuel',
                              'montant': '4 000 000',
                            },
                          ],
                        },
                      ],
                    );
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.picture_as_pdf_outlined, color: Colors.white, size: 16),
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
            const SizedBox(height: 4),
            const Text(
              'Vue détaillée des comptes et de leurs mouvements.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 16),

            // Barre de recherche
            TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un compte (ex: 411, Banque...)',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFEBF1FA),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Cartes Débit / Crédit
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2338),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Icon(Icons.arrow_downward, color: Color(0xFF4CAF50), size: 16),
                            SizedBox(width: 4),
                            Text(
                              'TOTAL DÉBIT',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          '12 450 000',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('XOF', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3EDFF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Icon(Icons.arrow_upward, color: Color(0xFFE53935), size: 16),
                            SizedBox(width: 4),
                            Text(
                              'TOTAL CRÉDIT',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          '9 800 000',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('XOF', style: TextStyle(color: Colors.black45, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Carte Solde Net
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF80EEEC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'SOLDE NET',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '2 650 000 XOF',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00695C),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance, color: Color(0xFF00695C)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // En-tête Comptes Actifs + Filtrer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Comptes Actifs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.filter_list, size: 16, color: Colors.black54),
                  label: const Text(
                    'FILTRER',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Compte 1 : Clients - Komi Services
            const CompteCardWidget(
              code: '411100',
              nom: 'Clients - Komi Services',
              solde: '+ 1 200 000 XOF',
              soldeColor: Color(0xFF00695C),
              headerBgColor: Color(0xFFE8F3FF),
              mouvements: [
                {
                  'date': '12 Oct 2023',
                  'libelle': 'Facture F-2023-089',
                  'montant': '500 000',
                },
                {
                  'date': '10 Oct 2023',
                  'libelle': 'Règlement avance',
                  'montant': '- 200 000',
                },
                {
                  'date': '01 Oct 2023',
                  'libelle': 'Facture F-2023-085',
                  'montant': '900 000',
                },
              ],
            ),
            const SizedBox(height: 16),

            // Compte 2 : Banque BIAO
            CompteCardWidget(
              code: '521000',
              nom: 'Banque BIAO',
              solde: '+ 5 450 000 XOF',
              soldeColor: const Color(0xFF00695C),
              headerBgColor: const Color(0xFFE8F3FF),
              mouvements: [
                {
                  'date': '14 Oct 2023',
                  'libelle': 'Virement Fournisseur X',
                  'montant': '- 1 500 000',
                  'montantColor': Colors.red.shade700,
                },
                {
                  'date': '12 Oct 2023',
                  'libelle': 'Encaissement Client Y',
                  'montant': '2 000 000',
                },
              ],
            ),
            const SizedBox(height: 16),

            // Compte 3 : Achats Marchandises
            CompteCardWidget(
              code: '601000',
              nom: 'Achats Marchandises',
              solde: '4 000 000 XOF',
              soldeColor: Colors.red.shade700,
              headerBgColor: const Color(0xFFE8F3FF),
              showHistoryButton: false,
              mouvements: const [
                {
                  'date': '05 Oct 2023',
                  'libelle': 'Achat Stock Mensuel',
                  'montant': '4 000 000',
                },
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}