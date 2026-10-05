import 'package:flutter/material.dart';
import '../../models/devis.dart';
import '../../services/devis_service.dart';
import 'devis_card.dart';

class DevisDetailScreen extends StatefulWidget {
  final Devis devis;
  const DevisDetailScreen({super.key, required this.devis});

  @override
  State<DevisDetailScreen> createState() => _DevisDetailScreenState();
}

class _DevisDetailScreenState extends State<DevisDetailScreen> {
  final _service = DevisService.instance;
  late Devis _devis;
  bool _modifie = false;

  // Le statut CONVERTI n'est pas proposé : il sera posé par la conversion
  // en facture (phase 2).
  static const _statutsProposes = [
    StatutDevis.brouillon,
    StatutDevis.envoye,
    StatutDevis.accepte,
    StatutDevis.refuse,
  ];

  @override
  void initState() {
    super.initState();
    _devis = widget.devis;
  }

  Future<void> _changerStatut(StatutDevis nouveau) async {
    try {
      await _service.changerStatut(_devis.id!, nouveau);
      if (!mounted) return;
      setState(() => _devis = _devis.copyWith(statut: nouveau));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Statut : ${nouveau.label}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec du changement de statut.')),
      );
    }
  }

  void _pdfBientot() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF bientôt disponible')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final converti = _devis.statut == StatutDevis.converti;
    return Scaffold(
      appBar: AppBar(
        title: Text(_devis.numeroDevis ?? 'Brouillon'),
        actions: [
          if (!converti)
            PopupMenuButton<StatutDevis>(
              tooltip: 'Changer le statut',
              icon: const Icon(Icons.swap_horiz),
              onSelected: _changerStatut,
              itemBuilder: (_) => [
                for (final s in _statutsProposes)
                  PopupMenuItem(value: s, child: Text(s.label)),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DevisCard(
              devis: _devis,
              onChanged: (d) => setState(() {
                _devis = d;
                _modifie = true;
              }),
              onApercuPdf: _pdfBientot,
              onPartager: _pdfBientot,
            ),
            if (_modifie)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Modifications des lignes non enregistrées (disponible '
                      'avec l\'API).',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
          ],
        ),
      ),
    );
  }
}