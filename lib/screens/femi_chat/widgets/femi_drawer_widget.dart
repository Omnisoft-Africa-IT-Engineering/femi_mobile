import 'package:flutter/material.dart';
import '../../../services/femi_api_service.dart';
import '../../auth/auth_gate.dart';
import '../../registre_journalier/registre_journalier_screen.dart';
import '../../etat_financier/etat_financier_screen.dart';
import '../../balance_generale/balance_generale_screen.dart';
import '../../balance_auxiliaire/balance_auxiliaire_screen.dart';
import '../../grand_livre/grand_livre_screen.dart';
import '../../echeances_fiscales/echeances_fiscales_screen.dart';

/// Menu latéral (Drawer) partagé, ouvrable depuis n'importe quel onglet
/// de MainNavigationScreen (Tableau de bord = 0, Chat Femi = 1,
/// Compte = 2). [currentTabIndex] permet d'adapter le comportement des
/// items "Tableau de bord" / "Chat Femi" / "Compte" : sur l'onglet déjà
/// actif, l'item se contente de fermer le Drawer plutôt que de
/// re-naviguer inutilement.
class FemiDrawerWidget extends StatelessWidget {
  static const int tabDashboard = 0;
  static const int tabChat = 1;
  static const int tabCompte = 2;

  final int currentTabIndex;
  final void Function(int tabIndex)? onNavigateToTab;

  const FemiDrawerWidget({
    super.key,
    required this.currentTabIndex,
    this.onNavigateToTab,
  });

  void _fermerPuisNaviguerVersOnglet(BuildContext context, int index) {
    debugPrint('🔵 Drawer: tap détecté sur onglet $index (actuel: $currentTabIndex)');
    final navigator = Navigator.of(context);
    navigator.pop(); // ferme le Drawer
    if (index == currentTabIndex) return; // déjà sur cet onglet
    if (onNavigateToTab == null) {
      debugPrint('⚠️ Drawer: onNavigateToTab est null — callback non câblé depuis le parent.');
      return;
    }
    onNavigateToTab!(index);
  }

  void _fermerPuisPousser(BuildContext context, Widget ecran) {
    debugPrint('🔵 Drawer: tap détecté, ouverture de ${ecran.runtimeType}');
    final navigator = Navigator.of(context);
    navigator.pop(); // ferme le Drawer
    navigator.push(MaterialPageRoute(builder: (_) => ecran));
  }

  Future<void> _deconnexion(BuildContext context) async {
    // On affiche la confirmation AVANT de fermer le Drawer, pour garder
    // un context valide (le Drawer reste ouvert derrière le dialogue,
    // ça n'a aucun impact visuel gênant). C'était le bug : fermer le
    // Drawer puis réutiliser le même context pour showDialog rendait
    // le dialogue instable / invisible.
    final bool? confirme = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    // Le Drawer ne se ferme qu'une fois la déconnexion confirmée.
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    await FemiApiService().logout();

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Text(
                'Femi',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0D5C52)),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _item(
                    context,
                    icon: Icons.grid_view_rounded,
                    label: 'Tableau de bord',
                    selected: currentTabIndex == tabDashboard,
                    onTap: () => _fermerPuisNaviguerVersOnglet(context, tabDashboard),
                  ),
                  _item(
                    context,
                    icon: Icons.event_note_outlined,
                    label: 'Échéances fiscales',
                    onTap: () => _fermerPuisPousser(context, const EcheancesFiscalesScreen()),
                  ),
                  _item(
                    context,
                    icon: Icons.auto_awesome,
                    label: 'Chat Femi',
                    selected: currentTabIndex == tabChat,
                    onTap: () => _fermerPuisNaviguerVersOnglet(context, tabChat),
                  ),
                  _item(
                    context,
                    icon: Icons.account_balance_outlined,
                    label: 'Compte',
                    selected: currentTabIndex == tabCompte,
                    onTap: () => _fermerPuisNaviguerVersOnglet(context, tabCompte),
                  ),
                  const Divider(height: 24),
                  _item(
                    context,
                    icon: Icons.calendar_today_outlined,
                    label: 'Registre journalier',
                    onTap: () => _fermerPuisPousser(context, const RegistreJournalierScreen()),
                  ),
                  _item(
                    context,
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'État financier',
                    onTap: () => _fermerPuisPousser(context, const EtatFinancierScreen()),
                  ),
                  _item(
                    context,
                    icon: Icons.balance_outlined,
                    label: 'Balance générale',
                    onTap: () => _fermerPuisPousser(context, const BalanceGeneraleScreen()),
                  ),
                  _item(
                    context,
                    icon: Icons.groups_outlined,
                    label: 'Balance auxiliaire',
                    onTap: () => _fermerPuisPousser(context, const BalanceAuxiliaireScreen()),
                  ),
                  _item(
                    context,
                    icon: Icons.menu_book_outlined,
                    label: 'Grand livre',
                    onTap: () => _fermerPuisPousser(context, const GrandLivreScreen()),
                  ),
                  const Divider(height: 24),
                  _item(
                    context,
                    icon: Icons.workspace_premium_outlined,
                    label: 'Abonnement',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/subscription');
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _item(
              context,
              icon: Icons.logout,
              label: 'Déconnexion',
              iconColor: Colors.red,
              textColor: Colors.red,
              onTap: () => _deconnexion(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      selected: selected,
      selectedTileColor: const Color(0xFFEAF6F3),
      leading: Icon(icon, color: iconColor ?? const Color(0xFF0D5C52)),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          color: textColor ?? const Color(0xFF0F172A),
        ),
      ),
      onTap: onTap,
    );
  }
}