import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'femi_api_service.dart';

/// Un KPI renvoyé par GET /api/v1/kpi/<niveau>/.
class KpiItem {
  final String nom;
  final String? icone;
  final String? unite;
  final bool disponible;
  final dynamic valeur;

  const KpiItem({
    required this.nom,
    required this.icone,
    required this.unite,
    required this.disponible,
    required this.valeur,
  });

  factory KpiItem.fromJson(Map<String, dynamic> json) {
    return KpiItem(
      nom: (json['nom'] ?? '').toString(),
      icone: json['icone']?.toString(),
      unite: json['unite']?.toString(),
      disponible: json['disponible'] == true,
      valeur: json['valeur'],
    );
  }

  /// Texte affiché sur la carte.
  String get valeurAffichee => KpiFormat.format(this);
}

/// Résultat du chargement d'un niveau : soit des KPI, soit un message d'erreur.
class KpiNiveauResult {
  final int numero;
  final String nom;
  final List<KpiItem> kpis;
  final String? erreur;

  const KpiNiveauResult({
    required this.numero,
    required this.nom,
    this.kpis = const [],
    this.erreur,
  });
}

class KpiFormat {
  static const String devise = 'FCFA';

  // KPI du catalogue exprimés en nombre (et non en montant).
  static const Set<String> _comptages = {
    'Clients',
    'Ventes',
    'Commandes',
    'Transactions',
    'Prestations',
    'Nombre de prestations',
    'Produits',
    'Ruptures de stock',
    'Alertes de stock',
  };

  static String montantCompact(num valeur) {
    final double v = valeur.toDouble();
    final double abs = v.abs();
    final String signe = v < 0 ? '-' : '';
    if (abs >= 1000000000) {
      return '$signe${(abs / 1000000000).toStringAsFixed(1)} B $devise';
    } else if (abs >= 1000000) {
      return '$signe${(abs / 1000000).toStringAsFixed(1)} M $devise';
    } else if (abs >= 1000) {
      return '$signe${(abs / 1000).toStringAsFixed(0)} k $devise';
    }
    return '$signe${abs.toStringAsFixed(0)} $devise';
  }

  static String format(KpiItem kpi) {
    if (!kpi.disponible) return 'Bientôt';
    final dynamic v = kpi.valeur;
    if (v == null) return '—';

    // Liste (ex. marge par prestation) : on affiche le nombre de lignes.
    if (v is List) {
      return v.isEmpty ? '—' : '${v.length} ligne${v.length > 1 ? 's' : ''}';
    }

    final num? n = v is num ? v : num.tryParse(v.toString());
    if (n == null) return v.toString();

    final String unite = (kpi.unite ?? '').trim();
    if (unite.contains('%') ||
        kpi.nom == 'Marge' ||
        kpi.nom == "Taux d'épargne") {
      return '${n.toDouble().toStringAsFixed(1)}%';
    }
    if (kpi.nom == 'Heures facturées') {
      return '${n.toDouble().toStringAsFixed(1)} h';
    }
    if (_comptages.contains(kpi.nom)) {
      return n.round().toString();
    }
    if (unite.isNotEmpty &&
        unite.toUpperCase() != 'FCFA' &&
        unite.toUpperCase() != 'XOF') {
      return '${n.toDouble().toStringAsFixed(0)} $unite';
    }
    return montantCompact(n);
  }
}

/// Appelle GET /api/v1/kpi/<niveau>/?period=... : le backend choisit lui-même
/// les KPI du secteur de l'entreprise (ou les KPI communs à défaut).
class KpiService {
  final FemiApiService _api = FemiApiService();

  Future<List<KpiNiveauResult>> getNiveaux(
    List<int> niveaux, {
    String period = 'this_month',
  }) {
    return Future.wait(niveaux.map((n) => getNiveau(n, period: period)));
  }

  Future<KpiNiveauResult> getNiveau(
    int numero, {
    String period = 'this_month',
  }) async {
    final String nomParDefaut = 'Niveau $numero';
    final String? token = await _api.getToken();
    if (token == null) {
      return KpiNiveauResult(
        numero: numero,
        nom: nomParDefaut,
        erreur: 'Session expirée, reconnecte-toi.',
      );
    }

    try {
      final response = await http
          .get(
            Uri.parse('${FemiApiService.baseUrl}/kpi/$numero/?period=$period'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Token $token',
            },
          )
          // Render (offre gratuite) peut mettre du temps à se réveiller.
          .timeout(const Duration(seconds: 60));

      Map<String, dynamic> corps = {};
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) corps = decoded;
      } catch (_) {}

      if (response.statusCode != 200) {
        final String detail =
            (corps['error'] ?? corps['detail'] ?? '').toString();
        debugPrint(
            'KPI niveau $numero : HTTP ${response.statusCode} $detail');
        return KpiNiveauResult(
          numero: numero,
          nom: nomParDefaut,
          erreur: detail.isNotEmpty
              ? detail
              : 'Erreur serveur (${response.statusCode}).',
        );
      }

      final Map<String, dynamic> niveau =
          (corps['niveau'] as Map<String, dynamic>?) ?? {};
      final List<dynamic> liste = (corps['kpis'] as List<dynamic>?) ?? [];

      return KpiNiveauResult(
        numero: numero,
        nom: (niveau['nom'] ?? nomParDefaut).toString(),
        kpis: liste
            .whereType<Map<String, dynamic>>()
            .map(KpiItem.fromJson)
            .toList(),
      );
    } on TimeoutException {
      return KpiNiveauResult(
        numero: numero,
        nom: nomParDefaut,
        erreur: 'Le serveur met trop de temps à répondre. Réessaie.',
      );
    } catch (e) {
      debugPrint('KPI niveau $numero : $e');
      return KpiNiveauResult(
        numero: numero,
        nom: nomParDefaut,
        erreur: 'Connexion impossible. Vérifie ton réseau.',
      );
    }
  }
}
