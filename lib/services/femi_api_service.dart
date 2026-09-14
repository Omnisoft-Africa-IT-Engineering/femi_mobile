import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service centralisant tous les appels vers le backend Django de Femi.
class FemiApiService {
  // Utilisation du loopback local pour le dev Web (Chrome)
  static const String baseUrl = 'https://shore-handiwork-croon.ngrok-free.dev/api/v1';
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
  Future<Map<String, dynamic>?> getRegistreJournalier({DateTime? date}) async {
    final token = await getToken();
    if (token == null) return null;

    final jour = date ?? DateTime.now();
    final dateStr =
        '${jour.year.toString().padLeft(4, '0')}-${jour.month.toString().padLeft(2, '0')}-${jour.day.toString().padLeft(2, '0')}';

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/registre-journalier/?date=$dateStr'),
        headers: _buildHeaders(token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
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
  Future<bool> activatePlan({required String planTitle}) async {
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

}