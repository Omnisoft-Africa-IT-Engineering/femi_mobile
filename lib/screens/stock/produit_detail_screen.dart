import 'package:flutter/material.dart';

import '../../models/produit.dart';
import '../../models/team_models.dart';
import '../../services/stock_service.dart';
import '../../states/auth_state.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/statut_stock_badge.dart';
import 'mouvement_sheet.dart';
import 'produit_form_sheet.dart';

/// Fiche d'un produit : situation du stock, actions et historique.
class ProduitDetailScreen extends StatefulWidget {
  final Produit produit;
  const ProduitDetailScreen({super.key, required this.produit});

  @override
  State<ProduitDetailScreen> createState() => _ProduitDetailScreenState();
}

class _ProduitDetailScreenState extends State<ProduitDetailScreen> {
  static const _taillePage = 50;

  final _service = StockService.instance;
  late Produit _produit;
  final List<MouvementStock> _mouvements = [];
  int _total = 0;
  bool _chargement = true;
  bool _chargementPlus = false;
  String? _erreur;

  bool get _estEmploye => AuthState.instance.role.value == UserRole.employe;

  @override
  void initState() {
    super.initState();
    _produit = widget.produit;
    _chargerHistorique(reset: true);
  }

  Future<void> _chargerHistorique({bool reset = false}) async {
    if (reset) {
      setState(() {
        _chargement = true;
        _erreur = null;
      });
    } else {
      setState(() => _chargementPlus = true);
    }
    try {
      final page = await _service.listerMouvements(
        produitId: _produit.id,
        limit: _taillePage,
        offset: reset ? 0 : _mouvements.length,
      );
      if (!mounted) return;
      setState(() {
        if (reset) _mouvements.clear();
        _mouvements.addAll(page.mouvements);
        _total = page.total;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _erreur = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _chargement = false;
          _chargementPlus = false;
        });
      }
    }
  }

  Future<void> _mouvement(String type) async {
    final maj = await showMouvementSheet(context, produit: _produit, type: type);
    if (maj == null || !mounted) return;
    setState(() => _produit = maj);
    _chargerHistorique(reset: true);
  }

  Future<void> _modifier() async {
    final ok = await showProduitFormSheet(context, produit: _produit);
    if (ok != true || !mounted) return;
    try {
      final maj = await _service.getProduit(_produit.id);
      if (mounted) setState(() => _produit = maj);
    } catch (_) {}
  }

  Future<void> _changerArchivage() async {
    final archiver = _produit.actif;
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(archiver ? 'Archiver ce produit ?' : 'Réactiver ce produit ?'),
        content: Text(archiver
            ? 'Il n\'apparaîtra plus dans la liste ni dans les ventes. '
                'Son historique est conservé et vous pourrez le réactiver.'
            : 'Il réapparaîtra dans la liste du stock.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(archiver ? 'Archiver' : 'Réactiver')),
        ],
      ),
    );
    if (confirme != true || !mounted) return;
    try {
      final maj = await _service.modifierProduit(_produit.id, {'actif': !archiver});
      if (!mounted) return;
      if (archiver) {
        Navigator.pop(context);
      } else {
        setState(() => _produit = maj);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _produit;
    return Scaffold(
      backgroundColor: AppColors.fondEcran,
      appBar: AppBar(
        title: Text(p.nom, overflow: TextOverflow.ellipsis),
        actions: [
          if (!_estEmploye)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'modifier') _modifier();
                if (v == 'archivage') _changerArchivage();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'modifier', child: Text('Modifier')),
                PopupMenuItem(
                  value: 'archivage',
                  child: Text(p.actif ? 'Archiver' : 'Réactiver'),
                ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _chargerHistorique(reset: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (!p.actif)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.fondGris,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Produit archivé : aucun mouvement possible.',
                    style: TextStyle(color: AppColors.ardoiseFoncee)),
              ),
            _entete(p),
            const SizedBox(height: 14),
            if (p.actif) _actions(),
            const SizedBox(height: 20),
            const Text('Historique',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.encre)),
            const SizedBox(height: 8),
            ..._historique(),
          ],
        ),
      ),
    );
  }

  Widget _entete(Produit p) {
    final couleur = couleurStatutStock(p.statut);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bordure),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Stock actuel',
                  style: TextStyle(color: AppColors.ardoise)),
              StatutStockBadge(statut: p.statut),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${formatQuantite(p.stockActuel)} ${p.unite}',
            style: TextStyle(
                fontSize: 30, fontWeight: FontWeight.bold, color: couleur),
          ),
          const Divider(height: 24),
          _ligne('Prix de vente', p.prixVente > 0 ? formatFcfa(p.prixVente) : '—'),
          _ligne('Coût moyen', p.coutMoyen > 0 ? formatFcfa(p.coutMoyen) : '—'),
          _ligne('Valeur du stock', formatFcfa(p.valeurStock)),
          _ligne('Seuil d\'alerte',
              p.seuilAlerte > 0 ? '${formatQuantite(p.seuilAlerte)} ${p.unite}' : 'Aucun'),
          if (p.sku.isNotEmpty) _ligne('Code article', p.sku),
        ],
      ),
    );
  }

  Widget _ligne(String libelle, String valeur) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(libelle, style: const TextStyle(color: AppColors.ardoise)),
          Text(valeur,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.encre)),
        ],
      ),
    );
  }

  Widget _actions() {
    Widget bouton(String texte, IconData icone, String type) => Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _mouvement(type),
            icon: Icon(icone, size: 18),
            label: Text(texte),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.vert,
              side: const BorderSide(color: AppColors.vert),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        );

    if (_estEmploye) {
      return Row(children: [bouton('Enregistrer une vente', Icons.remove_circle_outline, 'SORTIE')]);
    }
    return Row(
      children: [
        bouton('Entrée', Icons.add_circle_outline, 'ENTREE'),
        const SizedBox(width: 8),
        bouton('Sortie', Icons.remove_circle_outline, 'SORTIE'),
        const SizedBox(width: 8),
        bouton('Inventaire', Icons.fact_check_outlined, 'AJUSTEMENT'),
      ],
    );
  }

  List<Widget> _historique() {
    if (_chargement) {
      return const [
        Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_erreur != null) {
      return [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(_erreur!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.ardoise)),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => _chargerHistorique(reset: true),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ];
    }
    if (_mouvements.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text('Aucun mouvement pour le moment.',
              style: TextStyle(color: AppColors.ardoise)),
        ),
      ];
    }
    return [
      ..._mouvements.map(_tuileMouvement),
      if (_mouvements.length < _total)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Center(
            child: _chargementPlus
                ? const CircularProgressIndicator()
                : TextButton(
                    onPressed: () => _chargerHistorique(),
                    child: const Text('Voir plus'),
                  ),
          ),
        ),
    ];
  }

  Widget _tuileMouvement(MouvementStock m) {
    final entree = m.variation > 0;
    final couleur = entree ? AppColors.vert : const Color(0xFFDC2626);
    final details = [
      formatDateHeure(m.date),
      if (m.utilisateurNom != null && m.utilisateurNom!.isNotEmpty) m.utilisateurNom!,
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.bordure),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: couleur.withValues(alpha: 0.12),
              child: Icon(
                entree ? Icons.arrow_downward : Icons.arrow_upward,
                color: couleur,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${libelleTypeMouvement(m.type)} · ${libelleMotif(m.motif)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.encre),
                  ),
                  const SizedBox(height: 2),
                  Text(details,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.ardoise)),
                  if (m.note.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(m.note,
                          style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: AppColors.ardoiseFoncee)),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entree ? '+' : ''}${formatQuantite(m.variation)}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15, color: couleur),
                ),
                Text('Stock : ${formatQuantite(m.stockApres)}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.ardoise)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
