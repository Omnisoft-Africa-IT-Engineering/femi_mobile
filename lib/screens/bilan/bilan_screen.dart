import 'package:flutter/material.dart';
import '../../services/femi_api_service.dart';
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
  final FemiApiService _apiService = FemiApiService();
  int _selectedYear = DateTime.now().year;
  late Future<Map<String, dynamic>?> _syntheseFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _syntheseFuture = _apiService.getBilanSynthese(annee: _selectedYear);
  }

  void _onYearSelected(int year) {
    setState(() {
      _selectedYear = year;
      _loadData();
    });
  }

  // --- Formatage ---

  String _formatAmount(dynamic value) {
    if (value == null) return '0';
    final double amount = (value is num) ? value.toDouble() : 0.0;
    // Séparateur de milliers façon "124 500 000"
    final String sign = amount < 0 ? '-' : '';
    final String digits = amount.abs().toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return '$sign${buffer.toString()}';
  }

  String? _formatGrowth(dynamic value) {
    if (value == null) return null;
    final double v = (value is num) ? value.toDouble() : 0.0;
    final String sign = v >= 0 ? '+' : '';
    return '$sign${v.toStringAsFixed(1)}%';
  }

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
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _syntheseFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 8),
                  const Text('Erreur de chargement du bilan'),
                  ElevatedButton(
                    onPressed: () => setState(() => _loadData()),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          final Map<String, dynamic> ca = (data['chiffre_affaires'] as Map<String, dynamic>?) ?? {};
          final Map<String, dynamic> resultat = (data['resultat_net'] as Map<String, dynamic>?) ?? {};
          final Map<String, dynamic> marge = (data['marge_pct'] as Map<String, dynamic>?) ?? {};
          final Map<String, dynamic> tresorerie = (data['tresorerie'] as Map<String, dynamic>?) ?? {};

          final String devise = data['devise']?.toString() ?? 'XOF';
          final double marginValue = (marge['valeur'] is num) ? (marge['valeur'] as num).toDouble() : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SyscohadaHeaderWidget(),
                const SizedBox(height: 12),
                YearFilterWidget(
                  selectedYear: _selectedYear,
                  onYearSelected: _onYearSelected,
                ),
                const SizedBox(height: 12),
                // isCertified reste à false : rien dans le système ne
                // vérifie ce statut aujourd'hui.
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
                      'SYNTHÈSE DE L\'EXERCICE ($devise)',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                    ),
                    const Spacer(),
                    Text('Devise : $devise', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 8),
                MainKpiCardWidget(
                  title: 'Chiffre d\'Affaires (TTC)',
                  amount: _formatAmount(ca['valeur']),
                  growthPercentage: _formatGrowth(ca['croissance_pct']),
                ),
                const SizedBox(height: 8),
                SecondaryKpiRowWidget(
                  resultatNetValue: _formatAmount(resultat['valeur']),
                  tresorerieValue: _formatAmount(tresorerie['valeur']),
                ),
                const SizedBox(height: 12),

                // Diagnostic IA — sans le ratio d'autonomie non vérifié
                AiDiagnosticBannerWidget(marginPercentage: marginValue),
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
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                      // Honnête : ces 4 états nécessitent un module comptable
                      // (plan de comptes, immobilisations, ventilation des
                      // charges) qui n'existe pas encore dans le système —
                      // on ne prétend plus qu'ils sont "prêts".
                      child: const Text('0/4 Disponibles', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold)),
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
                  isAvailable: false,
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
                  isAvailable: false,
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
                  isAvailable: false,
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
                  isAvailable: false,
                ),
                const SizedBox(height: 20),

                // Ratios & Équilibre Financier
                const Text('Ratios & Équilibre Financier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Text('Critères d\'analyse bancaire et fiscale CEMAC/UEMOA', style: TextStyle(color: Colors.grey, fontSize: 10)),
                const SizedBox(height: 12),
                // Ratio d'autonomie : toujours isAvailable=false, car aucune
                // donnée de capitaux propres réels n'est disponible.
                const FinancialRatioCardWidget(
                  title: 'Autonomie Financière',
                  percentage: 'N/A',
                  progressValue: 0.0,
                  normText: 'Donnée indisponible : capitaux propres non suivis',
                  capitalText: '',
                  isAvailable: false,
                ),
                const SizedBox(height: 8),
                const FrngBfrRowWidget(isAvailable: false),
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
          );
        },
      ),
    );
  }
}