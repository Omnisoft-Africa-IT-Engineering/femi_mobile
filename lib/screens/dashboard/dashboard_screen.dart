import 'package:flutter/material.dart';
import '../../services/femi_api_service.dart';
import 'widgets/ai_recommendation_card_widget.dart';
import 'widgets/ai_summary_card_widget.dart';
import 'widgets/metric_card_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FemiApiService _apiService = FemiApiService();
  final TextEditingController _queryController = TextEditingController();
  late Future<Map<String, dynamic>?> _kpisFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _loadData() {
    _kpisFuture = _apiService.getDashboardKPIs(period: 'this_month');
  }

  Future<void> _refreshData() async {
    setState(() {
      _loadData();
    });
    await _kpisFuture;
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=5'),
          ),
        ),
        title: const Text(
          'Komi Services',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
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
            final kpis = responseData.containsKey('kpis')
                ? responseData['kpis'] as Map<String, dynamic>
                : responseData;

            // --- NIVEAU 1 : Santé ---
            final String revenue = _formatCompactAmount(kpis['total_revenue'] ?? kpis['chiffre_affaires']);
            final String netIncome = _formatCompactAmount(kpis['net_profit'] ?? kpis['resultat_net']);
            final String expenses = _formatCompactAmount(kpis['total_expenses'] ?? kpis['depenses']);
            final String cashFlow = _formatCompactAmount(kpis['cash_flow'] ?? kpis['tresorerie']);
            final String activeClientsCount = (kpis['active_clients_count'] ?? kpis['clients'] ?? 0).toString();
            final String totalReceivables = _formatCompactAmount(kpis['total_receivables'] ?? kpis['creances']);

            // --- NIVEAU 2 : Activité ---
            final String salesCount = (kpis['sales_count'] ?? kpis['ventes'] ?? 0).toString();
            final String pendingOrdersCount = (kpis['pending_orders_count'] ?? kpis['commandes'] ?? 0).toString();
            final String averageBasket = _formatCompactAmount(kpis['average_basket'] ?? kpis['panier_moyen']);
            final String totalProducts = (kpis['total_products_count'] ?? kpis['produits'] ?? 0).toString();
            final String recurringClientsCount = (kpis['recurring_clients_count'] ?? 0).toString();
            final String servicesCount = (kpis['completed_services_count'] ?? kpis['prestations'] ?? 0).toString();

            // --- NIVEAU 3 : Finance ---
            final String marginRate = _formatPercentage(kpis['profit_margin_percentage'] ?? kpis['taux_marge']);
            final String totalDebts = _formatCompactAmount(kpis['total_debts'] ?? kpis['dettes']);

            // --- NIVEAU 4 : Opérations ---
            final String stockStatus = _formatPercentage(kpis['stock_status'] ?? 85);
            final String suppliersCount = (kpis['suppliers_count'] ?? kpis['fournisseurs'] ?? 0).toString();
            final String productionRate = _formatPercentage(kpis['production_rate'] ?? 92);
            final String totalPurchases = _formatCompactAmount(kpis['total_purchases'] ?? kpis['achats']);
            final String deliveriesCount = (kpis['deliveries_count'] ?? kpis['livraisons'] ?? 0).toString();
            final String staffCount = (kpis['staff_count'] ?? '8/8').toString();

            // --- NIVEAU 5 : IA ---
            final String anomaliesCount = (kpis['anomalies_count'] ?? 1).toString();
            final String trendPercentage = _formatPercentage(kpis['sales_trend_percentage'] ?? 15);
            final String growthForecast = _formatPercentage(kpis['growth_forecast_percentage'] ?? 5);
            final String alertsCount = (kpis['alerts_count'] ?? 2).toString();
            final String recommendationsCount = (kpis['recommendations_count'] ?? 3).toString();
            final String opportunitiesCount = (kpis['opportunities_count'] ?? 12).toString();

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AiSummaryCardWidget(
                    message:
                        'Le chiffre d\'affaires est en hausse ce mois-ci. Données synchronisées avec le serveur Django.',
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Santé de l\'entreprise',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      RichText(
                        text: TextSpan(
                          text: 'Score global: ',
                          style: const TextStyle(color: Colors.black54, fontSize: 14),
                          children: [
                            TextSpan(
                              text: '${kpis['health_score'] ?? 78}/100',
                              style: const TextStyle(
                                color: Color(0xFF0E7A63),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildLevelHeader('Niveau 1 — Santé (6 KPI)'),
                  _buildHorizontalScrollRow([
                    MetricCardWidget(
                      title: 'CHIFFRE D\'AFFAIRES',
                      value: revenue,
                      icon: Icons.payments,
                      color: Colors.green,
                      subtitle: '+12% vs mois pr',
                    ),
                    MetricCardWidget(
                      title: 'BÉNÉFICE NET',
                      value: netIncome,
                      icon: Icons.trending_up,
                      color: Colors.green,
                      subtitle: '+5% vs mois pre',
                    ),
                    MetricCardWidget(
                      title: 'DÉPENSES',
                      value: expenses,
                      icon: Icons.shopping_bag,
                      color: Colors.red,
                      subtitle: '+8% vs mois',
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
                      subtitle: '+4 ce mois',
                    ),
                    MetricCardWidget(
                      title: 'CRÉANCES',
                      value: totalReceivables,
                      icon: Icons.warning_amber_rounded,
                      color: Colors.red,
                      subtitle: '${kpis['overdue_receivables_count'] ?? 3} retards',
                    ),
                  ]),
                  const SizedBox(height: 16),

                  _buildLevelHeader('Niveau 2 — Activité'),
                  _buildHorizontalScrollRow([
                    MetricCardWidget(
                      title: 'VENTES',
                      value: salesCount,
                      icon: Icons.point_of_sale,
                      color: Colors.green,
                      subtitle: '+18% ce mois',
                    ),
                    MetricCardWidget(
                      title: 'COMMANDES',
                      value: pendingOrdersCount,
                      icon: Icons.receipt_long,
                      color: const Color(0xFF1B75BC),
                      subtitle: '8 en cours',
                    ),
                    MetricCardWidget(
                      title: 'PANIER MOYEN',
                      value: averageBasket,
                      icon: Icons.shopping_cart,
                      color: Colors.green,
                      subtitle: '+2.4%',
                    ),
                    MetricCardWidget(
                      title: 'PRODUITS',
                      value: totalProducts,
                      icon: Icons.inventory_2,
                      color: Colors.grey,
                      subtitle: 'En catalogue',
                    ),
                    MetricCardWidget(
                      title: 'CLIENTS ACTIFS',
                      value: recurringClientsCount,
                      icon: Icons.person_pin,
                      color: Colors.green,
                      subtitle: 'Récurrents 65%',
                    ),
                    MetricCardWidget(
                      title: 'PRESTATIONS',
                      value: servicesCount,
                      icon: Icons.build,
                      color: const Color(0xFF1B75BC),
                      subtitle: 'Achevées',
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
                      subtitle: 'Mois en cours',
                    ),
                    MetricCardWidget(
                      title: 'DÉPENSES',
                      value: expenses,
                      icon: Icons.money_off,
                      color: Colors.red,
                      subtitle: 'Opérationnel',
                    ),
                    MetricCardWidget(
                      title: 'MARGE BRUTE',
                      value: marginRate,
                      icon: Icons.pie_chart,
                      color: Colors.orange,
                      subtitle: 'Cible: 25%',
                    ),
                    MetricCardWidget(
                      title: 'BÉNÉFICE',
                      value: netIncome,
                      icon: Icons.show_chart,
                      color: Colors.green,
                      subtitle: 'Avant impôt',
                    ),
                    MetricCardWidget(
                      title: 'TRÉSORERIE',
                      value: cashFlow,
                      icon: Icons.account_balance_wallet,
                      color: const Color(0xFF1B75BC),
                      subtitle: 'En banque',
                    ),
                    MetricCardWidget(
                      title: 'DETTES',
                      value: totalDebts,
                      icon: Icons.credit_card_off,
                      color: Colors.red,
                      subtitle: 'Échéance < 30j',
                    ),
                    MetricCardWidget(
                      title: 'CRÉANCES',
                      value: totalReceivables,
                      icon: Icons.request_quote,
                      color: Colors.orange,
                      subtitle: 'À recouvrir',
                    ),
                  ]),
                  const SizedBox(height: 16),

                  _buildLevelHeader('Niveau 4 — Opérations'),
                  _buildHorizontalScrollRow([
                    MetricCardWidget(
                      title: 'STOCKS',
                      value: stockStatus,
                      icon: Icons.store,
                      color: Colors.orange,
                      subtitle: '2 alerte stock',
                    ),
                    MetricCardWidget(
                      title: 'FOURNISSEURS',
                      value: suppliersCount,
                      icon: Icons.local_shipping,
                      color: Colors.grey,
                      subtitle: 'Actifs',
                    ),
                    MetricCardWidget(
                      title: 'PRODUCTION',
                      value: productionRate,
                      icon: Icons.precision_manufacturing,
                      color: Colors.green,
                      subtitle: 'Rendement',
                    ),
                    MetricCardWidget(
                      title: 'ACHATS',
                      value: totalPurchases,
                      icon: Icons.add_shopping_cart,
                      color: Colors.red,
                      subtitle: 'Ce mois',
                    ),
                    MetricCardWidget(
                      title: 'LIVRAISONS',
                      value: deliveriesCount,
                      icon: Icons.delivery_dining,
                      color: Colors.orange,
                      subtitle: '1 en retard',
                    ),
                    MetricCardWidget(
                      title: 'PERSONNEL',
                      value: staffCount,
                      icon: Icons.badge,
                      color: Colors.green,
                      subtitle: 'Présents',
                    ),
                  ]),
                  const SizedBox(height: 16),

                  _buildLevelHeader('Niveau 5 — Intelligence IA'),
                  _buildHorizontalScrollRow([
                    MetricCardWidget(
                      title: 'ANOMALIES',
                      value: anomaliesCount,
                      icon: Icons.error_outline,
                      color: Colors.red,
                      subtitle: 'Frais transport',
                    ),
                    MetricCardWidget(
                      title: 'TENDANCES',
                      value: trendPercentage,
                      icon: Icons.auto_graph,
                      color: Colors.green,
                      subtitle: 'Service Pro',
                    ),
                    MetricCardWidget(
                      title: 'PRÉVISIONS',
                      value: growthForecast,
                      icon: Icons.insights,
                      color: const Color(0xFF1B75BC),
                      subtitle: 'Croissance T4',
                    ),
                    MetricCardWidget(
                      title: 'ALERTES',
                      value: alertsCount,
                      icon: Icons.add_alert,
                      color: Colors.orange,
                      subtitle: 'Trésorerie/Stock',
                    ),
                    MetricCardWidget(
                      title: 'RECOMMAND.',
                      value: recommendationsCount,
                      icon: Icons.psychology,
                      color: const Color(0xFF1B75BC),
                      subtitle: 'Actions dispo',
                    ),
                    MetricCardWidget(
                      title: 'OPPORTUNITÉS',
                      value: opportunitiesCount,
                      icon: Icons.lightbulb_outline,
                      color: Colors.green,
                      subtitle: 'Clients fidèles',
                    ),
                  ]),
                  const SizedBox(height: 24),

                  TextField(
                    controller: _queryController,
                    decoration: InputDecoration(
                      hintText: "Posez une question sur vos chiffres...",
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF1B75BC)),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send, color: Color(0xFF1B75BC)),
                        onPressed: () {
                          // Traiter la soumission de la question
                        },
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

                  const AiRecommendationCardWidget(
                    description:
                        'Pour améliorer votre trésorerie immédiate, nous vous suggérons de relancer la facture #INV-2023-042 (Client: TechCorp) d\'un montant de 1.2M FCFA, en retard de 15 jours.',
                  ),
                ],
              ),
            );
          },
        ),
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
        leading: Icon(icon, color: const Color(0xFF1B75BC), size: 20),
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
          _queryController.text = title;
        },
      ),
    );
  }
}