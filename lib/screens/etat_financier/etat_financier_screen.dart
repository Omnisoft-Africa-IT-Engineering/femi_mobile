import 'package:flutter/material.dart';
import '../../services/femi_api_service.dart';
import '../../services/pdf_export_service.dart';
import 'widgets/total_bilan_card.dart';
import 'widgets/financial_section_card.dart';
import '../registre_journalier/widgets/exercice_selector_widget.dart';

class EtatFinancierScreen extends StatefulWidget {
  const EtatFinancierScreen({super.key});

  @override
  State<EtatFinancierScreen> createState() => _EtatFinancierScreenState();
}

class _EtatFinancierScreenState extends State<EtatFinancierScreen> {
  final FemiApiService _apiService = FemiApiService();
  late int _exerciceSelectionne;
  late Future<Map<String, dynamic>?> _bilanFuture;

  @override
  void initState() {
    super.initState();
    _exerciceSelectionne = DateTime.now().year;
    _bilanFuture = _apiService.getEtatFinancier(annee: _exerciceSelectionne);
  }

  Future<void> _rafraichir() async {
    setState(() {
      _bilanFuture = _apiService.getEtatFinancier(annee: _exerciceSelectionne);
    });
    await _bilanFuture;
  }

  void _changerExercice(int nouvelExercice) {
    setState(() {
      _exerciceSelectionne = nouvelExercice;
      _bilanFuture = _apiService.getEtatFinancier(annee: _exerciceSelectionne);
    });
  }

  String _formatMontant(dynamic value, String devise) {
    if (value == null) return '0 $devise';
    final double amount = (value is num) ? value.toDouble() : double.tryParse(value.toString()) ?? 0.0;
    final String entier = amount.abs().toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < entier.length; i++) {
      if (i > 0 && (entier.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(entier[i]);
    }
    final String signe = amount < 0 ? '-' : '';
    return '$signe$buffer $devise';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Compte',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _rafraichir,
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.black,
              radius: 18,
              child: Icon(Icons.person_outline, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _rafraichir,
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _bilanFuture,
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
                    ElevatedButton(onPressed: _rafraichir, child: const Text('Réessayer')),
                  ],
                ),
              );
            }

            final data = snapshot.data!;
            final String devise = (data['devise'] as String?) ?? 'XOF';
            final bool equilibre = (data['equilibre'] as bool?) ?? false;
            final Map<String, dynamic> actif = (data['actif'] as Map<String, dynamic>?) ?? {};
            final Map<String, dynamic> passif = (data['passif'] as Map<String, dynamic>?) ?? {};
            final String avertissement = (data['avertissement'] as String?) ?? '';

            final actifItems = <FinancialItem>[
              FinancialItem(label: 'Actif Immobilisé (non suivi)', amount: _formatMontant(actif['actif_immobilise'], devise)),
              FinancialItem(label: 'Actif Circulant (créances)', amount: _formatMontant(actif['actif_circulant'], devise)),
              FinancialItem(label: 'Trésorerie Actif', amount: _formatMontant(actif['tresorerie_actif'], devise)),
              FinancialItem(label: 'Total Actif', amount: _formatMontant(actif['total_actif'], devise), isTotal: true),
            ];

            final passifItems = <FinancialItem>[
              FinancialItem(label: 'Capitaux Propres (approx.)', amount: _formatMontant(passif['capitaux_propres'], devise)),
              FinancialItem(label: 'Dettes Financières', amount: _formatMontant(passif['dettes_financieres'], devise)),
              FinancialItem(label: 'Passif Circulant (non suivi)', amount: _formatMontant(passif['passif_circulant'], devise)),
              FinancialItem(label: 'Total Passif', amount: _formatMontant(passif['total_passif'], devise), isTotal: true),
            ];

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ÉTAT FINANCIER (SIMPLIFIÉ)',
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
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B75BC),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          PdfExportService.exportBilan(
                            totalAmount: _formatMontant(actif['total_actif'], devise),
                            actifs: actifItems.map((i) => {'label': i.label, 'amount': i.amount}).toList(),
                            passifs: passifItems.map((i) => {'label': i.label, 'amount': i.amount}).toList(),
                          );
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.picture_as_pdf_outlined, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text('PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            SizedBox(width: 4),
                            Icon(Icons.chevron_right, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  ExerciceSelectorWidget(
                    exerciceSelectionne: _exerciceSelectionne,
                    onExerciceChange: _changerExercice,
                  ),
                  const SizedBox(height: 8),

                  if (avertissement.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              avertissement,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                            ),
                          ),
                        ],
                      ),
                    ),

                  TotalBilanCard(
                    totalAmount: _formatMontant(actif['total_actif'], '').trim(),
                    currency: devise,
                    statusLabel: equilibre ? 'ÉQUILIBRÉ' : 'PARTIEL',
                  ),

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

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006654),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {},
                      child: const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Générer l\'analyse Femi',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
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
            );
          },
        ),
      ),
    );
  }
}