import '../models/devis.dart';
import '../models/ligne_devis.dart';
import '../models/profil_facturation.dart';

/// Service MOCKÉ : tout est en mémoire.
/// Quand l'API sera prête, on ne remplace que le contenu de ces méthodes
/// (mêmes signatures) et les écrans ne changent pas.
///   getProfil / enregistrerProfil -> GET / PATCH /api/v1/profile/
///   listerDevis / enregistrerDevis -> GET / POST /api/v1/devis/
class DevisService {
  DevisService._();
  static final DevisService instance = DevisService._();

  ProfilFacturation? _profil;
  final List<Devis> _devis = [
    Devis(
      id: '1',
      numeroDevis: 'DEV-2026-001',
      clientNom: 'M. Kodjo',
      lignes: const [
        LigneDevis(designation: 'Sac de riz', quantite: 5, prixUnitaire: 22000),
      ],
      dateEmission: DateTime(2026, 9, 28),
      statut: StatutDevis.envoye,
    ),
    Devis(
      id: '2',
      numeroDevis: 'DEV-2026-002',
      clientNom: 'Ets SANOGO',
      lignes: const [
        LigneDevis(
            designation: 'Huile végétale (carton)',
            quantite: 10,
            prixUnitaire: 45000),
      ],
      dateEmission: DateTime(2026, 9, 25),
      statut: StatutDevis.accepte,
    ),
  ];

  Future<void> _latence() =>
      Future.delayed(const Duration(milliseconds: 400));

  // ---- Profil de facturation ----
  Future<ProfilFacturation?> getProfil() async {
    await _latence();
    return _profil;
  }

  Future<void> enregistrerProfil(ProfilFacturation profil) async {
    await _latence();
    _profil = profil;
  }

  // ---- Devis ----
  Future<List<Devis>> listerDevis() async {
    await _latence();
    final copie = [..._devis]
      ..sort((a, b) => b.dateEmission.compareTo(a.dateEmission));
    return copie;
  }

  /// Le numéro sera généré par le backend ; ici on simule.
  Future<Devis> enregistrerDevis(Devis devis) async {
    await _latence();
    final n = (_devis.length + 1).toString().padLeft(3, '0');
    final nouveau = devis.copyWith(
      id: '${_devis.length + 1}',
      numeroDevis: 'DEV-${devis.dateEmission.year}-$n',
    );
    _devis.add(nouveau);
    return nouveau;
  }

  /// Supprime un devis, quel que soit son statut.
  /// TODO backend : -> DELETE /api/v1/devis/{id}/
  Future<void> supprimerDevis(String id) async {
    await _latence();
    final existait = _devis.any((d) => d.id == id);
    if (!existait) throw Exception('Devis introuvable');
    _devis.removeWhere((d) => d.id == id);
  }

  Future<Devis> changerStatut(String id, StatutDevis statut) async {
    await _latence();
    final i = _devis.indexWhere((d) => d.id == id);
    if (i == -1) throw Exception('Devis introuvable');
    _devis[i] = _devis[i].copyWith(statut: statut);
    return _devis[i];
  }

  /// Simule l'agent : texte -> BROUILLON de devis (non enregistré).
  ///
  /// ⚠️ MOCK amélioré : contrairement à un vrai agent IA, ceci reste une
  /// simple extraction par motif de texte (regex), pas une compréhension
  /// du langage. Elle reconnaît un format proche de :
  ///   "Devis pour M. Kodjo : 5 sacs de riz à 22000, 2 tables à 15000"
  /// Si le texte ne correspond à aucun motif reconnu, un brouillon vide
  /// (une ligne à corriger) est renvoyé plutôt qu'un devis fixe — pour que
  /// l'utilisateur voie clairement qu'il doit corriger, au lieu de croire
  /// que son texte a été ignoré.
  ///
  /// TODO backend/IA : remplacer entièrement par l'appel à l'agent réel
  /// (femi_agent), qui fera une vraie compréhension du texte dicté.
  Future<Devis> genererDevisDepuisTexte(String texte) async {
    await Future.delayed(const Duration(milliseconds: 900));
    return _extraireDevis(texte);
  }

  Devis _extraireDevis(String texte) {
    final clientNom = _extraireClient(texte) ?? 'Nouveau client';
    final lignes = _extraireLignes(texte);

    return Devis(
      clientNom: clientNom,
      lignes: lignes.isNotEmpty
          ? lignes
          : const [LigneDevis(designation: 'Article', quantite: 1, prixUnitaire: 0)],
      dateEmission: DateTime.now(),
    );
  }

  /// Cherche "pour <nom> :". Ne s'arrête pas sur un simple point
  /// d'abréviation (ex. "M." dans "pour M. Kodjo :"), seulement sur le ':'.
  String? _extraireClient(String texte) {
    final match = RegExp(
      r'pour\s+(.+?)\s*:',
      caseSensitive: false,
    ).firstMatch(texte);
    final nom = match?.group(1)?.trim();
    return (nom == null || nom.isEmpty) ? null : nom;
  }

  /// Cherche des motifs "<quantité> <désignation> à <prix>", séparés par
  /// une virgule ou " et ". La désignation s'arrête avant "à"/"a"/"@".
  List<LigneDevis> _extraireLignes(String texte) {
    final regexLigne = RegExp(
      r"(\d+(?:[.,]\d+)?)\s+([a-zA-ZÀ-ÿ'\s]+?)\s*(?:à|a|@)\s*(\d[\d\s]*)",
      caseSensitive: false,
    );

    final lignes = <LigneDevis>[];
    for (final m in regexLigne.allMatches(texte)) {
      final quantite = double.tryParse(m.group(1)!.replaceAll(',', '.'));
      final designation = m.group(2)!.trim();
      final prix = double.tryParse(m.group(3)!.replaceAll(' ', ''));
      if (quantite != null && prix != null && designation.isNotEmpty) {
        lignes.add(LigneDevis(
          designation: designation,
          quantite: quantite,
          prixUnitaire: prix,
        ));
      }
    }
    return lignes;
  }
}