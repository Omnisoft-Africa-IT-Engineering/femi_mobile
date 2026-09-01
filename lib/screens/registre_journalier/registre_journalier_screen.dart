import 'package:flutter/material.dart';
import 'widgets/date_selector_widget.dart';
import 'widgets/ecriture_card_widget.dart';
import 'widgets/total_card_widget.dart';

class RegistreJournalierScreen extends StatefulWidget {
  const RegistreJournalierScreen({super.key});

  @override
  State<RegistreJournalierScreen> createState() =>
      _RegistreJournalierScreenState();
}

class _RegistreJournalierScreenState extends State<RegistreJournalierScreen> {
  // Données des écritures sous forme de Map<String, dynamic>
  final List<Map<String, dynamic>> _ecritures = [
    {
      'id': 'RJ-2023-089',
      'time': '10:15 AM',
      'title': 'Paiement Facture Client F-234',
      'lines': [
        {
          'dotColor': const Color(0xFF0D9488),
          'codeName': '512000 - Banque',
          'amount': '+ 3,200.00',
          'amountColor': const Color(0xFF059669),
        },
        {
          'dotColor': Colors.black26,
          'codeName': '411000 - Clients',
          'amount': '3,200.00',
        },
      ],
    },
    {
      'id': 'RJ-2023-090',
      'time': '11:30 AM',
      'title': 'Achat Fournitures Bureau',
      'lines': [
        {
          'dotColor': Colors.black26,
          'codeName': '606400 - Fournitures',
          'amount': '150.00',
        },
        {
          'dotColor': Colors.black26,
          'codeName': '445660 - TVA Déd.',
          'amount': '30.00',
        },
      ],
      'bottomLine': {
        'dotColor': const Color(0xFFDC2626),
        'codeName': '512000 - Banque',
        'amount': '- 180.00',
        'amountColor': const Color(0xFFDC2626),
      },
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF0F172A), size: 20),
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
              // Titre de la page
              const Text(
                'Registre Journalier',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 20),

              // Sélecteur de date
              DateSelectorWidget(
                dateText: '12 Octobre 2023',
                subtitle: "Aujourd'hui",
                onPrevious: () {},
                onNext: () {},
              ),
              const SizedBox(height: 20),

              // Cartes Totaux (Débit / Crédit)
              Row(
                children: const [
                  Expanded(
                    child: TotalCardWidget(
                      title: 'TOTAL DÉBIT',
                      amount: '12,450.00 €',
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TotalCardWidget(
                      title: 'TOTAL CRÉDIT',
                      amount: '12,450.00 €',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Barre de recherche
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

              // Liste des écritures
              ..._ecritures.map((ecriture) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: EcritureCardWidget(ecriture: ecriture),
                  )),

              const SizedBox(height: 24),

              // Bouton Télécharger PDF
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
                  icon: const Icon(Icons.file_download_outlined,
                      color: Colors.white),
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
    );
  }
}