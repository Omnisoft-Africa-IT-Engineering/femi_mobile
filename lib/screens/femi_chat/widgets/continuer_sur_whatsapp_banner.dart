import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/femi_api_service.dart';

/// Bandeau compact (pas un bouton pleine largeur) invitant à continuer
/// la conversation avec Femi sur WhatsApp. Pensé pour être placé juste
/// au-dessus de la barre de saisie d'un écran de chat.
///
/// IMPORTANT (web) : le numéro est récupéré à l'AVANCE dans initState(),
/// pas au moment du clic. Sur navigateur, un appel réseau (await) juste
/// avant launchUrl casse le contexte de "geste utilisateur direct", et
/// Chrome bloque alors silencieusement l'ouverture du nouvel onglet —
/// sans erreur visible, juste "rien ne se passe". En préchargeant le
/// numéro, le clic déclenche launchUrl immédiatement, sans attente réseau
/// entre le tap et l'ouverture.
class ContinuerSurWhatsappBanner extends StatefulWidget {
  final String messagePreRempli;

  const ContinuerSurWhatsappBanner({
    super.key,
    this.messagePreRempli = 'Bonjour Femi, je continue notre conversation ici 👋',
  });

  @override
  State<ContinuerSurWhatsappBanner> createState() => _ContinuerSurWhatsappBannerState();
}

class _ContinuerSurWhatsappBannerState extends State<ContinuerSurWhatsappBanner> {
  final FemiApiService _apiService = FemiApiService();

  String? _numeroWhatsapp;
  bool _chargementInitial = true;

  @override
  void initState() {
    super.initState();
    _precharger();
  }

  Future<void> _precharger() async {
    final config = await _apiService.getAppConfig();
    final String? numero = config?['femi_whatsapp_number'] as String?;

    if (mounted) {
      setState(() {
        _numeroWhatsapp = (numero != null && numero.isNotEmpty) ? numero : null;
        _chargementInitial = false;
      });
    }
  }

  void _ouvrirWhatsapp() {
    if (_numeroWhatsapp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Numéro WhatsApp de Femi indisponible pour le moment.')),
      );
      return;
    }

    final String numeroNettoye = _numeroWhatsapp!.replaceAll(RegExp(r'[^\d]'), '');
    final Uri lienWhatsapp = Uri.parse(
      'https://wa.me/$numeroNettoye?text=${Uri.encodeComponent(widget.messagePreRempli)}',
    );

    // Pas de "await" avant cet appel : on reste dans le geste utilisateur
    // direct du clic, indispensable pour que le navigateur autorise
    // l'ouverture du nouvel onglet sans la bloquer comme un popup.
    launchUrl(lienWhatsapp, mode: LaunchMode.externalApplication).then((ouvert) {
      if (!ouvert && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible d'ouvrir WhatsApp.")),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _ouvrirWhatsapp,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: const Color(0xFF25D366).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF25D366).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              _chargementInitial
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF25D366)),
                    )
                  : const Icon(Icons.chat, color: Color(0xFF25D366), size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Envie de continuer sur WhatsApp ?',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0D5C52)),
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF0D5C52), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}