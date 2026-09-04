import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/femi_agent_models.dart';

class FemiAgentService {
  // URL avec le préfixe /api/v1 aligned sur Django
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api/v1';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/v1';
    } else {
      return 'http://localhost:8000/api/v1';
    }
  }

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Envoie un message texte, un fichier audio ou une image à l'Agent Femi
  Future<FemiAgentResponse> sendMessage({
    String? text,
    File? audioFile,
    File? imageFile,
  }) async {
    // Route alignée sur apps.femi_api.urls
    final url = Uri.parse('$baseUrl/transactions/process/');
    var request = http.MultipartRequest('POST', url);

    // 1. Récupération du Token JWT
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // 2. Envoi du texte sous les 2 clés (text et text_input) pour compatibilité
    final cleanText = text?.trim() ?? '';
    request.fields['text'] = cleanText;
    request.fields['text_input'] = cleanText;

    // 3. Ajout du fichier audio si présent
    if (audioFile != null && await audioFile.exists()) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'audio',
          audioFile.path,
          contentType: MediaType('audio', 'm4a'),
        ),
      );
    }

    // 4. Ajout du fichier image si présent (Reçu / Facture)
    if (imageFile != null && await imageFile.exists()) {
      String extension = imageFile.path.split('.').last.toLowerCase();
      if (extension == 'jpg') extension = 'jpeg';

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType('image', extension),
        ),
      );
    }

    try {
      // 5. Envoi de la requête au backend Python
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final responseText = utf8.decode(response.bodyBytes);
      final contentType = response.headers['content-type'] ?? '';

      // Vérification si la réponse est du JSON
      if (contentType.contains('application/json')) {
        final Map<String, dynamic> responseData = jsonDecode(responseText);

        if (response.statusCode == 200) {
          return FemiAgentResponse(
            statusCode: 200,
            message: responseData['message'] ?? 'Réponse reçue.',
          );
        } else if (response.statusCode == 201) {
          final transaction = FemiTransaction.fromJson(responseData);
          return FemiAgentResponse(
            statusCode: 201,
            message: 'Transaction enregistrée avec succès.',
            transaction: transaction,
          );
        } else {
          throw Exception(
            responseData['error'] ??
                responseData['detail'] ??
                responseData['message'] ??
                'Erreur lors du traitement (${response.statusCode})',
          );
        }
      } else {
        print('--- ERREUR SERVEUR BRUTE (${response.statusCode}) ---');
        print(responseText);
        throw Exception(
          'Erreur serveur (${response.statusCode}). Regardez le terminal Django pour voir le détail.',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}