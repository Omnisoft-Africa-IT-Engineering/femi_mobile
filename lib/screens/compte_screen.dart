import 'package:flutter/material.dart';
import 'etat_financier_screen.dart';
import 'grand_livre_screen.dart';
import 'registre_journalier_screen.dart';
// import 'subscription_pay_screen.dart';

class CompteScreen extends StatefulWidget {
  const CompteScreen({super.key});

  @override
  State<CompteScreen> createState() => _CompteScreenState();
}

class _CompteScreenState extends State<CompteScreen> {
  // Statut de l'abonnement (désactivé temporairement)
  // bool isPro = false;

  /// Ouvre l'écran de paiement et met à jour le statut en cas de succès
  /*
  Future<void> _openSubscriptionPayScreen({String? targetFeature}) async {
    final bool? paymentSuccess = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => SubscriptionPayScreen(targetFeature: targetFeature),
      ),
    );

    // Si le paiement a réussi, on passe l'utilisateur en PRO
    if (paymentSuccess == true) {
      setState(() {
        isPro = true;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Félicitations ! Votre abonnement Pro est activé 🎉'),
          backgroundColor: Color(0xFF059669),
        ),
      );
    }
  }
  */

  /// Fonction générique pour gérer l'accès aux fonctionnalités PRO (désactivée temporairement)
  /*
  void _handleProFeature(BuildContext context, String featureName, Widget destinationScreen) {
    if (isPro) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => destinationScreen),
      );
    } else {
      _showUpgradeDialog(context, featureName);
    }
  }
  */

  /// Boîte de dialogue affichée si l'utilisateur tente d'accéder à une fonctionnalité PRO (désactivée temporairement)
  /*
  void _showUpgradeDialog(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star, color: Color(0xFFD97706)),
            ),
            const SizedBox(width: 10),
            const Text('Fonctionnalité PRO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'L\'accès à "$featureName" est réservé aux abonnés de la formule PRO.',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            const Text(
              'Débloquez l\'ensemble des états financiers, le Grand Livre et les balances exportables dès maintenant.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Plus tard', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B75BC),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context); // Fermer le modal
              _openSubscriptionPayScreen(targetFeature: featureName); // Ouvrir l'écran d'abonnement
            },
            child: const Text('Passer au PRO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Color(0xFFE1EBFD),
            child: Icon(Icons.person_outline, color: Color(0xFF1B75BC)),
          ),
        ),
        title: const Text('Comptes', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
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
            // 1. Carte de Formule / Abonnement Actuel
            _buildPlanCard(context),
            const SizedBox(height: 20),

            // 2. Section Documents Comptables
            const Text('Documents Comptables', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87)),
            const SizedBox(height: 12),

            // REGISTRE JOURNALIER (Disponible pour TOUS)
            _buildDocCard(
              context,
              Icons.book_outlined,
              'Registre journalier',
              subtitle: 'Saisie quotidienne des flux',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegistreJournalierScreen()),
                );
              },
            ),

            // ÉTAT FINANCIER
            _buildDocCard(
              context,
              Icons.description_outlined,
              'État financier',
              // isProFeature: true, // COMMENTÉ
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BilanSyscohadaScreen()),
                );
              },
            ),

            // GRAND LIVRE
            _buildDocCard(
              context,
              Icons.menu_book_outlined,
              'Grand livre',
              // isProFeature: true, // COMMENTÉ
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GrandLivreScreen()),
                );
              },
            ),

            // BILAN
            _buildDocCard(
              context,
              Icons.account_balance_outlined,
              'Bilan',
              // isProFeature: true, // COMMENTÉ
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BilanSyscohadaScreen()),
                );
              },
            ),

            // BALANCE GÉNÉRALE
            _buildDocCard(
              context,
              Icons.balance_outlined,
              'Balance générale',
              // isProFeature: true, // COMMENTÉ
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Placeholder()),
                );
              },
            ),

            // BALANCE AUXILIAIRE
            _buildDocCard(
              context,
              Icons.swap_horiz_outlined,
              'Balance auxiliaire',
              // isProFeature: true, // COMMENTÉ
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Placeholder()),
                );
              },
            ),

            const SizedBox(height: 20),

            // 3. Banner Assistance Consultant Femi
            _buildConsultantCard(context),

            const SizedBox(height: 24),
            const Text('Paramètres du Profil', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.black87),
                title: const Text('Se déconnecter', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.exit_to_app, color: Colors.black54),
                onTap: () {},
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFAF0F1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: ListTile(
                title: const Text('Supprimer mon compte', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                trailing: const Icon(Icons.delete_outline, color: Colors.red),
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Carte Plan / Formule
  Widget _buildPlanCard(BuildContext context) {
    // Statut forcé visuellement en mode standard / neutre pour l'instant
    const bool isPro = false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPro
              ? [const Color(0xFF0D9488), const Color(0xFF059669)]
              : [const Color(0xFF1B75BC), const Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isPro ? 'Formule PRO Active' : 'Formule Micro',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isPro ? 'Compte Pro Débloqué' : 'Passez à la formule Pro',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  isPro
                      ? 'Accès complet au Grand Livre, aux Bilan Syscohada et exports PDF.'
                      : 'Débloquez le Grand Livre, les alertes IA et les exports complets.',
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          /* BOUTON CHANGER COMMENTÉ EN ATTENDANT
          if (!isPro)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1B75BC),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () => _openSubscriptionPayScreen(),
              child: const Text('Changer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          */
        ],
      ),
    );
  }

  // Widget Assistance Consultant
  Widget _buildConsultantCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1B75BC).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFF1B75BC),
            child: Icon(Icons.support_agent, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Besoin d\'un diagnostic ?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                ),
                SizedBox(height: 2),
                Text(
                  'Échangez 30 min avec un consultant Femi pour faire le point sur votre gestion.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF1B75BC)),
        ],
      ),
    );
  }

  // Widget des cartes de documents sans badge PRO ni cadenas
  Widget _buildDocCard(
    BuildContext context,
    IconData icon,
    String title, {
    String? subtitle,
    bool isProFeature = false, // Conservé pour la signature de méthode mais inutilisé
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF1B75BC)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    
                    /* BADGE PRO COMMENTÉ EN ATTENDANT
                    if (isProFeature && !isPro) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lock, size: 10, color: Color(0xFFD97706)),
                            SizedBox(width: 2),
                            Text(
                              'PRO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    */
                  ],
                ),
              ),

              /* ICONE DE CADENAS / FLÈCHE SIMPLIFIÉE */
              const Icon(
                Icons.chevron_right, // On remplace le cadenas par la flèche classique
                color: Colors.grey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}