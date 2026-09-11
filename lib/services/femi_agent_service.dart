import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class FemiAgentService {
  /// URL Ngrok unifiée pour la communication mobile et web
  static const String baseUrl = 'https://shore-handiwork-croon.ngrok-free.dev/api';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Alias pour assurer la rétrocompatibilité avec `femi_chat_screen.dart`
  Future<Map<String, dynamic>> sendMessage({
    String? text,
    dynamic audioFile,
    dynamic imageFile,
    Uint8List? imageBytes,
    Uint8List? audioBytes,
  }) async {
    return processTransaction(
      text: text,
      audioFile: audioFile,
      imageFile: imageFile,
      imageBytes: imageBytes,
      audioBytes: audioBytes,
    );
  }

  /// Envoie un message texte, une image ou un fichier vocal à l'agent Femi.
  Future<Map<String, dynamic>> processTransaction({
    String? text,
    dynamic audioFile,
    dynamic imageFile,
    Uint8List? imageBytes,
    Uint8List? audioBytes,
  }) async {
    // URL finale : https://shore-handiwork-croon.ngrok-free.dev/api/v1/transactions/process/
    final uri = Uri.parse('$baseUrl/v1/transactions/process/');
    var request = http.MultipartRequest('POST', uri);

    // 1. Récupération et nettoyage du Token d'authentification
    String? token = await _storage.read(key: 'auth_token') ??
        await _storage.read(key: 'token') ??
        await _storage.read(key: 'access_token');

    if (token != null && token.isNotEmpty) {
      final cleanToken = token.replaceAll('"', '').trim();
      request.headers['Authorization'] = 'Token $cleanToken';
      debugPrint('🔑 Token envoyé avec succès : Token $cleanToken');
    } else {
      throw Exception(
        'Aucun jeton d\'authentification trouvé. Veuillez vous reconnecter.',
      );
    }

    // 2. Ajout du texte si disponible
    if (text != null && text.trim().isNotEmpty) {
      request.fields['text'] = text.trim();
    }

    // 3. Ajout du fichier audio (Compatible Web & Mobile)
    if (kIsWeb && audioBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'audio',
          audioBytes,
          filename: 'vocal.m4a',
        ),
      );
    } else if (!kIsWeb && audioFile != null) {
      if (audioFile is io.File && await audioFile.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath('audio', audioFile.path),
        );
      }
    }

    // 4. Ajout de l'image (Compatible Web & Mobile)
    if (kIsWeb && imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'upload.jpg',
        ),
      );
    } else if (!kIsWeb && imageFile != null) {
      if (imageFile is io.File && await imageFile.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path),
        );
      }
    }

    // 5. Envoi de la requête multipart
    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedData = jsonDecode(utf8.decode(response.bodyBytes));
        return decodedData as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception(
          'Erreur 401 : Session expirée ou Token invalide. Veuillez vous reconnecter.',
        );
      } else {
        throw Exception(
          'Erreur serveur (${response.statusCode}) : ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}