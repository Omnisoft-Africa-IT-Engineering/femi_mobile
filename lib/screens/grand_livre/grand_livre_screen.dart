import 'package:flutter/material.dart';
import '../../services/femi_api_service.dart';
import 'widgets/compte_card_widget.dart';

class GrandLivreScreen extends StatefulWidget {
  const GrandLivreScreen({super.key});

  @override
  State<GrandLivreScreen> createState() => _GrandLivreScreenState();
}

class _GrandLivreScreenState extends State<GrandLivreScreen> {
  final FemiApiService _apiService = FemiApiService();
  late Future<Map<String, dynamic>?> _grandLivreFuture;

  static const List<String> _mois = [
    'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
    'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _grandLivreFuture = _apiService.getGrandLivre();
  }

  Future<void> _refreshData() async {
    setState(() {
      _loadData();
    });
    await _grandLivreFuture;
  }

  // --- Formatage ---

  String _formatNumber(num value) {
    final intValue = value.round();
    final digits = intValue.abs().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }
    return intValue < 0 ? '- ${buffer.toString()}' : buffer.toString();
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day.toString().padLeft(2, '0')} ${_mois[date.month - 1]} ${date.year}';
    } catch (_) {
      return isoDate;
    }
  }

  String _formatSolde(double solde, String nature, String devise) {
    if (nature == 'charge') {
      return '${_formatNumber(solde)} $devise';
    }
    final sign = solde >= 0 ? '+ ' : '- ';
    return '$sign${_formatNumber(solde.abs())} $devise';
  }

  Color _soldeColor(double solde, String nature) {
    if (nature == 'charge') return Colors.red.shade700;
    return solde >= 0 ? const Color(0xFF00695C) : Colors.red.shade700;
  }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _refreshData,
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.black12,
              child: Icon(Icons.person, color: Colors.black87),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _grandLivreFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || snapshot.data == null) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 8),
                  const Center(child: Text('Erreur de chargement des données')),
                  const SizedBox(height: 8),
                  Center(
                    child: ElevatedButton(
                      onPressed: _refreshData,
                      child: const Text('Réessayer'),
                    ),
                  ),
                ],
              );
            }

            final data = snapshot.data!;
            final String devise = (data['devise'] as String?) ?? 'XOF';
            final Map<String, dynamic> totaux =
                (data['totaux'] as Map<String, dynamic>?) ?? {};
            final List<dynamic> comptesData =
                (data['comptes'] as List<dynamic>?) ?? [];

            final double totalDebit = (totaux['total_debit'] as num?)?.toDouble() ?? 0.0;
            final double totalCredit = (totaux['total_credit'] as num?)?.toDouble() ?? 0.0;
            final double soldeNet = (totaux['solde_net'] as num?)?.toDouble() ?? 0.0;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre & Bouton PDF
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
                        onPressed: () {},
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

                  // Cartes Débit / Crédit (issues de la base de données)
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
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.arrow_downward, color: Color(0xFF4CAF50), size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'TOTAL DÉBIT',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _formatNumber(totalDebit),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(devise, style: const TextStyle(color: Colors.white54, fontSize: 11)),
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
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.arrow_upward, color: Color(0xFFE53935), size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'TOTAL CRÉDIT',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _formatNumber(totalCredit),
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(devise, style: const TextStyle(color: Colors.black45, fontSize: 11)),
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
                          children: [
                            const Text(
                              'SOLDE NET',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatNumber(soldeNet)} $devise',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00695C),
                              ),
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.filter_list, size: 16, color: Colors.black54),
                        label: const Text(
                          'FILTRER',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (comptesData.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text(
                          'Aucune donnée comptable pour le moment.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    )
                  else
                    ...List.generate(comptesData.length, (index) {
                      final compte = comptesData[index] as Map<String, dynamic>;
                      final String code = (compte['code'] as String?) ?? '';
                      final String nom = (compte['nom'] as String?) ?? '';
                      final String nature = (compte['nature'] as String?) ?? 'actif';
                      final double solde = (compte['solde'] as num?)?.toDouble() ?? 0.0;
                      final bool afficherHistorique =
                          (compte['afficher_historique'] as bool?) ?? true;
                      final List<dynamic> mouvementsData =
                          (compte['mouvements'] as List<dynamic>?) ?? [];

                      final mouvements = mouvementsData.map((m) {
                        final mouvement = m as Map<String, dynamic>;
                        final double montant = (mouvement['montant'] as num?)?.toDouble() ?? 0.0;
                        return {
                          'date': _formatDate(mouvement['date'] as String?),
                          'libelle': (mouvement['libelle'] as String?) ?? '',
                          'montant': _formatNumber(montant),
                          if (montant < 0) 'montantColor': Colors.red.shade700,
                        };
                      }).toList();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: CompteCardWidget(
                          code: code,
                          nom: nom,
                          solde: _formatSolde(solde, nature, devise),
                          soldeColor: _soldeColor(solde, nature),
                          headerBgColor: const Color(0xFFE8F3FF),
                          showHistoryButton: afficherHistorique,
                          mouvements: mouvements,
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}