import 'package:flutter/material.dart';
import 'widgets/syscohada_header_widget.dart';
import 'widgets/year_filter_widget.dart';
import 'widgets/company_status_card_widget.dart';
import 'widgets/main_kpi_card_widget.dart';
import 'widgets/secondary_kpi_row_widget.dart';
import 'widgets/ai_diagnostic_banner_widget.dart';
import 'widgets/syscohada_document_card_widget.dart';
import 'widgets/financial_ratio_card_widget.dart';
import 'widgets/frng_bfr_row_widget.dart';
import 'widgets/auditor_visa_card_widget.dart';
import 'widgets/action_buttons_widget.dart';

class BilanScreen extends StatefulWidget {
  const BilanScreen({super.key});

  @override
  State<BilanScreen> createState() => _BilanScreenState();
}

class _BilanScreenState extends State<BilanScreen> {
  int _selectedYear = 2023;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('Compte', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.black, size: 28),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SyscohadaHeaderWidget(),
            const SizedBox(height: 12),
            YearFilterWidget(
              selectedYear: _selectedYear,
              onYearSelected: (year) => setState(() => _selectedYear = year),
            ),
            const SizedBox(height: 12),
            const CompanyStatusCardWidget(
              companyName: 'KOMI SERVICES SA',
              ccNumber: '1408892 B • A...',
            ),
            const SizedBox(height: 16),

            // Synthèse de l'exercice
            Row(
              children: [
                const CircleAvatar(radius: 3, backgroundColor: Colors.green),
                const SizedBox(width: 6),
                Text(
                  'SYNTHÈSE DE L\'EXERCICE (XOF)',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                ),
                const Spacer(),
                const Text('Devise : FCFA', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            const MainKpiCardWidget(
              title: 'Chiffre d\'Affaires Net (HT)',
              amount: '124 500 000',
              growthPercentage: '+14.2%',
            ),
            const SizedBox(height: 8),
            const SecondaryKpiRowWidget(),
            const SizedBox(height: 12),

            // Diagnostic IA
            const AiDiagnosticBannerWidget(marginPercentage: 14.7),
            const SizedBox(height: 20),

            // Documents Légal SYSCOHADA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Documents Légaux SYSCOHADA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('4 états obligatoires normalisés AUDCIF', style: TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFE2EDFF), borderRadius: BorderRadius.circular(12)),
                  child: const Text('4/4 Prêts', style: TextStyle(color: Color(0xFF005AC1), fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const SyscohadaDocumentCardWidget(
              icon: Icons.scale,
              title: 'Bilan Patrimonial',
              tagText: 'Équilibré',
              subtitle: 'Actif Immobilisé, Circulant & Trésorerie | Capitaux Propres & Dettes',
              leftLabel: 'Actif Net Total',
              leftValue: '89 200 000 XOF',
              rightLabel: 'Passif Total',
              rightValue: '89 200 000 XOF',
            ),
            const SizedBox(height: 8),
            const SyscohadaDocumentCardWidget(
              icon: Icons.show_chart,
              title: 'Compte de Résultat (SIG)',
              tagText: 'Marge 14.7%',
              subtitle: 'Soldes Intermédiaires : Marge, Valeur Ajoutée, EBE & Résultat Net',
              leftLabel: 'Valeur Ajoutée (VA)',
              leftValue: '42 800 000 XOF',
              rightLabel: 'Excédent Brut (EBE)',
              rightValue: '26 150 000 XOF',
            ),
            const SizedBox(height: 8),
            const SyscohadaDocumentCardWidget(
              icon: Icons.swap_horiz,
              title: 'Tableau des Flux (TFT)',
              tagText: '+ 4.15M XOF',
              subtitle: 'Flux d\'activités opérationnelles, d\'investissement et de financement',
              leftLabel: 'Flux Opérationnels (A)',
              leftValue: '+15 900 000 XOF',
              rightLabel: 'Flux Invest. (B)',
              rightValue: '-11 750 000 XOF',
            ),
            const SizedBox(height: 8),
            const SyscohadaDocumentCardWidget(
              icon: Icons.description_outlined,
              title: 'Notes Annexes & Fiche R',
              tagText: '100% complété',
              subtitle: 'Règles comptables, tableau des immobilisations, amortissements & provisions',
              leftLabel: '',
              leftValue: '',
              rightLabel: '',
              rightValue: '',
              footerNote: '12 notes obligatoires applicables sur 36',
            ),
            const SizedBox(height: 20),

            // Ratios & Équilibre Financier
            const Text('Ratios & Équilibre Financier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Text('Critères d\'analyse bancaire et fiscale CEMAC/UEMOA', style: TextStyle(color: Colors.grey, fontSize: 10)),
            const SizedBox(height: 12),
            const FinancialRatioCardWidget(
              title: 'Autonomie Financière',
              percentage: '62%',
              progressValue: 0.62,
              normText: 'Norme SYSCOHADA : > 50% (Conforme)',
              capitalText: 'Capitaux : 55.3M XOF',
            ),
            const SizedBox(height: 8),
            const FrngBfrRowWidget(),
            const SizedBox(height: 12),
            const AuditorVisaCardWidget(),
            const SizedBox(height: 16),
            const ActionButtonsWidget(),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Conforme à l\'Acte Uniforme OHADA relatif au droit comptable et à l\'information financière (AUDCIF) adopté le 26 janvier 2017.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 8, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}