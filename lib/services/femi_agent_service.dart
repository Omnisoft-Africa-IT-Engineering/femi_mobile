import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class FemiAgentService {
  /// URL de base du backend Django déployé sur Render.
  static const String baseUrl =
      'https://mon-api-django-supabase.onrender.com';

  final FlutterSecureStorage _storage =
      const FlutterSecureStorage();

  /// Alias pour assurer la rétrocompatibilité
  /// avec `femi_chat_screen.dart`.
  Future<Map<String, dynamic>> sendMessage({
    String? text,
    dynamic audioFile,
    dynamic imageFile,
    dynamic pdfFile,
    Uint8List? imageBytes,
    Uint8List? audioBytes,
  }) async {
    return processTransaction(
      text: text,
      audioFile: audioFile,
      imageFile: imageFile,
      pdfFile: pdfFile,
      imageBytes: imageBytes,
      audioBytes: audioBytes,
    );
  }

  /// Envoie un message texte, une image, un fichier vocal
  /// ou un document PDF à l'agent Femi.
  Future<Map<String, dynamic>> processTransaction({
    String? text,
    dynamic audioFile,
    dynamic imageFile,
    dynamic pdfFile,
    Uint8List? imageBytes,
    Uint8List? audioBytes,
  }) async {
    // URL finale :
    // https://mon-api-django-supabase.onrender.com/api/v1/transactions/process/
    final uri = Uri.parse(
      '$baseUrl/api/v1/transactions/process/',
    );

    final request =
        http.MultipartRequest('POST', uri);

    // Header requis pour contourner la page d'avertissement
    // ngrok si utilisé en développement.
    request.headers['ngrok-skip-browser-warning'] =
        'true';

    // ============================================================
    // 1. AUTHENTIFICATION
    // ============================================================

    String? token =
        await _storage.read(key: 'auth_token') ??
        await _storage.read(key: 'token') ??
        await _storage.read(key: 'access_token');

    if (token != null && token.isNotEmpty) {
      final cleanToken =
          token.replaceAll('"', '').trim();

      request.headers['Authorization'] =
          'Token $cleanToken';

      debugPrint(
        '🔑 Token envoyé avec succès : Token $cleanToken',
      );
    } else {
      throw Exception(
        'Aucun jeton d\'authentification trouvé. '
        'Veuillez vous reconnecter.',
      );
    }

    // ============================================================
    // 2. TEXTE
    // ============================================================

    if (text != null &&
        text.trim().isNotEmpty) {
      request.fields['text'] = text.trim();
    }

    // ============================================================
    // 3. AUDIO
    // ============================================================

    if (kIsWeb && audioBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'audio',
          audioBytes,
          filename: 'vocal.m4a',
        ),
      );
    } else if (!kIsWeb && audioFile != null) {
      if (audioFile is io.File &&
          await audioFile.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'audio',
            audioFile.path,
          ),
        );
      }
    }

    // ============================================================
    // 4. IMAGE
    // ============================================================

    if (kIsWeb && imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'upload.jpg',
        ),
      );
    } else if (!kIsWeb && imageFile != null) {
      if (imageFile is io.File &&
          await imageFile.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
          ),
        );
      }
    }

    // ============================================================
    // 5. PDF
    // ============================================================

    if (!kIsWeb && pdfFile != null) {
      if (pdfFile is io.File &&
          await pdfFile.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'pdf',
            pdfFile.path,
            filename:
                pdfFile.path.split(io.Platform.pathSeparator).last,
          ),
        );

        debugPrint(
          '📄 PDF ajouté à la requête : ${pdfFile.path}',
        );
      }
    }

    // ============================================================
    // 6. DEBUG
    // ============================================================

    debugPrint(
      '📤 Envoi vers Femi : '
      '${request.files.length} fichier(s)',
    );

    for (final file in request.files) {
      debugPrint(
        '📎 Champ : ${file.field} | '
        'Nom : ${file.filename}',
      );
    }

    // ============================================================
    // 7. ENVOI DE LA REQUÊTE MULTIPART
    // ============================================================

    try {
      final streamedResponse =
          await request.send();

      final response =
          await http.Response.fromStream(
        streamedResponse,
      );

      debugPrint(
        '📥 Réponse Femi : ${response.statusCode}',
      );

      debugPrint(
        '📥 Body : ${response.body}',
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        final decodedData =
            jsonDecode(
          utf8.decode(
            response.bodyBytes,
          ),
        );

        return decodedData
            as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception(
          'Erreur 401 : Session expirée ou '
          'Token invalide. Veuillez vous reconnecter.',
        );
      } else {
        throw Exception(
          'Erreur serveur (${response.statusCode}) : '
          '${response.body}',
        );
      }
    } catch (e) {
      debugPrint(
        '❌ Erreur FemiAgentService : $e',
      );

      rethrow;
    }
  }

  /// Envoie un fichier audio au backend et récupère le texte transcrit.
  Future<String> transcribeAudio(io.File audioFile) async {
    final uri = Uri.parse('$baseUrl/api/v1/transcrire-audio/');
    // adapte le chemin si ton URL Django est différente

    final request = http.MultipartRequest('POST', uri);

    String? token = await _storage.read(key: 'auth_token') ??
        await _storage.read(key: 'token') ??
        await _storage.read(key: 'access_token');

    if (token == null || token.isEmpty) {
      throw Exception('Non authentifié. Reconnectez-vous.');
    }

    final cleanToken = token.replaceAll('"', '').trim();
    request.headers['Authorization'] = 'Token $cleanToken';
    request.headers['ngrok-skip-browser-warning'] = 'true';

    request.files.add(
      await http.MultipartFile.fromPath('audio', audioFile.path),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur transcription (${response.statusCode}) : ${response.body}',
      );
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    if (data['success'] != true) {
      throw Exception(data['message']?.toString() ?? 'Transcription échouée');
    }

    return (data['transcription'] ?? '').toString().trim();
  }
}