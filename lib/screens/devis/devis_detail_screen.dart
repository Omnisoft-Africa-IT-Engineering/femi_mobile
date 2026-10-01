import 'package:flutter/material.dart';
import '../../models/devis.dart';
import '../../services/devis_service.dart';
import '../../utils/devis_theme.dart';
import 'devis_card.dart';

/// Écran provisoire pour voir la carte dans l'app.
/// Sera remplacé par le chat devis (qui affichera la même DevisCard).
class DevisDetailScreen extends StatefulWidget {
  final Devis devis;
  const DevisDetailScreen({super.key, required this.devis});

  @override
  State<DevisDetailScreen> createState() => _DevisDetailScreenState();
}

class _DevisDetailScreenState extends State<DevisDetailScreen> {
  late Devis _devis = widget.devis;
  bool _enregistrement = false;

  void _info(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _enregistrer() async {
    setState(() => _enregistrement = true);
    try {
      final saved = await DevisService.instance.enregistrerDevis(_devis);
      if (!mounted) return;
      setState(() => _devis = saved);
      _info('Devis enregistré : ${saved.numeroDevis}');
    } catch (_) {
      if (mounted) _info("Échec de l'enregistrement");
    } finally {
      if (mounted) setState(() => _enregistrement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estBrouillon = _devis.id == null;
    return Scaffold(
      appBar: AppBar(title: Text(_devis.numeroDevis ?? 'Nouveau devis')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DevisCard(
            devis: _devis,
            onChanged: (d) => setState(() => _devis = d),
            onApercuPdf: () => _info('Aperçu PDF : prochaine étape'),
            onPartager: () => _info('Partage : prochaine étape'),
          ),
          if (estBrouillon) ...[
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kEmeraude),
              onPressed: _enregistrement ? null : _enregistrer,
              child: _enregistrement
                  ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Enregistrer le devis'),
            ),
          ],
        ],
      ),
    );
  }
}