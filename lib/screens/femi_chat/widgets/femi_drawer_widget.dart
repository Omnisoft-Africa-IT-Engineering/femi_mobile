import 'package:flutter/material.dart';
import '../../../services/femi_api_service.dart';
import '../../../states/auth_state.dart';
import '../../auth/auth_gate.dart';
import '../../registre_journalier/registre_journalier_screen.dart';
import '../../etat_financier/etat_financier_screen.dart';
import '../../balance_generale/balance_generale_screen.dart';
import '../../balance_auxiliaire/balance_auxiliaire_screen.dart';
import '../../grand_livre/grand_livre_screen.dart';
import '../../echeances_fiscales/echeances_fiscales_screen.dart';
import '../../settings/settings_screen.dart';

/// Menu latéral (Drawer) partagé, ouvrable depuis n'importe quel onglet
/// de MainNavigationScreen (Tableau de bord = 0, Chat Femi = 1,
/// Compte = 2). [currentTabIndex] permet d'adapter le comportement des
/// items "Tableau de bord" / "Chat Femi" / "Compte" : sur l'onglet déjà
/// actif, l'item se contente de fermer le Drawer plutôt que de
/// re-naviguer inutilement.
///
/// Le contenu dépend du rôle de l'utilisateur :
/// - gérant   : menu complet + Paramètres ;
/// - serveuse : seulement Chat Femi, Registre journalier et Déconnexion.
///
/// Les écrans PRO (État financier, Balance générale, Balance auxiliaire,
/// Grand livre) suivent la même règle que l'écran Compte : verrouillés
/// avec un badge PRO tant que la formule n'est pas PRO.
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

  /// Ouvre un écran réservé au PRO, ou propose de passer au PRO.
  Future<void> _ouvrirEcranPro(BuildContext context, Widget ecran) async {
    if (AuthState.instance.isPro.value) {
      _fermerPuisPousser(context, ecran);
      return;
    }

    // Dialogue affiché AVANT de fermer le Drawer (context encore valide).
    final bool? veutPasserPro = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Fonctionnalité PRO'),
        content: const Text('Cet outil est réservé aux abonnés PRO de Femi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Passer au PRO'),
          ),
        ],
      ),
    );

    if (veutPasserPro == true && context.mounted) {
      final navigator = Navigator.of(context);
      navigator.pop(); // ferme le Drawer
      navigator.pushNamed('/subscription');
    }
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
    // Le Drawer est reconstruit à chaque ouverture : on lit le rôle ici.
    final bool estGerant = AuthState.instance.isGerant;

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
              // Se met à jour tout seul si l'utilisateur passe au PRO.
              child: ValueListenableBuilder<bool>(
                valueListenable: AuthState.instance.isPro,
                builder: (context, isPro, _) {
                  return ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      // --- Gérant seulement ---
                      if (estGerant)
                        _item(
                          context,
                          icon: Icons.grid_view_rounded,
                          label: 'Tableau de bord',
                          selected: currentTabIndex == tabDashboard,
                          onTap: () => _fermerPuisNaviguerVersOnglet(context, tabDashboard),
                        ),
                      if (estGerant)
                        _item(
                          context,
                          icon: Icons.event_note_outlined,
                          label: 'Échéances fiscales',
                          onTap: () => _fermerPuisPousser(context, const EcheancesFiscalesScreen()),
                        ),

                      // --- Gérant et serveuse ---
                      _item(
                        context,
                        icon: Icons.auto_awesome,
                        label: 'Chat Femi',
                        selected: currentTabIndex == tabChat,
                        onTap: () => _fermerPuisNaviguerVersOnglet(context, tabChat),
                      ),

                      // --- Gérant seulement ---
                      if (estGerant)
                        _item(
                          context,
                          icon: Icons.account_balance_outlined,
                          label: 'Compte',
                          selected: currentTabIndex == tabCompte,
                          onTap: () => _fermerPuisNaviguerVersOnglet(context, tabCompte),
                        ),

                      const Divider(height: 24),

                      // --- Gérant et serveuse ---
                      _item(
                        context,
                        icon: Icons.calendar_today_outlined,
                        label: 'Registre journalier',
                        onTap: () => _fermerPuisPousser(context, const RegistreJournalierScreen()),
                      ),

                      // --- Gérant seulement ---
                      if (estGerant) ...[
                        // Écrans réservés au PRO
                        _item(
                          context,
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'État financier',
                          verrouille: !isPro,
                          onTap: () => _ouvrirEcranPro(context, const EtatFinancierScreen()),
                        ),
                        _item(
                          context,
                          icon: Icons.balance_outlined,
                          label: 'Balance générale',
                          verrouille: !isPro,
                          onTap: () => _ouvrirEcranPro(context, const BalanceGeneraleScreen()),
                        ),
                        _item(
                          context,
                          icon: Icons.groups_outlined,
                          label: 'Balance auxiliaire',
                          verrouille: !isPro,
                          onTap: () => _ouvrirEcranPro(context, const BalanceAuxiliaireScreen()),
                        ),
                        _item(
                          context,
                          icon: Icons.menu_book_outlined,
                          label: 'Grand livre',
                          verrouille: !isPro,
                          onTap: () => _ouvrirEcranPro(context, const GrandLivreScreen()),
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
                        _item(
                          context,
                          icon: Icons.settings_outlined,
                          label: 'Paramètres',
                          onTap: () => _fermerPuisPousser(context, const SettingsScreen()),
                        ),
                      ],
                    ],
                  );
                },
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
        bool verrouille = false,
        Color? iconColor,
        Color? textColor,
      }) {
    return ListTile(
      selected: selected,
      selectedTileColor: const Color(0xFFEAF6F3),
      leading: Icon(icon, color: iconColor ?? const Color(0xFF0D5C52)),
      title: Row(
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: textColor ?? const Color(0xFF0F172A),
              ),
            ),
          ),
          if (verrouille) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0C2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE6C36A)),
              ),
              child: const Text(
                'PRO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE59A00),
                ),
              ),
            ),
          ],
        ],
      ),
      trailing: verrouille
          ? const Icon(Icons.lock_outline, size: 18, color: Color(0xFF475569))
          : null,
      onTap: onTap,
    );
  }
}