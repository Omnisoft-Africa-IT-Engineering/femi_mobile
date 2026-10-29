import 'package:flutter/material.dart';

import '../../models/produit.dart';
import '../../models/team_models.dart';
import '../../services/stock_service.dart';
import '../../states/auth_state.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';

/// Formulaire d'entrée, de sortie ou d'inventaire pour un produit.
/// [type] : 'ENTREE' | 'SORTIE' | 'AJUSTEMENT'.
/// Renvoie le produit mis à jour (ou null si l'utilisateur a annulé).
Future<Produit?> showMouvementSheet(
  BuildContext context, {
  required Produit produit,
  required String type,
}) {
  return showModalBottomSheet<Produit>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _MouvementForm(produit: produit, type: type),
  );
}

class _MouvementForm extends StatefulWidget {
  final Produit produit;
  final String type;
  const _MouvementForm({required this.produit, required this.type});

  @override
  State<_MouvementForm> createState() => _MouvementFormState();
}

class _MouvementFormState extends State<_MouvementForm> {
  final _service = StockService.instance;
  final _formKey = GlobalKey<FormState>();
  final _quantite = TextEditingController();
  final _cout = TextEditingController();
  final _note = TextEditingController();

  // Générée une seule fois : un nouvel envoi du même formulaire ne sera
  // jamais compté deux fois par le serveur.
  final String _cle = nouvelleCleIdempotence();

  late String _motif;
  bool _enCours = false;

  static const _motifs = {
    'ENTREE': {
      'ACHAT': 'Achat / réapprovisionnement',
      'RETOUR_CLIENT': 'Retour client',
      'AUTRE': 'Autre',
    },
    'SORTIE': {
      'VENTE': 'Vente',
      'PERTE': 'Perte',
      'CASSE': 'Casse / péremption',
      'USAGE_INTERNE': 'Usage interne',
      'RETOUR_FOURNISSEUR': 'Retour fournisseur',
      'AUTRE': 'Autre',
    },
    'AJUSTEMENT': {'INVENTAIRE': 'Inventaire'},
  };

  bool get _estEmploye => AuthState.instance.role.value == UserRole.employe;

  Map<String, String> get _motifsDuType => _motifs[widget.type]!;

  @override
  void initState() {
    super.initState();
    _motif = _motifsDuType.keys.first;
  }

  @override
  void dispose() {
    _quantite.dispose();
    _cout.dispose();
    _note.dispose();
    super.dispose();
  }

  double? _lire(String t) {
    final propre = t.replaceAll(RegExp(r'\s'), '').replaceAll(',', '.');
    if (propre.isEmpty) return null;
    return double.tryParse(propre) ?? double.nan;
  }

  String get _titre {
    switch (widget.type) {
      case 'ENTREE':
        return 'Entrée de stock';
      case 'SORTIE':
        return _estEmploye ? 'Enregistrer une vente' : 'Sortie de stock';
      default:
        return 'Inventaire';
    }
  }

  String get _libelleQuantite {
    switch (widget.type) {
      case 'ENTREE':
        return 'Quantité reçue';
      case 'SORTIE':
        return 'Quantité sortie';
      default:
        return 'Stock compté';
    }
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enCours = true);
    try {
      final produit = await _service.enregistrerMouvement(
        produitId: widget.produit.id,
        type: widget.type,
        quantite: _lire(_quantite.text)!,
        cleIdempotence: _cle,
        motif: _estEmploye ? 'VENTE' : _motif,
        coutUnitaire: widget.type == 'ENTREE' ? _lire(_cout.text) : null,
        note: _note.text,
      );
      if (!mounted) return;
      Navigator.pop(context, produit);
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
    final p = widget.produit;
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
                _titre,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.encre),
              ),
              const SizedBox(height: 4),
              Text(
                '${p.nom} · en stock : ${formatQuantite(p.stockActuel)} ${p.unite}',
                style: const TextStyle(color: AppColors.ardoise),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantite,
                keyboardType: nombre,
                autofocus: true,
                decoration: _deco(_libelleQuantite, suffixe: p.unite),
                validator: (t) {
                  final v = _lire(t ?? '');
                  if (v == null || v.isNaN) return 'Saisissez un nombre';
                  if (widget.type == 'AJUSTEMENT') {
                    if (v < 0) return 'Ne peut pas être négatif';
                  } else if (v <= 0) {
                    return 'Doit être supérieur à zéro';
                  }
                  return null;
                },
              ),
              if (widget.type == 'ENTREE') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cout,
                  keyboardType: nombre,
                  decoration: _deco(
                    "Prix d'achat unitaire",
                    suffixe: 'FCFA',
                    aide: p.coutMoyen > 0
                        ? 'Coût moyen actuel : ${formatFcfa(p.coutMoyen)}. '
                            'Laissez vide pour le conserver.'
                        : 'Sert à calculer le coût moyen et la marge.',
                  ),
                  validator: (t) {
                    final v = _lire(t ?? '');
                    if (v == null) return null;
                    return (v.isNaN || v < 0) ? 'Nombre invalide' : null;
                  },
                ),
              ],
              if (!_estEmploye && _motifsDuType.length > 1) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _motif,
                  decoration: _deco('Motif'),
                  items: _motifsDuType.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) => setState(() => _motif = v ?? _motif),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                maxLength: 255,
                decoration: _deco('Note (facultatif)'),
              ),
              const SizedBox(height: 8),
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
