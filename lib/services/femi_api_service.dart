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

          final companyName = data['company_name'] ?? data['username'] ?? username;
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
  Future<Map<String, dynamic>?> getEtatFinancier() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/etat-financier/'),
        headers: _buildHeaders(token),
      );

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
}