import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'femi_api_service.dart';

/// État de l'abonnement renvoyé par GET /api/v1/abonnement/.
class AbonnementStatut {
  final bool actif;

  /// Vrai quand le serveur applique le blocage (ABONNEMENT_OBLIGATOIRE).
  final bool obligatoire;
  final String? plan;
  final int joursRestants;
  final bool essai;

  const AbonnementStatut({
    required this.actif,
    required this.obligatoire,
    required this.plan,
    required this.joursRestants,
    required this.essai,
  });

  /// L'accès est coupé : le serveur exige un abonnement et il n'y en a plus.
  bool get accesBloque => obligatoire && !actif;
}

class AbonnementService {
  final FemiApiService _api = FemiApiService();

  /// Retourne null si le statut est illisible (réseau, session expirée...).
  /// L'appelant ne doit PAS bloquer l'utilisateur dans ce cas : le serveur
  /// refuse de toute façon les requêtes d'un abonnement expiré (HTTP 402).
  Future<AbonnementStatut?> getStatut() async {
    final String? token = await _api.getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('${FemiApiService.baseUrl}/abonnement/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        debugPrint('Abonnement : HTTP ${response.statusCode}');
        return null;
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) return null;

      final Map<String, dynamic> abonnement =
          (decoded['abonnement'] as Map<String, dynamic>?) ?? {};

      return AbonnementStatut(
        actif: abonnement['actif'] == true,
        obligatoire: decoded['abonnement_obligatoire'] == true,
        plan: abonnement['plan']?.toString(),
        joursRestants: (abonnement['jours_restants'] as num?)?.toInt() ?? 0,
        essai: abonnement['essai'] == true,
      );
    } catch (e) {
      debugPrint('Abonnement : $e');
      return null;
    }
  }
}
