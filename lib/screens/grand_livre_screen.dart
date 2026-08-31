import 'package:flutter/material.dart';

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
            // Titre & Bouton PDF compact aligné à droite
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
                    // Action de téléchargement PDF
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
                              style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text('12 450 000', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                              style: TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text('9 800 000', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
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
                      Text('SOLDE NET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                      SizedBox(height: 4),
                      Text(
                        '2 650 000 XOF',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF00695C)),
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.filter_list, size: 16, color: Colors.black54),
                  label: const Text('FILTRER', style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Compte 1 : Clients - Komi Services
            _buildCompteCard(
              code: '411100',
              nom: 'Clients - Komi Services',
              solde: '+ 1 200 000 XOF',
              soldeColor: const Color(0xFF00695C),
              headerBgColor: const Color(0xFFE8F3FF),
              lignes: [
                _buildLigneMouvement('12 Oct 2023', 'Facture F-2023-089', '500 000'),
                _buildLigneMouvement('10 Oct 2023', 'Règlement avance', '- 200 000'),
                _buildLigneMouvement('01 Oct 2023', 'Facture F-2023-085', '900 000'),
              ],
            ),
            const SizedBox(height: 16),

            // Compte 2 : Banque BIAO
            _buildCompteCard(
              code: '521000',
              nom: 'Banque BIAO',
              solde: '+ 5 450 000 XOF',
              soldeColor: const Color(0xFF00695C),
              headerBgColor: const Color(0xFFE8F3FF),
              lignes: [
                _buildLigneMouvement('14 Oct 2023', 'Virement Fournisseur X', '- 1 500 000', montantColor: Colors.red.shade700),
                _buildLigneMouvement('12 Oct 2023', 'Encaissement Client Y', '2 000 000'),
              ],
            ),
            const SizedBox(height: 16),

            // Compte 3 : Achats Marchandises
            _buildCompteCard(
              code: '601000',
              nom: 'Achats Marchandises',
              solde: '4 000 000 XOF',
              soldeColor: Colors.red.shade700,
              headerBgColor: const Color(0xFFE8F3FF),
              showHistoryButton: false,
              lignes: [
                _buildLigneMouvement('05 Oct 2023', 'Achat Stock Mensuel', '4 000 000'),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCompteCard({
    required String code,
    required String nom,
    required String solde,
    required Color soldeColor,
    required Color headerBgColor,
    required List<Widget> lignes,
    bool showHistoryButton = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: headerBgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(code, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                    ),
                    const SizedBox(height: 8),
                    Text(nom, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('SOLDE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black45)),
                    const SizedBox(height: 2),
                    Text(solde, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: soldeColor)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: lignes,
            ),
          ),
          if (showHistoryButton) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  'VOIR TOUT L\'HISTORIQUE',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
            ),
          ] else
            const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildLigneMouvement(String date, String libelle, String montant, {Color? montantColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(libelle, style: const TextStyle(fontSize: 13, color: Colors.black87)),
            ],
          ),
          Text(
            montant,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: montantColor ?? const Color(0xFF00695C)),
          ),
        ],
      ),
    );
  }
}