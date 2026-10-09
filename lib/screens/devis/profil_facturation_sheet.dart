import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/profil_facturation.dart';
import '../../services/devis_service.dart';
import '../../utils/devis_theme.dart';

/// Ouvre la feuille de configuration En-tête / Pied de page.
/// Renvoie `true` si le profil a été enregistré.
Future<bool?> showProfilFacturationSheet(
    BuildContext context, {
      ProfilFacturation? initial,
    }) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ProfilFacturationSheet(initial: initial),
  );
}

class _ProfilFacturationSheet extends StatefulWidget {
  final ProfilFacturation? initial;
  const _ProfilFacturationSheet({this.initial});

  @override
  State<_ProfilFacturationSheet> createState() =>
      _ProfilFacturationSheetState();
}

class _ProfilFacturationSheetState extends State<_ProfilFacturationSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nom;
  late final TextEditingController _tel;
  late final TextEditingController _adresse;
  late final TextEditingController _nif;
  late final TextEditingController _paiement;
  late final TextEditingController _conditions;
  String? _logoPath;
  bool _saving = false;

  bool get _premiereFois =>
      widget.initial == null || !widget.initial!.pretPourDevis;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _nom = TextEditingController(text: p?.nomCommercial ?? '');
    _tel = TextEditingController(text: p?.telephonePro ?? '');
    _adresse = TextEditingController(text: p?.adresse ?? '');
    _nif = TextEditingController(text: p?.nifRccm ?? '');
    _paiement = TextEditingController(text: p?.moyensPaiement ?? '');
    _conditions = TextEditingController(text: p?.conditionsDefaut ?? '');
    _logoPath = p?.logoLocalPath;
  }

  @override
  void dispose() {
    for (final c in [_nom, _tel, _adresse, _nif, _paiement, _conditions]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _choisirLogo() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (x != null) setState(() => _logoPath = x.path);
  }

  String? _obligatoire(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null;

  String? _nullSiVide(String s) => s.trim().isEmpty ? null : s.trim();

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await DevisService.instance.enregistrerProfil(
        ProfilFacturation(
          nomCommercial: _nom.text.trim(),
          telephonePro: _tel.text.trim(),
          adresse: _nullSiVide(_adresse.text),
          nifRccm: _nullSiVide(_nif.text),
          moyensPaiement: _paiement.text.trim(),
          conditionsDefaut: _nullSiVide(_conditions.text),
          logoUrl: widget.initial?.logoUrl,
          logoLocalPath: _logoPath,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Échec de l'enregistrement. Réessayez.")),
      );
    }
  }

  Widget _logo() {
    ImageProvider? image;
    if (_logoPath != null) {
      image = FileImage(File(_logoPath!));
    } else if (widget.initial?.logoUrl != null) {
      image = NetworkImage(widget.initial!.logoUrl!);
    }
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: kEmeraude.withAlpha(30),
          backgroundImage: image,
          child: image == null
              ? const Icon(Icons.storefront, color: kEmeraude, size: 30)
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _choisirLogo,
            icon: const Icon(Icons.image_outlined),
            label: Text(image == null
                ? 'Ajouter un logo (optionnel)'
                : 'Changer le logo'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _premiereFois
                    ? "Bienvenue dans l'outil de devis Femi !"
                    : 'Mes informations de facturation',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _premiereFois
                    ? 'Configurez votre en-tête et votre pied de page une seule '
                    'fois : ils habilleront tous vos futurs documents.'
                    : 'Ces informations apparaissent sur vos devis et factures.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              _logo(),
              const SizedBox(height: 20),
              Text('En-tête',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nom,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    labelText: 'Nom commercial *',
                    border: OutlineInputBorder()),
                validator: _obligatoire,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tel,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Téléphone professionnel *',
                    border: OutlineInputBorder()),
                validator: _obligatoire,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _adresse,
                decoration: const InputDecoration(
                    labelText: 'Adresse', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nif,
                decoration: const InputDecoration(
                  labelText: 'NIF / RCCM',
                  helperText: 'Facultatif pour un devis, requis pour une facture',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Text('Pied de page',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _paiement,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Moyens de paiement *',
                  hintText: 'Ex : Flooz 90 00 00 00 / T-Money 99 00 00 00',
                  border: OutlineInputBorder(),
                ),
                validator: _obligatoire,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _conditions,
                decoration: const InputDecoration(
                  labelText: 'Conditions par défaut',
                  hintText: 'Ex : Devis valable 30 jours',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: kEmeraude,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _saving ? null : _enregistrer,
                  child: _saving
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}