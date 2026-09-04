import 'package:flutter/material.dart';

// Import des écrans
import '../etat_financier/etat_financier_screen.dart';
import '../grand_livre/grand_livre_screen.dart';
import '../registre_journalier/registre_journalier_screen.dart';
import '../subscription_pay/subscription_pay_screen.dart';
import '../balance_generale/balance_generale_screen.dart';
import '../balance_auxiliaire/balance_auxiliaire_screen.dart';
import '../etat_financier/etat_financier_complet_screen.dart';

// Import des widgets propres
import 'widgets/plan_card.dart';
import 'widgets/doc_title.dart';

class CompteScreen extends StatefulWidget {
  const CompteScreen({super.key});

  @override
  State<CompteScreen> createState() => _CompteScreenState();
}

class _CompteScreenState extends State<CompteScreen> {
  // 1. ÉTAT DE LA PAGE
  bool isPro = false;

  // 2. LOGIQUE DE NAVIGATION ET DE PAIEMENT
  Future<void> _naviguerVersAbonnement() async {
    final paymentSuccess = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const SubscriptionPayScreen()),
    );

    if (paymentSuccess == true) {
      setState(() => isPro = true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Félicitations ! Abonnement Pro activé 🎉')),
      );
    }
  }

  void _ouvrirPageControle(Widget pageDestination, bool besoinPro) {
    if (!besoinPro || isPro) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => pageDestination));
    } else {
      _afficherDialogueUpgrade();
    }
  }

  void _afficherDialogueUpgrade() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fonctionnalité PRO'),
        content: const Text('Cet outil est réservé aux abonnés PRO de Femi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _naviguerVersAbonnement();
            },
            child: const Text('Passer au PRO'),
          ),
        ],
      ),
    );
  }

  // 3. CONSTRUCTION DE L'INTERFACE
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Compte'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Section 1: Carte de la formule actuelle
          PlanCard(
            isPro: isPro,
            onUpgradePressed: _naviguerVersAbonnement,
          ),

          const SizedBox(height: 24),
          const Text('Documents Comptables', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // Section 2: Liste de TOUS les documents comptables
          DocTile(
            icon: Icons.book_outlined,
            title: 'Registre journalier',
            isUserPro: isPro,
            onTap: () => _ouvrirPageControle(const RegistreJournalierScreen(), false),
          ),
          DocTile(
            icon: Icons.description_outlined,
            title: 'État financier',
            isProFeature: true,
            isUserPro: isPro,
            onTap: () => _ouvrirPageControle(const EtatFinancierCompletScreen(), true),
          ),
          DocTile(
            icon: Icons.menu_book_outlined,
            title: 'Grand livre',
            isProFeature: true,
            isUserPro: isPro,
            onTap: () => _ouvrirPageControle(GrandLivreScreen(), true), // SANS const
          ),
          DocTile(
            icon: Icons.account_balance_outlined,
            title: 'Bilan',
            isProFeature: true,
            isUserPro: isPro,
            onTap: () => _ouvrirPageControle(EtatFinancierScreen(), true), // SANS const
          ),
          DocTile(
            icon: Icons.balance_outlined,
            title: 'Balance générale',
            isProFeature: true,
            isUserPro: isPro,
            onTap: () => _ouvrirPageControle(const BalanceGeneraleScreen(), true),
          ),
          DocTile(
            icon: Icons.swap_horiz_outlined,
            title: 'Balance auxiliaire',
            isProFeature: true,
            isUserPro: isPro,
            onTap: () => _ouvrirPageControle(const BalanceAuxiliaireScreen(), true),
          ),

          const SizedBox(height: 20),

          // Section 3: Assistance / Diagnostic Consultant Femi
          Card(
            color: const Color(0xFFEAF2FF),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF1B75BC),
                child: Icon(Icons.support_agent, color: Colors.white),
              ),
              title: const Text(
                'Besoin d\'un diagnostic ?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: const Text(
                'Échangez 30 min avec un consultant Femi pour faire le point sur votre gestion.',
                style: TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right, color: Color(0xFF1B75BC)),
              onTap: () {},
            ),
          ),

          const Divider(height: 32),

          // Section 4: Actions de compte
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Se déconnecter'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Supprimer mon compte', style: TextStyle(color: Colors.red)),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}