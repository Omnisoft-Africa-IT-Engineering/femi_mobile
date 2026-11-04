import 'package:flutter/material.dart';
import '../../services/femi_api_service.dart';
import '../../services/kpi_service.dart';
import 'widgets/ai_recommendation_card_widget.dart';
import 'widgets/ai_summary_card_widget.dart';
import 'widgets/metric_card_widget.dart';
import 'widgets/stock_alert_banner.dart';
import '../femi_chat/widgets/femi_drawer_widget.dart';
import '../notifications/notification_bell.dart';

import '../../theme/app_colors.dart';
class DashboardScreen extends StatefulWidget {
  /// Appelé quand l'utilisateur veut basculer vers l'agent Femi avec un
  /// message pré-rempli (ex. depuis la carte de recommandation IA).
  final void Function(String prompt)? onNavigateToFemi;

  /// Permet au Drawer de demander à MainNavigationScreen de basculer
  /// vers un autre onglet (Chat Femi = 1, Compte = 2).
  final void Function(int tabIndex)? onNavigateToTab;

  const DashboardScreen({
    super.key,
    this.onNavigateToFemi,
    this.onNavigateToTab,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FemiApiService _apiService = FemiApiService();
  final KpiService _kpiService = KpiService();
  late Future<Map<String, dynamic>?> _kpisFuture;
  late Future<List<KpiNiveauResult>> _niveauxFuture;
  late Future<AlertesStock?> _stockFuture;

  // Niveaux affichés (les niveaux 4 et 5 n'ont pas encore de calcul).
  static const List<int> _niveauxAffiches = [1, 2, 3];

  // Nom de l'entreprise du compte connecté, affiché dans l'AppBar.
  String _companyName = 'Femi';

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadCompanyName();
  }

  void _loadData() {
    _kpisFuture = _apiService.getDashboardKPIs(period: 'this_month');
    _niveauxFuture =
        _kpiService.getNiveaux(_niveauxAffiches, period: 'this_month');
    _stockFuture = AlertesStock.charger();
  }

  Future<void> _loadCompanyName() async {
    final name = await _apiService.getCompanyName();
    if (mounted) {
      setState(() => _companyName = name);
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _loadData();
    });
    await Future.wait([_kpisFuture, _niveauxFuture, _stockFuture]);
  }

  String _formatCompactAmount(dynamic value, {String currency = 'FCFA'}) {
    if (value == null) return '0 $currency';

    double amount = 0.0;
    if (value is num) {
      amount = value.toDouble();
    } else {
      amount =
          double.tryParse(
            value.toString().replaceAll(RegExp(r'[^\d.-]'), ''),
          ) ??
          0.0;
    }

    final double absAmount = amount.abs();
    final String sign = amount < 0 ? '-' : '';

    if (absAmount >= 1000000000) {
      return '$sign${(absAmount / 1000000000).toStringAsFixed(1)} B $currency';
    } else if (absAmount >= 1000000) {
      return '$sign${(absAmount / 1000000).toStringAsFixed(1)} M $currency';
    } else if (absAmount >= 1000) {
      return '$sign${(absAmount / 1000).toStringAsFixed(0)} k $currency';
    } else {
      return '$sign${absAmount.toStringAsFixed(0)} $currency';
    }
  }

  String _formatPercentage(dynamic value) {
    if (value == null) return '0%';
    final double numValue =
        (value is num) ? value.toDouble() : double.tryParse(value.toString()) ?? 0.0;
    return '${numValue.toStringAsFixed(1)}%';
  }

  String _formatTrend(dynamic value) {
    if (value == null) return '';
    final double numValue =
        (value is num) ? value.toDouble() : double.tryParse(value.toString()) ?? 0.0;
    final String sign = numValue >= 0 ? '+' : '';
    return '$sign${numValue.toStringAsFixed(1)}% vs période préc.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: FemiDrawerWidget(
        currentTabIndex: FemiDrawerWidget.tabDashboard,
        onNavigateToTab: widget.onNavigateToTab,
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(
                'https://femi.ai/static/images/femi_logo.png',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _companyName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _refreshData,
          ),
          const NotificationBell(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _kpisFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 8),
                    const Text('Erreur de chargement des données'),
                    ElevatedButton(
                      onPressed: _refreshData,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              );
            }

            final responseData = snapshot.data ?? {};

            final Map<String, dynamic> kpis =
                (responseData['kpis'] as Map<String, dynamic>?) ?? {};
            final Map<String, dynamic> trends =
                (responseData['trends'] as Map<String, dynamic>?) ?? {};

            final bool resumeDisponible = snapshot.data != null;

            final String revenue = _formatCompactAmount(kpis['total_revenue']);
            final String expenses = _formatCompactAmount(kpis['total_expenses']);

            final String revenueChange =
                _formatTrend(trends['revenue_change_percentage']);
            final String expensesChange =
                _formatTrend(trends['expenses_change_percentage']);

            final double marginValue =
                (kpis['profit_margin_percentage'] as num?)?.toDouble() ?? 0.0;
            final String marginRate = _formatPercentage(marginValue);

            final String contexte =
                'Contexte : chiffre d\'affaires de $revenue ce mois-ci, '
                'dépenses de $expenses, marge actuelle de $marginRate.';
            final String femiPrompt = marginValue < 0
                ? 'Comment puis-je réduire mes charges ce mois-ci pour repasser en marge positive ? $contexte'
                : 'Propose-moi un plan d\'action pour optimiser ma rentabilité actuelle. $contexte';

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StockAlertBanner(
                    future: _stockFuture,
                    onRetourStock: _refreshData,
                  ),
                  if (resumeDisponible) ...[
                    AiSummaryCardWidget(
                      message:
                          'Chiffre d\'affaires : $revenue ce mois-ci ($revenueChange). '
                          'Dépenses : $expenses ($expensesChange).',
                    ),
                    const SizedBox(height: 20),
                  ],

                  const Text(
                    'Santé de l\'entreprise',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  _buildNiveaux(),
                  const SizedBox(height: 24),

                  // Pas de barre de saisie ici : les suggestions
                  // envoient directement vers Femi.
                  const Text(
                    'Questions suggérées :',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),

                  _buildSuggestedQuestion(
                    icon: Icons.analytics_outlined,
                    title: "Analyse de la rentabilité par produit/service",
                  ),
                  _buildSuggestedQuestion(
                    icon: Icons.account_balance_wallet_outlined,
                    title: "Où va l'argent ? (Analyse des charges)",
                  ),
                  _buildSuggestedQuestion(
                    icon: Icons.people_outline,
                    title: "Qui relancer ce mois-ci ? (Créances)",
                  ),
                  _buildSuggestedQuestion(
                    icon: Icons.trending_up_outlined,
                    title: "Prévisions financières pour les 3 prochains mois",
                  ),

                  const SizedBox(height: 20),

                  if (kpis.isNotEmpty)
                    AiRecommendationCardWidget(
                      description:
                          'Chiffre d\'affaires de $revenue ce mois-ci, dépenses de $expenses. '
                          'Marge actuelle : $marginRate.',
                      onPrimaryPressed: () {
                        widget.onNavigateToFemi?.call(femiPrompt);
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// KPI par niveau, filtrés par secteur côté serveur (GET /kpi/<niveau>/).
  Widget _buildNiveaux() {
    return FutureBuilder<List<KpiNiveauResult>>(
      future: _niveauxFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final List<KpiNiveauResult> niveaux = snap.data ?? [];
        if (niveaux.isEmpty) {
          return _buildNiveauErreur(
            'Impossible de charger les indicateurs.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final niveau in niveaux) ...[
              _buildLevelHeader('Niveau ${niveau.numero} — ${niveau.nom}'),
              if (niveau.erreur != null)
                _buildNiveauErreur(niveau.erreur!)
              else if (niveau.kpis.isEmpty)
                _buildNiveauErreur('Aucun indicateur pour ce niveau.')
              else
                _buildHorizontalScrollRow([
                  for (final kpi in niveau.kpis) _buildKpiCard(kpi),
                ]),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }

  Widget _buildKpiCard(KpiItem kpi) {
    final bool negatif = kpi.disponible &&
        kpi.valeur is num &&
        (kpi.valeur as num) < 0;

    Color couleur = Colors.green;
    if (!kpi.disponible) {
      couleur = Colors.grey;
    } else if (const {
      'Dépenses',
      'Dettes',
      'Créances',
      'Ruptures de stock',
      'Alertes de stock',
    }.contains(kpi.nom)) {
      couleur = Colors.red;
    } else if (kpi.nom == 'Trésorerie') {
      couleur = AppColors.vert;
    }

    return MetricCardWidget(
      title: kpi.nom.toUpperCase(),
      value: kpi.valeurAffichee,
      emoji: kpi.icone,
      icon: Icons.analytics_outlined,
      color: couleur,
      valueColor: !kpi.disponible
          ? Colors.grey
          : (negatif ? Colors.red : Colors.black87),
      subtitle: kpi.disponible ? null : 'Pas encore calculé',
    );
  }

  Widget _buildNiveauErreur(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
          TextButton(
            onPressed: _refreshData,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalScrollRow(List<Widget> children) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: children),
    );
  }

  Widget _buildLevelHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildSuggestedQuestion({
    required IconData icon,
    required String title,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: AppColors.vert, size: 20),
        title: Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.grey,
        ),
        onTap: () {
          widget.onNavigateToFemi?.call(title);
        },
      ),
    );
  }
}