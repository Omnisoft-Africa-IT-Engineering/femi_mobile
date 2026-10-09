import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/devis.dart';
import '../models/profil_facturation.dart';
import 'femi_api_service.dart';

/// Accès aux devis du backend (GET/PATCH/DELETE sur /api/v1/devis/).
/// La création se fait dans le chat Femi, pas ici.
class DevisService {
  DevisService._();
  static final DevisService instance = DevisService._();

  final FemiApiService _api = FemiApiService();

  // Render (offre gratuite) peut mettre du temps à se réveiller.
  static const _delai = Duration(seconds: 60);

  String get _base => '${FemiApiService.baseUrl}/devis';

  Future<Map<String, String>> _headers() async {
    final token = await _api.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Utilisateur non connecté');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Token $token',
    };
  }

  Never _echec(String action, http.Response r) {
    debugPrint('Devis $action: ${r.statusCode} - ${r.body}');
    throw Exception('Devis $action : erreur ${r.statusCode}');
  }

  // --- Liste : GET /api/v1/devis/ ---
  Future<List<Devis>> listerDevis() async {
    final r = await http
        .get(Uri.parse('$_base/'), headers: await _headers())
        .timeout(_delai);
    if (r.statusCode != 200) _echec('liste', r);

    final data = jsonDecode(utf8.decode(r.bodyBytes));
    final liste = data is List
        ? data
        : (data is Map && data['results'] is List
        ? data['results'] as List
        : <dynamic>[]);

    final devis = liste
        .map((e) => Devis.fromJson(e as Map<String, dynamic>))
        .toList();
    devis.sort((a, b) => b.dateEmission.compareTo(a.dateEmission));
    return devis;
  }

  // --- Détail : GET /api/v1/devis/{id}/ ---
  // [id] est un Object pour accepter un String ou un int.
  Future<Devis> getDevis(Object id) async {
    final r = await http
        .get(Uri.parse('$_base/$id/'), headers: await _headers())
        .timeout(_delai);
    if (r.statusCode != 200) _echec('détail', r);
    return Devis.fromJson(
        jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>);
  }

  // --- Changement de statut : PATCH /api/v1/devis/{id}/ ---
  // Envoie BROUILLON, ENVOYE, ACCEPTE, REFUSE ou CONVERTI.
  Future<void> changerStatut(Object id, StatutDevis statut) async {
    final r = await http
        .patch(
      Uri.parse('$_base/$id/'),
      headers: await _headers(),
      body: jsonEncode({'statut': statut.apiValue}),
    )
        .timeout(_delai);
    if (r.statusCode != 200) _echec('statut', r);
  }

  // --- Suppression : DELETE /api/v1/devis/{id}/ ---
  Future<void> supprimerDevis(Object id) async {
    final r = await http
        .delete(Uri.parse('$_base/$id/'), headers: await _headers())
        .timeout(_delai);
    if (r.statusCode != 204 && r.statusCode != 200) _echec('suppression', r);
  }

  // --- PDF : GET /api/v1/devis/{id}/pdf/ ---
  // Renvoie les octets du PDF (aperçu et partage à brancher ensuite).
  Future<Uint8List> telechargerPdf(Object id) async {
    final headers = await _headers();
    final r = await http
        .get(Uri.parse('$_base/$id/pdf/'), headers: headers)
        .timeout(_delai);
    if (r.statusCode != 200) _echec('PDF', r);
    return r.bodyBytes;
  }

  // --- Profil de facturation : PROVISOIRE, en mémoire ---
  // Aucun endpoint de profil connu pour l'instant : les données sont
  // perdues au redémarrage, comme dans l'ancien service mocké.
  ProfilFacturation? _profil;

  Future<ProfilFacturation?> getProfil() async => _profil;

  Future<void> enregistrerProfil(ProfilFacturation profil) async {
    _profil = profil;
  }
}