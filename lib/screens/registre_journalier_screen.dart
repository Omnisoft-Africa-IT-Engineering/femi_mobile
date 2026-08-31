import 'package:flutter/material.dart';

class RegistreJournalierScreen extends StatefulWidget {
  const RegistreJournalierScreen({super.key});

  @override
  State<RegistreJournalierScreen> createState() => _RegistreJournalierScreenState();
}

class _RegistreJournalierScreenState extends State<RegistreJournalierScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FE),
        elevation: 0,
        // Bouton pour revenir en arrière à l'écran précédent
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 20),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Compte',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Titre de la page ---
              const Text(
                'Registre Journalier',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 20),

              // --- Sélecteur de date ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCircleIconButton(Icons.chevron_left),
                  Column(
                    children: const [
                      Text(
                        '12 Octobre 2023',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Aujourd'hui",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                  _buildCircleIconButton(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 20),

              // --- Cartes Totaux (Débit / Crédit) ---
              Row(
                children: [
                  Expanded(
                    child: _buildTotalCard(
                      title: 'TOTAL DÉBIT',
                      amount: '12,450.00 €',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTotalCard(
                      title: 'TOTAL CRÉDIT',
                      amount: '12,450.00 €',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- Barre de recherche ---
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher une écriture...',
                    hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Colors.black54),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- Cartes d'écritures ---
              _buildEcritureCard(
                id: 'RJ-2023-089',
                time: '10:15 AM',
                title: 'Paiement Facture Client F-234',
                lines: [
                  _EcritureLine(
                    dotColor: const Color(0xFF0D9488),
                    codeName: '512000 - Banque',
                    amount: '+ 3,200.00',
                    amountColor: const Color(0xFF059669),
                  ),
                  _EcritureLine(
                    dotColor: Colors.black26,
                    codeName: '411000 - Clients',
                    amount: '3,200.00',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildEcritureCard(
                id: 'RJ-2023-090',
                time: '11:30 AM',
                title: 'Achat Fournitures Bureau',
                lines: [
                  _EcritureLine(
                    dotColor: Colors.black26,
                    codeName: '606400 - Fournitures',
                    amount: '150.00',
                  ),
                  _EcritureLine(
                    dotColor: Colors.black26,
                    codeName: '445660 - TVA Déd.',
                    amount: '30.00',
                  ),
                ],
                bottomLine: _EcritureLine(
                  dotColor: const Color(0xFFDC2626),
                  codeName: '512000 - Banque',
                  amount: '- 180.00',
                  amountColor: const Color(0xFFDC2626),
                ),
              ),
              const SizedBox(height: 24),

              // --- Bouton Télécharger PDF ---
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006654),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.file_download_outlined, color: Colors.white),
                  label: const Text(
                    'Télécharger en PDF',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      // bottomNavigationBar supprimée pour masquer la barre du bas
    );
  }

  // Helper : Bouton circulaire pour la navigation de date
  Widget _buildCircleIconButton(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: Colors.black87, size: 20),
        onPressed: () {},
      ),
    );
  }

  // Helper : Carte de total (Débit/Crédit)
  Widget _buildTotalCard({required String title, required String amount}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE2EDFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  // Helper : Carte d'écriture comptable
  Widget _buildEcritureCard({
    required String id,
    required String time,
    required String title,
    required List<_EcritureLine> lines,
    _EcritureLine? bottomLine,
  }) {
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

          // Lignes comptables supérieures
          ...lines.map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildLineRow(line),
              )),

          // Ligne séparatrice & ligne inférieure spéciale s'il y en a une
          if (bottomLine != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4.0), // Correction appliquée ici
              child: Divider(color: Color(0xFFF1F5F9), thickness: 1),
            ),
            const SizedBox(height: 4),
            _buildLineRow(bottomLine),
          ],
        ],
      ),
    );
  }

  // Helper : Rangée individuelle dans une écriture
  Widget _buildLineRow(_EcritureLine line) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: line.dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            line.codeName,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Text(
          line.amount,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: line.amountColor ?? const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

class _EcritureLine {
  final Color dotColor;
  final String codeName;
  final String amount;
  final Color? amountColor;

  _EcritureLine({
    required this.dotColor,
    required this.codeName,
    required this.amount,
    this.amountColor,
  });
}