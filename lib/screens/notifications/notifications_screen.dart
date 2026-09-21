import 'package:flutter/material.dart';
import '../../services/femi_api_service.dart';
// ⚠️ ajustez ce chemin selon votre arborescence réelle
import '../echeances_fiscales/echeances_fiscales_screen.dart';

/// Centre de notifications : liste des rappels d'échéances fiscales reçus.
///
/// Suit les mêmes conventions visuelles que EcheancesFiscalesScreen
/// (fond F8F9FE, vert primaire 006654, cartes blanches bordées E2E8F0).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FemiApiService _apiService = FemiApiService();

  List<Map<String, dynamic>> _notifications = [];
  bool _chargement = true;
  bool _erreur = false;
  bool _toutLireEnCours = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger({bool silencieux = false}) async {
    if (!silencieux) {
      setState(() {
        _chargement = true;
        _erreur = false;
      });
    }

    final List<dynamic>? donnees = await _apiService.getNotifications();
    if (!mounted) return;

    setState(() {
      _chargement = false;
      if (donnees == null) {
        // On garde la liste déjà affichée si un rafraîchissement échoue.
        _erreur = _notifications.isEmpty;
      } else {
        _erreur = false;
        _notifications =
            donnees.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    });
  }

  int get _nbNonLues => _notifications.where((n) => n['lue'] != true).length;

  Color _couleurPalier(String? palier) {
    switch (palier) {
      case 'RETARD':
        return const Color(0xFFDC2626);
      case 'J0':
      case 'J1':
        return const Color(0xFFEA580C);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _iconePalier(String? palier) {
    switch (palier) {
      case 'RETARD':
        return Icons.error_outline;
      case 'J0':
      case 'J1':
        return Icons.alarm;
      default:
        return Icons.event_outlined;
    }
  }

  String _formatRelatif(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    DateTime date;
    try {
      date = DateTime.parse(iso).toLocal();
    } catch (_) {
      return '';
    }

    final DateTime maintenant = DateTime.now();
    final DateTime aujourdhui = DateTime(maintenant.year, maintenant.month, maintenant.day);
    final DateTime jour = DateTime(date.year, date.month, date.day);
    final int ecart = aujourdhui.difference(jour).inDays;
    final String heure =
        '${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}';

    if (ecart == 0) return "Aujourd'hui, $heure";
    if (ecart == 1) return 'Hier, $heure';

    const mois = [
      'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'
    ];
    return '${date.day} ${mois[date.month - 1]} ${date.year}';
  }

  Future<void> _ouvrir(Map<String, dynamic> notification) async {
    if (notification['lue'] != true) {
      // Mise à jour immédiate à l'écran ; le serveur suit en arrière-plan.
      setState(() => notification['lue'] = true);
      _apiService.marquerNotificationLue(notification['id'].toString());
    }

    if (notification['echeance'] != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EcheancesFiscalesScreen()),
      );
    }
  }

  Future<void> _toutMarquerLu() async {
    setState(() => _toutLireEnCours = true);
    final bool succes = await _apiService.marquerToutesNotificationsLues();
    if (!mounted) return;
    setState(() => _toutLireEnCours = false);

    if (succes) {
      setState(() {
        for (final n in _notifications) {
          n['lue'] = true;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notifications marquées comme lues.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Échec de la mise à jour. Réessayez.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        centerTitle: false,
        actions: [
          if (_nbNonLues > 0)
            TextButton(
              onPressed: _toutLireEnCours ? null : _toutMarquerLu,
              child: const Text(
                'Tout marquer comme lu',
                style: TextStyle(color: Color(0xFF006654), fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _charger(silencieux: true),
          child: _buildCorps(),
        ),
      ),
    );
  }

  Widget _buildCorps() {
    if (_chargement) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (_erreur) return _buildErreur();

    if (_notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 60.0),
        children: const [
          Icon(Icons.notifications_none_rounded, size: 48, color: Color(0xFF94A3B8)),
          SizedBox(height: 12),
          Text(
            'Aucune notification pour le moment.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          SizedBox(height: 6),
          Text(
            'Vous serez prévenu ici avant chaque échéance fiscale.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      itemCount: _notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildCarte(_notifications[index]),
    );
  }

  Widget _buildErreur() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 8),
        const Text(
          'Impossible de charger les notifications.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton(
            onPressed: _charger,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006654)),
            child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildCarte(Map<String, dynamic> notification) {
    final bool lue = notification['lue'] == true;
    final String? palier = notification['palier'] as String?;
    final Color couleur = _couleurPalier(palier);

    final RoundedRectangleBorder forme = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: lue ? const Color(0xFFE2E8F0) : const Color(0xFF006654).withOpacity(0.4),
      ),
    );

    return Material(
      color: Colors.white,
      shape: forme,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: forme,
        onTap: () => _ouvrir(notification),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: couleur.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(_iconePalier(palier), color: couleur, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (notification['titre'] ?? '').toString(),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: lue ? FontWeight.w600 : FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (!lue)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF006654),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (notification['message'] ?? '').toString(),
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatRelatif(notification['created_at'] as String?),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}