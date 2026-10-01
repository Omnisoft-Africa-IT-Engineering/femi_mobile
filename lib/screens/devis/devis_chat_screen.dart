import 'package:flutter/material.dart';
import '../../models/devis.dart';
import '../../services/devis_service.dart';
import '../../services/pdf_export_service.dart';
import '../../utils/devis_theme.dart';
import 'devis_card.dart';

/// Chat devis : l'utilisateur décrit le devis (texte, micro plus tard),
/// l'agent (mocké) renvoie un brouillon, affiché via DevisCard pour
/// correction avant enregistrement.
class DevisChatScreen extends StatefulWidget {
  /// Si fourni : on ouvre directement sur ce devis (déjà enregistré),
  /// sans repasser par la saisie. Sinon, on démarre en mode "nouveau".
  final Devis? devisExistant;

  const DevisChatScreen({super.key, this.devisExistant});

  @override
  State<DevisChatScreen> createState() => _DevisChatScreenState();
}

class _DevisChatScreenState extends State<DevisChatScreen> {
  final _saisieController = TextEditingController();
  final _service = DevisService.instance;

  Devis? _brouillon;
  bool _generation = false;
  bool _enregistrement = false;

  @override
  void initState() {
    super.initState();
    _brouillon = widget.devisExistant;
  }

  @override
  void dispose() {
    _saisieController.dispose();
    super.dispose();
  }

  void _info(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _genererDevis() async {
    final texte = _saisieController.text.trim();
    if (texte.isEmpty) {
      _info('Décrivez le devis, par exemple : "Devis pour M. Kodjo : 5 sacs de riz à 22 000"');
      return;
    }
    setState(() => _generation = true);
    try {
      final devis = await _service.genererDevisDepuisTexte(texte);
      if (!mounted) return;
      setState(() {
        _brouillon = devis;
        _saisieController.clear();
      });
    } catch (_) {
      if (mounted) _info("Impossible de générer le devis, réessayez.");
    } finally {
      if (mounted) setState(() => _generation = false);
    }
  }

  Future<void> _enregistrer() async {
    if (_brouillon == null) return;
    if (_brouillon!.lignes.isEmpty) {
      _info('Ajoutez au moins une ligne avant d\'enregistrer.');
      return;
    }
    setState(() => _enregistrement = true);
    try {
      final saved = await _service.enregistrerDevis(_brouillon!);
      if (!mounted) return;
      setState(() => _brouillon = saved);
      _info('Devis enregistré : ${saved.numeroDevis}');
    } catch (_) {
      if (mounted) _info("Échec de l'enregistrement, réessayez.");
    } finally {
      if (mounted) setState(() => _enregistrement = false);
    }
  }

  Future<void> _apercuPdf() async {
    if (_brouillon == null || _brouillon!.lignes.isEmpty) {
      _info('Ajoutez au moins une ligne avant de générer le PDF.');
      return;
    }
    final profil = await _service.getProfil();
    if (!mounted) return;
    if (profil == null) {
      _info('Complétez vos informations de facturation avant de générer un PDF.');
      return;
    }
    try {
      await PdfExportService.exportDevis(devis: _brouillon!, profil: profil);
    } catch (_) {
      if (mounted) _info('Impossible de générer le PDF, réessayez.');
    }
  }

  Future<void> _partager() async {
    if (_brouillon == null || _brouillon!.lignes.isEmpty) {
      _info('Ajoutez au moins une ligne avant de partager.');
      return;
    }
    final profil = await _service.getProfil();
    if (!mounted) return;
    if (profil == null) {
      _info('Complétez vos informations de facturation avant de partager.');
      return;
    }
    try {
      await PdfExportService.shareDevis(devis: _brouillon!, profil: profil);
    } catch (_) {
      if (mounted) _info('Impossible de partager le devis, réessayez.');
    }
  }

  bool get _estNouveauBrouillon => _brouillon != null && _brouillon!.id == null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_brouillon?.numeroDevis ?? 'Nouveau devis'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _brouillon == null
                ? _EtatInitial(onExemple: (texte) {
              _saisieController.text = texte;
              _genererDevis();
            })
                : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DevisCard(
                  devis: _brouillon!,
                  onChanged: (d) => setState(() => _brouillon = d),
                  onApercuPdf: _apercuPdf,
                  onPartager: _partager,
                ),
                if (_estNouveauBrouillon) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: kEmeraude),
                      onPressed:
                      _enregistrement ? null : _enregistrer,
                      child: _enregistrement
                          ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                          : const Text('Enregistrer le devis'),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Barre de saisie : reste visible seulement tant qu'aucun devis
          // n'est enregistré (avant, pour créer/ajuster ; après, la carte
          // suffit pour les corrections).
          if (_brouillon == null || _estNouveauBrouillon)
            _BarreSaisie(
              controller: _saisieController,
              chargement: _generation,
              onEnvoyer: _genererDevis,
            ),
        ],
      ),
    );
  }
}

class _EtatInitial extends StatelessWidget {
  final ValueChanged<String> onExemple;
  const _EtatInitial({required this.onExemple});

  @override
  Widget build(BuildContext context) {
    const exemple = 'Devis pour M. Kodjo : 5 sacs de riz à 22 000';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Décrivez le devis à créer',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Client, articles, quantités et prix. Vous pourrez tout corriger ensuite.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => onExemple(exemple),
              child: const Text('Essayer un exemple'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarreSaisie extends StatelessWidget {
  final TextEditingController controller;
  final bool chargement;
  final VoidCallback onEnvoyer;

  const _BarreSaisie({
    required this.controller,
    required this.chargement,
    required this.onEnvoyer,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            // Emplacement réservé pour le micro (saisie vocale, étape suivante).
            IconButton(
              tooltip: 'Saisie vocale (bientôt disponible)',
              icon: const Icon(Icons.mic_none),
              onPressed: null,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                enabled: !chargement,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => chargement ? null : onEnvoyer(),
                decoration: InputDecoration(
                  hintText: 'Ex. Devis pour M. Kodjo : 5 sacs de riz à 22 000',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              style: IconButton.styleFrom(backgroundColor: kEmeraude),
              onPressed: chargement ? null : onEnvoyer,
              icon: chargement
                  ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.send, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}