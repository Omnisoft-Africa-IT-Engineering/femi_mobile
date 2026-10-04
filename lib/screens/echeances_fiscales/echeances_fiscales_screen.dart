import 'package:flutter/material.dart';
import '../../services/femi_api_service.dart';

/// Écran listant les échéances fiscales de l'entreprise, avec filtres par
/// statut et une action "Marquer payé" par ligne.
///
/// Suit les mêmes conventions visuelles que RegistreJournalierScreen
/// (fond F8F9FE, vert primaire 006654) pour rester cohérent avec le
/// reste de la section "Compte".
class EcheancesFiscalesScreen extends StatefulWidget {
  const EcheancesFiscalesScreen({super.key});

  @override
  State<EcheancesFiscalesScreen> createState() => _EcheancesFiscalesScreenState();
}

/// Filtre appliqué à la liste. "urgent" regroupe RAPPELE + EN_RETARD,
/// pour retrouver rapidement ce qui demande une action.
enum _FiltreStatut { tous, urgent, enAttente, payees }

class _EcheancesFiscalesScreenState extends State<EcheancesFiscalesScreen> {
  final FemiApiService _apiService = FemiApiService();

  late Future<List<dynamic>?> _echeancesFuture;
  _FiltreStatut _filtre = _FiltreStatut.tous;

  // id de l'échéance en cours de traitement (pour désactiver son bouton
  // pendant l'appel réseau et éviter un double-tap).
  String? _idEnCoursDeMaj;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  void _chargerDonnees() {
    _echeancesFuture = _apiService.getEcheancesFiscales();
  }

  Future<void> _rafraichir() async {
    setState(_chargerDonnees);
    await _echeancesFuture;
  }

  String _labelType(String? typeEcheance) {
    switch (typeEcheance) {
      case 'TVA':
        return 'TVA mensuelle';
      case 'TPU_ACOMPTE':
        return 'Acompte TPU / Patente';
      case 'LIASSE_ANNUELLE':
        return 'Liasse fiscale SYSCOHADA';
      case 'DAS':
        return 'Déclaration annuelle des salaires';
      case 'AUTRE':
        return 'Autre obligation OTR';
      default:
        return typeEcheance ?? 'Échéance';
    }
  }

  String _labelStatut(String? statut) {
    switch (statut) {
      case 'EN_ATTENTE':
        return 'En attente';
      case 'RAPPELE':
        return 'Rappel envoyé';
      case 'PAYE':
        return 'Payé';
      case 'EN_RETARD':
        return 'En retard';
      default:
        return statut ?? '';
    }
  }

  Color _couleurStatut(String? statut) {
    switch (statut) {
      case 'PAYE':
        return const Color(0xFF059669);
      case 'EN_RETARD':
        return const Color(0xFFDC2626);
      case 'RAPPELE':
        return const Color(0xFFEA580C);
      case 'EN_ATTENTE':
      default:
        return const Color(0xFF64748B);
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '';
    DateTime? date;
    try {
      date = DateTime.parse(isoDate);
    } catch (_) {
      return isoDate;
    }
    const mois = [
      'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'
    ];
    return '${date.day} ${mois[date.month - 1]} ${date.year}';
  }

  List<dynamic> _appliquerFiltre(List<dynamic> echeances) {
    switch (_filtre) {
      case _FiltreStatut.urgent:
        return echeances
            .where((e) => e['statut'] == 'RAPPELE' || e['statut'] == 'EN_RETARD')
            .toList();
      case _FiltreStatut.enAttente:
        return echeances.where((e) => e['statut'] == 'EN_ATTENTE').toList();
      case _FiltreStatut.payees:
        return echeances.where((e) => e['statut'] == 'PAYE').toList();
      case _FiltreStatut.tous:
        return echeances;
    }
  }

  Future<void> _confirmerEtMarquerPaye(Map<String, dynamic> echeance) async {
    final String id = echeance['id'].toString();
    final String libelle = (echeance['libelle'] ?? '').toString();

    final bool? confirme = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Marquer comme payé'),
        content: Text('Confirmer le paiement de "$libelle" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006654)),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirmer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    setState(() => _idEnCoursDeMaj = id);

    final bool succes = await _apiService.marquerEcheancePayee(id);

    if (!mounted) return;

    setState(() => _idEnCoursDeMaj = null);

    if (succes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échéance marquée comme payée.')),
      );
      await _rafraichir();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Échec de la mise à jour. Réessayez.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Échéances fiscales',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _rafraichir,
          child: FutureBuilder<List<dynamic>?>(
            future: _echeancesFuture,
            builder: (context, snapshot) {
              final bool chargement = snapshot.connectionState == ConnectionState.waiting;

              if (!chargement && snapshot.data == null) {
                return _buildErreur();
              }

              final List<dynamic> toutes = snapshot.data ?? [];
              final List<dynamic> filtrees = _appliquerFiltre(toutes);

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                children: [
                  _buildFiltres(toutes),
                  const SizedBox(height: 16),
                  if (chargement)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (filtrees.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'Aucune échéance dans cette catégorie.',
                          style: TextStyle(color: Colors.black45),
                        ),
                      ),
                    )
                  else
                    ...filtrees.map((brute) {
                      final echeance = brute as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildEcheanceCard(echeance),
                      );
                    }),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildErreur() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            const Text('Impossible de charger les échéances fiscales.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _rafraichir,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006654)),
              child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltres(List<dynamic> toutes) {
    final int nbUrgent = toutes
        .where((e) => e['statut'] == 'RAPPELE' || e['statut'] == 'EN_RETARD')
        .length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chipFiltre('Tous', _FiltreStatut.tous),
          const SizedBox(width: 8),
          _chipFiltre(nbUrgent > 0 ? 'Urgent ($nbUrgent)' : 'Urgent', _FiltreStatut.urgent),
          const SizedBox(width: 8),
          _chipFiltre('En attente', _FiltreStatut.enAttente),
          const SizedBox(width: 8),
          _chipFiltre('Payées', _FiltreStatut.payees),
        ],
      ),
    );
  }

  Widget _chipFiltre(String label, _FiltreStatut valeur) {
    final bool selectionne = _filtre == valeur;
    return ChoiceChip(
      label: Text(label),
      selected: selectionne,
      onSelected: (_) => setState(() => _filtre = valeur),
      selectedColor: const Color(0xFF006654),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selectionne ? Colors.white : const Color(0xFF0F172A),
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      side: BorderSide(color: selectionne ? const Color(0xFF006654) : const Color(0xFFE2E8F0)),
    );
  }

  Widget _buildEcheanceCard(Map<String, dynamic> echeance) {
    final String? statut = echeance['statut'] as String?;
    final bool estPayee = statut == 'PAYE';
    final bool enCoursDeMaj = _idEnCoursDeMaj == echeance['id'].toString();
    final Color couleur = _couleurStatut(statut);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _labelType(echeance['type_echeance'] as String?),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: couleur.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _labelStatut(statut),
                  style: TextStyle(fontSize: 11, color: couleur, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            (echeance['libelle'] ?? '').toString(),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.event_outlined, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                'Échéance : ${_formatDate(echeance['date_echeance'] as String?)}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
          if (!estPayee) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: enCoursDeMaj ? null : () => _confirmerEtMarquerPaye(echeance),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF006654)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: enCoursDeMaj
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF006654)),
                label: Text(
                  enCoursDeMaj ? 'Mise à jour...' : 'Marquer payé',
                  style: const TextStyle(color: Color(0xFF006654), fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}