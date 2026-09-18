import 'package:flutter/material.dart';
import '../../services/femi_api_service.dart';
import 'widgets/ai_recommendation_card_widget.dart';
import 'widgets/ai_summary_card_widget.dart';
import 'widgets/metric_card_widget.dart';
import '../femi_chat/widgets/femi_drawer_widget.dart';

class DashboardScreen extends StatefulWidget {
  /// Appelé quand l'utilisateur veut basculer vers l'agent Femi avec un
  /// message pré-rempli (ex. depuis la carte de recommandation IA).
  final void Function(String prompt)? onNavigateToFemi;

  /// Permet au Drawer de demander à MainNavigationScreen de basculer
  /// vers un autre onglet (Chat Femi = 1, Compte = 2).
  final void Function(int tabIndex)? onNavigateToTab;

  const DashboardScreen({super.key, this.onNavigateToFemi, this.onNavigateToTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FemiApiService _apiService = FemiApiService();
  final TextEditingController _queryController = TextEditingController();
  late Future<Map<String, dynamic>?> _kpisFuture;

  // Nom de l'entreprise du compte connecté, affiché dans l'AppBar
  // au lieu du "Komi Services" codé en dur.
  String _companyName = 'Femi';

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadCompanyName();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _loadData() {
    _kpisFuture = _apiService.getDashboardKPIs(period: 'this_month');
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
    await _kpisFuture;
  }

  /// Envoie le contenu de la barre de recherche à Femi (bascule vers son
  /// onglet avec ce texte comme prompt initial), puis vide le champ.
  void _envoyerRechercheVersFemi() {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;
    widget.onNavigateToFemi?.call(query);
    _queryController.clear();
  }

  String _formatCompactAmount(dynamic value, {String currency = 'FCFA'}) {
    if (value == null) return '0 $currency';

    double amount = 0.0;
    if (value is num) {
      amount = value.toDouble();
    } else {
      amount = double.tryParse(value.toString().replaceAll(RegExp(r'[^\d.-]'), '')) ?? 0.0;
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
    final double numValue = (value is num) ? value.toDouble() : double.tryParse(value.toString()) ?? 0.0;
    return '${numValue.toStringAsFixed(1)}%';
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
              backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=5'),
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
          IconButton(
            icon: const Icon(
              Icons.notifications_none_outlined,
              color: Colors.black87,
            ),
            onPressed: () {},
          ),
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

            // La réponse Django a cette forme :
            // { "kpis": {...}, "trends": {...}, "treasury": {...}, ... }
            // On extrait chaque bloc séparément, au lieu de tout aplatir
            // dans une seule variable "kpis" comme avant — c'était la
            // source du bug : "cash_flow" par exemple n'est PAS dans
            // "kpis", il est dans "treasury".
            final Map<String, dynamic> kpis =
                (responseData['kpis'] as Map<String, dynamic>?) ?? {};
            final Map<String, dynamic> treasury =
                (responseData['treasury'] as Map<String, dynamic>?) ?? {};
            final Map<String, dynamic> trends =
                (responseData['trends'] as Map<String, dynamic>?) ?? {};

            // --- NIVEAU 1 : Santé ---
            // Ces 3 champs correspondent exactement aux noms renvoyés
            // par DashboardKPIAPIView (voir views.py) :
            final String revenue = _formatCompactAmount(kpis['total_revenue']);
            final String netIncome = _formatCompactAmount(kpis['net_profit']);
            final String expenses = _formatCompactAmount(kpis['total_expenses']);

            // La trésorerie est dans le bloc "treasury", pas "kpis" :
            final String cashFlow = _formatCompactAmount(treasury['balance']);

            // Django renvoie "unique_clients_count", pas "active_clients_count" :
            final String activeClientsCount =
                (kpis['unique_clients_count'] ?? 0).toString();

            // NOTE : Django ne calcule pas encore les créances dans cet
            // endpoint (DashboardKPIAPIView). Ce chiffre reste à 0 tant
            // que ce n'est pas ajouté côté backend, ou récupéré via
            // KpiNiveauAPIView (qui a bien un calculateur "Créances").
            final String totalReceivables = _formatCompactAmount(kpis['total_receivables']);

            // --- Variation vs période précédente (bloc "trends") ---
            final String revenueChange = _formatTrend(trends['revenue_change_percentage']);
            final String expensesChange = _formatTrend(trends['expenses_change_percentage']);
            final String profitChange = _formatTrend(trends['profit_change_percentage']);

            // --- NIVEAU 2 : Activité ---
            // NOTE : "sales_count" n'existe pas dans la réponse actuelle de
            // Django. Le plus proche est "total_transactions_count" (qui
            // compte TOUTES les opérations, pas seulement les ventes).
            // À ajuster côté Django si tu veux un vrai compteur de ventes.
            final String salesCount = (kpis['total_transactions_count'] ?? 0).toString();
            final String averageBasket = _formatCompactAmount(kpis['average_sale_amount']);

            // Les champs suivants n'existent pas encore dans la réponse
            // Django actuelle — ils restent à 0/valeur par défaut tant que
            // le backend ne les calcule pas. Pense à les ajouter à
            // DashboardKPIAPIView si tu veux les voir remplis.
            final String pendingOrdersCount = '0';
            final String totalProducts = '0';
            final String recurringClientsCount = '0';
            final String servicesCount = '0';

            // --- NIVEAU 3 : Finance ---
            final double marginValue = (kpis['profit_margin_percentage'] as num?)?.toDouble() ?? 0.0;
            final String marginRate = _formatPercentage(marginValue);
            final String totalDebts = '0'; // pas encore fourni par Django

            // --- NIVEAU 4 : Opérations (pas encore fourni par Django) ---
            const String stockStatus = '0%';
            const String suppliersCount = '0';
            const String productionRate = '0%';
            const String totalPurchases = '0 FCFA';
            const String deliveriesCount = '0';
            const String staffCount = '-';

            // --- NIVEAU 5 : IA (pas encore fourni par Django) ---
            const String anomaliesCount = '0';
            const String trendPercentage = '0%';
            const String growthForecast = '0%';
            const String alertsCount = '0';
            const String recommendationsCount = '0';
            const String opportunitiesCount = '0';

            // --- Prompt contextuel pour le bouton "Agir maintenant" ---
            // On adapte la question selon que la marge est négative
            // (priorité : réduire les charges) ou positive (priorité :
            // optimiser davantage la rentabilité).
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
                  AiSummaryCardWidget(
                    message:
                        'Chiffre d\'affaires : $revenue ce mois-ci ($revenueChange). '
                        'Dépenses : $expenses ($expensesChange).',
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Santé de l\'entreprise',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  _buildLevelHeader('Niveau 1 — Santé'),
                  _buildHorizontalScrollRow([
                    MetricCardWidget(
                      title: 'CHIFFRE D\'AFFAIRES',
                      value: revenue,
                      icon: Icons.payments,
                      color: Colors.green,
                      subtitle: revenueChange,
                    ),
                    MetricCardWidget(
                      title: 'BÉNÉFICE NET',
                      value: netIncome,
                      icon: Icons.trending_up,
                      color: Colors.green,
                      subtitle: profitChange,
                    ),
                    MetricCardWidget(
                      title: 'DÉPENSES',
                      value: expenses,
                      icon: Icons.shopping_bag,
                      color: Colors.red,
                      subtitle: expensesChange,
                    ),
                    MetricCardWidget(
                      title: 'TRÉSORERIE',
                      value: cashFlow,
                      icon: Icons.account_balance,
                      color: Colors.blue,
                      subtitle: 'Disponible',
                    ),
                    MetricCardWidget(
                      title: 'CLIENTS',
                      value: activeClientsCount,
                      icon: Icons.people,
                      color: Colors.green,
                      subtitle: 'Ce mois',
                    ),
                    MetricCardWidget(
                      title: 'CRÉANCES',
                      value: totalReceivables,
                      icon: Icons.warning_amber_rounded,
                      color: Colors.red,
                      subtitle: 'À recouvrir',
                    ),
                  ]),
                  const SizedBox(height: 16),

                  _buildLevelHeader('Niveau 2 — Activité'),
                  _buildHorizontalScrollRow([
                    MetricCardWidget(
                      title: 'TRANSACTIONS',
                      value: salesCount,
                      icon: Icons.point_of_sale,
                      color: Colors.green,
                      subtitle: 'Ce mois',
                    ),
                    MetricCardWidget(
                      title: 'COMMANDES',
                      value: pendingOrdersCount,
                      icon: Icons.receipt_long,
                      color: const Color(0xFF1B75BC),
                    ),
                    MetricCardWidget(
                      title: 'PANIER MOYEN',
                      value: averageBasket,
                      icon: Icons.shopping_cart,
                      color: Colors.green,
                    ),
                    MetricCardWidget(
                      title: 'PRODUITS',
                      value: totalProducts,
                      icon: Icons.inventory_2,
                      color: Colors.grey,
                    ),
                    MetricCardWidget(
                      title: 'CLIENTS ACTIFS',
                      value: recurringClientsCount,
                      icon: Icons.person_pin,
                      color: Colors.green,
                    ),
                    MetricCardWidget(
                      title: 'PRESTATIONS',
                      value: servicesCount,
                      icon: Icons.build,
                      color: const Color(0xFF1B75BC),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  _buildLevelHeader('Niveau 3 — Finance'),
                  _buildHorizontalScrollRow([
                    MetricCardWidget(
                      title: 'REVENUS',
                      value: revenue,
                      icon: Icons.attach_money,
                      color: Colors.green,
                    ),
                    MetricCardWidget(
                      title: 'DÉPENSES',
                      value: expenses,
                      icon: Icons.money_off,
                      color: Colors.red,
                    ),
                    MetricCardWidget(
                      title: 'MARGE',
                      value: marginRate,
                      icon: Icons.pie_chart,
                      color: Colors.orange,
                    ),
                    MetricCardWidget(
                      title: 'BÉNÉFICE',
                      value: netIncome,
                      icon: Icons.show_chart,
                      color: Colors.green,
                    ),
                    MetricCardWidget(
                      title: 'TRÉSORERIE',
                      value: cashFlow,
                      icon: Icons.account_balance_wallet,
                      color: const Color(0xFF1B75BC),
                    ),
                    MetricCardWidget(
                      title: 'DETTES',
                      value: totalDebts,
                      icon: Icons.credit_card_off,
                      color: Colors.red,
                    ),
                  ]),
                  const SizedBox(height: 16),
/* 
                  _buildLevelHeader('Niveau 4 — Opérations (à venir)'),
                  _buildHorizontalScrollRow([
                    MetricCardWidget(title: 'STOCKS', value: stockStatus, icon: Icons.store, color: Colors.orange),
                    MetricCardWidget(title: 'FOURNISSEURS', value: suppliersCount, icon: Icons.local_shipping, color: Colors.grey),
                    MetricCardWidget(title: 'PRODUCTION', value: productionRate, icon: Icons.precision_manufacturing, color: Colors.green),
                    MetricCardWidget(title: 'ACHATS', value: totalPurchases, icon: Icons.add_shopping_cart, color: Colors.red),
                    MetricCardWidget(title: 'LIVRAISONS', value: deliveriesCount, icon: Icons.delivery_dining, color: Colors.orange),
                    MetricCardWidget(title: 'PERSONNEL', value: staffCount, icon: Icons.badge, color: Colors.green),
                  ]),
                  const SizedBox(height: 16),

                  _buildLevelHeader('Niveau 5 — Intelligence IA (à venir)'),
                  _buildHorizontalScrollRow([
                    MetricCardWidget(title: 'ANOMALIES', value: anomaliesCount, icon: Icons.error_outline, color: Colors.red),
                    MetricCardWidget(title: 'TENDANCES', value: trendPercentage, icon: Icons.auto_graph, color: Colors.green),
                    MetricCardWidget(title: 'PRÉVISIONS', value: growthForecast, icon: Icons.insights, color: const Color(0xFF1B75BC)),
                    MetricCardWidget(title: 'ALERTES', value: alertsCount, icon: Icons.add_alert, color: Colors.orange),
                    MetricCardWidget(title: 'RECOMMAND.', value: recommendationsCount, icon: Icons.psychology, color: const Color(0xFF1B75BC)),
                    MetricCardWidget(title: 'OPPORTUNITÉS', value: opportunitiesCount, icon: Icons.lightbulb_outline, color: Colors.green),
                  ]),
                  const SizedBox(height: 24), */

                  TextField(
                    controller: _queryController,
                    onSubmitted: (_) => _envoyerRechercheVersFemi(),
                    decoration: InputDecoration(
                      hintText: "Posez une question sur vos chiffres...",
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF1B75BC)),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send, color: Color(0xFF1B75BC)),
                        onPressed: _envoyerRechercheVersFemi,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Questions suggérées :',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),

                  _buildSuggestedQuestion(icon: Icons.analytics_outlined, title: "Analyse de la rentabilité par produit/service"),
                  _buildSuggestedQuestion(icon: Icons.account_balance_wallet_outlined, title: "Où va l'argent ? (Analyse des charges)"),
                  _buildSuggestedQuestion(icon: Icons.people_outline, title: "Qui relancer ce mois-ci ? (Créances)"),
                  _buildSuggestedQuestion(icon: Icons.trending_up_outlined, title: "Prévisions financières pour les 3 prochains mois"),

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

  String _formatTrend(dynamic value) {
    if (value == null) return '';
    final double numValue = (value is num) ? value.toDouble() : double.tryParse(value.toString()) ?? 0.0;
    final String sign = numValue >= 0 ? '+' : '';
    return '$sign${numValue.toStringAsFixed(1)}% vs période préc.';
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

  Widget _buildSuggestedQuestion({required IconData icon, required String title}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: const Color(0xFF1B75BC), size: 20),
        title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () {
          // Bascule directement vers l'onglet Femi avec la question comme
          // prompt initial, pour qu'elle soit envoyée et que Femi réponde
          // — au lieu de juste remplir la barre de recherche du Dashboard.
          widget.onNavigateToFemi?.call(title);
        },
      ),
    );
  }
}