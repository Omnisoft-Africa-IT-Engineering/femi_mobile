import 'package:flutter/material.dart';
import '../../services/pdf_export_service.dart';
import 'widgets/total_bilan_card.dart';
import 'widgets/financial_section_card.dart';

/// Écran État Financier SYSCOHADA complet, avec 4 documents en onglets :
/// Bilan, Compte de Résultat, TAFIRE, Notes Annexes.
///
/// Contrairement à EtatFinancierScreen (qui n'affiche que le Bilan seul,
/// utilisé par l'item "Bilan" du menu Mon Compte), cet écran est destiné
/// à l'item "État financier" et regroupe l'ensemble du document légal.
class EtatFinancierCompletScreen extends StatefulWidget {
  const EtatFinancierCompletScreen({super.key});

  @override
  State<EtatFinancierCompletScreen> createState() =>
      _EtatFinancierCompletScreenState();
}

class _EtatFinancierCompletScreenState
    extends State<EtatFinancierCompletScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // --- Données mockées — à remplacer par un appel API une fois le backend prêt ---

  final actifItems = const [
    FinancialItem(label: 'Actif Immobilisé', amount: '65 350 000'),
    FinancialItem(label: 'Actif Circulant', amount: '58 100 000'),
    FinancialItem(label: 'Trésorerie Actif', amount: '21 800 000'),
    FinancialItem(label: 'Total Actif', amount: '145 250 000', isTotal: true),
  ];

  final passifItems = const [
    FinancialItem(label: 'Capitaux Propres', amount: '82 400 000'),
    FinancialItem(label: 'Dettes Financières', amount: '25 000 000'),
    FinancialItem(label: 'Passif Circulant', amount: '36 300 000'),
    FinancialItem(label: 'Trésorerie Passif', amount: '1 550 000'),
    FinancialItem(label: 'Total Passif', amount: '145 250 000', isTotal: true),
  ];

  final produitsItems = const [
    FinancialItem(label: 'Ventes de marchandises', amount: '58 900 000'),
    FinancialItem(label: 'Production vendue', amount: '12 000 000'),
    FinancialItem(label: 'Total Produits', amount: '70 900 000', isTotal: true),
  ];

  final chargesItems = const [
    FinancialItem(label: 'Achats de marchandises', amount: '35 600 000'),
    FinancialItem(label: 'Charges de personnel', amount: '12 400 000'),
    FinancialItem(label: 'Charges externes', amount: '8 200 000'),
    FinancialItem(label: 'Total Charges', amount: '56 200 000', isTotal: true),
  ];

  final ressourcesItems = const [
    FinancialItem(label: "Capacité d'autofinancement", amount: '14 700 000'),
    FinancialItem(label: 'Nouveaux emprunts', amount: '2 000 000'),
    FinancialItem(label: 'Total Ressources', amount: '16 700 000', isTotal: true),
  ];

  final emploisItems = const [
    FinancialItem(label: 'Investissements', amount: '5 000 000'),
    FinancialItem(label: 'Remboursement dettes financières', amount: '3 000 000'),
    FinancialItem(label: 'Total Emplois', amount: '8 000 000', isTotal: true),
  ];

  final notesAnnexes = const [
    "Méthode d'évaluation des stocks : coût moyen pondéré",
    "Mode d'amortissement : linéaire sur la durée de vie du bien",
    "Engagement hors bilan : caution bancaire de 5 000 000 FCFA",
    "Événements postérieurs à la clôture : aucun événement significatif",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _exportCurrentTab() {
    switch (_tabController.index) {
      case 0:
        PdfExportService.exportBilan(
          totalAmount: '145 250 000',
          actifs: actifItems.map((i) => {'label': i.label, 'amount': i.amount}).toList(),
          passifs: passifItems.map((i) => {'label': i.label, 'amount': i.amount}).toList(),
        );
        break;
      case 1:
        PdfExportService.exportCompteResultat(
          resultatNet: '14 700 000',
          produits:
          produitsItems.map((i) => {'label': i.label, 'amount': i.amount}).toList(),
          charges: chargesItems.map((i) => {'label': i.label, 'amount': i.amount}).toList(),
        );
        break;
      case 2:
        PdfExportService.exportTafire(
          variationTresorerie: '+8 700 000',
          ressources:
          ressourcesItems.map((i) => {'label': i.label, 'amount': i.amount}).toList(),
          emplois: emploisItems.map((i) => {'label': i.label, 'amount': i.amount}).toList(),
        );
        break;
      case 3:
        PdfExportService.exportNotesAnnexes(notes: notesAnnexes);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'État Financier SYSCOHADA',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B75BC),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _exportCurrentTab,
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
                ],
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF1B75BC),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1B75BC),
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(text: 'Bilan'),
            Tab(text: 'Compte de Résultat'),
            Tab(text: 'TAFIRE'),
            Tab(text: 'Notes Annexes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBilanTab(),
          _buildCompteResultatTab(),
          _buildTafireTab(),
          _buildNotesAnnexesTab(),
        ],
      ),
    );
  }

  Widget _buildBilanTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TotalBilanCard(totalAmount: '145,2 M'),
          const SizedBox(height: 24),
          FinancialSectionCard(
            icon: Icons.account_balance_outlined,
            title: 'Actif (Emplois)',
            items: actifItems,
          ),
          const SizedBox(height: 24),
          FinancialSectionCard(
            icon: Icons.subtitles_outlined,
            title: 'Passif (Ressources)',
            items: passifItems,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCompteResultatTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TotalBilanCard(
            totalAmount: '14,7 M',
            statusLabel: 'BÉNÉFICE',
            topLabel: 'RÉSULTAT NET',
          ),
          const SizedBox(height: 24),
          FinancialSectionCard(
            icon: Icons.trending_up,
            title: 'Produits',
            items: produitsItems,
          ),
          const SizedBox(height: 24),
          FinancialSectionCard(
            icon: Icons.trending_down,
            title: 'Charges',
            items: chargesItems,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTafireTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TotalBilanCard(
            totalAmount: '+8,7 M',
            statusLabel: 'POSITIF',
            topLabel: 'VARIATION TRÉSORERIE',
          ),
          const SizedBox(height: 24),
          FinancialSectionCard(
            icon: Icons.arrow_downward,
            title: 'Ressources',
            items: ressourcesItems,
          ),
          const SizedBox(height: 24),
          FinancialSectionCard(
            icon: Icons.arrow_upward,
            title: 'Emplois',
            items: emploisItems,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildNotesAnnexesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notes Annexes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...notesAnnexes.map(
                (note) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF1B75BC), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      note,
                      style: const TextStyle(fontSize: 13.5, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}