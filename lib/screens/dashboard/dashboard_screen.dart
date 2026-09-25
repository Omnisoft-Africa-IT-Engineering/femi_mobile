import 'package:flutter/material.dart';
import '../../services/kpi_service.dart';
// import 'widgets/ai_recommendation_card_widget.dart';
// import 'widgets/ai_summary_card_widget.dart';
import 'widgets/metric_card_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _kpi;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await KpiService.fetch();
      if (!mounted) return;
      setState(() => _kpi = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(num v, String type) {
    if (type == 'pct') return '${v.toStringAsFixed(1)}%';
    if (type == 'nombre') return v.round().toString();
    final a = v.abs();
    if (a >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (a >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.round().toString();
  }

  // items = [clé_json, LIBELLÉ, type, (optionnel) 'warning']
  Widget _kpiRow(String niveau, List<List<String>> items) {
    final data = (_kpi?[niveau] as Map<String, dynamic>?) ?? {};
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((it) {
          final k = data[it[0]] as Map<String, dynamic>?;
          final num? valeur = k?['valeur'] as num?;
          final num? variation = k?['variation'] as num?;
          final sub = variation == null
              ? '—'
              : '${variation >= 0 ? '+' : ''}$variation% vs préc.';
          return MetricCardWidget(
            label: it[1],
            value: valeur == null ? '—' : _fmt(valeur, it[2]),
            subtitle: sub,
            subColor: variation == null
                ? Colors.grey
                : (variation >= 0 ? Colors.green : Colors.red),
            warning: it.length > 3,
          );
        }).toList(),
      ),
    );
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
            onPressed: _load,
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
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_loading) const LinearProgressIndicator(),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Impossible de charger les KPI : $_error',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),

              // 1. Encadré Résumé IA (masqué)
              // const AiSummaryCardWidget(
              //   message:
              //       'Le chiffre d\'affaires est en hausse de 12% ce mois-ci, mais les dépenses ont augmenté de 8%. Attention au flux de trésorerie dans les 2 prochaines semaines en raison de 3 grosses factures en attente.',
              // ),
              // const SizedBox(height: 20),

              // 2. Titre (score global masqué)
              const Text(
                'Santé de l\'entreprise',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     const Text(
              //       'Santé de l\'entreprise',
              //       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              //     ),
              //     RichText(
              //       text: const TextSpan(
              //         text: 'Score global: ',
              //         style: TextStyle(color: Colors.black54, fontSize: 14),
              //         children: [
              //           TextSpan(
              //             text: '78/100',
              //             style: TextStyle(
              //               color: Color(0xFF0E7A63),
              //               fontWeight: FontWeight.bold,
              //             ),
              //           ),
              //         ],
              //       ),
              //     ),
              //   ],
              // ),
              const SizedBox(height: 16),

              // NIVEAU 1 — Santé
              _buildLevelHeader('Niveau 1 — Santé (6 KPI)'),
              _kpiRow('niveau_1', [
                ['chiffre_affaires', 'CHIFFRE D\'AFFAIRES', 'montant'],
                ['benefice', 'BÉNÉFICE NET', 'montant'],
                ['depenses', 'DÉPENSES', 'montant'],
                ['tresorerie', 'TRÉSORERIE', 'montant'],
                ['clients', 'CLIENTS', 'nombre'],
                ['creances', 'CRÉANCES', 'montant', 'warning'],
              ]),
              const SizedBox(height: 16),

              // NIVEAU 2 — Activité
              _buildLevelHeader('Niveau 2 — Activité'),
              _kpiRow('niveau_2', [
                ['ventes', 'VENTES', 'nombre'],
                ['commandes', 'COMMANDES', 'nombre'],
                ['panier_moyen', 'PANIER MOYEN', 'montant'],
                ['clients', 'CLIENTS ACTIFS', 'nombre'],
                ['prestations', 'PRESTATIONS', 'nombre'],
              ]),
              const SizedBox(height: 16),

              // NIVEAU 3 — Finance
              _buildLevelHeader('Niveau 3 — Finance'),
              _kpiRow('niveau_3', [
                ['revenus', 'REVENUS', 'montant'],
                ['depenses', 'DÉPENSES', 'montant'],
                ['marge', 'MARGE', 'pct'],
                ['benefice', 'BÉNÉFICE', 'montant'],
                ['tresorerie', 'TRÉSORERIE', 'montant'],
                ['dettes', 'DETTES', 'montant', 'warning'],
                ['creances', 'CRÉANCES', 'montant'],
              ]),
              const SizedBox(height: 24),

              // Champ de saisie pour poser une question à l'IA
              TextField(
                decoration: InputDecoration(
                  hintText: "Posez une question sur vos chiffres...",
                  prefixIcon:
                  const Icon(Icons.search, color: Color(0xFF1B75BC)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF1B75BC)),
                    onPressed: () {},
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

              // Section Questions suggérées
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

              // 4. Recommandation IA (masquée)
              // const SizedBox(height: 20),
              // const AiRecommendationCardWidget(
              //   description:
              //       'Pour améliorer votre trésorerie immédiate, nous vous suggérons de relancer la facture #INV-2023-042 (Client: TechCorp) d\'un montant de 1.2M FCFA, en retard de 15 jours.',
              // ),
            ],
          ),
        ),
      ),
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
        onTap: () {},
      ),
    );
  }
}