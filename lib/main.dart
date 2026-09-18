import 'package:flutter/material.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/femi_chat/femi_chat_screen.dart';
import 'screens/compte/compte_screen.dart';
import 'screens/subscription_pay/subscription_pay_screen.dart';
import 'screens/auth/auth_gate.dart';

void main() {
  runApp(const FemiApp());
}

class FemiApp extends StatelessWidget {
  const FemiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Femi',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const AuthGate(),
      routes: {
        '/subscription': (context) => const SubscriptionPayScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/subscription') {
          final targetFeature = settings.arguments as String?;
          return MaterialPageRoute(
            builder: (context) => SubscriptionPayScreen(
              targetFeature: targetFeature,
            ),
          );
        }
        return null;
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // --- Basculement vers Femi avec un prompt contextuel ---
  // `_femiPromptNonce` change à chaque déclenchement, même si le texte
  // du prompt est identique à la fois précédente : c'est ce qui permet à
  // FemiChatScreen (gardé en vie par l'IndexedStack) de détecter qu'un
  // NOUVEL envoi est demandé, via didUpdateWidget.
  String? _pendingFemiPrompt;
  int _femiPromptNonce = 0;

  void _switchToFemiWithPrompt(String prompt) {
    setState(() {
      _currentIndex = 1;
      _pendingFemiPrompt = prompt;
      _femiPromptNonce++;
    });
  }

  // --- Basculement d'onglet demandé depuis un écran enfant ---
  // Utilisé par le Drawer de FemiChatScreen pour "Tableau de bord" et
  // "Compte", qui sont des onglets de cet IndexedStack, pas des écrans
  // indépendants qu'on peut simplement empiler par-dessus. Aussi utilisé
  // par la flèche de retour de FemiChatScreen (voir onBack ci-dessous).
  void _switchToTab(int index) {
    setState(() => _currentIndex = index);
  }

  List<Widget> get _screens => [
        DashboardScreen(
          onNavigateToFemi: _switchToFemiWithPrompt,
          onNavigateToTab: _switchToTab),

        FemiChatScreen(
          initialPrompt: _pendingFemiPrompt,
          promptNonce: _femiPromptNonce,
          // Comme MainNavigationScreen est l'unique route de l'app (les
          // onglets ne sont que des index d'IndexedStack, pas des routes
          // Navigator séparées), la flèche de retour de l'AppBar ne peut
          // pas faire un Navigator.pop classique — il n'y a rien à
          // dépiler. On lui dit explicitement de revenir au Dashboard.
          onBack: () => _switchToTab(0),
        ),
        const CompteScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // On n'autorise la fermeture réelle de l'app (pop du dernier écran)
      // que si on est déjà sur l'onglet Dashboard (index 0). Sinon, on
      // intercepte le retour (bouton système Android / bouton retour du
      // navigateur Chrome) pour revenir au Dashboard au lieu de laisser
      // Flutter tenter de fermer l'app, ce qui provoquait l'écran
      // noir/blanc observé.
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _switchToTab(0);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 1),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.grid_view_rounded, 'KPI'),
              _buildNavItem(1, Icons.auto_awesome, 'Femi'),
              _buildNavItem(2, Icons.account_balance_outlined, 'Compte'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF80F2DD) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: isSelected ? const Color(0xFF0D5C52) : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFF0D5C52) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}