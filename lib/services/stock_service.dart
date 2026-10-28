import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/produit.dart';
import 'femi_api_service.dart';

/// Clé unique générée à l'ouverture d'un formulaire de mouvement : si l'envoi
/// est répété (réseau coupé), le serveur ne compte le mouvement qu'une fois.
String nouvelleCleIdempotence() {
  final alea = Random.secure();
  final bloc = List.generate(12, (_) => alea.nextInt(256))
      .map((o) => o.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-$bloc';
}

/// Accès au module Stock du backend (/api/v1/stock/).
class StockService {
  StockService._();
  static final StockService instance = StockService._();

  final FemiApiService _api = FemiApiService();

  // Render (offre gratuite) peut mettre du temps à se réveiller.
  static const _delai = Duration(seconds: 60);

  String get _base => '${FemiApiService.baseUrl}/stock';

  Future<Map<String, String>> _headers({bool json = true}) async {
    final token = await _api.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Utilisateur non connecté');
    }
    return {
      if (json) 'Content-Type': 'application/json',
      'Authorization': 'Token $token',
    };
  }

  /// Message lisible tiré d'une réponse d'erreur du backend
  /// ({"error": ...}, {"detail": ...} ou erreurs de champs).
  Exception _erreur(http.Response r, String defaut) {
    debugPrint('Stock ${r.request?.url.path}: ${r.statusCode} - ${r.body}');
    try {
      final d = jsonDecode(utf8.decode(r.bodyBytes));
      if (d is Map) {
        if (d['error'] != null) return Exception(d['error'].toString());
        if (d['detail'] != null) return Exception(d['detail'].toString());
        final msgs = d.entries
            .map((e) => e.value is List
                ? (e.value as List).join(' ')
                : e.value.toString())
            .where((m) => m.isNotEmpty)
            .toList();
        if (msgs.isNotEmpty) return Exception(msgs.join(' '));
      }
    } catch (_) {}
    return Exception('$defaut (erreur ${r.statusCode}).');
  }

  Map<String, dynamic> _objet(http.Response r) =>
      jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;

  // GET /stock/resume/
  Future<ResumeStock> resume() async {
    final r = await http
        .get(Uri.parse('$_base/resume/'), headers: await _headers())
        .timeout(_delai);
    if (r.statusCode != 200) throw _erreur(r, 'Chargement du résumé impossible');
    return ResumeStock.fromJson(_objet(r));
  }

  // GET /stock/produits/
  Future<List<Produit>> listerProduits({
    String? recherche,
    String? statut, // 'ALERTE' | 'RUPTURE' | null
    bool archives = false,
  }) async {
    final params = <String, String>{
      'actif': archives ? 'false' : 'true',
      if (recherche != null && recherche.isNotEmpty) 'q': recherche,
      if (statut != null && statut.isNotEmpty) 'statut': statut,
    };
    final uri = Uri.parse('$_base/produits/').replace(queryParameters: params);
    final r = await http.get(uri, headers: await _headers()).timeout(_delai);
    if (r.statusCode != 200) throw _erreur(r, 'Chargement des produits impossible');
    final liste = (_objet(r)['resultats'] as List<dynamic>?) ?? [];
    return liste
        .map((e) => Produit.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /stock/produits/{id}/
  Future<Produit> getProduit(String id) async {
    final r = await http
        .get(Uri.parse('$_base/produits/$id/'), headers: await _headers())
        .timeout(_delai);
    if (r.statusCode != 200) throw _erreur(r, 'Produit introuvable');
    return Produit.fromJson(_objet(r));
  }

  // POST /stock/produits/ (administrateur)
  Future<Produit> creerProduit({
    required String nom,
    String? unite,
    double? prixVente,
    double? seuilAlerte,
    String? sku,
    double? stockInitial,
    double? coutInitial,
  }) async {
    final corps = <String, dynamic>{
      'nom': nom,
      if (unite != null && unite.isNotEmpty) 'unite': unite,
      'prix_vente': prixVente ?? 0,
      'seuil_alerte': seuilAlerte ?? 0,
      if (sku != null && sku.isNotEmpty) 'sku': sku,
      if (stockInitial != null && stockInitial > 0) 'stock_initial': stockInitial,
      if (coutInitial != null) 'cout_initial': coutInitial,
    };
    final r = await http
        .post(Uri.parse('$_base/produits/'),
            headers: await _headers(), body: jsonEncode(corps))
        .timeout(_delai);
    if (r.statusCode != 201) throw _erreur(r, 'Création du produit impossible');
    return Produit.fromJson(_objet(r));
  }

  // PATCH /stock/produits/{id}/ (administrateur)
  Future<Produit> modifierProduit(String id, Map<String, dynamic> champs) async {
    final r = await http
        .patch(Uri.parse('$_base/produits/$id/'),
            headers: await _headers(), body: jsonEncode(champs))
        .timeout(_delai);
    if (r.statusCode != 200) throw _erreur(r, 'Modification impossible');
    return Produit.fromJson(_objet(r));
  }

  // GET /stock/mouvements/?produit=...
  Future<PageMouvements> listerMouvements({
    required String produitId,
    int limit = 50,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$_base/mouvements/').replace(queryParameters: {
      'produit': produitId,
      'limit': '$limit',
      'offset': '$offset',
    });
    final r = await http.get(uri, headers: await _headers()).timeout(_delai);
    if (r.statusCode != 200) throw _erreur(r, "Chargement de l'historique impossible");
    final corps = _objet(r);
    final liste = (corps['resultats'] as List<dynamic>?) ?? [];
    return PageMouvements(
      (corps['total'] as num?)?.toInt() ?? liste.length,
      liste.map((e) => MouvementStock.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  // POST /stock/mouvements/ : renvoie le produit mis à jour.
  // type : 'ENTREE' | 'SORTIE' | 'AJUSTEMENT' (pour AJUSTEMENT, [quantite] est
  // le stock constaté après comptage).
  Future<Produit> enregistrerMouvement({
    required String produitId,
    required String type,
    required double quantite,
    required String cleIdempotence,
    String? motif,
    double? coutUnitaire,
    String? note,
  }) async {
    final corps = <String, dynamic>{
      'produit': produitId,
      'type_mouvement': type,
      'quantite': quantite,
      'cle_idempotence': cleIdempotence,
      if (motif != null && motif.isNotEmpty) 'motif': motif,
      if (coutUnitaire != null) 'cout_unitaire': coutUnitaire,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    };
    final r = await http
        .post(Uri.parse('$_base/mouvements/'),
            headers: await _headers(), body: jsonEncode(corps))
        .timeout(_delai);
    // 201 : créé ; 200 : déjà enregistré (envoi répété avec la même clé).
    if (r.statusCode != 201 && r.statusCode != 200) {
      throw _erreur(r, "Enregistrement du mouvement impossible");
    }
    return Produit.fromJson(_objet(r)['produit'] as Map<String, dynamic>);
  }

  // POST /stock/produits/import/ (multipart, administrateur)
  Future<RapportImport> importerProduits({
    required List<int> octets,
    required String nomFichier,
  }) async {
    final requete =
        http.MultipartRequest('POST', Uri.parse('$_base/produits/import/'))
          ..headers.addAll(await _headers(json: false))
          ..files.add(
              http.MultipartFile.fromBytes('fichier', octets, filename: nomFichier));
    final r = await http.Response.fromStream(
      await requete.send().timeout(const Duration(seconds: 120)),
    );
    if (r.statusCode != 200) throw _erreur(r, 'Import impossible');
    return RapportImport.fromJson(_objet(r));
  }

  // GET /stock/produits/modele/ : fichier Excel modèle.
  Future<List<int>> telechargerModele() async {
    final r = await http
        .get(Uri.parse('$_base/produits/modele/'),
            headers: await _headers(json: false))
        .timeout(_delai);
    if (r.statusCode != 200) throw _erreur(r, 'Téléchargement du modèle impossible');
    return r.bodyBytes;
  }
}
