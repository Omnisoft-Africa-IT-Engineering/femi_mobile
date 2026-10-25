import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/devis.dart';
import '../models/ligne_devis.dart';
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

  /// Message lisible tiré d'une réponse d'erreur du backend
  /// ({"error": ...}, {"detail": ...} ou erreurs de champs DRF).
  String _messageErreur(http.Response r, String defaut) {
    try {
      final d = jsonDecode(utf8.decode(r.bodyBytes));
      if (d is Map) {
        if (d['error'] != null) return d['error'].toString();
        if (d['detail'] != null) return d['detail'].toString();
        final msgs = d.values
            .map((v) => v is List ? v.join(' ') : v.toString())
            .where((m) => m.isNotEmpty)
            .toList();
        if (msgs.isNotEmpty) return msgs.join(' ');
      }
    } catch (_) {}
    return defaut;
  }

  Never _echecLigne(String action, http.Response r) {
    debugPrint('Devis ligne $action: ${r.statusCode} - ${r.body}');
    throw Exception(
        _messageErreur(r, 'Ligne : $action impossible (erreur ${r.statusCode}).'));
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
  // API : BROUILLON → VALIDE | ANNULE ; VALIDE → ANNULE
  Future<void> changerStatut(Object id, StatutDevis statut) async {
    final r = await http
        .patch(
          Uri.parse('$_base/$id/'),
          headers: await _headers(),
          body: jsonEncode({'statut': statut.apiValue}),
        )
        .timeout(_delai);

    if (r.statusCode == 200 || r.statusCode == 202) {
      return;
    }

    if (r.statusCode == 409) {
      throw Exception('Ce devis ne peut plus être modifié.');
    }

    if (r.statusCode == 400) {
      throw Exception('Statut invalide ou transition interdite.');
    }

    _echec('statut', r);
  }

  
  // --- Suppression : DELETE /api/v1/devis/{id}/ ---
  Future<void> supprimerDevis(Object id) async {
    final r = await http
        .delete(Uri.parse('$_base/$id/'), headers: await _headers())
        .timeout(_delai);
    if (r.statusCode != 204 && r.statusCode != 200) _echec('suppression', r);
  }

  // --- Lignes : le backend recalcule les montants et renvoie le devis à jour ---

  // POST /api/v1/devis/{id}/lignes/
  Future<Devis> ajouterLigne(Object devisId, LigneDevis ligne) async {
    final r = await http
        .post(
          Uri.parse('$_base/$devisId/lignes/'),
          headers: await _headers(),
          body: jsonEncode(ligne.toJson()),
        )
        .timeout(_delai);
    if (r.statusCode != 201 && r.statusCode != 200) _echecLigne('ajout', r);
    return Devis.fromJson(
        jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>);
  }

  // PATCH /api/v1/devis/{id}/lignes/{ligneId}/
  Future<Devis> modifierLigne(
      Object devisId, int ligneId, LigneDevis ligne) async {
    final r = await http
        .patch(
          Uri.parse('$_base/$devisId/lignes/$ligneId/'),
          headers: await _headers(),
          body: jsonEncode(ligne.toJson()),
        )
        .timeout(_delai);
    if (r.statusCode != 200) _echecLigne('modification', r);
    return Devis.fromJson(
        jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>);
  }

  // DELETE /api/v1/devis/{id}/lignes/{ligneId}/
  Future<Devis> supprimerLigne(Object devisId, int ligneId) async {
    final r = await http
        .delete(
          Uri.parse('$_base/$devisId/lignes/$ligneId/'),
          headers: await _headers(),
        )
        .timeout(_delai);
    if (r.statusCode != 200) _echecLigne('suppression', r);
    return Devis.fromJson(
        jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>);
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

  // --- Profil de facturation (en-tête / pied de page des devis) ---

  // GET /api/v1/devis/profil/
  // Renvoie null si le profil ne peut pas être lu : l'écran des devis reste
  // utilisable et la feuille de configuration s'ouvre vide.
  Future<ProfilFacturation?> getProfil() async {
    try {
      final r = await http
          .get(Uri.parse('$_base/profil/'), headers: await _headers())
          .timeout(_delai);
      if (r.statusCode != 200) {
        debugPrint('Devis profil: ${r.statusCode} - ${r.body}');
        return null;
      }
      return ProfilFacturation.fromJson(
          jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Devis profil (lecture) : $e');
      return null;
    }
  }

  // PATCH /api/v1/devis/profil/ : lève une exception si l'enregistrement échoue.
  Future<void> enregistrerProfil(ProfilFacturation profil) async {
    final r = await http
        .patch(
          Uri.parse('$_base/profil/'),
          headers: await _headers(),
          body: jsonEncode(profil.toJson()),
        )
        .timeout(_delai);
    if (r.statusCode != 200) {
      debugPrint('Devis profil (enregistrement): ${r.statusCode} - ${r.body}');
      throw Exception(_messageErreur(
          r, 'Profil : enregistrement impossible (erreur ${r.statusCode}).'));
    }

    // Le logo part séparément (multipart) : seulement si un nouveau a été choisi.
    final cheminLogo = profil.logoLocalPath;
    if (cheminLogo != null && cheminLogo.isNotEmpty) {
      await _envoyerLogo(cheminLogo);
    }
  }

  // POST /api/v1/devis/profil/logo/ (champ multipart « logo »)
  Future<void> _envoyerLogo(String chemin) async {
    final entetes = await _headers();
    entetes.remove('Content-Type'); // multipart : le boundary est géré par http
    final requete =
        http.MultipartRequest('POST', Uri.parse('$_base/profil/logo/'))
          ..headers.addAll(entetes)
          ..files.add(await http.MultipartFile.fromPath('logo', chemin));

    final r = await http.Response.fromStream(
      await requete.send().timeout(const Duration(seconds: 90)),
    );
    if (r.statusCode != 200) {
      debugPrint('Devis profil (logo): ${r.statusCode} - ${r.body}');
      throw Exception(_messageErreur(
          r, "Les informations sont enregistrées, mais le logo n'a pas pu "
              "être envoyé (erreur ${r.statusCode})."));
    }
  }
}