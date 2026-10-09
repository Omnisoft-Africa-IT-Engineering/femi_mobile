import 'package:flutter/material.dart';
import '../../models/devis.dart';
import '../../models/ligne_devis.dart';
import '../../utils/devis_theme.dart';
import '../../utils/format.dart';
import '../../widgets/statut_badge.dart';

/// Carte d'un devis : lignes éditables, total recalculé, boutons d'action.
/// Le widget ne garde aucun état : il renvoie le devis modifié via [onChanged].
class DevisCard extends StatelessWidget {
  final Devis devis;
  final ValueChanged<Devis> onChanged;
  final VoidCallback? onApercuPdf;
  final VoidCallback? onPartager;

  const DevisCard({
    super.key,
    required this.devis,
    required this.onChanged,
    this.onApercuPdf,
    this.onPartager,
  });

  bool get _editable => devis.estModifiable;

  // HYPOTHÈSE : quantite et prixUnitaire sont des double.
  // Si ce sont des int, adaptez uniquement cette méthode (ex. .round()).
  LigneDevis _creerLigne(String designation, double quantite, double prix) =>
      LigneDevis(
        designation: designation,
        quantite: quantite,
        prixUnitaire: prix,
      );

  String _fmtQte(num q) =>
      q == q.roundToDouble() ? q.toInt().toString() : q.toString();

  void _remplacerLigne(int index, LigneDevis ligne) {
    final l = [...devis.lignes]..[index] = ligne;
    onChanged(devis.copyWith(lignes: l));
  }

  void _supprimerLigne(int index) {
    final l = [...devis.lignes]..removeAt(index);
    onChanged(devis.copyWith(lignes: l));
  }

  Future<void> _editer(BuildContext context, {int? index}) async {
    final existante = index != null ? devis.lignes[index] : null;
    final designation = TextEditingController(text: existante?.designation);
    final quantite = TextEditingController(
        text: existante != null ? _fmtQte(existante.quantite) : '1');
    final prix = TextEditingController(
        text: existante != null ? _fmtQte(existante.prixUnitaire) : '');
    final cle = GlobalKey<FormState>();

    double? nombre(String s) =>
        double.tryParse(s.replaceAll(' ', '').replaceAll(',', '.'));

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existante == null ? 'Ajouter une ligne' : 'Modifier la ligne'),
        content: Form(
          key: cle,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: designation,
                decoration: const InputDecoration(labelText: 'Désignation'),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
              ),
              TextFormField(
                controller: quantite,
                decoration: const InputDecoration(labelText: 'Quantité'),
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final n = nombre(v ?? '');
                  return (n == null || n <= 0) ? 'Quantité invalide' : null;
                },
              ),
              TextFormField(
                controller: prix,
                decoration:
                const InputDecoration(labelText: 'Prix unitaire (FCFA)'),
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final n = nombre(v ?? '');
                  return (n == null || n < 0) ? 'Prix invalide' : null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kEmeraude),
            onPressed: () {
              if (cle.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    final ligne = _creerLigne(
      designation.text.trim(),
      nombre(quantite.text)!,
      nombre(prix.text)!,
    );
    if (index == null) {
      onChanged(devis.copyWith(lignes: [...devis.lignes, ligne]));
    } else {
      _remplacerLigne(index, ligne);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête : client, numéro, statut
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(devis.clientNom,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                        '${devis.numeroDevis ?? 'Brouillon'} • ${formatDate(devis.dateEmission)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                StatutBadge(statut: devis.statut),
              ],
            ),
            const Divider(height: 24),

            // Lignes
            if (devis.lignes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Aucune ligne. Ajoutez un article.'),
              ),
            for (var i = 0; i < devis.lignes.length; i++)
              InkWell(
                onTap: _editable ? () => _editer(context, index: i) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(devis.lignes[i].designation,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text(
                              '${_fmtQte(devis.lignes[i].quantite)} × ${formatFcfa(devis.lignes[i].prixUnitaire)}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Text(formatFcfa(devis.lignes[i].totalLigne),
                          style:
                          const TextStyle(fontWeight: FontWeight.w600)),
                      if (_editable)
                        IconButton(
                          tooltip: 'Supprimer',
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => _supprimerLigne(i),
                        ),
                    ],
                  ),
                ),
              ),

            if (_editable)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _editer(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter une ligne'),
                  style: TextButton.styleFrom(foregroundColor: kEmeraude),
                ),
              ),

            const Divider(height: 24),

            // Totaux
            if (devis.tvaTaux > 0) ...[
              _ligneTotal('Sous-total', formatFcfa(devis.sousTotal)),
              _ligneTotal('TVA', formatFcfa(devis.montantTva)),
              const SizedBox(height: 4),
            ],
            _ligneTotal('Total', formatFcfa(devis.total), gras: true),
            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: devis.lignes.isEmpty ? null : onApercuPdf,
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Aperçu PDF'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: kEmeraude),
                    onPressed: devis.lignes.isEmpty ? null : onPartager,
                    icon: const Icon(Icons.share),
                    label: const Text('Partager'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _ligneTotal(String label, String valeur, {bool gras = false}) {
    final style = TextStyle(
      fontSize: gras ? 16 : 14,
      fontWeight: gras ? FontWeight.w800 : FontWeight.w500,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: style), Text(valeur, style: style)],
    );
  }
}