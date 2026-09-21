import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'femi_api_service.dart';
import '../screens/notifications/notification_events.dart';

/// Gère les notifications push (Firebase Cloud Messaging) :
///  - affichage quand l'app est ouverte (Android n'affiche rien par défaut),
///  - enregistrement du token de l'appareil auprès du backend,
///  - ouverture de l'écran des échéances quand l'utilisateur touche une notification.
///
/// Câblage à faire une seule fois dans main.dart :
///
///   WidgetsFlutterBinding.ensureInitialized();
///   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
///   PushNotificationService.instance.onOuvrirEcheances = () {
///     PushNotificationService.navigatorKey.currentState?.push(
///       MaterialPageRoute(builder: (_) => const EcheancesFiscalesScreen()),
///     );
///   };
///   await PushNotificationService.instance.init();
///   runApp(...);   // avec MaterialApp(navigatorKey: PushNotificationService.navigatorKey)
///
/// Puis, dans AuthState :
///   - après une connexion / inscription réussie :
///       PushNotificationService.instance.enregistrerAppareil();
///   - à la déconnexion, AVANT d'effacer le token d'authentification :
///       await PushNotificationService.instance.desenregistrerAppareil();
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  /// À passer à MaterialApp(navigatorKey: ...) pour naviguer depuis une notification.
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Définie dans main.dart : ouvre l'écran des échéances fiscales.
  void Function()? onOuvrirEcheances;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  final FemiApiService _api = FemiApiService();

  static const String _canalId = 'echeances_fiscales';
  static const String _canalNom = 'Échéances fiscales';

  bool _initialise = false;
  String? _tokenActuel;
  StreamSubscription<String>? _abonnementToken;

  /// À appeler une fois au démarrage, après Firebase.initializeApp.
  Future<void> init() async {
    if (_initialise) return;
    _initialise = true;

    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (_) => _ouvrirEcheances(),
    );

    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _canalId,
            _canalNom,
            description: 'Rappels avant chaque échéance fiscale',
            importance: Importance.high,
          ),
        );

    // iOS affiche lui-même les notifications quand l'app est ouverte.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_surMessageAuPremierPlan);
    FirebaseMessaging.onMessageOpenedApp.listen((_) => _ouvrirEcheances());

    // App lancée en touchant une notification alors qu'elle était fermée.
    final RemoteMessage? initial = await _messaging.getInitialMessage();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ouvrirEcheances());
    }
  }

  /// Demande la permission, récupère le token FCM et l'envoie au backend.
  /// À appeler après chaque connexion. Sans permission, le centre de
  /// notifications de l'app fonctionne quand même.
  Future<void> enregistrerAppareil() async {
    try {
      final NotificationSettings permission = await _messaging.requestPermission();
      if (permission.authorizationStatus == AuthorizationStatus.denied) return;

      final String? token = await _messaging.getToken();
      if (token == null) return;

      await _envoyerToken(token);
      _abonnementToken ??= _messaging.onTokenRefresh.listen(_envoyerToken);
    } catch (e) {
      debugPrint('Push : enregistrement impossible ($e)');
    }
  }

  /// À appeler à la déconnexion, tant que l'utilisateur est encore
  /// authentifié : le backend cesse d'envoyer des push à cet appareil.
  Future<void> desenregistrerAppareil() async {
    final String? token = _tokenActuel;
    try {
      if (token != null) await _api.supprimerAppareil(token);
    } catch (e) {
      debugPrint('Push : désenregistrement impossible ($e)');
    }
    await _abonnementToken?.cancel();
    _abonnementToken = null;
    _tokenActuel = null;
  }

  Future<void> _envoyerToken(String token) async {
    _tokenActuel = token;
    final String plateforme =
        defaultTargetPlatform == TargetPlatform.iOS ? 'IOS' : 'ANDROID';
    await _api.enregistrerAppareil(token, plateforme);
  }

  Future<void> _surMessageAuPremierPlan(RemoteMessage message) async {
    NotificationEvents.nouvelleNotification.value++;

    // Sur iOS, le système affiche déjà la notification.
    if (defaultTargetPlatform != TargetPlatform.android) return;

    final RemoteNotification? notification = message.notification;
    if (notification == null) return;

    await _local.show(
      message.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _canalId,
          _canalNom,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: 'echeance',
    );
  }

  void _ouvrirEcheances() {
    final void Function()? ouvrir = onOuvrirEcheances;
    if (ouvrir != null) ouvrir();
  }
}