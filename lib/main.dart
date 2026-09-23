import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter/foundation.dart'; // Add this import at the top
import 'services/femi_api_service.dart';   // Adjust to your actual path
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/femi_chat/femi_chat_screen.dart';
import 'screens/compte/compte_screen.dart';
import 'screens/subscription_pay/subscription_pay_screen.dart';
import 'screens/auth/auth_gate.dart';

// ⚠️ Ajuste ce chemin selon l'emplacement exact de notification_events.dart dans ton projet
import 'screens/notifications/notification_events.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialisation et écoute FCM
  await _setupFcmToken();

  runApp(const FemiApp());
}

Future<void> _setupFcmToken() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  await messaging.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
  alert: true,
  badge: true,
  sound: true,
);

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    String? token = await messaging.getToken();
    debugPrint("==================================================");
    debugPrint("MON TOKEN FCM : $token");
    debugPrint("==================================================");

    if (token != null) {
      // 1. On détecte la plateforme (IOS ou ANDROID)
      String plateforme = defaultTargetPlatform == TargetPlatform.iOS ? 'IOS' : 'ANDROID';

      // 2. On envoie le token au backend via la méthode 22 de ton service
      bool succes = await FemiApiService().enregistrerAppareil(token, plateforme);
      if (succes) {
        debugPrint("✅ Appareil enregistré avec succès dans le backend.");
      } else {
        debugPrint("⚠️ Échec de l'enregistrement (l'utilisateur n'est peut-être pas encore connecté).");
      }
    }

    // 3. Écoute des messages quand l'application est ouverte
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Message FCM reçu au premier plan : ${message.notification?.title}");
      NotificationEvents.nouvelleNotification.value++;
    });

  } else {
    debugPrint("Permission notification refusée par l'utilisateur.");
  }
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

  String? _pendingFemiPrompt;
  int _femiPromptNonce = 0;

  void _switchToFemiWithPrompt(String prompt) {
    setState(() {
      _currentIndex = 1;
      _pendingFemiPrompt = prompt;
      _femiPromptNonce++;
    });
  }

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
          onBack: () => _switchToTab(0),
        ),
        const CompteScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
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