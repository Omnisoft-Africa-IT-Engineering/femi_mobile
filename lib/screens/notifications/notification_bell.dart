import 'package:flutter/material.dart';
import '../../services/femi_api_service.dart';
import 'notification_events.dart';
import 'notifications_screen.dart';

/// Cloche avec pastille du nombre de notifications non lues.
/// À placer dans l'AppBar (actions) ou l'en-tête de l'écran d'accueil.
///
/// Le compteur se recharge au chargement, au retour dans l'app, à la
/// réception d'un push app ouverte, et au retour depuis l'écran de liste.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> with WidgetsBindingObserver {
  final FemiApiService _apiService = FemiApiService();
  int _nonLues = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationEvents.nouvelleNotification.addListener(_charger);
    _charger();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationEvents.nouvelleNotification.removeListener(_charger);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _charger();
  }

  Future<void> _charger() async {
    final int? nombre = await _apiService.getNombreNotificationsNonLues();
    if (!mounted || nombre == null) return;
    setState(() => _nonLues = nombre);
  }

  Future<void> _ouvrir() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    _charger();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Notifications',
      onPressed: _ouvrir,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_none_rounded, color: Color(0xFF0F172A), size: 26),
          if (_nonLues > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _nonLues > 9 ? '9+' : '$_nonLues',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}