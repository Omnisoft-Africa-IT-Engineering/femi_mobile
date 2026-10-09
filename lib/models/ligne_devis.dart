/// Convertit une valeur JSON (num ou String, ex. Decimal DRF) en double.
double toDouble(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

class LigneDevis {
  final String designation;
  final double quantite;
  final double prixUnitaire;

  const LigneDevis({
    required this.designation,
    required this.quantite,
    required this.prixUnitaire,
  });

  /// Équivalent de `total_ligne` côté backend (recalculé localement).
  double get totalLigne => quantite * prixUnitaire;

  LigneDevis copyWith({
    String? designation,
    double? quantite,
    double? prixUnitaire,
  }) =>
      LigneDevis(
        designation: designation ?? this.designation,
        quantite: quantite ?? this.quantite,
        prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      );

  factory LigneDevis.fromJson(Map<String, dynamic> json) => LigneDevis(
    designation: json['designation'] as String? ?? '',
    quantite: toDouble(json['quantite']),
    prixUnitaire: toDouble(json['prix_unitaire']),
  );

  /// `total_ligne` n'est pas envoyé : le backend le calcule.
  Map<String, dynamic> toJson() => {
    'designation': designation,
    'quantite': quantite,
    'prix_unitaire': prixUnitaire,
  };
}