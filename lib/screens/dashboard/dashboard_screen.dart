import 'package:flutter/material.dart';
import 'widgets/ai_recommendation_card_widget.dart';
import 'widgets/ai_summary_card_widget.dart';
import 'widgets/metric_card_widget.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
            icon: const Icon(
              Icons.notifications_none_outlined,
              color: Colors.black87,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Encadré Résumé IA
            const AiSummaryCardWidget(
              message:
                  'Le chiffre d\'affaires est en hausse de 12% ce mois-ci, mais les dépenses ont augmenté de 8%. Attention au flux de trésorerie dans les 2 prochaines semaines en raison de 3 grosses factures en attente.',
            ),
            const SizedBox(height: 20),

            // 2. Score Global
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Santé de l\'entreprise',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                RichText(
                  text: const TextSpan(
                    text: 'Score global: ',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                    children: [
                      TextSpan(
                        text: '78/100',
                        style: TextStyle(
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

            // NIVEAU 1 — Santé de l'entreprise
            _buildLevelHeader('Niveau 1 — Santé (6 KPI)'),
            const SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  MetricCardWidget(
                    label: 'CHIFFRE D\'AFFAIRES',
                    value: '15M',
                    subtitle: '+12% vs mois pr',
                    subColor: Colors.green,
                  ),
                  MetricCardWidget(
                    label: 'BÉNÉFICE NET',
                    value: '3.2M',
                    subtitle: '+5% vs mois pre',
                    subColor: Colors.green,
                  ),
                  MetricCardWidget(
                    label: 'DÉPENSES',
                    value: '11.8M',
                    subtitle: '+8% vs mois',
                    subColor: Colors.red,
                  ),
                  MetricCardWidget(
                    label: 'TRÉSORERIE',
                    value: '4.5M',
                    subtitle: 'Disponible',
                    subColor: Colors.grey,
                  ),
                  MetricCardWidget(
                    label: 'CLIENTS',
                    value: '142',
                    subtitle: '+4 ce mois',
                    subColor: Colors.green,
                  ),
                  MetricCardWidget(
                    label: 'CRÉANCES',
                    value: '2.1M',
                    subtitle: '3 retards',
                    subColor: Colors.red,
                    warning: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // NIVEAU 2 — Activité
            _buildLevelHeader('Niveau 2 — Activité'),
            const SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  MetricCardWidget(
                    label: 'VENTES',
                    value: '124',
                    subtitle: '+18% ce mois',
                    subColor: Colors.green,
                  ),
                  MetricCardWidget(
                    label: 'COMMANDES',
                    value: '45',
                    subtitle: '8 en cours',
                    subColor: Color(0xFF1B75BC),
                  ),
                  MetricCardWidget(
                    label: 'PANIER MOYEN',
                    value: '121K',
                    subtitle: '+2.4%',
                    subColor: Colors.green,
                  ),
                  MetricCardWidget(
                    label: 'PRODUITS',
                    value: '380',
                    subtitle: 'En catalogue',
                    subColor: Colors.grey,
                  ),
                  MetricCardWidget(
                    label: 'CLIENTS ACTIFS',
                    value: '89',
                    subtitle: 'Récurrents 65%',
                    subColor: Colors.green,
                  ),
                  MetricCardWidget(
                    label: 'PRESTATIONS',
                    value: '18',
                    subtitle: 'Achevées: 15',
                    subColor: Color(0xFF1B75BC),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // NIVEAU 3 — Finance
            _buildLevelHeader('Niveau 3 — Finance'),
            const SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  MetricCardWidget(
                    label: 'REVENUS',
                    value: '15.0M',
                    subtitle: 'Mois en cours',
                    subColor: Colors.green,
                  ),
                  MetricCardWidget(
                    label: 'DÉPENSES',
                    value: '11.8M',
                    subtitle: 'Opérationnel',
                    subColor: Colors.red,
                  ),
                  MetricCardWidget(
                    label: 'MARGE BRUTE',
                    value: '21.3%',
                    subtitle: 'Cible: 25%',
                    subColor: Colors.orange,
                  ),
                  MetricCardWidget(
                    label: 'BÉNÉFICE',
                    value: '3.2M',
                    subtitle: 'Avant impôt',
                    subColor: Colors.green,
                  ),
                  MetricCardWidget(
                    label: 'TRÉSORERIE',
                    value: '4.5M',
                    subtitle: 'En banque',
                    subColor: Color(0xFF1B75BC),
                  ),
                  MetricCardWidget(
                    label: 'DETTES',
                    value: '1.8M',
                    subtitle: 'Échéance < 30j',
                    subColor: Colors.red,
                    warning: true,
                  ),
                  MetricCardWidget(
                    label: 'CRÉANCES',
                    value: '2.1M',
                    subtitle: 'A recouvrir',
                    subColor: Colors.orange,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // NIVEAU 4 — Opérations
            _buildLevelHeader('Niveau 4 — Opérations'),
            const SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  MetricCardWidget(
                    label: 'STOCKS',
                    value: '85%',
                    subtitle: '2 alerte stock',
                    subColor: Colors.orange,
                    warning: true,
                  ),
                  MetricCardWidget(
                    label: 'FOURNISSEURS',
                    value: '12',
                    subtitle: 'Actifs',
                    subColor: Colors.grey,
                  ),
                  MetricCardWidget(
                    label: 'PRODUCTION',
                    value: '92%',
                    subtitle: 'Rendement',
                    subColor: Colors.green,
                  ),
                  MetricCardWidget(
                    label: 'ACHATS',
                    value: '3.4M',
                    subtitle: 'Ce mois',
                    subColor: Colors.red,
                  ),
                  MetricCardWidget(
                    label: 'LIVRAISONS',
                    value: '24',
                    subtitle: '1 en retard',
                    subColor: Colors.orange,
                  ),
                  MetricCardWidget(
                    label: 'PERSONNEL',
                    value: '8/8',
                    subtitle: 'Présents',
                    subColor: Colors.green,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // NIVEAU 5 — Intelligence IA
            _buildLevelHeader('Niveau 5 — Intelligence IA'),
            const SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  MetricCardWidget(
                    label: 'ANOMALIES',
                    value: '1',
                    subtitle: 'Frais transport',
                    subColor: Colors.red,
                    warning: true,
                  ),
                  MetricCardWidget(
                    label: 'TENDANCES',
                    value: '+15%',
                    subtitle: 'Service Pro',
                    subColor: Colors.green,
                  ),
                  MetricCardWidget(
                    label: 'PRÉVISIONS',
                    value: '+5%',
                    subtitle: 'Croissance T4',
                    subColor: Color(0xFF1B75BC),
                  ),
                  MetricCardWidget(
                    label: 'ALERTES',
                    value: '2',
                    subtitle: 'Trésorerie/Stock',
                    subColor: Colors.orange,
                  ),
                  MetricCardWidget(
                    label: 'RECOMMAND.',
                    value: '3',
                    subtitle: 'Actions dispo',
                    subColor: Color(0xFF1B75BC),
                  ),
                  MetricCardWidget(
                    label: 'OPPORTUNITÉS',
                    value: '12',
                    subtitle: 'Clients fidèles',
                    subColor: Colors.green,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Champ de saisie pour poser une question à l'IA
            TextField(
              decoration: InputDecoration(
                hintText: "Posez une question sur vos chiffres...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1B75BC)),
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

            const SizedBox(height: 20),

            // 4. Recommandation IA
            const AiRecommendationCardWidget(
              description:
                  'Pour améliorer votre trésorerie immédiate, nous vous suggérons de relancer la facture #INV-2023-042 (Client: TechCorp) d\'un montant de 1.2M FCFA, en retard de 15 jours.',
            ),
          ],
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