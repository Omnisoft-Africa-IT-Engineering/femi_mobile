import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service centralisant tous les appels vers le backend Django de Femi.
class FemiApiService {
  // Hôte commun aux deux préfixes d'API utilisés par le backend :
  // - api/v1/...   (apps.femi_api)
  // - api/auth/... (apps.femi_account — échéances fiscales, register/login JWT)
  static const String _host = 'https://shore-handiwork-croon.ngrok-free.dev';

  // Utilisation du loopback local pour le dev Web (Chrome)
  static const String baseUrl = '$_host/api/v1';

  // Base URL pour les endpoints montés sous apps.femi_account
  // (voir core/urls.py : path('api/auth/', include('apps.femi_account.urls'))).
  // C'est ici que vivent les échéances fiscales, PAS sous /api/v1/.
  static const String authBaseUrl = '$_host/api/auth';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // En-têtes HTTP requis pour communiquer avec Django
  Map<String, String> _buildHeaders([String? token]) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      // Indispensable en Flutter Web : sans ce header, ngrok (offre
      // gratuite) intercepte la requête avec sa page d'avertissement
      // HTML au lieu de la transmettre à Django — cette page n'a pas
      // d'en-têtes CORS, ce qui bloque la requête côté navigateur.
      'ngrok-skip-browser-warning': 'true',
    };
    if (token != null) {
      headers['Authorization'] = 'Token $token';
    }
    return headers;
  }

  // --- 1. Authentification (POST /api/v1/auth/token/) ---
  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/token/'),
        headers: _buildHeaders(),
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final token = data['token'] ?? data['access'] ?? data['key'];
        if (token != null) {
          await _storage.write(key: 'auth_token', value: token.toString());

          // Django (LoginAPIView) renvoie "entreprise_nom", pas
          // "company_name" — avec l'ancien champ, ça retombait toujours
          // sur le username au lieu du vrai nom de l'entreprise.
          final companyName = data['entreprise_nom'] ?? data['company_name'] ?? data['username'] ?? username;
          await _storage.write(key: 'company_name', value: companyName.toString());

          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Erreur lors du login: $e');
      return false;
    }
  }

  // --- 1bis. Inscription (POST /api/v1/auth/register/) ---
  // Crée l'Entreprise + l'Utilisateur, stocke le token comme login().
  Future<bool> register({
    required String username,
    required String password,
    required String nomEntreprise,
    String? nomComplet,
    String? email,
    String? telephoneWhatsapp,
    String? secteurNom,
    String? devise,
    // Forme juridique de l'entreprise — valeurs attendues côté Django :
    // 'INDIVIDUEL', 'SARL', 'SA', 'AUTRE' (voir Entreprise.TYPE_ENTREPRISE_CHOICES).
    // Sert à déterminer plus tard les échéances fiscales applicables.
    String? typeEntreprise,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register/'),
        headers: _buildHeaders(),
        body: jsonEncode({
          'username': username,
          'password': password,
          'nom_entreprise': nomEntreprise,
          if (nomComplet != null && nomComplet.isNotEmpty) 'nom_complet': nomComplet,
          if (email != null && email.isNotEmpty) 'email': email,
          if (telephoneWhatsapp != null && telephoneWhatsapp.isNotEmpty)
            'telephone_whatsapp': telephoneWhatsapp,
          if (secteurNom != null && secteurNom.isNotEmpty) 'secteur_nom': secteurNom,
          if (devise != null && devise.isNotEmpty) 'devise': devise,
          if (typeEntreprise != null && typeEntreprise.isNotEmpty)
            'type_entreprise': typeEntreprise,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);

        final token = data['token'];
        if (token != null) {
          await _storage.write(key: 'auth_token', value: token.toString());

          final companyName = data['entreprise_nom'] ?? nomEntreprise;
          await _storage.write(key: 'company_name', value: companyName.toString());

          return true;
        }
        return false;
      } else {
        debugPrint('Erreur HTTP Register: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'inscription: $e');
      return false;
    }
  }

  // --- 2. Récupérer le nom de l'entreprise ---
  Future<String> getCompanyName() async {
    final localName = await _storage.read(key: 'company_name');
    if (localName != null && localName.isNotEmpty) {
      return localName;
    }

    final profile = await getUserProfile();
    if (profile != null) {
      final name = profile['company_name'] ?? profile['username'] ?? 'Mon Entreprise';
      await _storage.write(key: 'company_name', value: name.toString());
      return name.toString();
    }

    return 'Mon Entreprise';
  }

  // --- 3. Récupérer le profil complet de l'utilisateur (GET /api/v1/auth/profile/) ---
  Future<Map<String, dynamic>?> getUserProfile() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile/'),
        headers: _buildHeaders(token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la récupération du profil: $e');
      return null;
    }
  }

  // --- 4. Récupérer le token stocké localement ---
  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  // --- 5. Déconnexion ---
  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'company_name');
  }

  // --- 6. Obtenir les KPIs du Dashboard (GET /api/v1/dashboard/kpis/) ---
  Future<Map<String, dynamic>?> getDashboardKPIs({String period = 'this_month'}) async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/kpis/?period=$period'),
        headers: _buildHeaders(token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des KPIs: $e');
      return null;
    }
  }

  // --- 7. Envoyer un message à Femi Agent (POST /api/v1/agent/chat/) ---
  Future<Map<String, dynamic>?> sendAgentMessage({
    required String message,
    String? conversationId,
  }) async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/agent/chat/'),
        headers: _buildHeaders(token),
        body: jsonEncode({
          'message': message,
          if (conversationId != null) 'conversation_id': conversationId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint('Erreur HTTP Agent Chat: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Erreur réseau lors de la communication avec Femi Agent: $e');
      return null;
    }
  }

  // --- 8. Obtenir l'historique d'une conversation avec l'Agent ---
  Future<List<dynamic>?> getChatHistory({String? conversationId}) async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final uri = Uri.parse(
        conversationId != null
            ? '$baseUrl/agent/history/?conversation_id=$conversationId'
            : '$baseUrl/agent/history/',
      );

      final response = await http.get(
        uri,
        headers: _buildHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data;
        } else if (data is Map && data.containsKey('messages')) {
          return data['messages'] as List<dynamic>;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la récupération de l\'historique du chat: $e');
      return null;
    }
  }

 // --- 9. Obtenir le registre journalier (GET /api/v1/registre-journalier/) ---
  Future<Map<String, dynamic>?> getRegistreJournalier({
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    final token = await getToken();
    if (token == null) return null;

    final debut = dateDebut ?? DateTime.now();
    final fin = dateFin ?? debut;

    final String dateDebutStr =
        '${debut.year.toString().padLeft(4, '0')}-${debut.month.toString().padLeft(2, '0')}-${debut.day.toString().padLeft(2, '0')}';
    final String dateFinStr =
        '${fin.year.toString().padLeft(4, '0')}-${fin.month.toString().padLeft(2, '0')}-${fin.day.toString().padLeft(2, '0')}';

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/registre-journalier/?date_debut=$dateDebutStr&date_fin=$dateFinStr'),
        headers: _buildHeaders(token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint('Erreur HTTP Registre Journalier: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération du registre journalier: $e');
      return null;
    }
  }

  // --- 10. Obtenir l'état financier simplifié (GET /api/v1/etat-financier/) ---
  // 'annee' = exercice comptable choisi ; sans ce paramètre, Django prend
  // l'année courante par défaut (photo du bilan à la date du jour).
  Future<Map<String, dynamic>?> getEtatFinancier({int? annee}) async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final uri = Uri.parse(
        annee != null
            ? '$baseUrl/etat-financier/?annee=$annee'
            : '$baseUrl/etat-financier/',
      );

      final response = await http.get(uri, headers: _buildHeaders(token));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la récupération de l\'état financier: $e');
      return null;
    }
  }

  // --- 11. Activer une formule d'abonnement (POST /api/v1/activate-plan/) ---
  // transactionId : optionnel, transaction_id renvoyé par la mutation
  // payWithFedaPay. Envoyé si fourni, pour que Django puisse vérifier/
  // tracer le paiement plutôt que de faire confiance à l'appel seul.
  Future<bool> activatePlan({required String planTitle, String? transactionId}) async {
    final token = await getToken();
    if (token == null) {
      debugPrint('❌ Token d\'authentification introuvable.');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/activate-plan/'),
        headers: _buildHeaders(token),
        body: jsonEncode({
          'plan': planTitle,
          if (transactionId != null && transactionId.isNotEmpty)
            'transaction_id': transactionId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint('❌ Échec activation plan (${response.statusCode}): ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Erreur réseau lors de l\'activation de la formule: $e');
      return false;
    }
  }

  // --- 12. Obtenir le grand livre simplifié (GET /api/v1/grand-livre/) ---
  Future<Map<String, dynamic>?> getGrandLivre() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/grand-livre/'),
        headers: _buildHeaders(token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint('Erreur HTTP Grand Livre: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération du grand livre: $e');
      return null;
    }
  }

  // --- 13. Obtenir la synthèse annuelle du bilan (GET /api/v1/bilan/synthese/) ---
  // Renvoie CA, résultat net, marge, trésorerie (calculables), plus
  // total_bilan/ratio_autonomie/certification marqués "disponible: false" —
  // à ne jamais afficher comme une valeur réelle côté UI.
  Future<Map<String, dynamic>?> getBilanSynthese({int? annee}) async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final uri = Uri.parse(
        annee != null
            ? '$baseUrl/bilan/synthese/?annee=$annee'
            : '$baseUrl/bilan/synthese/',
      );

      final response = await http.get(uri, headers: _buildHeaders(token));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint('Erreur HTTP Bilan Synthèse: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la synthèse du bilan: $e');
      return null;
    }
  }
  // --- 12. Obtenir la balance générale (GET /api/v1/balance-generale/) ---
  // 'annee' = exercice comptable ; année courante par défaut côté Django.
  Future<Map<String, dynamic>?> getBalanceGenerale({int? annee}) async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final uri = Uri.parse(
        annee != null
            ? '$baseUrl/balance-generale/?annee=$annee'
            : '$baseUrl/balance-generale/',
      );

      final response = await http.get(uri, headers: _buildHeaders(token));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint('Erreur HTTP Balance Générale: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la balance générale: $e');
      return null;
    }
  }
  // --- 13. Obtenir la balance auxiliaire (GET /api/v1/balance-auxiliaire/) ---
  // 'annee' = exercice comptable ; année courante par défaut côté Django.
  Future<Map<String, dynamic>?> getBalanceAuxiliaire({int? annee}) async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final uri = Uri.parse(
        annee != null
            ? '$baseUrl/balance-auxiliaire/?annee=$annee'
            : '$baseUrl/balance-auxiliaire/',
      );

      final response = await http.get(uri, headers: _buildHeaders(token));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint('Erreur HTTP Balance Auxiliaire: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la balance auxiliaire: $e');
      return null;
    }
  }

  // --- 14. Obtenir la configuration publique (GET /api/v1/config/) ---
  // Pas besoin de token : endpoint public, utilisé pour récupérer le
  // numéro WhatsApp Business de Femi (bouton "Continuer sur WhatsApp").
  Future<Map<String, dynamic>?> getAppConfig() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/config/'),
        headers: _buildHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la config: $e');
      return null;
    }
  }

  // --- 15. Persistance d'une inscription en attente après paiement confirmé ---
  // Sécurité : si register() échoue juste après un paiement FedaPay réussi
  // (panne réseau, serveur Django indisponible...), on ne veut pas perdre
  // les infos ni forcer l'utilisateur à repayer. On les garde ici jusqu'à
  // ce que register() + activatePlan() réussissent réellement.
  static const String _pendingRegistrationKey = 'pending_registration';

  Future<void> savePendingRegistration(Map<String, dynamic> data) async {
    await _storage.write(key: _pendingRegistrationKey, value: jsonEncode(data));
  }

  Future<Map<String, dynamic>?> getPendingRegistration() async {
    final raw = await _storage.read(key: _pendingRegistrationKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Erreur lors de la lecture de pending_registration: $e');
      return null;
    }
  }

  Future<void> clearPendingRegistration() async {
    await _storage.delete(key: _pendingRegistrationKey);
  }

  // --- 16. Obtenir les échéances fiscales (GET /api/auth/echeances-fiscales/) ---
  // ⚠️ Cet endpoint vit sous authBaseUrl (api/auth/), PAS baseUrl (api/v1/) —
  // voir core/urls.py : path('api/auth/', include('apps.femi_account.urls')).
  // Renvoie la liste brute (pas de pagination DRF activée globalement),
  // mais on gère quand même le cas {"results": [...]} par sécurité si la
  // pagination est ajoutée un jour côté backend.
  Future<List<dynamic>?> getEcheancesFiscales() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$authBaseUrl/echeances-fiscales/'),
        headers: _buildHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data;
        } else if (data is Map && data.containsKey('results')) {
          return data['results'] as List<dynamic>;
        }
        return null;
      } else {
        debugPrint('Erreur HTTP Échéances Fiscales: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération des échéances fiscales: $e');
      return null;
    }
  }

  // --- 17. Marquer une échéance fiscale comme payée
  //          (POST /api/auth/echeances-fiscales/{id}/marquer_paye/) ---
  // 'id' est un int côté Django (EcheanceFiscale n'a pas de PK UUID
  // explicite comme les autres modèles) — on l'accepte en String ici
  // pour rester flexible si ça change plus tard, et on l'interpole tel
  // quel dans l'URL.
  Future<bool> marquerEcheancePayee(String id) async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final response = await http.patch(
        Uri.parse('$authBaseUrl/echeances-fiscales/$id/marquer_paye/'),
        headers: _buildHeaders(token),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Erreur HTTP Marquer Échéance Payée: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Erreur lors du marquage de l\'échéance comme payée: $e');
      return false;
    }
  }

  // ============================================================
  // À COLLER dans FemiApiService, juste après la méthode 17
  // (marquerEcheancePayee), avant l'accolade fermante de la classe.
  //
  // Comme les échéances fiscales, les notifications vivent sous
  // authBaseUrl (api/auth/) : apps.femi_account.urls.
  // ============================================================

  // --- 18. Obtenir les notifications (GET /api/auth/notifications/) ---
  // On décode via bodyBytes en UTF-8 pour ne jamais altérer les accents
  // et tirets longs des titres/messages, quel que soit le Content-Type.
  Future<List<dynamic>?> getNotifications() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$authBaseUrl/notifications/'),
        headers: _buildHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is List) {
          return data;
        } else if (data is Map && data.containsKey('results')) {
          return data['results'] as List<dynamic>;
        }
        return null;
      } else {
        debugPrint('Erreur HTTP Notifications: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération des notifications: $e');
      return null;
    }
  }

  // --- 19. Nombre de notifications non lues (GET /api/auth/notifications/non-lues/) ---
  // Renvoie null en cas d'erreur pour que la cloche garde son dernier
  // compteur connu au lieu de retomber à 0.
  Future<int?> getNombreNotificationsNonLues() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$authBaseUrl/notifications/non-lues/'),
        headers: _buildHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is Map && data['count'] is int) {
          return data['count'] as int;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la récupération du compteur de notifications: $e');
      return null;
    }
  }

  // --- 20. Marquer une notification comme lue
  //          (POST /api/auth/notifications/{id}/lue/) ---
  Future<bool> marquerNotificationLue(String id) async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$authBaseUrl/notifications/$id/lue/'),
        headers: _buildHeaders(token),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        return true;
      }
      debugPrint('Erreur HTTP Notification Lue: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Erreur lors du marquage de la notification comme lue: $e');
      return false;
    }
  }

  // --- 21. Tout marquer comme lu (POST /api/auth/notifications/tout-lire/) ---
  Future<bool> marquerToutesNotificationsLues() async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$authBaseUrl/notifications/tout-lire/'),
        headers: _buildHeaders(token),
      );

      if (response.statusCode == 200) {
        return true;
      }
      debugPrint('Erreur HTTP Tout Lire: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Erreur lors du marquage de toutes les notifications: $e');
      return false;
    }
  }

  // --- 22. Enregistrer l'appareil pour les push
  //          (POST /api/auth/notifications/appareils/) ---
  // fcmToken : token Firebase de l'appareil (à ne pas confondre avec le
  // token d'authentification Django, lu ici via getToken()).
  // plateforme : 'ANDROID' ou 'IOS'.
  Future<bool> enregistrerAppareil(String fcmToken, String plateforme) async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$authBaseUrl/notifications/appareils/'),
        headers: _buildHeaders(token),
        body: jsonEncode({
          'token': fcmToken,
          'plateforme': plateforme,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      }
      debugPrint('Erreur HTTP Enregistrement Appareil: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Erreur lors de l\'enregistrement de l\'appareil: $e');
      return false;
    }
  }

  // --- 23. Supprimer l'appareil (DELETE /api/auth/notifications/appareils/) ---
  // À appeler AVANT logout() : la requête a besoin du token d'authentification.
  Future<bool> supprimerAppareil(String fcmToken) async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final response = await http.delete(
        Uri.parse('$authBaseUrl/notifications/appareils/'),
        headers: _buildHeaders(token),
        body: jsonEncode({'token': fcmToken}),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        return true;
      }
      debugPrint('Erreur HTTP Suppression Appareil: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Erreur lors de la suppression de l\'appareil: $e');
      return false;
    }
  }

}