/// Correspond au modèle backend PMEProfile (GET/PATCH /api/v1/profile/).
class ProfilFacturation {
  // En-tête
  final String nomCommercial;
  final String? logoUrl; // URL renvoyée par l'API
  final String? logoLocalPath; // fichier choisi, à envoyer en multipart
  final String telephonePro;
  final String? adresse;
  final String? nifRccm;

  // Pied de page
  final String moyensPaiement; // numéros Mobile Money, RIB...
  final String? conditionsDefaut; // ex. "Devis valable 30 jours"

  const ProfilFacturation({
    required this.nomCommercial,
    this.logoUrl,
    this.logoLocalPath,
    required this.telephonePro,
    this.adresse,
    this.nifRccm,
    required this.moyensPaiement,
    this.conditionsDefaut,
  });

  /// Suffisant pour créer un devis.
  bool get pretPourDevis =>
      nomCommercial.trim().isNotEmpty &&
          telephonePro.trim().isNotEmpty &&
          moyensPaiement.trim().isNotEmpty;

  /// Nécessaire pour convertir en facture (étape 4).
  bool get pretPourFacture =>
      pretPourDevis && (nifRccm ?? '').trim().isNotEmpty;

  factory ProfilFacturation.fromJson(Map<String, dynamic> json) =>
      ProfilFacturation(
        nomCommercial: json['nom_commercial'] as String? ?? '',
        logoUrl: json['logo'] as String?,
        telephonePro: json['telephone_pro'] as String? ?? '',
        adresse: json['adresse'] as String?,
        nifRccm: json['nif_rccm'] as String?,
        moyensPaiement: json['moyens_paiement'] as String? ?? '',
        conditionsDefaut: json['conditions_defaut'] as String?,
      );

  /// Champs texte uniquement ; le logo part à part en multipart
  /// (voir [logoLocalPath]).
  Map<String, dynamic> toJson() => {
    'nom_commercial': nomCommercial,
    'telephone_pro': telephonePro,
    'adresse': adresse,
    'nif_rccm': nifRccm,
    'moyens_paiement': moyensPaiement,
    'conditions_defaut': conditionsDefaut,
  };
}