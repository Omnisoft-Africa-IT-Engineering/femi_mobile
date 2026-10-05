import 'ligne_devis.dart';

/// `refuse` n'existe pas encore côté backend (BROUILLON, ENVOYE, ACCEPTE,
/// CONVERTI) : à faire ajouter ou à retirer.
enum StatutDevis { brouillon, envoye, accepte, refuse, converti }

extension StatutDevisX on StatutDevis {
  String get label {
    switch (this) {
      case StatutDevis.brouillon:
        return 'Brouillon';
      case StatutDevis.envoye:
        return 'Envoyé';
      case StatutDevis.accepte:
        return 'Accepté';
      case StatutDevis.refuse:
        return 'Refusé';
      case StatutDevis.converti:
        return 'Converti en facture';
    }
  }

  /// Valeur échangée avec l'API : BROUILLON, ENVOYE, ACCEPTE, CONVERTI...
  String get apiValue => name.toUpperCase();

  static StatutDevis fromApi(String? v) => StatutDevis.values.firstWhere(
        (s) => s.apiValue == (v ?? '').toUpperCase(),
    orElse: () => StatutDevis.brouillon,
  );
}

class Devis {
  final String? id;
  final String? numeroDevis; // ex. DEV-2026-001, généré par le backend
  final String clientNom;
  final String? clientTelephone;
  final List<LigneDevis> lignes;
  final DateTime dateEmission;
  final StatutDevis statut;

  /// TODO backend : la TVA n'existe pas encore dans leur modèle.
  /// Gardée localement (0 = non assujetti), non envoyée à l'API.
  final double tvaTaux;

  const Devis({
    this.id,
    this.numeroDevis,
    required this.clientNom,
    this.clientTelephone,
    required this.lignes,
    required this.dateEmission,
    this.statut = StatutDevis.brouillon,
    this.tvaTaux = 0,
  });

  double get sousTotal => lignes.fold(0, (sum, l) => sum + l.totalLigne);
  double get montantTva => sousTotal * tvaTaux;
  double get total => sousTotal + montantTva;

  /// Un devis converti (ou refusé) ne doit plus être modifié.
  bool get estModifiable =>
      statut == StatutDevis.brouillon || statut == StatutDevis.envoye;

  Devis copyWith({
    String? id,
    String? numeroDevis,
    String? clientNom,
    String? clientTelephone,
    List<LigneDevis>? lignes,
    DateTime? dateEmission,
    StatutDevis? statut,
    double? tvaTaux,
  }) =>
      Devis(
        id: id ?? this.id,
        numeroDevis: numeroDevis ?? this.numeroDevis,
        clientNom: clientNom ?? this.clientNom,
        clientTelephone: clientTelephone ?? this.clientTelephone,
        lignes: lignes ?? this.lignes,
        dateEmission: dateEmission ?? this.dateEmission,
        statut: statut ?? this.statut,
        tvaTaux: tvaTaux ?? this.tvaTaux,
      );

  factory Devis.fromJson(Map<String, dynamic> json) => Devis(
    id: json['id']?.toString(),
    numeroDevis: json['numero_devis'] as String?,
    clientNom: json['client_nom'] as String? ?? '',
    clientTelephone: json['client_telephone'] as String?,
    lignes: ((json['lignes'] as List?) ?? [])
        .map((e) => LigneDevis.fromJson(e as Map<String, dynamic>))
        .toList(),
    dateEmission:
    DateTime.tryParse(json['date_emission'] as String? ?? '') ??
        DateTime.now(),
    statut: StatutDevisX.fromApi(json['statut'] as String?),
  );

  /// `numero_devis` et `montant_total` sont gérés par le backend.
  /// Format de date envoyé : AAAA-MM-JJ (à confirmer avec le backend).
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'client_nom': clientNom,
    'client_telephone': clientTelephone,
    'lignes': lignes.map((l) => l.toJson()).toList(),
    'date_emission': dateEmission.toIso8601String().substring(0, 10),
    'statut': statut.apiValue,
  };
}