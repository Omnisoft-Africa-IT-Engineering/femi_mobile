import 'package:flutter/material.dart';

import '../../models/produit.dart';
import '../../services/stock_service.dart';
import '../../theme/app_colors.dart';

/// Fiche de création / modification d'un produit.
/// Renvoie `true` si le produit a été enregistré.
Future<bool?> showProduitFormSheet(BuildContext context, {Produit? produit}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ProduitForm(produit: produit),
  );
}

class _ProduitForm extends StatefulWidget {
  final Produit? produit;
  const _ProduitForm({this.produit});

  @override
  State<_ProduitForm> createState() => _ProduitFormState();
}

class _ProduitFormState extends State<_ProduitForm> {
  final _service = StockService.instance;
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nom;
  late final TextEditingController _unite;
  late final TextEditingController _prixVente;
  late final TextEditingController _seuil;
  late final TextEditingController _sku;
  final _stockInitial = TextEditingController();
  final _coutInitial = TextEditingController();

  bool _enCours = false;

  bool get _creation => widget.produit == null;

  @override
  void initState() {
    super.initState();
    final p = widget.produit;
    _nom = TextEditingController(text: p?.nom ?? '');
    _unite = TextEditingController(text: p?.unite ?? 'pièce');
    _prixVente = TextEditingController(
        text: p == null || p.prixVente == 0 ? '' : _texte(p.prixVente));
    _seuil = TextEditingController(
        text: p == null || p.seuilAlerte == 0 ? '' : _texte(p.seuilAlerte));
    _sku = TextEditingController(text: p?.sku ?? '');
  }

  @override
  void dispose() {
    for (final c in [_nom, _unite, _prixVente, _seuil, _sku, _stockInitial, _coutInitial]) {
      c.dispose();
    }
    super.dispose();
  }

  String _texte(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();

  /// "1 500,5" -> 1500.5 ; vide -> null ; illisible -> NaN
  double? _lire(String t) {
    final propre = t.replaceAll(RegExp(r'\s'), '').replaceAll(',', '.');
    if (propre.isEmpty) return null;
    return double.tryParse(propre) ?? double.nan;
  }

  String? _validerNombre(String? t) {
    final v = _lire(t ?? '');
    if (v == null) return null;
    if (v.isNaN || v < 0) return 'Nombre invalide';
    return null;
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enCours = true);
    try {
      if (_creation) {
        await _service.creerProduit(
          nom: _nom.text.trim(),
          unite: _unite.text.trim(),
          prixVente: _lire(_prixVente.text),
          seuilAlerte: _lire(_seuil.text),
          sku: _sku.text.trim(),
          stockInitial: _lire(_stockInitial.text),
          coutInitial: _lire(_coutInitial.text),
        );
      } else {
        await _service.modifierProduit(widget.produit!.id, {
          'nom': _nom.text.trim(),
          'unite': _unite.text.trim(),
          'prix_vente': _lire(_prixVente.text) ?? 0,
          'seuil_alerte': _lire(_seuil.text) ?? 0,
          'sku': _sku.text.trim(),
        });
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _enCours = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  InputDecoration _deco(String label, {String? aide, String? suffixe}) =>
      InputDecoration(
        labelText: label,
        helperText: aide,
        suffixText: suffixe,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  @override
  Widget build(BuildContext context) {
    const nombre = TextInputType.numberWithOptions(decimal: true);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _creation ? 'Nouveau produit' : 'Modifier le produit',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.encre),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nom,
                textCapitalization: TextCapitalization.sentences,
                decoration: _deco('Nom du produit *'),
                validator: (t) =>
                    (t == null || t.trim().isEmpty) ? 'Le nom est obligatoire' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _unite,
                      decoration: _deco('Unité', aide: 'sac, pièce, kg…'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _prixVente,
                      keyboardType: nombre,
                      decoration: _deco('Prix de vente', suffixe: 'FCFA'),
                      validator: _validerNombre,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _seuil,
                      keyboardType: nombre,
                      decoration: _deco("Seuil d'alerte", aide: 'Alerte à ce niveau'),
                      validator: _validerNombre,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _sku,
                      decoration: _deco('Code article', aide: 'Facultatif'),
                    ),
                  ),
                ],
              ),
              if (_creation) ...[
                const SizedBox(height: 20),
                const Text(
                  'Stock de départ',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.encre),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ce que vous avez réellement en stock aujourd\'hui.',
                  style: TextStyle(color: AppColors.ardoise, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockInitial,
                        keyboardType: nombre,
                        decoration: _deco('Quantité'),
                        validator: _validerNombre,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _coutInitial,
                        keyboardType: nombre,
                        decoration: _deco("Prix d'achat unitaire", suffixe: 'FCFA'),
                        validator: _validerNombre,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _enCours ? null : _enregistrer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.vert,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _enCours
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Enregistrer',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
