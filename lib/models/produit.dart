/// Modèles du module Stock (produits, mouvements, résumé, rapport d'import).

double _nombre(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

enum StatutStock { ok, alerte, rupture }

StatutStock _statutDepuis(String? s) {
  switch (s) {
    case 'RUPTURE':
      return StatutStock.rupture;
    case 'ALERTE':
      return StatutStock.alerte;
    default:
      return StatutStock.ok;
  }
}

class Produit {
  final String id;
  final String nom;
  final String sku;
  final String unite;
  final double prixVente;
  final double coutMoyen;
  final double stockActuel;
  final double seuilAlerte;
  final double valeurStock;
  final bool actif;
  final StatutStock statut;

  const Produit({
    required this.id,
    required this.nom,
    required this.sku,
    required this.unite,
    required this.prixVente,
    required this.coutMoyen,
    required this.stockActuel,
    required this.seuilAlerte,
    required this.valeurStock,
    required this.actif,
    required this.statut,
  });

  factory Produit.fromJson(Map<String, dynamic> json) => Produit(
        id: '${json['id']}',
        nom: (json['nom'] ?? '').toString(),
        sku: (json['sku'] ?? '').toString(),
        unite: (json['unite'] ?? 'pièce').toString(),
        prixVente: _nombre(json['prix_vente']),
        coutMoyen: _nombre(json['cout_moyen']),
        stockActuel: _nombre(json['stock_actuel']),
        seuilAlerte: _nombre(json['seuil_alerte']),
        valeurStock: _nombre(json['valeur_stock']),
        actif: json['actif'] != false,
        statut: _statutDepuis(json['statut_stock']?.toString()),
      );
}

/// Libellés affichés pour les types et motifs de mouvement.
String libelleTypeMouvement(String type) {
  switch (type) {
    case 'ENTREE':
      return 'Entrée';
    case 'SORTIE':
      return 'Sortie';
    case 'AJUSTEMENT':
      return 'Inventaire';
    default:
      return type;
  }
}

String libelleMotif(String motif) {
  switch (motif) {
    case 'STOCK_INITIAL':
      return 'Stock initial';
    case 'ACHAT':
      return 'Achat';
    case 'RETOUR_CLIENT':
      return 'Retour client';
    case 'VENTE':
      return 'Vente';
    case 'RETOUR_FOURNISSEUR':
      return 'Retour fournisseur';
    case 'PERTE':
      return 'Perte';
    case 'CASSE':
      return 'Casse / péremption';
    case 'USAGE_INTERNE':
      return 'Usage interne';
    case 'INVENTAIRE':
      return 'Inventaire';
    default:
      return 'Autre';
  }
}

class MouvementStock {
  final String id;
  final String type;
  final String motif;
  final double variation;
  final double stockApres;
  final double? coutUnitaire;
  final String note;
  final String? utilisateurNom;
  final String unite;
  final DateTime date;

  const MouvementStock({
    required this.id,
    required this.type,
    required this.motif,
    required this.variation,
    required this.stockApres,
    required this.coutUnitaire,
    required this.note,
    required this.utilisateurNom,
    required this.unite,
    required this.date,
  });

  factory MouvementStock.fromJson(Map<String, dynamic> json) => MouvementStock(
        id: '${json['id']}',
        type: (json['type_mouvement'] ?? '').toString(),
        motif: (json['motif'] ?? '').toString(),
        variation: _nombre(json['variation']),
        stockApres: _nombre(json['stock_apres']),
        coutUnitaire:
            json['cout_unitaire'] == null ? null : _nombre(json['cout_unitaire']),
        note: (json['note'] ?? '').toString(),
        utilisateurNom: json['utilisateur_nom']?.toString(),
        unite: (json['unite'] ?? '').toString(),
        date: DateTime.tryParse('${json['date_mouvement']}')?.toLocal() ??
            DateTime.now(),
      );
}

class PageMouvements {
  final int total;
  final List<MouvementStock> mouvements;
  const PageMouvements(this.total, this.mouvements);
}

class ResumeStock {
  final int nombreProduits;
  final double valeurStock;
  final int nbRuptures;
  final int nbAlertes;

  const ResumeStock({
    required this.nombreProduits,
    required this.valeurStock,
    required this.nbRuptures,
    required this.nbAlertes,
  });

  factory ResumeStock.fromJson(Map<String, dynamic> json) => ResumeStock(
        nombreProduits: (json['nombre_produits'] as num?)?.toInt() ?? 0,
        valeurStock: _nombre(json['valeur_stock']),
        nbRuptures: (json['nb_ruptures'] as num?)?.toInt() ?? 0,
        nbAlertes: (json['nb_alertes'] as num?)?.toInt() ?? 0,
      );
}

class LigneImportIgnoree {
  final int ligne;
  final String nom;
  final String erreur;
  const LigneImportIgnoree(this.ligne, this.nom, this.erreur);
}

class RapportImport {
  final int totalLignes;
  final int crees;
  final List<LigneImportIgnoree> ignores;

  const RapportImport(this.totalLignes, this.crees, this.ignores);

  factory RapportImport.fromJson(Map<String, dynamic> json) => RapportImport(
        (json['total_lignes'] as num?)?.toInt() ?? 0,
        (json['crees'] as num?)?.toInt() ?? 0,
        ((json['ignores'] as List<dynamic>?) ?? []).map((e) {
          final m = e as Map<String, dynamic>;
          return LigneImportIgnoree(
            (m['ligne'] as num?)?.toInt() ?? 0,
            (m['nom'] ?? '').toString(),
            (m['erreur'] ?? '').toString(),
          );
        }).toList(),
      );
}
