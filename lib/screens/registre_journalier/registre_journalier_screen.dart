import 'package:flutter/material.dart';
import '../../services/femi_api_service.dart';
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
  final FemiApiService _apiService = FemiApiService();
  DateTime _dateSelectionnee = DateTime.now();
  late Future<Map<String, dynamic>?> _registreFuture;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  void _chargerDonnees() {
    _registreFuture = _apiService.getRegistreJournalier(date: _dateSelectionnee);
  }

  void _changerDate(int deltaJours) {
    setState(() {
      _dateSelectionnee = _dateSelectionnee.add(Duration(days: deltaJours));
      _chargerDonnees();
    });
  }

  String _formatDate(DateTime date) {
    const mois = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${date.day} ${mois[date.month - 1]} ${date.year}';
  }

  String _sousTitreDate(DateTime date) {
    final aujourdhui = DateTime.now();
    final estAujourdhui = date.year == aujourdhui.year &&
        date.month == aujourdhui.month &&
        date.day == aujourdhui.day;
    return estAujourdhui ? "Aujourd'hui" : '';
  }

  String _formatMontant(dynamic value, String devise) {
    if (value == null) return '0 $devise';
    final double amount = (value is num) ? value.toDouble() : double.tryParse(value.toString()) ?? 0.0;
    // Espace comme séparateur de milliers, courant en zone XOF/CFA.
    final String entier = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < entier.length; i++) {
      if (i > 0 && (entier.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(entier[i]);
    }
    return '$buffer $devise';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Compte',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _registreFuture,
          builder: (context, snapshot) {
            final bool chargement = snapshot.connectionState == ConnectionState.waiting;
            final Map<String, dynamic> data = snapshot.data ?? {};
            final String devise = (data['devise'] as String?) ?? 'XOF';
            final List<dynamic> ecrituresBrutes = (data['ecritures'] as List<dynamic>?) ?? [];

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Registre Journalier',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 20),

                  DateSelectorWidget(
                    dateText: _formatDate(_dateSelectionnee),
                    subtitle: _sousTitreDate(_dateSelectionnee),
                    onPrevious: () => _changerDate(-1),
                    onNext: () => _changerDate(1),
                  ),
                  const SizedBox(height: 20),

                  if (chargement)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: TotalCardWidget(
                            title: 'TOTAL RECETTES',
                            amount: _formatMontant(data['total_recettes'], devise),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TotalCardWidget(
                            title: 'TOTAL DÉPENSES',
                            amount: _formatMontant(data['total_depenses'], devise),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (ecrituresBrutes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'Aucune transaction ce jour-là.',
                            style: TextStyle(color: Colors.black45),
                          ),
                        ),
                      )
                    else
                      ...ecrituresBrutes.map((brute) {
                        final ecriture = brute as Map<String, dynamic>;
                        final bool estRecette = ecriture['type'] == 'RECETTE';
                        final double montant = (ecriture['montant'] as num?)?.toDouble() ?? 0.0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: EcritureCardWidget(
                            ecriture: {
                              'id': (ecriture['id'] as String).substring(0, 8),
                              'time': ecriture['heure'] ?? '',
                              'title': ecriture['titre'] ?? '',
                              'lines': [
                                {
                                  'dotColor': estRecette ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                  'codeName': ecriture['categorie'] ?? (estRecette ? 'Recette' : 'Dépense'),
                                  'amount': '${estRecette ? '+ ' : '- '}${_formatMontant(montant, devise)}',
                                  'amountColor': estRecette ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                },
                              ],
                            },
                          ),
                        );
                      }),
                  ],

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006654),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.file_download_outlined, color: Colors.white),
                      label: const Text(
                        'Télécharger en PDF',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
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