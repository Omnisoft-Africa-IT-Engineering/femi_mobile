import 'package:flutter/material.dart';

class KpiScreen extends StatelessWidget {
  const KpiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IA Summary Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EFFD),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E75BB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Résumé IA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        SizedBox(height: 4),
                        Text(
                          'Le chiffre d\'affaires est en hausse de 12% ce mois-ci, mais les dépenses ont augmenté de 8%. Attention au flux de trésorerie dans les 2 prochaines semaines en raison de 3 grosses factures en attente.',
                          style: TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Health Score Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Santé de l\'entreprise', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                RichText(
                  text: const TextSpan(
                    text: 'Score global: ',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                    children: [
                      TextSpan(
                        text: '78/100',
                        style: TextStyle(color: Color(0xFF0E7A63), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Horizontally Scrollable Cards
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildMetricCard('CHIFFRE D\'AFFAIRES', '15M', '+12% vs mois pr', Colors.green),
                  _buildMetricCard('BÉNÉFICE NET', '3.2M', '+5% vs mois pre', Colors.green),
                  _buildMetricCard('DÉPENSES', '11.8M', '+8% vs mois', Colors.red),
                ],
              ),
            ),
            const SizedBox(height: 12),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildMetricCard('TRÉSORERIE', '4.5M', 'Disponible', Colors.grey),
                  _buildMetricCard('CRÉANCES CLIENTS', '2.1M', '3 factures en retard', Colors.red, warning: true),
                  _buildMetricCard('NOUVEAUX CLIENTS', '4', 'ce mois', Colors.green),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Quick Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(Icons.show_chart, 'Analyses'),
                  _buildFilterChip(Icons.search, 'Où va l\'argent ?'),
                  _buildFilterChip(Icons.campaign_outlined, 'Relancer', isSelected: true),
                  _buildFilterChip(Icons.trending_up, 'Prévisions'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // AI Recommendation Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 20),
                      SizedBox(width: 8),
                      Text('Recommandation IA', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Pour améliorer votre trésorerie immédiate, nous vous suggérons de relancer la facture #INV-2023-042 (Client: TechCorp) d\'un montant de 1.2M FCFA, en retard de 15 jours.',
                    style: TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B75BC),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Agir maintenant'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Voir le détail'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, String subtitle, Color subColor, {bool warning = false}) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warning ? const Color(0xFFFFF5F5) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warning ? Colors.red.shade200 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ),
              if (warning) const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 10, color: subColor, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(IconData icon, String label, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFF0F0) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? Colors.red.shade200 : Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.red : Colors.black87),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isSelected ? Colors.red : Colors.black87)),
        ],
      ),
    );
  }
}