import 'package:flutter/material.dart';
import '../../services/femi_api_service.dart';
import '../../services/pdf_export_service.dart';
import '../registre_journalier/widgets/exercice_selector_widget.dart';
import '../etat_financier/widgets/total_bilan_card.dart';
import 'widgets/balance_account_table.dart';

class BalanceAuxiliaireScreen extends StatefulWidget {
  const BalanceAuxiliaireScreen({super.key});

  @override
  State<BalanceAuxiliaireScreen> createState() => _BalanceAuxiliaireScreenState();
}

class _BalanceAuxiliaireScreenState extends State<BalanceAuxiliaireScreen> {
  final FemiApiService _apiService = FemiApiService();
  late int _exerciceSelectionne;
  late Future<Map<String, dynamic>?> _balanceFuture;

  @override
  void initState() {
    super.initState();
    _exerciceSelectionne = DateTime.now().year;
    _balanceFuture = _apiService.getBalanceAuxiliaire(annee: _exerciceSelectionne);
  }

  void _changerExercice(int nouvelExercice) {
    setState(() {
      _exerciceSelectionne = nouvelExercice;
      _balanceFuture = _apiService.getBalanceAuxiliaire(annee: _exerciceSelectionne);
    });
  }

  Future<void> _rafraichir() async {
    setState(() {
      _balanceFuture = _apiService.getBalanceAuxiliaire(annee: _exerciceSelectionne);
    });
    await _balanceFuture;
  }

  String _formatMontant(dynamic value) {
    if (value == null) return '0';
    final double amount = (value is num) ? value.toDouble() : double.tryParse(value.toString()) ?? 0.0;
    final String entier = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < entier.length; i++) {
      if (i > 0 && (entier.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(entier[i]);
    }
    return buffer.toString();
  }

  String _formatMontantCourt(double amount) {
    if (amount.abs() >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1).replaceAll('.', ',')} M';
    }
    if (amount.abs() >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)} k';
    }
    return amount.toStringAsFixed(0);
  }

  List<BalanceRowData> _construireLignes(List<dynamic> lignesBrutes) {
    return lignesBrutes.map((brute) {
      final ligne = brute as Map<String, dynamic>;
      return BalanceRowData(
        numero: '', // pas de code de compte : soldes réels par contact
        libelle: (ligne['libelle'] as String?) ?? '',
        debit: _formatMontant(ligne['debit']),
        credit: _formatMontant(ligne['credit']),
        solde: _formatMontant(ligne['solde']),
        soldeDebiteur: (ligne['solde_debiteur'] as bool?) ?? true,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _rafraichir,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _rafraichir,
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _balanceFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || snapshot.data == null) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 80.0),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 8),
                        const Text('Erreur de chargement de la balance auxiliaire'),
                        ElevatedButton(onPressed: _rafraichir, child: const Text('Réessayer')),
                      ],
                    ),
                  ),
                ),
              );
            }

            final data = snapshot.data!;
            final List<dynamic> clientsBrutes = (data['clients'] as List<dynamic>?) ?? [];
            final List<dynamic> fournisseursBrutes = (data['fournisseurs'] as List<dynamic>?) ?? [];
            final clientRows = _construireLignes(clientsBrutes);
            final fournisseurRows = _construireLignes(fournisseursBrutes);
            final double totalSoldeClients = (data['total_solde_clients'] as num?)?.toDouble() ?? 0.0;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B75BC),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          PdfExportService.exportBalanceAuxiliaire(
                            clients: clientRows
                                .map((r) => {
                                      'numero': r.numero,
                                      'libelle': r.libelle,
                                      'debit': r.debit,
                                      'credit': r.credit,
                                      'solde': r.solde,
                                    })
                                .toList(),
                            fournisseurs: fournisseurRows
                                .map((r) => {
                                      'numero': r.numero,
                                      'libelle': r.libelle,
                                      'debit': r.debit,
                                      'credit': r.credit,
                                      'solde': r.solde,
                                    })
                                .toList(),
                          );
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.picture_as_pdf_outlined, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text('PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ExerciceSelectorWidget(
                    exerciceSelectionne: _exerciceSelectionne,
                    onExerciceChange: _changerExercice,
                  ),
                  const SizedBox(height: 24),

                  TotalBilanCard(
                    totalAmount: _formatMontantCourt(totalSoldeClients),
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
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (clientRows.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('Aucun client mouvementé sur cet exercice.', style: TextStyle(color: Colors.black45)),
                    )
                  else
                    BalanceAccountTable(rows: clientRows),

                  const SizedBox(height: 24),

                  // Section Fournisseurs
                  Row(
                    children: const [
                      Icon(Icons.local_shipping_outlined, color: Colors.black, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Fournisseurs',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (fournisseurRows.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('Aucun fournisseur mouvementé sur cet exercice.', style: TextStyle(color: Colors.black45)),
                    )
                  else
                    BalanceAccountTable(rows: fournisseurRows),

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