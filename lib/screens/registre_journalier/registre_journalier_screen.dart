import 'package:flutter/material.dart';
import '../../services/femi_api_service.dart';
import '../../services/pdf_export_service.dart';
import 'widgets/exercice_selector_widget.dart';
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

  late int _exerciceSelectionne;
  late DateTimeRange _periodeSelectionnee;
  late Future<Map<String, dynamic>?> _registreFuture;

  @override
  void initState() {
    super.initState();
    final DateTime aujourdhui = DateTime.now();
    _exerciceSelectionne = aujourdhui.year;

    // Plage par défaut : du 1er du mois jusqu'à aujourd'hui
    _periodeSelectionnee = DateTimeRange(
      start: DateTime(aujourdhui.year, aujourdhui.month, 1),
      end: aujourdhui,
    );

    _chargerDonnees();
  }

  void _chargerDonnees() {
    _registreFuture = _apiService.getRegistreJournalier(
      dateDebut: _periodeSelectionnee.start,
      dateFin: _periodeSelectionnee.end,
    );
  }

  /// Change l'exercice et recale la plage dans les bornes de cet exercice
  void _changerExercice(int nouvelExercice) {
    setState(() {
      _exerciceSelectionne = nouvelExercice;

      final DateTime aujourdhui = DateTime.now();
      if (nouvelExercice == aujourdhui.year) {
        _periodeSelectionnee = DateTimeRange(
          start: DateTime(aujourdhui.year, aujourdhui.month, 1),
          end: aujourdhui,
        );
      } else {
        // Pour un exercice passé, toute l'année sélectionnée par défaut
        _periodeSelectionnee = DateTimeRange(
          start: DateTime(nouvelExercice, 1, 1),
          end: DateTime(nouvelExercice, 12, 31),
        );
      }

      _chargerDonnees();
    });
  }

  /// Ouvre le sélectionneur de plage de dates (DateRangePicker)
  Future<void> _selectionnerPlageDates(BuildContext context) async {
    final DateTimeRange? nouvellePlage = await showDateRangePicker(
      context: context,
      initialDateRange: _periodeSelectionnee,
      firstDate: DateTime(_exerciceSelectionne, 1, 1),
      lastDate: DateTime(_exerciceSelectionne, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF006654),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (nouvellePlage != null && nouvellePlage != _periodeSelectionnee) {
      setState(() {
        _periodeSelectionnee = nouvellePlage;
        _chargerDonnees();
      });
    }
  }

  String _formatDate(DateTime date) {
    const mois = [
      'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'
    ];
    return '${date.day} ${mois[date.month - 1]} ${date.year}';
  }

  String _formatPlageDates(DateTimeRange plage) {
    return '${_formatDate(plage.start)} — ${_formatDate(plage.end)}';
  }

  String _formatMontant(dynamic value, String devise) {
    if (value == null) return '0 $devise';
    final double amount = (value is num) ? value.toDouble() : double.tryParse(value.toString()) ?? 0.0;
    final String entier = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < entier.length; i++) {
      if (i > 0 && (entier.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(entier[i]);
    }
    return '$buffer $devise';
  }

  void _telechargerPdf(Map<String, dynamic> data) {
    final String devise = (data['devise'] as String?) ?? 'XOF';
    final List<dynamic> ecrituresBrutes = (data['ecritures'] as List<dynamic>?) ?? [];

    final List<Map<String, String>> ecrituresPdf = ecrituresBrutes.map((brute) {
      final ecriture = brute as Map<String, dynamic>;
      final bool estRecette = ecriture['type'] == 'RECETTE';
      final double montant = (ecriture['montant'] as num?)?.toDouble() ?? 0.0;

      return {
        'date': (ecriture['date'] ?? '').toString(),
        'heure': (ecriture['heure'] ?? '').toString(),
        'titre': (ecriture['titre'] ?? '').toString(),
        'categorie': (ecriture['categorie'] ?? (estRecette ? 'Recette' : 'Dépense')).toString(),
        'montant': '${estRecette ? '+ ' : '- '}${_formatMontant(montant, devise)}',
      };
    }).toList();

    PdfExportService.exportRegistreJournalier(
      dateLabel: _formatPlageDates(_periodeSelectionnee),
      totalRecettes: _formatMontant(data['total_recettes'], devise),
      totalDepenses: _formatMontant(data['total_depenses'], devise),
      ecritures: ecrituresPdf,
    );
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
                  const SizedBox(height: 16),

                  ExerciceSelectorWidget(
                    exerciceSelectionne: _exerciceSelectionne,
                    onExerciceChange: _changerExercice,
                  ),
                  const SizedBox(height: 12),

                  // Sélecteur de Plage de Dates
                  InkWell(
                    onTap: () => _selectionnerPlageDates(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.date_range_outlined, color: Color(0xFF006654), size: 22),
                              const SizedBox(width: 12),
                              Text(
                                _formatPlageDates(_periodeSelectionnee),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          const Icon(Icons.edit_calendar, color: Color(0xFF64748B), size: 18),
                        ],
                      ),
                    ),
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
                            'Aucune transaction enregistrée pour cette période.',
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
                      onPressed: chargement ? null : () => _telechargerPdf(data),
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