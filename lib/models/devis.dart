import 'ligne_devis.dart';

/// Statuts API : BROUILLON | VALIDE | FACTURE | ANNULE
enum StatutDevis { brouillon, valide, facture, annule }

extension StatutDevisX on StatutDevis {
  String get label {
    switch (this) {
      case StatutDevis.brouillon:
        return 'Brouillon';
      case StatutDevis.valide:
        return 'Validé';
      case StatutDevis.facture:
        return 'Facturé';
      case StatutDevis.annule:
        return 'Annulé';
    }
  }

  /// Valeur exacte pour l'API.
  String get apiValue {
    switch (this) {
      case StatutDevis.brouillon:
        return 'BROUILLON';
      case StatutDevis.valide:
        return 'VALIDE';
      case StatutDevis.facture:
        return 'FACTURE';
      case StatutDevis.annule:
        return 'ANNULE';
    }
  }

  static StatutDevis fromApi(String? v) {
    switch ((v ?? '').toUpperCase().trim()) {
      case 'VALIDE':
      case 'ENVOYE': // rétrocompat si ancien backend
        return StatutDevis.valide;
      case 'FACTURE':
      case 'CONVERTI':
      case 'ACCEPTE':
        return StatutDevis.facture;
      case 'ANNULE':
      case 'REFUSE':
        return StatutDevis.annule;
      case 'BROUILLON':
      default:
        return StatutDevis.brouillon;
    }
  }

  /// Transitions autorisées par l'API.
  /// BROUILLON → VALIDE | ANNULE
  /// VALIDE → ANNULE
  /// FACTURE / ANNULE → aucune
  List<StatutDevis> get transitionsAutorisees {
    switch (this) {
      case StatutDevis.brouillon:
        return [StatutDevis.valide, StatutDevis.annule];
      case StatutDevis.valide:
        return [StatutDevis.annule];
      case StatutDevis.facture:
      case StatutDevis.annule:
        return [];
    }
  }
}

class Devis {
  final String? id;
  final String? numeroDevis; // reference API, ex. DEV-A1B2C3D4
  final String clientNom;
  final String? clientTelephone;
  final List<LigneDevis> lignes;
  final DateTime dateEmission;
  final DateTime? dateValidite;
  final StatutDevis statut;
  final double? montantTotalApi;

  /// Local uniquement (non envoyé à l'API pour l'instant).
  final double tvaTaux;

  const Devis({
    this.id,
    this.numeroDevis,
    required this.clientNom,
    this.clientTelephone,
    required this.lignes,
    required this.dateEmission,
    this.dateValidite,
    this.statut = StatutDevis.brouillon,
    this.montantTotalApi,
    this.tvaTaux = 0,
  });

  double get sousTotal => lignes.fold(0, (sum, l) => sum + l.totalLigne);

  double get montantTva => sousTotal * tvaTaux;

  double get total =>
      montantTotalApi ?? (sousTotal + montantTva);

  bool get estModifiable => statut == StatutDevis.brouillon;

  Devis copyWith({
    String? id,
    String? numeroDevis,
    String? clientNom,
    String? clientTelephone,
    List<LigneDevis>? lignes,
    DateTime? dateEmission,
    DateTime? dateValidite,
    StatutDevis? statut,
    double? montantTotalApi,
    double? tvaTaux,
  }) {
    return Devis(
      id: id ?? this.id,
      numeroDevis: numeroDevis ?? this.numeroDevis,
      clientNom: clientNom ?? this.clientNom,
      clientTelephone: clientTelephone ?? this.clientTelephone,
      lignes: lignes ?? this.lignes,
      dateEmission: dateEmission ?? this.dateEmission,
      dateValidite: dateValidite ?? this.dateValidite,
      statut: statut ?? this.statut,
      montantTotalApi: montantTotalApi ?? this.montantTotalApi,
      tvaTaux: tvaTaux ?? this.tvaTaux,
    );
  }

  factory Devis.fromJson(Map<String, dynamic> json) {
    final montantRaw = json['montant_total'];
    double? montantApi;
    if (montantRaw is num) {
      montantApi = montantRaw.toDouble();
    } else if (montantRaw != null) {
      montantApi = double.tryParse(montantRaw.toString());
    }

    return Devis(
      id: json['id']?.toString(),
      numeroDevis: (json['reference'] ?? json['numero_devis'])?.toString(),
      clientNom: json['client_nom']?.toString() ?? '',
      clientTelephone: json['client_telephone']?.toString(),
      lignes: ((json['lignes'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => LigneDevis.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      dateEmission: DateTime.tryParse(
            json['date_emission']?.toString() ?? '',
          ) ??
          DateTime.now(),
      dateValidite: DateTime.tryParse(
        json['date_validite']?.toString() ?? '',
      ),
      statut: StatutDevisX.fromApi(json['statut']?.toString()),
      montantTotalApi: montantApi,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'client_nom': clientNom,
        if (clientTelephone != null) 'client_telephone': clientTelephone,
        'lignes': lignes.map((l) => l.toJson()).toList(),
        if (dateValidite != null)
          'date_validite':
              dateValidite!.toIso8601String().substring(0, 10),
        'statut': statut.apiValue,
      };
}