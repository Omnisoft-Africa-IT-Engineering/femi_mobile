import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/produit.dart';
import '../../models/team_models.dart';
import '../../services/stock_service.dart';
import '../../states/auth_state.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/statut_stock_badge.dart';
import 'import_produits_screen.dart';
import 'produit_detail_screen.dart';
import 'produit_form_sheet.dart';

class _DonneesStock {
  final ResumeStock resume;
  final List<Produit> produits;
  _DonneesStock(this.resume, this.produits);
}

/// Écran principal du stock : chiffres clés, recherche, filtres et liste.
class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final _service = StockService.instance;
  final _recherche = TextEditingController();
  Timer? _debounce;

  String _statut = ''; // '' = tous, 'ALERTE', 'RUPTURE'
  bool _archives = false;
  late Future<_DonneesStock> _futur;

  bool get _estEmploye => AuthState.instance.role.value == UserRole.employe;

  @override
  void initState() {
    super.initState();
    _futur = _charger();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _recherche.dispose();
    super.dispose();
  }

  Future<_DonneesStock> _charger() async {
    final r = await Future.wait<Object>([
      _service.resume(),
      _service.listerProduits(
        recherche: _recherche.text.trim(),
        statut: _statut,
        archives: _archives,
      ),
    ]);
    return _DonneesStock(r[0] as ResumeStock, r[1] as List<Produit>);
  }

  void _recharger() {
    setState(() => _futur = _charger());
  }

  void _surRecherche(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _recharger);
  }

  void _filtrer(String statut) {
    _statut = _statut == statut ? '' : statut;
    _recharger();
  }

  Future<void> _nouveauProduit() async {
    final ok = await showProduitFormSheet(context);
    if (ok == true && mounted) _recharger();
  }

  Future<void> _importer() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ImportProduitsScreen()),
    );
    if (mounted) _recharger();
  }

  Future<void> _ouvrirProduit(Produit p) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProduitDetailScreen(produit: p)),
    );
    if (mounted) _recharger();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondEcran,
      appBar: AppBar(
        title: const Text('Stock'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'import') _importer();
              if (v == 'archives') {
                _archives = !_archives;
                _recharger();
              }
            },
            itemBuilder: (_) => [
              if (!_estEmploye)
                const PopupMenuItem(
                  value: 'import',
                  child: Text('Importer depuis Excel'),
                ),
              CheckedPopupMenuItem(
                value: 'archives',
                checked: _archives,
                child: const Text('Produits archivés'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: _estEmploye
          ? null
          : FloatingActionButton.extended(
              onPressed: _nouveauProduit,
              backgroundColor: AppColors.vert,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Produit'),
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _recherche,
              onChanged: _surRecherche,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Rechercher un produit ou un code',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.bordure),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.bordure),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Stock bas'),
                  selected: _statut == 'ALERTE',
                  onSelected: (_) => _filtrer('ALERTE'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Ruptures'),
                  selected: _statut == 'RUPTURE',
                  onSelected: (_) => _filtrer('RUPTURE'),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<_DonneesStock>(
              future: _futur,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) return _erreur(snap.error);
                final d = snap.data!;
                return RefreshIndicator(
                  onRefresh: () async {
                    _recharger();
                    await _futur;
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    children: [
                      _resume(d.resume),
                      const SizedBox(height: 12),
                      if (d.produits.isEmpty) _vide() else ...d.produits.map(_tuile),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _erreur(Object? e) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 40, color: AppColors.gris),
            const SizedBox(height: 12),
            Text(
              e.toString().replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.ardoise),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _recharger, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }

  Widget _vide() {
    final filtre = _statut.isNotEmpty ||
        _recherche.text.trim().isNotEmpty ||
        _archives;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.gris),
          const SizedBox(height: 12),
          Text(
            filtre ? 'Aucun produit trouvé' : 'Aucun produit pour le moment',
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: AppColors.encre),
          ),
          if (!filtre && !_estEmploye) ...[
            const SizedBox(height: 6),
            const Text(
              'Ajoutez vos produits un par un ou importez un fichier Excel.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.ardoise),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _importer,
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Importer depuis Excel'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _resume(ResumeStock r) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _carte('Produits', '${r.nombreProduits}',
                  Icons.inventory_2_outlined, AppColors.vert),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _carte('Valeur du stock', formatFcfa(r.valeurStock),
                  Icons.payments_outlined, AppColors.vert),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _carte('Stock bas', '${r.nbAlertes}',
                  Icons.warning_amber_rounded, couleurStatutStock(StatutStock.alerte),
                  onTap: () => _filtrer('ALERTE')),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _carte('Ruptures', '${r.nbRuptures}',
                  Icons.remove_shopping_cart_outlined,
                  couleurStatutStock(StatutStock.rupture),
                  onTap: () => _filtrer('RUPTURE')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _carte(String titre, String valeur, IconData icone, Color couleur,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.bordure),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: couleur.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icone, color: couleur, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.ardoise)),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(valeur,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.encre)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tuile(Produit p) {
    final couleur = couleurStatutStock(p.statut);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.bordure),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _ouvrirProduit(p),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.nom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.encre),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.prixVente > 0
                          ? 'Prix de vente : ${formatFcfa(p.prixVente)}'
                          : 'Prix de vente non renseigné',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.ardoise),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${formatQuantite(p.stockActuel)} ${p.unite}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: couleur),
                  ),
                  const SizedBox(height: 4),
                  if (p.statut != StatutStock.ok)
                    StatutStockBadge(statut: p.statut),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
