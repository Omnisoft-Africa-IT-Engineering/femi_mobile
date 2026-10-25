/// Convertit une valeur JSON (num ou String, ex. Decimal DRF) en double.
double toDouble(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

class LigneDevis {
  /// Identifiant serveur (null pour une ligne pas encore enregistrée).
  final int? id;
  final String designation;
  final double quantite;
  final double prixUnitaire;

  const LigneDevis({
    this.id,
    required this.designation,
    required this.quantite,
    required this.prixUnitaire,
  });

  /// Équivalent de `montant_total` côté backend (recalculé localement).
  double get totalLigne => quantite * prixUnitaire;

  LigneDevis copyWith({
    int? id,
    String? designation,
    double? quantite,
    double? prixUnitaire,
  }) =>
      LigneDevis(
        id: id ?? this.id,
        designation: designation ?? this.designation,
        quantite: quantite ?? this.quantite,
        prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      );

  /// Le backend nomme le champ `description` (on accepte aussi l'ancien
  /// nom `designation`).
  factory LigneDevis.fromJson(Map<String, dynamic> json) => LigneDevis(
    id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
    designation:
        (json['description'] ?? json['designation'])?.toString() ?? '',
    quantite: toDouble(json['quantite']),
    prixUnitaire: toDouble(json['prix_unitaire']),
  );

  /// Corps attendu par le backend ; `montant_total` n'est jamais envoyé.
  Map<String, dynamic> toJson() => {
    'description': designation,
    'quantite': quantite,
    'prix_unitaire': prixUnitaire,
  };
}